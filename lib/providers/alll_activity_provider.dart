import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllActivityProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  final List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> get allData => List.unmodifiable(_allData);

  bool _serverFetched = false; // 🔁 Track if server fetch happened

  /// Call this to load (or reload) data
  Future<void> loadActivities(String uid, String coachingCode,
      {bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    _allData.clear();
    notifyListeners();

    try {
      final List<Map<String, dynamic>> tempData = [];

      /// Determine source
      final Source preferredSource =
          (forceRefresh || !_serverFetched) ? Source.server : Source.cache;

      // 🔹 Fetch quizzes
      List<QueryDocumentSnapshot<Map<String, dynamic>>> quizDocs = [];
      try {
        final quizSnap = await FirebaseFirestore.instance
            .collection('quizzes')
            .where('createdBy', isEqualTo: uid)
            .where('coachingCode', isEqualTo: coachingCode)
            .get(GetOptions(source: preferredSource));
        quizDocs = quizSnap.docs;
        debugPrint("✅ quizzes loaded from $preferredSource");
      } catch (e) {
        if (preferredSource == Source.cache) {
          debugPrint("⚠️ Cache failed, trying server...");
          final fallbackSnap = await FirebaseFirestore.instance
              .collection('quizzes')
              .where('createdBy', isEqualTo: uid)
              .where('coachingCode', isEqualTo: coachingCode)
              .get(const GetOptions(source: Source.server));
          quizDocs = fallbackSnap.docs;
          _serverFetched = true;
        }
      }

      for (final doc in quizDocs) {
        final quizData = doc.data();
        tempData.add({
          'type': 'quiz',
          'id': doc.id,
          'data': quizData,
          'createdAt':
              quizData['createdAt'] is Timestamp ? quizData['createdAt'] : null,
        });
      }

      // 🔹 Fetch students
      List<QueryDocumentSnapshot<Map<String, dynamic>>> joinedDocs = [];
      try {
        final joinedSnap = await FirebaseFirestore.instance
            .collection('coachingCodes')
            .doc(coachingCode)
            .collection('students')
            .get(GetOptions(source: preferredSource));
        joinedDocs = joinedSnap.docs;
        debugPrint("✅ students loaded from $preferredSource");
      } catch (e) {
        if (preferredSource == Source.cache) {
          debugPrint("⚠️ Cache failed for students, trying server...");
          final fallbackSnap = await FirebaseFirestore.instance
              .collection('coachingCodes')
              .doc(coachingCode)
              .collection('students')
              .get(const GetOptions(source: Source.server));
          joinedDocs = fallbackSnap.docs;
          _serverFetched = true;
        }
      }

      for (final subDoc in joinedDocs) {
        final studentUid = subDoc.id;

        DocumentSnapshot<Map<String, dynamic>> studentDoc;
        try {
          studentDoc = await FirebaseFirestore.instance
              .collection('students')
              .doc(studentUid)
              .get(GetOptions(source: preferredSource));
        } catch (e) {
          if (preferredSource == Source.cache) {
            debugPrint(
                "⚠️ Cache failed for student $studentUid, trying server...");
            studentDoc = await FirebaseFirestore.instance
                .collection('students')
                .doc(studentUid)
                .get(const GetOptions(source: Source.server));
            _serverFetched = true;
          } else {
            rethrow;
          }
        }

        if (studentDoc.exists) {
          final studentData = studentDoc.data()!;
          final joinedAt = subDoc.data()['joinedAt'];
          tempData.add({
            'type': 'student',
            'id': studentUid,
            'data': studentData,
            'createdAt': joinedAt is Timestamp
                ? joinedAt
                : (studentData['createdAt'] is Timestamp
                    ? studentData['createdAt']
                    : null),
          });
        }
      }

      // 🔹 Sort by createdAt
      tempData.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      _allData.addAll(tempData);
      if (preferredSource == Source.server) _serverFetched = true;
    } catch (e, st) {
      debugPrint("❌ Error loading activities: $e");
      debugPrint(st.toString());
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
