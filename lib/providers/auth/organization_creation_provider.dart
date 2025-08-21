import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/secure_locally_storage.dart';
import '../../utils/cloudinary.dart';
import '../../services/firebase_notification.dart';
import '../../services/unique_code.dart';

class OrganizationSignupProvider extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  // Teacher Details
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();

  // Coaching Details
  final coachingNameController = TextEditingController();
  final coachingAddressController = TextEditingController();

  // Local States
  bool obscurePassword = true;
  bool isLoading = false;
  String? teacherImageUrl;
  String? coachingImageUrl;

  bool isUploadingTeacherImage = false;
  bool isUploadingCoachingImage = false;

  void togglePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  Future<void> pickTeacherImage(dynamic file) async {
    isUploadingTeacherImage = true;
    notifyListeners();

    final url = await uploadImageToCloudinary(file,
        folderName: "testify_learn/images");

    if (url != null) {
      teacherImageUrl = url;
    }
    isUploadingTeacherImage = false;
    notifyListeners();
  }

  Future<void> pickCoachingImage(dynamic file) async {
    isUploadingCoachingImage = true;
    notifyListeners();

    final url = await uploadImageToCloudinary(file,
        folderName: "testify_learn/images");

    if (url != null) {
      coachingImageUrl = url;
    }
    isUploadingCoachingImage = false;
    notifyListeners();
  }

  Future<String?> signup(BuildContext context) async {
    if (!formKey.currentState!.validate()) return null;

    if (teacherImageUrl == null || coachingImageUrl == null) {
      return "Please upload both images.";
    }

    try {
      isLoading = true;
      notifyListeners();

      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final name = fullNameController.text.trim();
      final phone = phoneController.text.trim();
      final coachingName = coachingNameController.text.trim();
      final coachingAddress = coachingAddressController.text.trim();

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;
      await credential.user!.sendEmailVerification();

      final coachingCode =
          await generateUniqueCoachingCode(coachingName: coachingName);

      await FirebaseFirestore.instance.collection("teachers").doc(uid).set({
        "uid": uid,
        "email": email,
        "fullName": name,
        "phone": phone,
        "teacherImageUrl": teacherImageUrl,
        "isApproved": false,
        "isAdmin": true,
        "createdAt": Timestamp.now(),
        "coachingCode": coachingCode,
      });

      await FirebaseFirestore.instance
          .collection("coachingCodes")
          .doc(coachingCode)
          .set({
        "name": coachingName,
        "code": coachingCode,
        "createdBy": uid,
        "logoUrl": coachingImageUrl,
        "active": true,
        "contact": phone,
        "address": coachingAddress,
        "createdAt": Timestamp.now(),
      });

      await LocalStorage.saveLocalStorage("uid", uid);
      await FirebaseNotification.saveTokenToFirestore(uid, true);

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
}
