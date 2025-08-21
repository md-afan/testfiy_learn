import 'package:flutter/material.dart';

import 'package:cloud_functions/cloud_functions.dart';

class PayoutScreen extends StatefulWidget {
  @override
  _PayoutScreenState createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  final functions = FirebaseFunctions.instance;

  Future<void> payToPhone() async {
    final double amount = 100.00;
    try {
      final result = await functions.httpsCallable('cashfreePayToPhone').call({
        'phone': '6307874140',
        'name': 'John Doe',
        'amount': amount.toStringAsFixed(2),
        'transferId': 'TRANS-${DateTime.now().millisecondsSinceEpoch}',
        'remarks': 'Test payout'
      });

      final data = result.data;
      print('Response: $data');
      final status = data['status'];
      if (status == 'SUCCESS') {
        final utr = data['data']['utr'];
        _showDialog('Success', 'Transfer done! UTR: $utr');
      } else if (status == 'PENDING') {
        _showDialog('Pending', 'Transfer pending…');
      } else {
        _showDialog('Error', data['message'] ?? 'Unknown error');
      }
    } catch (e) {
      print('Error: $e');
      _showDialog('Error', e.toString());
    }
  }

  void _showDialog(String title, String msg) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: Text(title),
                content: Text(msg),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pay-to-Phone')),
      body: Center(
          child:
              ElevatedButton(onPressed: payToPhone, child: Text('Send ₹100'))),
    );
  }
}
