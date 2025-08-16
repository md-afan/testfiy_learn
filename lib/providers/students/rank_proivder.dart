import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/secure_locally_storage.dart';

class LeaderboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> tests = [];
  List<Map<String, dynamic>> leaderboardData = [];
  String? selectedTestId;
  String selectedTestName = '';
  String coachingCode = '';

  bool isLoadingTests = false;
  bool isLoadingLeaderboard = false;
  bool isLoadingMore = false;
  bool hasMore = true;

  static const int pageSize = 15;

  DocumentSnapshot? lastDocument; // For pagination cursor

  /// Initialize provider: load coachingCode and tests
  Future<void> init() async {
    coachingCode =
        (await LocalStorage.getLocalStorage("coachingCode")).toString();
    await fetchTests();
  }

  /// Fetch tests (no pagination needed)
  Future<void> fetchTests() async {
    isLoadingTests = true;
    notifyListeners();

    final snapshot = await _firestore
        .collection('quizzes')
        .where('coachingCode', isEqualTo: coachingCode)
        .where('status', isEqualTo: 'completed')
        .get(GetOptions(source: Source.cache)) // Try cache first
        .catchError((_) => _firestore
            .collection('quizzes')
            .where('coachingCode', isEqualTo: coachingCode)
            .where('status', isEqualTo: 'completed')
            .get(GetOptions(source: Source.server)));

    tests = snapshot.docs.map((doc) {
      final data = doc.data();
      final Timestamp startTime = data['testDateTime'] ?? Timestamp.now();
      final formattedTime =
          DateFormat('dd MMM yyyy').format(startTime.toDate());

      return {
        'id': doc.id,
        'testName': data['title'] ?? 'Untitled Test',
        'displayName': "${data['title'] ?? 'Untitled'} - $formattedTime",
      };
    }).toList();

    isLoadingTests = false;

    if (tests.isNotEmpty) {
      selectedTestId = tests.first['id'];
      selectedTestName = tests.first['testName'];
      await refreshLeaderboard(); // Fetch first page of leaderboard
    }

    notifyListeners();
  }

  /// Format seconds into MM:SS
  String formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Refresh leaderboard: clear old data and fetch first page from cache or server
  Future<void> refreshLeaderboard() async {
    if (selectedTestId == null) return;

    isLoadingLeaderboard = true;
    hasMore = true;
    lastDocument = null;
    leaderboardData = [];
    notifyListeners();

    try {
      final snapshot = await _fetchLeaderboardPage(
        testId: selectedTestId!,
        startAfterDoc: null,
        source: Source.cache,
      );

      if (snapshot.docs.isEmpty) {
        // fallback to server
        final serverSnapshot = await _fetchLeaderboardPage(
          testId: selectedTestId!,
          startAfterDoc: null,
          source: Source.server,
        );
        await _processSnapshot(serverSnapshot);
      } else {
        await _processSnapshot(snapshot);
      }
    } catch (_) {
      // On error fallback to server
      final serverSnapshot = await _fetchLeaderboardPage(
        testId: selectedTestId!,
        startAfterDoc: null,
        source: Source.server,
      );
      await _processSnapshot(serverSnapshot);
    }
    isLoadingLeaderboard = false;
    notifyListeners();
  }

  /// Load more leaderboard entries (pagination)
  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore || selectedTestId == null) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      final snapshot = await _fetchLeaderboardPage(
        testId: selectedTestId!,
        startAfterDoc: lastDocument,
        source: Source.server, // For pagination, prefer server
      );

      if (snapshot.docs.isNotEmpty) {
        await _processSnapshot(snapshot, append: true);
      } else {
        hasMore = false;
      }
    } catch (_) {
      // Could log error or silently ignore loadMore failure
    }

    isLoadingMore = false;
    notifyListeners();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchLeaderboardPage({
    required String testId,
    DocumentSnapshot? startAfterDoc,
    required Source source,
  }) {
    var ref = _firestore
        .collection('quizzes')
        .doc(testId)
        .collection('leaderboard')
        .orderBy('rank')
        .limit(pageSize);

    if (startAfterDoc != null) {
      ref = ref.startAfterDocument(startAfterDoc);
    }

    return ref.get(GetOptions(source: source));
  }

  Future<void> _processSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot,
      {bool append = false}) async {
    List<Map<String, dynamic>> tempList = [];

    for (final doc in snapshot.docs) {
      final d = doc.data();
      final int seconds = d['timeTaken'] is String
          ? int.tryParse(d['timeTaken']) ?? 0
          : (d['timeTaken'] ?? 0);

      String? name;
      String? avatarUrl;

      try {
        final studentSnap = await _firestore
            .collection('students')
            .doc(doc.id)
            .get(GetOptions(source: Source.cache));
        if (!studentSnap.exists) {
          // Fallback to server for student info
          final s2 = await _firestore
              .collection('students')
              .doc(doc.id)
              .get(GetOptions(source: Source.server));
          if (s2.exists) {
            final s = s2.data() ?? {};
            name = s['fullName'] ?? "Anonymous";
            avatarUrl = s['profileImageUrl'] ??
                "https://mohdbinsufiyan.vercel.app/assets/media/mypic.jpg";
          }
        } else {
          final s = studentSnap.data() ?? {};
          name = s['fullName'] ?? "Anonymous";
          avatarUrl = s['profileImageUrl'] ??
              "https://mohdbinsufiyan.vercel.app/assets/media/mypic.jpg";
        }
      } catch (_) {
        // fallback name/avatar
      }

      tempList.add({
        'uid': doc.id,
        'name': name,
        'avatarUrl': avatarUrl,
        'score': d['score'] ?? 0,
        'timeTaken': seconds,
        'time': formatSeconds(seconds),
        'rank': d['rank'] ?? 0,
        'reward': d['reward'] ?? 0,
      });
    }

    if (append) {
      leaderboardData.addAll(tempList);
    } else {
      leaderboardData = tempList;
    }

    lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    hasMore = snapshot.docs.length == pageSize;
  }

  /// Select a new test and load its leaderboard fresh
  Future<void> selectTest(String testId) async {
    if (testId == selectedTestId) return;
    selectedTestId = testId;
    selectedTestName =
        tests.firstWhere((t) => t['id'] == testId)['testName'] ?? '';
    await refreshLeaderboard();
  }
}
