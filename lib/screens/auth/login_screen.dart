import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/helpers.dart';
import "../../utils/responsive.dart";
import '../../constants/app_routes.dart';
import "../../services/singin_with_google.dart";
import '../../services/firebase_service.dart';
import '../../services/firebase_notification.dart';
import '../../utils/secure_locally_storage.dart';
import '../../utils/subscribe_enrolled_quizes_or_published.dart';
import '../../utils/enryped_decryped.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool isLoading = false;
  String? errorMessage;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) {
        setState(() => errorMessage = 'User not found');
        return;
      }

      if (!user.emailVerified) {
        setState(() => errorMessage = 'Please verify your email');
        await FirebaseAuth.instance.signOut();
        return;
      }

      final role = await getUserRole(user.uid);
      final encryptedRole = await EncryptionHelper.encrypt(role.toString());
      await LocalStorage.saveLocalStorage("role", encryptedRole);
      await LocalStorage.saveLocalStorage('uid', user.uid);
      bool isTeacher = role != 'student' ? true : false;

      await FirebaseNotification.saveTokenToFirestore(user.uid, isTeacher);
      _redirectToDashboard(role);
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message ?? 'Login failed');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> subscribeTopic(String uid, bool isTeacher) async {
    await FirebaseNotification.saveTokenToFirestore(uid, isTeacher);
    await subscribeToAllQuizTopics(uid, isTeacher);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userCredential = await signInWithGoogle();
      if (userCredential == null) {
        setState(() => isLoading = false);
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

      bool isTeacher = role != "student" ? true : false;

      await subscribeTopic(uid, isTeacher);
      final encryptedRole = await EncryptionHelper.encrypt(role.toString());
      print('encrypted $encryptedRole');
      await LocalStorage.saveLocalStorage("role", encryptedRole);
      await LocalStorage.saveLocalStorage('uid', uid);
      _redirectToDashboard(role);
    } catch (e) {
      setState(() => errorMessage = 'Google Sign-In failed');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _redirectToDashboard(String? role) {
    print("User role: $role");
    if (role == 'teacher_admin') {
      context.go(AppRoutes.teacherDashboard);
    } else if (role == 'teacher') {
      // Pass `isTeacher=true` as a query parameter
      context.go(Uri(path: AppRoutes.joinInCoaching, queryParameters: {
        'isTeacher': 'true',
      }).toString());
    } else if (role == 'student') {
      context.go(AppRoutes.joinInCoaching);
    } else {
      setState(() => errorMessage = 'Network issue!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiHelpers.customAuthAppBar(context, "Get Started", () {
        context.replace(AppRoutes.role);
      }),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ResponsiveLayout(
                mobile: _form(),
                tablet: Center(child: SizedBox(width: 500, child: _form())),
                desktop: Center(child: SizedBox(width: 500, child: _form())),
                largeDesttop:
                    Center(child: SizedBox(width: 500, child: _form())),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Welcome Back",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Enter your details below",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          const Text("Email Address",
              style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          UiHelpers.customTextField(
            context,
            hintText: "Email Address",
            controller: emailController,
            prefixIcon: const Icon(Icons.email),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          const Text("Password", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          UiHelpers.customTextField(
            context,
            hintText: "Password",
            controller: passwordController,
            prefixIcon: const Icon(Icons.lock),
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6)
                return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 24),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : UiHelpers.customButton(context, "Sign In", _handleLogin),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(errorMessage!,
                  style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => context.push(AppRoutes.resetPassword),
              child: const Text("Forgot your password?"),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text("Or sign in with"),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                  "Google", "assets/images/google.jpg", _handleGoogleSignIn),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
      String label, String assetPath, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Image.asset(assetPath, height: 24),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF5F7FB),
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }
}
