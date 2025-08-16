import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/comman providers/cashfree_payout_provider.dart';

class PayoutScreen extends StatelessWidget {
  const PayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Withdraw Money")),
      body: Consumer<CashfreeWithdrawalProvider>(
        builder: (context, provider, _) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (provider.isProcessing)
                  const CircularProgressIndicator(),
                if (provider.lastStatus != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(provider.lastStatus!),
                  ),
                ElevatedButton(
                  onPressed: provider.isProcessing
                      ? null
                      : () {
                          provider.withdrawMoney(
                            beneficiaryId: "BENEFICIARY123",
                            amount: 100.0,
                          );
                        },
                  child: const Text("Withdraw ₹100"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
