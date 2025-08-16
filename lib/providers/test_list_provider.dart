import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestListProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _error;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _quizzes = [];

  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  String? get error => _error;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get quizzes => _quizzes;

  Future<void> loadTests(String uid, String coachingCode) async {
    if (_isLoaded) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('createdBy', isEqualTo: uid)
          .where('coachingCode', isEqualTo: coachingCode)
          .orderBy('createdAt', descending: true)
          .get();

      _quizzes = snapshot.docs;
      _isLoaded = true;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh(String uid, String coachingCode) async {
    _isLoaded = false;
    await loadTests(uid, coachingCode);
  }
}
