import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnrolledStudentsProvider extends ChangeNotifier {
  // TestId param passed in init
  String? _testId;

  // Pagination & cache data
  final List<String> _studentUids = [];
  final List<DocumentSnapshot> _lastDocs = [];
  final Map<String, Map<String, dynamic>> _studentCache = {};
  final Map<String, Timestamp?> _enrolledAtMap = {};

  bool _isLoading = false;
  bool _hasMore = true;
  int _totalStudents = 0;
  bool _isSearching = false;
  String _searchQuery = "";

  final int _limit = 20;

  // Real-time subscription for total enrolled students
  StreamSubscription<QuerySnapshot>? _totalStudentsSubscription;

  // Getters
  List<String> get studentUids {
    if (!_isSearching) return _studentUids;

    return _studentUids.where((uid) {
      final data = _studentCache[uid];
      if (data == null) return false;
      final name = (data['fullName'] ?? "").toString().toLowerCase();
      final email = (data['email'] ?? "").toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Map<String, Map<String, dynamic>> get studentCache => _studentCache;
  Map<String, Timestamp?> get enrolledAtMap => _enrolledAtMap;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  int get totalStudents => _totalStudents;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;

  /// Initialize provider with testId param
  Future<void> init(String testId) async {
    if (_testId != testId) {
      // Reset on new testId
      _testId = testId;
      _studentUids.clear();
      _lastDocs.clear();
      _studentCache.clear();
      _enrolledAtMap.clear();
      _hasMore = true;
      _isLoading = false;
      _searchQuery = "";
      _isSearching = false;
      _totalStudents = 0;

  

      // Fetch initial data
      await fetchStudents(isRefresh: true);
    }
  }

  /// Dispose subscription when provider disposed
  @override
  void dispose() {
    _totalStudentsSubscription?.cancel();
    super.dispose();
  }

  /// Fetch paginated students data
  Future<void> fetchStudents({bool isRefresh = false}) async {
    if (_isLoading || _testId == null) return;

    if (isRefresh) {
      _studentUids.clear();
      _lastDocs.clear();
      _hasMore = true;
      _studentCache.clear();
      _enrolledAtMap.clear();
      notifyListeners();
    }

    if (!_hasMore && !isRefresh) return;

    _isLoading = true;
    notifyListeners();

    Query query = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(_testId!)
        .collection('enrolledStudents')
        .orderBy(FieldPath.documentId)
        .limit(_limit);

    if (_lastDocs.isNotEmpty && !isRefresh) {
      query = query.startAfterDocument(_lastDocs.last);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        final uid = doc.id;
        final data = doc.data() as Map<String, dynamic>;

        _enrolledAtMap[uid] = data['enrolledAt'] is Timestamp
            ? data['enrolledAt'] as Timestamp
            : null;

        if (!_studentCache.containsKey(uid)) {
          final studentData = await _getStudentData(uid);
          if (studentData != null) {
            _studentCache[uid] = studentData;
          }
        }
      }

      _studentUids.addAll(snapshot.docs.map((doc) => doc.id));
      _lastDocs.add(snapshot.docs.last);
    } else {
      _hasMore = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _getStudentData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching student data for $uid: $e");
      }
      return null;
    }
  }

  /// Scroll listener to trigger pagination
  void scrollListener(double pixels, double maxScrollExtent) {
    if (pixels >= maxScrollExtent - 200) {
      fetchStudents();
    }
  }

  /// Set search query for filtering
  void setSearchQuery(String query) {
    _searchQuery = query;
    _isSearching = query.isNotEmpty;
    notifyListeners();
  }
}
