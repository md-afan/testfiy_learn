import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentTestListProvider extends ChangeNotifier {
  String? coachingCode;
  String? uid;
  String filter = 'all';

  final int pageSize = 10;

  bool isLoading = false;
  bool isFetchingMore = false;
  bool hasMore = true;
  String errorMessage = '';

  List<QueryDocumentSnapshot<Map<String, dynamic>>> tests = [];
  DocumentSnapshot<Map<String, dynamic>>? lastDoc;

  bool _hasInitialServerFetch = false;

  StudentTestListProvider();

  void setParams({
    required String coachingCode,
    required String uid,
    String? filter,
  }) {
    this.coachingCode = coachingCode;
    this.uid = uid;
    if (filter != null) this.filter = filter;
    resetData();
    notifyListeners();
  }

  void resetData() {
    tests.clear();
    lastDoc = null;
    hasMore = true;
    _hasInitialServerFetch = false;
    errorMessage = '';
  }

  Future<void> loadTests({bool refresh = false}) async {
    if (isLoading) return;
    if (coachingCode == null || uid == null) {
      errorMessage = 'coachingCode or uid is not set';
      notifyListeners();
      return;
    }

    isLoading = true;
    if (refresh) {
      resetData();
    }
    notifyListeners();

    try {
      final now = DateTime.now();

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('quizzes')
          .where('coachingCode', isEqualTo: coachingCode)
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc!);
      }

      // Fetch from server only for initial load or refresh
      // Otherwise use cache
      Source source =
          (_hasInitialServerFetch && !refresh) ? Source.cache : Source.server;

      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await query.get(GetOptions(source: source));

      // If this was a server fetch, mark that we've done initial server fetch
      if (source == Source.server || refresh) {
        _hasInitialServerFetch = true;
      }

      if (querySnapshot.docs.isNotEmpty) {
        lastDoc = querySnapshot.docs.last;
      } else {
        hasMore = false;
      }

      final enrollmentMap = await _fetchEnrollmentMapBatch(
        querySnapshot.docs.map((d) => d.id).toList(),
      );

      final filtered = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final Timestamp? testTs = data['testDateTime'];
        final DateTime? testDate = testTs?.toDate();
        final isEnrolled = enrollmentMap[doc.id] ?? false;
        final isCompleted = testDate != null && testDate.isBefore(now);
        final isUpcoming = testDate != null && testDate.isAfter(now);
        final String status = (data['status'] ?? '').toString();

        switch (filter) {
          case 'enrolled':
            if (status == 'completed') return false;
            return isEnrolled;
          case 'completed':
            if (status == 'pending' || status == 'live') return false;
            return isCompleted;
          case 'upcoming':
            if (isUpcoming && !isEnrolled) return true;
            if (status == 'pending' && !isEnrolled) return true;
            return false;
          default:
            return true;
        }
      });

      if (refresh) {
        tests = filtered.toList();
      } else {
        tests.addAll(filtered);
      }
    } catch (e) {
      errorMessage = e.toString();
      print("Error loading tests: $errorMessage");
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMoreTests() async {
    if (isFetchingMore || !hasMore) return;
    isFetchingMore = true;
    notifyListeners();

    await loadTests();
    isFetchingMore = false;
    notifyListeners();
  }

  Future<void> refreshTests() async {
    await loadTests(refresh: true);
  }

  Future<Map<String, bool>> _fetchEnrollmentMapBatch(
      List<String> quizIds) async {
    final Map<String, bool> enrollmentMap = {};

    if (quizIds.isEmpty) return enrollmentMap;

    final futures = quizIds.map((quizId) async {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId)
          .collection('enrolledStudents')
          .doc(uid)
          .get();

      enrollmentMap[quizId] = docSnapshot.exists;
    });

    await Future.wait(futures);

    return enrollmentMap;
  }
}
