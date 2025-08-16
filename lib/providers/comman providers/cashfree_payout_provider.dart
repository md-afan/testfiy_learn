import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class CashfreeWithdrawalProvider with ChangeNotifier {
  bool isProcessing = false;
  String? lastStatus;

  Future<void> withdrawMoney({
    required String beneficiaryId,
    required double amount,
  }) async {
    isProcessing = true;
    lastStatus = null;
    notifyListeners();

    try {
      // 1. Get token from Firebase Function
      final tokenResponse = await FirebaseFunctions.instance
          .httpsCallable('getPayoutToken')
          .call();
      print(tokenResponse.data);
      final token = tokenResponse.data['data']['token'];

      // 2. Request withdrawal
      final withdrawalResponse = await FirebaseFunctions.instance
          .httpsCallable('requestWithdrawal')
          .call({
        'token': token,
        'beneficiaryId': beneficiaryId,
        'amount': amount,
      });

      lastStatus =
          withdrawalResponse.data['message'] ?? "Withdrawal Successful";
    } catch (e) {
      lastStatus = "Error: $e";
    }

    isProcessing = false;
    notifyListeners();
  }
}
