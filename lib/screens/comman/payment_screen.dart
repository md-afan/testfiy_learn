import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/comman providers/cashfree_payment_provider.dart';
import '../../utils/helpers.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<CashfreePaymentProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(context, "Add Money to Wallet",
          automaticallyImplyLeading: true),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Secure Payment",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter your payment details to add money",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Form Card
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          UiHelpers.customTextField(context,
                              hintText: "Amount",
                              controller: _amountController,
                              prefixIcon: const Icon(Icons.currency_rupee),
                              validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter an amount";
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return "Enter a valid amount";
                            }
                            if (amount < 10) {
                              return "Minimum amount is ₹10";
                            }
                            return null;
                          }),
                          const SizedBox(height: 24),
                          !paymentProvider.isProcessing
                              ? UiHelpers.customButton(
                                  context,
                                  "Pay Now",
                                  () {
                                    if (_formKey.currentState!.validate()) {
                                      paymentProvider.startPayment(
                                        orderId:
                                            "ORDER_${DateTime.now().millisecondsSinceEpoch}",
                                        amount: double.parse(
                                            _amountController.text),
                                        customerId: "CUST123",
                                        email: "test@example.com",
                                        phone: "9999999999",
                                      );
                                    }
                                  },
                                )
                              : SizedBox(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          )),
                                      SizedBox(width: 10),
                                      Text("Processing..."),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),

                  // Security & Info Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Your payment details are securely encrypted and processed",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.currency_rupee_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "No additional fees for adding money to wallet",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Terms & Conditions
                  Center(
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Terms & Conditions opened")),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "By proceeding, you agree to our ",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          children: [
                            TextSpan(
                              text: "Terms & Conditions",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
