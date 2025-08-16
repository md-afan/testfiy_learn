import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestListProvider with ChangeNotifier {
  final String uid;
  final String coachingCode;
  final int pageSize;

  TestListProvider({
    required this.uid,
    required this.coachingCode,
    this.pageSize = 10,
  }) {
    fetchInitialTests();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> _tests = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String? _error;

  List<DocumentSnapshot> get tests => _tests;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> fetchInitialTests() async {
    _tests.clear();
    _lastDocument = null;
    _hasMore = true;
    _error = null;
    notifyListeners();
    await fetchNextTests();
  }

  Future<void> fetchNextTests() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query query = _firestore
          .collection('quizzes')
          .where('createdBy', isEqualTo: uid)
          .where('coachingCode', isEqualTo: coachingCode)
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      // First try cache
      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await query.get(GetOptions(source: Source.cache));
        if (querySnapshot.docs.isEmpty) throw Exception('Cache empty');
      } catch (_) {
        // fallback to server
        querySnapshot = await query.get(GetOptions(source: Source.server));
      }

      final fetchedDocs = querySnapshot.docs;

      if (fetchedDocs.length < pageSize) {
        _hasMore = false;
      }

      if (fetchedDocs.isNotEmpty) {
        _lastDocument = fetchedDocs.last;
        _tests.addAll(fetchedDocs);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshTests() async {
    await fetchInitialTests();
  }
}
