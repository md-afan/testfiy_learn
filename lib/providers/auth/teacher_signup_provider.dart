import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/cloudinary.dart';
import '../../services/firebase_notification.dart';

class TeacherSignupProvider extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  // Controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  String? teacherImageUrl;
  bool isUploadingTeacherImage = false;

  /// Toggle password visibility
  void togglePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  /// Pick teacher image
  Future<void> pickTeacherImage(dynamic file) async {
    isUploadingTeacherImage = true;
    notifyListeners();

    final url = await uploadImageToCloudinary(file,
        folderName: "testify_learn/images");

    log("Uploaded Image URL: $url");

    if (url != null) {
      teacherImageUrl = url;
    }

    isUploadingTeacherImage = false;
    notifyListeners();
  }

  /// Signup teacher
  Future<String?> signup(BuildContext context) async {
    if (!formKey.currentState!.validate()) return null;

    if (teacherImageUrl == null) {
      return "Please upload your profile image.";
    }

    try {
      isLoading = true;
      notifyListeners();

      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final name = fullNameController.text.trim();
      final phone = phoneController.text.trim();

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;

      await credential.user!.sendEmailVerification();

      await FirebaseFirestore.instance.collection("teachers").doc(uid).set({
        "uid": uid,
        "email": email,
        "fullName": name,
        "phone": phone,
        "teacherImageUrl": teacherImageUrl ??
            "https://res.cloudinary.com/dujsdlqm0/image/upload/v1753368261/testify_learn/images/xbcbotja5wmyo8zwqrjh.jpg",
        "isApproved": false,
        "isAdmin": false,
        "createdAt": Timestamp.now(),
      });

      await FirebaseNotification.saveTokenToFirestore(uid, false);

      return null; // success
    } on FirebaseAuthException catch (e) {
      return "Signup failed: ${e.message}";
    } catch (e) {
      return "Unexpected error: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Dispose controllers
  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
