import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:testify_learn_application/providers/comman%20providers/wallets_provider.dart';

import '../../constants/app_routes.dart';
import '../../utils/secure_locally_storage.dart';
import '../../services/firebase_notification.dart';
import '../../utils/enryped_decryped.dart';

enum UserRole { teacher, student, admin }

class TestScreenProvider with ChangeNotifier {
  // State variables
  int _selectedFilter = 0;
  String? _coachingCode;
  String? _uid;
  UserRole? _userRole;
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  bool _isRefreshing = false;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 5;
  String? _errorMessage;

  // Filter options based on user role
  final Map<UserRole, List<String>> _roleFilters = {
    UserRole.teacher: [
      'All',
      'Upcoming',
      'Live',
      'Completed',
      'Published',
      'Unpublished'
    ],
    UserRole.student: ['All', 'Upcoming', 'Live', 'Enrolled', 'Completed'],
    UserRole.admin: [
      'All',
      'Upcoming',
      'Live',
      'Completed',
      'Published',
      'Unpublished'
    ],
  };

  StreamSubscription<QuerySnapshot>? _firstPageSubscription;
  final List<QueryDocumentSnapshot> _allTests = [];

  // Getters
  int get selectedFilter => _selectedFilter;
  String? get coachingCode => _coachingCode;
  String? get uid => _uid;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMoreData => _hasMoreData;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  List<QueryDocumentSnapshot> get allTests => _allTests;
  List<String> get filters =>
      _roleFilters[_userRole] ?? _roleFilters[UserRole.student]!;

  // Initialize the provider
  Future<void> initialize() async {
    try {
      await _loadData();
    } catch (e, stackTrace) {
      _handleError('Initialization failed', e, stackTrace);
    }
  }

  // Load initial data
  Future<void> _loadData() async {
    _coachingCode = await LocalStorage.getLocalStorage("coachingCode");
    _uid = await LocalStorage.getLocalStorage("uid");
    final roleString = await LocalStorage.getLocalStorage("role");
    String decryptedTest = EncryptionHelper.decrypt(roleString!);
    print(decryptedTest);

    _userRole = _parseUserRole(decryptedTest);
    await _loadFirstPage();
    _isLoading = false;
    notifyListeners();
  }

  UserRole _parseUserRole(String? roleString) {
    switch (roleString?.toLowerCase()) {
      case 'teacher':
        return UserRole.teacher;
      case "teacher_admin":
        return UserRole.teacher;

      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.student;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();

    try {
      await _loadFirstPage();
      _clearError();
    } catch (e, stackTrace) {
      _handleError('Refresh failed', e, stackTrace);
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // Load first page with real-time updates
  Future<void> _loadFirstPage() async {
    _firstPageSubscription?.cancel();
    _allTests.clear();
    _lastDocument = null;
    _hasMoreData = true;
    notifyListeners();

    Query query = FirebaseFirestore.instance
        .collection('quizzes')
        .where('coachingCode', isEqualTo: _coachingCode);

    // Apply role-specific filters
    query = _applyRoleBasedFilters(query);

    query = query.limit(_pageSize);

    _firstPageSubscription = query.snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        _processNewSnapshot(snapshot.docs);
        _lastDocument = snapshot.docs.last;
        _hasMoreData = snapshot.docs.length == _pageSize;
      } else {
        _hasMoreData = false;
      }
      notifyListeners();
    }, onError: (e) => _handleError('Real-time update error', e, null));
  }

  Query _applyRoleBasedFilters(Query query) {
    if (_userRole == UserRole.teacher || _userRole == UserRole.admin) {
      switch (_selectedFilter) {
        case 4:
          return query.where('isPublished', isEqualTo: true); // Published
        case 5:
          return query.where('isPublished', isEqualTo: false); // Unpublished
      }
    }
    return query;
  }

  // Process new snapshot data
  void _processNewSnapshot(List<QueryDocumentSnapshot> newDocs) {
    final existingIds = _allTests.map((test) => test.id).toSet();

    for (final doc in newDocs) {
      final index = _allTests.indexWhere((test) => test.id == doc.id);
      if (index >= 0) {
        _allTests[index] = doc;
      } else {
        _allTests.add(doc);
      }
    }

    final newIds = newDocs.map((doc) => doc.id).toSet();
    _allTests.removeWhere((test) => !newIds.contains(test.id));
  }

  // Load more data for pagination
  Future<void> loadMoreData() async {
    if (_isFetchingMore || !_hasMoreData || _lastDocument == null) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      Query query = FirebaseFirestore.instance
          .collection('quizzes')
          .where('coachingCode', isEqualTo: _coachingCode);

      query = _applyRoleBasedFilters(query);
      query = query.startAfterDocument(_lastDocument!).limit(_pageSize);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _allTests.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.last;
        _hasMoreData = snapshot.docs.length == _pageSize;
      } else {
        _hasMoreData = false;
      }
      _clearError();
    } catch (e, stackTrace) {
      _handleError('Load more failed', e, stackTrace);
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // Change filter selection
  void setFilter(int index) {
    _selectedFilter = index;
    _loadFirstPage(); // reload data on filter change
    notifyListeners();
  }

  Future<void> handleTeacherAction({
    required BuildContext context,
    required String testStatus,
    required String testId,
    required Map<String, dynamic> data,
    required int fee,
  }) async {
    if (testStatus == 'upcoming' || testStatus == 'pending') {
      context.push('${AppRoutes.studentsAttandance}/$testId');
    } else if (testStatus == 'completed') {
      context.push(
        '${AppRoutes.testLeaderborad}/$testId',
        extra: {'testName': data['title'] ?? 'Test', 'fee': fee},
      );
    }
  }

  Future<void> handleStudentAction({
    required BuildContext context,
    required String testStatus,
    required bool isPaid,
    required int fee,
    required String testId,
    required Map<String, dynamic> data,
  }) async {
    if ((testStatus == 'upcoming' || testStatus == 'pending') && isPaid) {
      context.push('${AppRoutes.enrolledStudents}/$testId');
    } else if (testStatus == 'live' && isPaid) {
      context.go('${AppRoutes.takeTest}/$testId');
    } else if (testStatus == 'completed' && isPaid) {
      context.push(
        '${AppRoutes.testLeaderborad}/$testId',
        extra: {'testName': data['title'] ?? 'Test', 'fee': fee},
      );
    } else if (!isPaid) {
      await _handlePayment(
          context: context, fee: fee, testId: testId, data: data);
    }
  }

  // Payment handling methods remain the same...
  Future<void> _handlePayment({
    required BuildContext context,
    required int fee,
    required String testId,
    required Map<String, dynamic> data,
  }) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final walletBalance = walletProvider.balance;

    if (walletBalance < fee) {
      await _showInsufficientBalanceDialog(context, fee, walletBalance);
      return;
    }

    final confirm = await _showPaymentConfirmationDialog(context, fee);
    if (confirm != true) return;

    try {
      await _processPayment(
        fee: fee.toDouble(),
        testId: testId,
        data: data,
        walletProvider: walletProvider,
      );

      await FirebaseNotification.subscribeToQuizTopics(testId, false);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Payment successful! You are now enrolled.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      _handleError('Payment processing failed', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Payment failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // UI helper methods

  _CardInfo getTeacherCardInfo(
      {required String testStatus, required BuildContext context}) {
    switch (testStatus) {
      case 'live':
        return _CardInfo(
          'Live',
          'Join Now',
          Theme.of(context).colorScheme.primary,
        );
      case 'completed':
        return _CardInfo(
          'Completed',
          'Leaderboard',
          Colors.grey,
        );
      default:
        return _CardInfo(
          'Upcoming',
          'Attendance',
          Theme.of(context).colorScheme.secondary,
        );
    }
  }

  Future<void> _showInsufficientBalanceDialog(
      BuildContext context, int fee, double walletBalance) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Insufficient Wallet Balance"),
        content: Text(
          "You need ₹$fee but only ₹$walletBalance is available.\nPlease recharge your wallet.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.studentWallet);
            },
            child: const Text("Add Money"),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPaymentConfirmationDialog(
      BuildContext context, int fee) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Do you want to pay ₹$fee for this test?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(
      {required double fee,
      required String testId,
      required Map<String, dynamic> data,
      required WalletProvider walletProvider}) async {
    final now = Timestamp.now();

    final studentRef =
        FirebaseFirestore.instance.collection('students').doc(_uid);
    final enrolledRef = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(testId)
        .collection('enrolledStudents')
        .doc(_uid);
    final studentTestRef = studentRef.collection('enrolledTests').doc(testId);
    await FirebaseFirestore.instance.runTransaction((txn) async {
      walletProvider.paidfromWallets(fee,
          note: 'Test payment for ${data['title']}',
          type: 'Test Paid',
          id: testId);

      txn.set(
          enrolledRef,
          {
            'enrolledAt': now,
            'isPresent': true,
            'hasPaid': true,
            //'paymentId': paymentRef.id,
            'status': 'enrolled',
          },
          SetOptions(merge: true));

      txn.set(
          studentTestRef,
          {
            'hasPaid': true,
            'enrolledAt': now,
            'status': 'enrolled',
            //  'paymentId': paymentRef.id,
          },
          SetOptions(merge: true));
    });
  }

  _CardInfo getStudentCardInfo({
    required String testStatus,
    required bool isPaid,
    required int fee,
    required BuildContext context,
  }) {
    if (testStatus == 'live') {
      return _CardInfo(
        'Live',
        isPaid ? 'Join Now' : '₹$fee',
        Theme.of(context).colorScheme.primary,
      );
    } else if (testStatus == 'completed') {
      return _CardInfo(
        'Completed',
        'Leaderboard',
        Colors.grey,
      );
    } else if (isPaid) {
      return _CardInfo(
        'Enrolled',
        'Enrolled Students',
        Theme.of(context).colorScheme.primary,
      );
    } else {
      return _CardInfo(
        'Upcoming',
        '₹$fee',
        Theme.of(context).colorScheme.secondary,
      );
    }
  }

  bool shouldSkipCard(String testStatus, bool isPaid, bool isPublished) {
    switch (_userRole) {
      case UserRole.teacher:
      case UserRole.admin:
        switch (_selectedFilter) {
          case 0:
            return false; // All
          case 1:
            return testStatus != 'upcoming'; // Upcoming
          case 2:
            return testStatus != 'live'; // Live
          case 3:
            return testStatus != 'completed'; // Completed
          case 4:
            return !isPublished; // Published
          case 5:
            return isPublished; // Unpublished
          default:
            return false;
        }
      case UserRole.student:
        switch (_selectedFilter) {
          case 0:
            return false; // All
          case 1:
            return testStatus != 'upcoming'; // Upcoming
          case 2:
            return testStatus != 'live'; // Live
          case 3:
            return !isPaid; // Enrolled
          case 4:
            return testStatus != 'completed'; // Completed
          default:
            return false;
        }
      default:
        return false;
    }
  }

  // Error handling
  void _handleError(String context, dynamic error, StackTrace? stackTrace) {
    debugPrint('$context: $error');
    if (stackTrace != null) debugPrint(stackTrace.toString());
    _errorMessage = '$context: ${error.toString()}';
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Clean up resources
  void disposeProvider() {
    _firstPageSubscription?.cancel();
    super.dispose();
  }
}

class _CardInfo {
  final String statusLabel;
  final String actionLabel;
  final Color statusColor;

  _CardInfo(this.statusLabel, this.actionLabel, this.statusColor);
}
