import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestsProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isLoaded = false;
  List<DocumentSnapshot> _tests = [];

  List<DocumentSnapshot> get tests => _tests;
  bool get isLoading => _isLoading;

  Future<void> loadTests() async {
    if (_isLoaded) return; // Already loaded
    _isLoading = true;
    notifyListeners();

    try {
      final snap = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      _tests = snap.docs;
    } catch (e) {
      debugPrint('TestsProvider error: $e');
    }

    _isLoading = false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    _isLoaded = false;
    await loadTests();
  }
}
