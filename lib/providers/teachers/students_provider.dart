import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentsProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _hasMore = true;
  List<DocumentSnapshot> _students = [];
  DocumentSnapshot? _lastDocument;
  List<String> _uids = []; // keep full list of UIDs for pagination

  List<DocumentSnapshot> get students => _students;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> loadStudents(String coachingCode) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch student UIDs with cache first
      var uidsSnap = await FirebaseFirestore.instance
          .collection('coachingCodes')
          .doc(coachingCode)
          .collection('students')
          .get(GetOptions(source: Source.cache));

      if (uidsSnap.docs.isEmpty) {
        uidsSnap = await FirebaseFirestore.instance
            .collection('coachingCodes')
            .doc(coachingCode)
            .collection('students')
            .get(GetOptions(source: Source.server));
      }

      _uids = uidsSnap.docs.map((d) => d.id).toList();

      _students.clear();
      _lastDocument = null;
      _hasMore = true;

      await _fetchStudentsBatch(0);
    } catch (e) {
      debugPrint('StudentsProvider loadStudents error: $e');
      _hasMore = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchStudentsBatch(int startIndex) async {
    const batchSize = 15;
    if (startIndex >= _uids.length) {
      _hasMore = false;
      return;
    }

    final batch = _uids.sublist(
      startIndex,
      (startIndex + batchSize > _uids.length)
          ? _uids.length
          : startIndex + batchSize,
    );

    try {
      // Fetch student docs by batch with cache first
      var snapshot = await FirebaseFirestore.instance
          .collection('students')
          .where(FieldPath.documentId, whereIn: batch)
          .get(GetOptions(source: Source.cache));

      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('students')
            .where(FieldPath.documentId, whereIn: batch)
            .get(GetOptions(source: Source.server));
      }

      _students.addAll(snapshot.docs);

      if (_students.length < _uids.length) {
        _hasMore = true;
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('StudentsProvider _fetchStudentsBatch error: $e');
      _hasMore = false;
    }
  }

  Future<void> loadMoreStudents(String coachingCode) async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (_students.isEmpty) {
        await loadStudents(coachingCode);
        _isLoading = false;
        notifyListeners();
        return;
      }

      final currentCount = _students.length;
      await _fetchStudentsBatch(currentCount);
    } catch (e) {
      debugPrint('StudentsProvider loadMoreStudents error: $e');
      _hasMore = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh(String coachingCode) async {
    _hasMore = true;
    _lastDocument = null;
    _students.clear();
    _uids.clear();
    await loadStudents(coachingCode);
  }
}
