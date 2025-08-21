import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_routes.dart';
import '../../services/singin_with_google.dart';
import '../../services/firebase_notification.dart';
import '../../utils/secure_locally_storage.dart';
import '../../utils/subscribe_enrolled_quizes_or_published.dart';
import '../../utils/enryped_decryped.dart';
import '../../services/firebase_service.dart';

class LoginProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  String? errorMessage;
  bool obscurePassword = true;

  /// Toggle password visibility
  void togglePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  /// Email + Password login
  Future<void> loginWithEmail(
      BuildContext context, String email, String password) async {
    if (email.isEmpty || !email.contains('@')) {
      errorMessage = "Enter valid email";
      notifyListeners();
      return;
    }
    if (password.length < 6) {
      errorMessage = "Password must be at least 6 characters";
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) {
        errorMessage = 'User not found';
        notifyListeners();
        return;
      }

      if (!user.emailVerified) {
        errorMessage = 'Please verify your email';
        await _auth.signOut();
        notifyListeners();
        return;
      }

      final role = await getUserRole(user.uid);
      final encryptedRole = await EncryptionHelper.encrypt(role.toString());
      await LocalStorage.saveLocalStorage("role", encryptedRole);
      await LocalStorage.saveLocalStorage('uid', user.uid);

      bool isTeacher = role != "student";
      await FirebaseNotification.saveTokenToFirestore(user.uid, isTeacher);

      _redirectToDashboard(context, role);
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? 'Login failed';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Google sign-in
  Future<void> loginWithGoogle(BuildContext context) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await signInWithGoogle();
      if (userCredential == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final uid = userCredential.user!.uid;
      final email = userCredential.user!.email;
      final displayName = userCredential.user!.displayName;
      final photoURL = userCredential.user!.photoURL;

      final userDoc =
          FirebaseFirestore.instance.collection('students').doc(uid);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        await userDoc.set({
          "uid": uid,
          "email": email,
          "fullName": displayName,
          "photoURL": photoURL,
          "isGoogle": true,
          "createdAt": Timestamp.now(),
        });
      }

      final role = await getUserRole(uid);
      bool isTeacher = role != "student";

      await FirebaseNotification.saveTokenToFirestore(uid, isTeacher);
      await subscribeToAllQuizTopics(uid, isTeacher);

      final encryptedRole = await EncryptionHelper.encrypt(role.toString());
      await LocalStorage.saveLocalStorage("role", encryptedRole);
      await LocalStorage.saveLocalStorage('uid', uid);

      _redirectToDashboard(context, role);
    } catch (e) {
      errorMessage = "Google Sign-In failed";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _redirectToDashboard(BuildContext context, String? role) {
    if (role == 'teacher_admin') {
      context.go(AppRoutes.teacherDashboard);
    } else if (role == 'teacher') {
      context.go(Uri(path: AppRoutes.joinInCoaching, queryParameters: {
        'isTeacher': 'true',
      }).toString());
    } else if (role == 'student') {
      context.go(AppRoutes.joinInCoaching);
    } else {
      errorMessage = "Network issue!";
    }
  }
}
