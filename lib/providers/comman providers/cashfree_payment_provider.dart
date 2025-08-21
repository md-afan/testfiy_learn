import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
// import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart'; // For CFEnvironment

class CashfreePaymentProvider with ChangeNotifier {
  bool isProcessing = false;
  String? paymentStatus;

  Future<void> startPayment({
    required String orderId,
    required double amount,
    required String customerId,
    required String email,
    required String phone,
  }) async {
    isProcessing = true;
    paymentStatus = null;
    notifyListeners();

    try {
      // 1. Call Firebase Function to generate payment session
      final callable =
          FirebaseFunctions.instance.httpsCallable('generateCashfreeToken');
      final response = await callable.call({
        "orderId": orderId,
        "amount": amount,
        "uid": customerId,
        "email": email,
        "phone": phone,
      });

      final data = Map<String, dynamic>.from(response.data);
      final paymentSessionId = data['payment_session_id'];

      // 2. Create a Cashfree session
      final session = CFSessionBuilder()
          .setEnvironment(
              CFEnvironment.SANDBOX) // Switch to PRODUCTION when deploying live
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();

      // 3. Build the Web Checkout Payment object
      final cfWebCheckout =
          CFWebCheckoutPaymentBuilder().setSession(session).build();

      // // 4. (Optional) Customize Theme UI
      // final theme = CFThemeBuilder()
      //     .setNavigationBarBackgroundColorColor("#4CAF50")
      //     .setNavigationBarTextColor("#FFFFFF")
      //     .setButtonBackgroundColor("#4CAF50")
      //     .setButtonTextColor("#FFFFFF")
      //     .build();

      // 5. Start the Cashfree Payment flow with callbacks
      final cfService = CFPaymentGatewayService();
      cfService.setCallback(
        (returnedOrderId) {
          paymentStatus = "Payment Successful: $returnedOrderId";
          isProcessing = false;
          notifyListeners();
        },
        (CFErrorResponse error, String returnedOrderId) {
          paymentStatus =
              "Payment Failed: ${error.getMessage()} for $returnedOrderId";
          isProcessing = false;
          notifyListeners();
        },
      );

      cfService.doPayment(cfWebCheckout);
    } catch (e) {
      paymentStatus = "Payment Error: $e";
      isProcessing = false;
      notifyListeners();
    }
  }
}
