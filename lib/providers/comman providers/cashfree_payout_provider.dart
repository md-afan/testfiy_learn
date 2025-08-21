// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:provider/provider.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// // Conditional imports
// import 'package:flutter_cashfree_pg_sdk/cashfreepgsdk.dart'
//     if (dart.library.html) 'package:flutter_cashfree_pg_sdk_web/flutter_cashfree_pg_sdk_web.dart';
// import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart'
//     if (dart.library.html) 'dummy_cfenums.dart';

// class CashfreePayoutProvider with ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   String _upiId = '';
//   bool _isLoading = false;
//   String _errorMessage = '';
//   String _successMessage = '';

//   String get upiId => _upiId;
//   bool get isLoading => _isLoading;
//   String get errorMessage => _errorMessage;
//   String get successMessage => _successMessage;

//   void setUpiId(String id) {
//     _upiId = id.trim();
//     notifyListeners();
//   }

//   Future<String> _getAuthToken() async {
//     final user = _auth.currentUser;
//     if (user == null) throw Exception('User not authenticated');
//     final token = await user.getIdToken();
//     return token ?? '';
//   }

//   void _initializeCashfree() {
//     if (kIsWeb) {
//       // Web initialization
//       CashfreePGSDKWeb.init(
//         environment: CFEnvironment.SANDBOX,
//         appId: "YOUR_APP_ID",
//       );
//     } else {
//       // Mobile initialization
//       CashfreePGSDK.init(
//         environment: CFEnvironment.SANDBOX,
//         appId: "YOUR_APP_ID",
//       );
//     }
//   }

//   Future<void> _addBeneficiaryMobile(String beneId, String token) async {
//     await CashfreePGSDK.addBeneficiary(
//       {
//         "beneId": beneId,
//         "name": "Recipient Name",
//         "email": "recipient@example.com",
//         "phone": "9876543210",
//         "vpa": _upiId,
//       },
//       token,
//     );
//   }

//   Future<void> _addBeneficiaryWeb(String beneId, String token) async {
//     // Web doesn't support beneficiary management in current SDK
//     throw UnsupportedError('Beneficiary management not supported on web');
//   }

//   Future<void> addUpiBeneficiary() async {
//     try {
//       _isLoading = true;
//       _errorMessage = '';
//       _successMessage = '';
//       notifyListeners();

//       if (kIsWeb) {
//         throw UnsupportedError('Beneficiary management not available on web');
//       }

//       final token = await _getAuthToken();
//       final beneId =
//           "UPI_${_upiId.replaceAll('@', '_')}_${DateTime.now().millisecondsSinceEpoch}";

//       _initializeCashfree();

//       if (kIsWeb) {
//         await _addBeneficiaryWeb(beneId, token);
//       } else {
//         await _addBeneficiaryMobile(beneId, token);
//       }

//       await _firestore.collection('beneficiaries').doc(beneId).set({
//         'upiId': _upiId,
//         'userId': _auth.currentUser?.uid,
//         'createdAt': FieldValue.serverTimestamp(),
//         'status': 'active',
//       });

//       _successMessage = 'Beneficiary added successfully';
//     } catch (e) {
//       _errorMessage = 'Failed to add beneficiary: ${e.toString()}';
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> _requestTransferMobile(
//       String beneId, double amount, String token) async {
//     final transferId = "PAYOUT_${DateTime.now().millisecondsSinceEpoch}";
//     await CashfreePGSDK.requestTransfer(
//       {
//         "beneId": beneId,
//         "amount": amount.toStringAsFixed(2),
//         "transferId": transferId,
//         "transferMode": "upi",
//         "remarks": "Payment via UPI",
//       },
//       token,
//     );
//     return transferId;
//   }

//   Future<void> _requestTransferWeb(
//       String beneId, double amount, String token) async {
//     // Web doesn't support direct payouts in current SDK
//     throw UnsupportedError('Payouts not supported on web');
//   }

//   Future<void> initiatePayout(double amount) async {
//     try {
//       _isLoading = true;
//       _errorMessage = '';
//       _successMessage = '';
//       notifyListeners();

//       if (kIsWeb) {
//         throw UnsupportedError('Payouts not available on web');
//       }

//       final token = await _getAuthToken();
//       final beneId = "UPI_${_upiId.replaceAll('@', '_')}";

//       _initializeCashfree();

//       String transferId;
//       if (kIsWeb) {
//         transferId = await _requestTransferWeb(beneId, amount, token);
//       } else {
//         transferId = await _requestTransferMobile(beneId, amount, token);
//       }

//       await _firestore.collection('payouts').doc(transferId).set({
//         'amount': amount,
//         'upiId': _upiId,
//         'status': 'initiated',
//         'userId': _auth.currentUser?.uid,
//         'createdAt': FieldValue.serverTimestamp(),
//         'transferId': transferId,
//       });

//       _successMessage = 'Payout initiated successfully';
//     } catch (e) {
//       _errorMessage = 'Failed to initiate payout: ${e.toString()}';
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   void clearMessages() {
//     _errorMessage = '';
//     _successMessage = '';
//     notifyListeners();
//   }
// }