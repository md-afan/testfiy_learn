import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_routes.dart';
import '../../../utils/helpers.dart';
import '../../../widgets/picker_images.dart';
import '../../../providers/auth/teacher_signup_provider.dart';

class TeacherSignup extends StatelessWidget {
  const TeacherSignup({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherSignupProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: UiHelpers.customAuthAppBar(context, "Sign In", () {
            context.replace(AppRoutes.login);
          }),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: provider.formKey,
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
                  _teacherDetails(context, provider),
                  const SizedBox(height: 40),
                  provider.isLoading
                      ? const CircularProgressIndicator() // only vertically centered by Row
                      : UiHelpers.customButton(
                          context,
                          "Submit",
                          () async {
                            // ✅ First validate form
                            if (provider.formKey.currentState!.validate()) {
                              // ✅ Validate teacher image
                              if (provider.teacherImageUrl == null) {
                                UiHelpers.showSnackbar(
                                    context, "Please upload a teacher image");
                                return;
                              }

                              // ✅ Validate coaching image

                              // ✅ Call signup
                              final error = await provider.signup(context);
                              if (error != null) {
                                UiHelpers.showSnackbar(context, error);
                              } else {
                                UiHelpers.showSnackbar(
                                  context,
                                  "Signup successful. Please verify your email.",
                                  backgroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                );
                                context.go(AppRoutes.emailVerification);
                              }
                            } else {
                              UiHelpers.showSnackbar(
                                context,
                                "Please fix all errors before submitting.",
                              );
                            }
                          },
                        ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _teacherDetails(BuildContext context, TeacherSignupProvider provider) {
    return Column(
      children: [
        UiHelpers.customTextField(
          context,
          hintText: "Full Name",
          controller: provider.fullNameController,
          prefixIcon: const Icon(Icons.person),
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Full Name is required'
              : null,
        ),
        const SizedBox(height: 16),
        UiHelpers.customTextField(
          context,
          hintText: "Email Address",
          controller: provider.emailController,
          prefixIcon: const Icon(Icons.email),
          keyboardType: TextInputType.emailAddress,
          validator: (val) =>
              val == null || !val.contains('@') ? 'Enter a valid email' : null,
        ),
        const SizedBox(height: 16),
        UiHelpers.customTextField(
          context,
          hintText: "Phone Number",
          controller: provider.phoneController,
          prefixIcon: const Icon(Icons.phone),
          keyboardType: TextInputType.phone,
          validator: (val) => val == null || val.length != 10
              ? 'Enter a valid 10-digit phone number'
              : null,
        ),
        const SizedBox(height: 16),
        UiHelpers.customTextField(
          context,
          hintText: "Password",
          controller: provider.passwordController,
          prefixIcon: const Icon(Icons.lock),
          obscureText: provider.obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(provider.obscurePassword
                ? Icons.visibility_off
                : Icons.visibility),
            onPressed: provider.togglePassword,
          ),
          validator: (val) => val != null && val.length < 6
              ? 'Password must be at least 6 characters'
              : null,
        ),
        const SizedBox(height: 24),
        UiHelpers.sectionTitle("Upload Image"),
        const SizedBox(height: 10),
        ImagePickerWidget(
          onImageSelected: provider.pickTeacherImage,
          title: "Upload teacher image",
          isLoading: provider.isUploadingTeacherImage,
        ),
      ],
    );
  }
}
