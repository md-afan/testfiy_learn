import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/secure_locally_storage.dart';
import '../../services/firebase_notification.dart';
import '../../services/firebase_service.dart';

class TeacherDashboardProvider with ChangeNotifier {
  String? uid;
  String? code;
  String? coachingName;
  String? name;
  String? profileUrl;

  int totalTests = 0;
  int totalStudents = 0;

  bool isLoading = false;

  StreamSubscription<QuerySnapshot>? quizSub;
  StreamSubscription<QuerySnapshot>? studentSub;

  /// Fetch teacher details and start listening to changes
  Future<void> fetchAndListenTeacherDetails() async {
    isLoading = true;
    notifyListeners();

    try {
      final userId = await LocalStorage.getLocalStorage("uid");
      final user = await userDetails(userId.toString(), "teachers");

      if (user != null) {
        final coachingCode = await LocalStorage.getLocalStorage("coachingCode");
        if (coachingCode == null) {
          await FirebaseNotification.subscribeToCoaching(
              coachingCode.toString(), true);
        }

        uid = userId;
        code = coachingCode.toString();
        coachingName = user['coachingName']?.toString() ?? "N/A";
        name = user['fullName']?.toString() ?? "N/A";
        profileUrl = user['teacherImageUrl'];

        _listenToQuizzes(userId.toString(), coachingCode.toString());
        _listenToStudents(coachingCode.toString());
      } else {
        debugPrint("User not found");
      }
    } catch (e) {
      debugPrint("Error fetching teacher details: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  void _listenToQuizzes(String userId, String coachingCode) {
    quizSub?.cancel();
    quizSub = FirebaseFirestore.instance
        .collection('quizzes')
        .where('createdBy', isEqualTo: userId)
        .where('coachingCode', isEqualTo: coachingCode)
        .snapshots()
        .listen((snapshot) {
      totalTests = snapshot.docs.length;
      notifyListeners();
    });
  }

  void _listenToStudents(String coachingCode) {
    studentSub?.cancel();
    studentSub = FirebaseFirestore.instance
        .collection('coachingCodes')
        .doc(coachingCode)
        .collection("students")
        .snapshots()
        .listen((snapshot) async {
      totalStudents = snapshot.docs.length;
      notifyListeners();
    });
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    await fetchAndListenTeacherDetails();
  }

  /// Cleanup
  void disposeStreams() {
    quizSub?.cancel();
    studentSub?.cancel();
  }

  @override
  void dispose() {
    disposeStreams();
    super.dispose();
  }
}
