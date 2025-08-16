import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletProvider extends ChangeNotifier {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final int _transactionsPerPage = 10;

  bool isLoadingTransactions = true;
  bool isLoadingMore = false;
  bool hasMoreTransactions = true;

  double balance = 0.0;
  List<QueryDocumentSnapshot> allTransactions = [];
  DocumentSnapshot? lastDocument;

  int selectedFilter = 0;
  final List<String> filters = [
    'All',
    'Add Money',
    'Withdrawals',
    'Test Paid',
    'Rewards',
  ];

  WalletProvider() {
    if (userId != null) {
      _loadBalanceFromCache();
      fetchTransactions(fromCache: true).then((_) {
        fetchTransactions(fromCache: false); // Update with latest from server
      });
    }
  }

  void changeFilter(int index) {
    selectedFilter = index;
    notifyListeners();
  }

  /// Load wallet balance from Firestore cache first
  Future<void> _loadBalanceFromCache() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(userId)
          .get(const GetOptions(source: Source.cache));

      if (doc.exists) {
        balance = (doc.data()?['balance'] ?? 0.0).toDouble();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Fetch transactions (either from cache or server)
  Future<void> fetchTransactions({bool fromCache = false}) async {
    if (userId == null) return;

    try {
      isLoadingTransactions = true;
      notifyListeners();

      final snapshot = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(userId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(_transactionsPerPage)
          .get(GetOptions(source: fromCache ? Source.cache : Source.server));

      allTransactions = snapshot.docs;
      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
        hasMoreTransactions = snapshot.docs.length == _transactionsPerPage;
      } else {
        hasMoreTransactions = false;
      }

      // If fetching from server, also update balance
      if (!fromCache) {
        final walletDoc = await FirebaseFirestore.instance
            .collection('wallets')
            .doc(userId)
            .get();
        balance = (walletDoc.data()?['balance'] ?? 0.0).toDouble();
      }
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
    } finally {
      isLoadingTransactions = false;
      notifyListeners();
    }
  }

  /// Load more transactions for pagination
  Future<void> loadMoreTransactions() async {
    if (!hasMoreTransactions || isLoadingMore || lastDocument == null) return;

    try {
      isLoadingMore = true;
      notifyListeners();

      final nextPage = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(userId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(lastDocument!)
          .limit(_transactionsPerPage)
          .get();

      if (nextPage.docs.isNotEmpty) {
        allTransactions.addAll(nextPage.docs);
        lastDocument = nextPage.docs.last;
        hasMoreTransactions = nextPage.docs.length == _transactionsPerPage;
      } else {
        hasMoreTransactions = false;
      }
    } catch (e) {
      debugPrint("Error loading more: $e");
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Refresh by clearing cache and fetching latest
  Future<void> refreshTransactions() async {
    allTransactions.clear();
    lastDocument = null;
    hasMoreTransactions = true;
    await fetchTransactions(fromCache: false);
  }

  /// Get filtered transactions
  List<QueryDocumentSnapshot> get filteredTransactions {
    if (filters[selectedFilter] == 'All') {
      return allTransactions;
    }
    return allTransactions.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['type'] == filters[selectedFilter];
    }).toList();
  }

  /// Add money to wallet
  Future<void> addMoney(double amount,
      {String note = "Added to wallet",
      String type = "Add Moaney",
      String id = ""}) async {
    if (userId == null) return;

    final walletRef =
        FirebaseFirestore.instance.collection('wallets').doc(userId);
    final txRef = walletRef.collection('transactions').doc();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final walletDoc = await transaction.get(walletRef);
      double newBalance =
          (walletDoc.data()?['balance'] ?? 0.0).toDouble() + amount;

      transaction.update(walletRef,
          {'balance': newBalance, "updatedAt": FieldValue.serverTimestamp()});
      transaction.set(txRef, {
        'amount': amount,
        'type': type,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        "status": "Success"
      });

      balance = newBalance; // Update local balance
    });
    await refreshTransactions();
  }

  /// Withdraw money from wallet
  Future<void> paidfromWallets(double amount,
      {String note = "paid from teat !",
      String type = 'Test paid',
      String id = ''}) async {
    if (userId == null) return;
    if (amount > balance) {
      throw Exception("Insufficient balance");
    }

    final walletRef =
        FirebaseFirestore.instance.collection('wallets').doc(userId);
    final txRef = walletRef.collection('transactions').doc();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final walletDoc = await transaction.get(walletRef);
      double currentBalance = (walletDoc.data()?['balance'] ?? 0.0).toDouble();

      if (amount > currentBalance) {
        throw Exception("Insufficient balance");
      }

      double newBalance = currentBalance - amount;

      transaction.update(walletRef,
          {'balance': newBalance, "updatedAt": FieldValue.serverTimestamp()});
      transaction.set(txRef, {
        'amount': amount,
        'type': type,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        "status": "Success",
        "data": {
          id: id,
        }
      });

      balance = newBalance; // Update local balance
    });

    await refreshTransactions();
  }
}
