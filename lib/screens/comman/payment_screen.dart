import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/comman providers/cashfree_payment_provider.dart';

class PaymentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CashfreePaymentProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Cashfree Payment")),
      body: Center(
        child: provider.isProcessing
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: () {
                  provider.startPayment(
                    orderId: "ORDER_${DateTime.now().millisecondsSinceEpoch}",
                    amount: 500.0,
                    customerId: "CUST123",
                    email: "test@example.com",
                    phone: "9999999999",
                  );
                },
                child: Text("Pay Now"),
              ),
      ),
    );
  }
}
