import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/secure_locally_storage.dart';

class StudentDashboardProvider extends ChangeNotifier {
  int _tabIndex = 0;
  String? _coachingCode;
  String? _coachingName;
  String? _coachingImageUrl;
  String _uid = "";
  bool _isLoading = false;

  int _testsTaken = 0;
  int _testsWon = 0;
  int _rank = 0;

  // Getters
  int get tabIndex => _tabIndex;
  String? get coachingCode => _coachingCode;
  String? get coachingName => _coachingName;
  String? get coachingImageUrl => _coachingImageUrl;
  String get uid => _uid;
  bool get isLoading => _isLoading;
  int get testsTaken => _testsTaken;
  int get testsWon => _testsWon;
  int get rank => _rank;

  get isLoadingTests => null;

  // Set Tab
  void setTab(int index) {
    _tabIndex = index;
    notifyListeners();
  }

  // Load from local storage
  Future<void> loadLocalData() async {
    _coachingCode = await LocalStorage.getLocalStorage("coachingCode");
    _coachingName = await LocalStorage.getLocalStorage("coachingName");
    _coachingImageUrl = await LocalStorage.getLocalStorage("coachingImage");
    _uid = (await LocalStorage.getLocalStorage("uid")).toString();
    notifyListeners();
  }

  // Fetch all data
  Future<void> fetchAllData() async {
    if (_coachingCode == null || _uid.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    await Future.wait([
      fetchStats(),
      fetchCoachingDetails(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  // Fetch stats for quizzes (server first, then cache)
  Future<void> fetchStats() async {
    try {
      QuerySnapshot<Map<String, dynamic>> quizzesSnap;

      try {
        // Try server first
        quizzesSnap = await FirebaseFirestore.instance
            .collection("quizzes")
            .where("coachingCode", isEqualTo: _coachingCode)
            .get(const GetOptions(source: Source.serverAndCache));
      } catch (_) {
        // If fails, try cache
        quizzesSnap = await FirebaseFirestore.instance
            .collection("quizzes")
            .where("coachingCode", isEqualTo: _coachingCode)
            .get(const GetOptions(source: Source.cache));
      }

      String? lastQuizId;
      Timestamp? lastQuizTime;

      await Future.wait(quizzesSnap.docs.map((quizDoc) async {
        final quizId = quizDoc.id;

        // Submissions (server first, then cache)
        DocumentSnapshot submissionDoc;
        try {
          submissionDoc = await FirebaseFirestore.instance
              .collection("quizzes")
              .doc(quizId)
              .collection("submissions")
              .doc(_uid)
              .get(const GetOptions(source: Source.serverAndCache));
        } catch (_) {
          submissionDoc = await FirebaseFirestore.instance
              .collection("quizzes")
              .doc(quizId)
              .collection("submissions")
              .doc(_uid)
              .get(const GetOptions(source: Source.cache));
        }
        if (submissionDoc.exists) {
          _testsTaken++;

          final data = submissionDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            final submittedAt = data["submittedAt"];
            if (submittedAt is Timestamp) {
              if (lastQuizTime == null ||
                  submittedAt.compareTo(lastQuizTime!) > 0) {
                lastQuizTime = submittedAt;
                lastQuizId = quizId;
              }
            }
          }
        }

        // Leaderboard (server first, then cache)
        DocumentSnapshot leaderboardDoc;
        try {
          leaderboardDoc = await FirebaseFirestore.instance
              .collection("quizzes")
              .doc(quizId)
              .collection("leaderboard")
              .doc(_uid)
              .get(const GetOptions(source: Source.serverAndCache));
        } catch (_) {
          leaderboardDoc = await FirebaseFirestore.instance
              .collection("quizzes")
              .doc(quizId)
              .collection("leaderboard")
              .doc(_uid)
              .get(const GetOptions(source: Source.cache));
        }
        final data = submissionDoc.data() as Map<String, dynamic>?;
        final submittedAt = data?["submittedAt"] as Timestamp?;
        if (submittedAt != null) {
          // your logic
        }
      }));

      // Rank for most recent quiz
      if (lastQuizId != null) {
        try {
          final rankDoc = await FirebaseFirestore.instance
              .collection("quizzes")
              .doc(lastQuizId)
              .collection("leaderboard")
              .doc(_uid)
              .get(const GetOptions(source: Source.serverAndCache));

          if (rankDoc.exists) {
            _rank = rankDoc.data()?["rank"] ?? 0;
          }
        } catch (_) {
          final rankDoc = await FirebaseFirestore.instance
              .collection("quizzes")
              .doc(lastQuizId)
              .collection("leaderboard")
              .doc(_uid)
              .get(const GetOptions(source: Source.cache));

          if (rankDoc.exists) {
            _rank = rankDoc.data()?["rank"] ?? 0;
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    }
  }

  // Fetch coaching details (server first, then cache)
  Future<void> fetchCoachingDetails() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await FirebaseFirestore.instance
            .collection("coachingCodes")
            .doc(_coachingCode)
            .get(const GetOptions(source: Source.serverAndCache));
      } catch (_) {
        doc = await FirebaseFirestore.instance
            .collection("coachingCodes")
            .doc(_coachingCode)
            .get(const GetOptions(source: Source.cache));
      }

      if (doc.exists) {
        _coachingName = doc.data()?["name"] ?? _coachingName;
        _coachingImageUrl = doc.data()?["logoUrl"] ?? _coachingImageUrl;

        await LocalStorage.saveLocalStorage(
            "coachingName", _coachingName ?? "");
        await LocalStorage.saveLocalStorage(
            "coachingImage", _coachingImageUrl ?? "");
      }
    } catch (e) {
      debugPrint("Error fetching coaching details: $e");
    }
  }

  // Pull-to-refresh
  Future<void> refreshData() async {
    await fetchAllData();
  }
}
