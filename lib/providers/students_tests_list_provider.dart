// test_list_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestListProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<DocumentSnapshot> _quizzes = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String? _error;

  List<DocumentSnapshot> get quizzes => _quizzes;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> loadInitial({
    required String uid,
    required String coachingCode,
    required String filter,
  }) async {
    _quizzes.clear();
    _lastDocument = null;
    _hasMore = true;
    await _loadMore(uid: uid, coachingCode: coachingCode, filter: filter);
  }

  Future<void> loadMore({
    required String uid,
    required String coachingCode,
    required String filter,
  }) async {
    if (_isLoading || !_hasMore) return;
    await _loadMore(uid: uid, coachingCode: coachingCode, filter: filter);
  }

  Future<void> _loadMore({
    required String uid,
    required String coachingCode,
    required String filter,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query query = _firestore
          .collection('quizzes')
          .where('coachingCode', isEqualTo: coachingCode)
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      final now = DateTime.now();

      final newDocs = <DocumentSnapshot>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final Timestamp? testTs = data['testDateTime'];
        final DateTime? testDate = testTs?.toDate();
        final isCompleted = testDate != null && testDate.isBefore(now);
        final isUpcoming = testDate != null && testDate.isAfter(now);
        final String status = (data['status'] ?? '').toString();

        final enrolledSnapshot = await _firestore
            .collection('quizzes')
            .doc(doc.id)
            .collection('enrolledStudents')
            .doc(uid)
            .get();

        final isEnrolled = enrolledSnapshot.exists;

        bool shouldInclude = false;

        switch (filter) {
          case 'enrolled':
            if (status != 'completed') shouldInclude = isEnrolled;
            break;
          case 'completed':
            if (status != 'live' && status != 'live_pending') {
              shouldInclude = isCompleted;
            }
            break;
          case 'upcoming':
            if (!isEnrolled && (isUpcoming || status == 'live_pending'))
              shouldInclude = true;
            break;
          default:
            shouldInclude = true;
        }

        if (shouldInclude) {
          newDocs.add(doc);
        }
      }

      if (newDocs.isNotEmpty) {
        _lastDocument = newDocs.last;
        _quizzes.addAll(newDocs);
      }

      if (snapshot.docs.length < 10) {
        _hasMore = false;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh({
    required String uid,
    required String coachingCode,
    required String filter,
  }) async {
    _quizzes.clear();
    _lastDocument = null;
    _hasMore = true;
    await _loadMore(uid: uid, coachingCode: coachingCode, filter: filter);
  }
}
