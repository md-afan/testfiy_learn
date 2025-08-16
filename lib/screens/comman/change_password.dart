import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/helpers.dart'; // Make sure this contains your UiHelpers

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool showCurrent = false;
  bool showNew = false;
  bool showConfirm = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPasswordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Password updated successfully')),
      );

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      String message = 'Error: ${e.message}';
      if (e.code == 'wrong-password') {
        message = '❌ Incorrect current password';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(
        context,
        "Change Password",
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    UiHelpers.customTextField(
                      context,
                      hintText: "Current Password",
                      controller: currentPasswordController,
                      prefixIcon: const Icon(Icons.lock),
                      obscureText: !showCurrent,
                      suffixIcon: IconButton(
                        icon: Icon(
                          showCurrent ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => showCurrent = !showCurrent),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Current password is required!';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    UiHelpers.customTextField(
                      context,
                      hintText: "New Password",
                      controller: newPasswordController,
                      prefixIcon: const Icon(Icons.lock),
                      obscureText: !showNew,
                      suffixIcon: IconButton(
                        icon: Icon(
                          showNew ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => showNew = !showNew),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    UiHelpers.customTextField(
                      context,
                      hintText: "Confirm Password",
                      controller: confirmPasswordController,
                      prefixIcon: const Icon(Icons.lock),
                      obscureText: !showConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(
                          showConfirm ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => showConfirm = !showConfirm),
                      ),
                      validator: (value) {
                        if (value != newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                   !isLoading ? UiHelpers.customButton(
                      context,
                      'Change Password',
                      _changePassword,
                      icon: Icons.lock_reset,
                    ):CircularProgressIndicator()
                  ],
                ), 
              ),
            ),
          ),
        ),
      ),
    );
  }
}
