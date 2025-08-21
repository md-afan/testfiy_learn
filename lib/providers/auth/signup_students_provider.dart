import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../utils/secure_locally_storage.dart';
import '../../utils/helpers.dart';
import '../../constants/app_routes.dart';
import '../../services/firebase_notification.dart';

class SignupStudentsProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<void> registerStudent({
    required BuildContext context,
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required GlobalKey<FormState> formKey,
  }) async {
    if (!formKey.currentState!.validate()) return;

    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      await credential.user!.sendEmailVerification();
      await LocalStorage.saveLocalStorage("uid", uid);

      await _firestore.collection("students").doc(uid).set({
        "uid": uid,
        "email": email,
        "fullName": fullName,
        "phone": phone,
        "createdAt": Timestamp.now(),
      });

      if (!context.mounted) return;

      UiHelpers.showSnackbar(
        context,
        "Signup successful. Check your email for verification.",
      );

      await FirebaseNotification.saveTokenToFirestore(uid, false);

      context.go(AppRoutes.emailVerification);
    } on FirebaseAuthException catch (error) {
      if (context.mounted) {
        UiHelpers.showSnackbar(
          context,
          error.message ?? "Signup failed",
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
