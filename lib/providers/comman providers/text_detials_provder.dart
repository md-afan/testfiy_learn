import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/comman providers/wallets_provider.dart';
import 'package:provider/provider.dart';

class TestDetailsProvider with ChangeNotifier {
  String? testId;
  String? uid;

  // State variables
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  bool _isRefreshing = false;
  Map<String, dynamic>? _quizData;
  Map<String, dynamic>? _enrollmentData;
  int _totalEnrolledStudents = 0;
  double _walletBalance = 0.0;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  bool get isProcessingPayment => _isProcessingPayment;
  bool get isRefreshing => _isRefreshing;
  Map<String, dynamic>? get quizData => _quizData;
  Map<String, dynamic>? get enrollmentData => _enrollmentData;
  int get totalEnrolledStudents => _totalEnrolledStudents;
  double get walletBalance => _walletBalance;
  String? get error => _error;
  bool get hasPaid => _enrollmentData?['hasPaid'] ?? false;
  String get testStatus => _quizData?['status'] ?? 'upcoming';

  // Initialize and fetch data
  Future<void> setParam({
    required String textId,
    required String userId,
  }) async {
    testId = textId;
    uid = userId;

    notifyListeners(); // let widgets know data changed
  }

  Future<void> initialize() async {
    await _fetchData();
  }

  // Main data fetching method
  Future<void> _fetchData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      print('${uid} studnets');

      // Fetch all data in parallel
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('quizzes').doc(testId).get(),
        FirebaseFirestore.instance
            .collection('quizzes')
            .doc(testId)
            .collection('enrolledStudents')
            .doc(uid)
            .get(),
        FirebaseFirestore.instance
            .collection('quizzes')
            .doc(testId)
            .collection('enrolledStudents')
            .get(),
      ]);

      // Process quiz data
      final quizDoc = results[0] as DocumentSnapshot;
      if (!quizDoc.exists) {
        throw Exception('Test not found');
      }
      _quizData = quizDoc.data() as Map<String, dynamic>? ?? {};

      // Process enrollment data
      final enrolledDoc = results[1] as DocumentSnapshot;
      _enrollmentData = enrolledDoc.data() as Map<String, dynamic>?;
      print(_enrollmentData);

      // Process total enrolled students
      final enrolledStudents = results[2] as QuerySnapshot;
      _totalEnrolledStudents = enrolledStudents.docs.length;

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    print(hasPaid);
    try {
      _isRefreshing = true;
      notifyListeners();
      await _fetchData();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // Process payment
  Future<void> processPayment(BuildContext context) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    if (_quizData == null || _isProcessingPayment) return;

    final fee = (_quizData!['fee'] as num).toDouble();
    if (walletProvider.balance < fee) {
      _error = 'Insufficient wallet balance';
      notifyListeners();
      return;
    }

    try {
      _isProcessingPayment = true;
      notifyListeners();

      final now = Timestamp.now();

      final studentRef =
          FirebaseFirestore.instance.collection('students').doc(uid);
      final enrolledRef = FirebaseFirestore.instance
          .collection('quizzes')
          .doc(testId)
          .collection('enrolledStudents')
          .doc(uid);
      final studentTestRef = studentRef.collection('enrolledTests').doc(testId);
      await FirebaseFirestore.instance.runTransaction((txn) async {
        walletProvider.paidfromWallets(
          fee,
          note: 'Paid ₹${fee} for ${_quizData!['title'] ?? ""}',
          type: 'Test Paid',
        );

        txn.set(
            enrolledRef,
            {
              'enrolledAt': now,
              'isPresent': true,
              'hasPaid': true,
              'paymentId': "wallet",
              'status': 'enrolled',
            },
            SetOptions(merge: true));
        txn.set(
            studentTestRef,
            {
              'hasPaid': true,
              'enrolledAt': now,
              'status': 'enrolled',
              'paymentId': "wallet",
            },
            SetOptions(merge: true));
      });

      // Update local state
      _walletBalance -= fee;
      _enrollmentData = {
        ...?_enrollmentData,
        'hasPaid': true,
        'enrolledAt': now,
        'status': 'enrolled',
        'paymentId': "wallet",
      };

      _isProcessingPayment = false;
      notifyListeners();
//return true;
    } catch (e) {
      _isProcessingPayment = false;
      _error = 'Payment failed: ${e.toString()}';
      notifyListeners();
      // return false;
    }
  }
}
