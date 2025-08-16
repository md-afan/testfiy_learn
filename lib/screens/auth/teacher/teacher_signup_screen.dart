import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// routes name
import '../../../constants/app_routes.dart';
import '../../../utils/helpers.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/picker_images.dart';
import '../../../utils/cloudinary.dart';
import '../../../services/firebase_notification.dart';

class TeacherSignup extends StatefulWidget {
  const TeacherSignup({super.key});

  @override
  State<TeacherSignup> createState() => _TeacherSignupState();
}

class _TeacherSignupState extends State<TeacherSignup> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? teacherImageUrl;
  bool isUploadingTeacherImage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: UiHelpers.customAuthAppBar(context, "Sign In", () {
        context.replace(AppRoutes.login);
      }),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: _form(),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Create Teacher Account",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Fill in your personal details",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _teacherDetails(),
          const SizedBox(height: 40),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : UiHelpers.customButton(context, "Submit", () async {
                  if (_formKey.currentState!.validate()) {
                    if (teacherImageUrl != null) {
                      UiHelpers.showSnackbar(
                        context,
                        "Please upload your profile image.",
                      );
                      return;
                    }

                    setState(() {
                      _isLoading = true;
                    });

                    final String email = emailController.text.trim();
                    final String password = passwordController.text.trim();
                    final String name = fullNameController.text.trim();
                    final String phone = phoneController.text.trim();

                    try {
                      final credential = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                              email: email, password: password);

                      final uid = credential.user!.uid;

                      await credential.user!.sendEmailVerification();

                      await FirebaseFirestore.instance
                          .collection("teachers")
                          .doc(uid)
                          .set({
                        "uid": uid,
                        "email": email,
                        "fullName": name,
                        "phone": phone,
                        "teacherImageUrl": teacherImageUrl ??
                            "https://res.cloudinary.com/dujsdlqm0/image/upload/v1753368261/testify_learn/images/xbcbotja5wmyo8zwqrjh.jpg",
                        "isApproved": false,
                        'isAdmin': false,
                        "createdAt": Timestamp.now(),
                      });

                      setState(() {
                        _isLoading = false;
                      });

                      UiHelpers.showSnackbar(
                        context,
                        "Signup successful. Please verify your email.",
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                      );

                      await FirebaseNotification.saveTokenToFirestore(
                          uid, false);

                      context.go(AppRoutes.emailVerification);
                    } on FirebaseAuthException catch (error) {
                      setState(() {
                        _isLoading = false;
                      });
                      UiHelpers.showSnackbar(
                          context, "Signup failed: ${error.message}");
                    } catch (error) {
                      setState(() {
                        _isLoading = false;
                      });
                      UiHelpers.showSnackbar(
                          context, "Unexpected error: $error");
                    }
                  }
                }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _teacherDetails() {
    return Column(
      children: [
        UiHelpers.customTextField(
          context,
          hintText: "Full Name",
          controller: fullNameController,
          prefixIcon: Icon(Icons.person),
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Full Name is required'
              : null,
        ),
        const SizedBox(height: 16),
        UiHelpers.customTextField(
          context,
          hintText: "Email Address",
          controller: emailController,
          prefixIcon: Icon(Icons.email),
          keyboardType: TextInputType.emailAddress,
          validator: (val) =>
              val == null || !val.contains('@') ? 'Enter a valid email' : null,
        ),
        const SizedBox(height: 16),
        UiHelpers.customTextField(
          context,
          hintText: "Phone Number",
          controller: phoneController,
          prefixIcon: Icon(Icons.phone),
          keyboardType: TextInputType.phone,
          validator: (val) => val == null || val.length != 10
              ? 'Enter a valid 10-digit phone number'
              : null,
        ),
        const SizedBox(height: 16),
        UiHelpers.customTextField(
          context,
          hintText: "Password",
          controller: passwordController,
          prefixIcon: const Icon(Icons.lock),
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (val) => val != null && val.length < 6
              ? 'Password must be at least 6 characters'
              : null,
        ),
        const SizedBox(height: 24),
        UiHelpers.sectionTitle("Upload Image"),
        const SizedBox(height: 10),
        ImagePickerWidget(
          onImageSelected: (file) async {
            setState(() {
              isUploadingTeacherImage = true;
            });
            final url = await uploadImageToCloudinary(
              file,
              folderName: "testify_learn/images",
            );
            log(url.toString());
            if (url != null) {
              setState(() {
                teacherImageUrl = url;
                isUploadingTeacherImage = false;
              });
            }
          },
          title: "Upload teacher image",
          isLoading: isUploadingTeacherImage,
        ),
      ],
    );
  }
}
