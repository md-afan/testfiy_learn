import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_routes.dart';
import '../../../utils/helpers.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/picker_images.dart';
import '../../../providers/auth/organization_creation_provider.dart';

class OrganizationSignupScreen extends StatelessWidget {
  const OrganizationSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrganizationSignupProvider(),
      child: Consumer<OrganizationSignupProvider>(
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
                    const Text("Create Teacher Account",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Fill in your personal and coaching details",
                        style: TextStyle(color: Colors.grey)),

                    const SizedBox(height: 20),

                    /// 🔑 Responsive Layout
                    ResponsiveLayout(
                      mobile: Column(
                        children: [
                          UiHelpers.sectionTitle("Teacher Details"),
                          _teacherDetails(context, provider),
                          const SizedBox(height: 32),
                          UiHelpers.sectionTitle("Coaching Details"),
                          _coachingDetails(context, provider),
                        ],
                      ),
                      tablet: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UiHelpers.sectionTitle("Teacher Details"),
                                _teacherDetails(context, provider),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UiHelpers.sectionTitle("Coaching Details"),
                                _coachingDetails(context, provider),
                              ],
                            ),
                          ),
                        ],
                      ),
                      desktop: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UiHelpers.sectionTitle("Teacher Details"),
                                _teacherDetails(context, provider),
                              ],
                            ),
                          ),
                          const SizedBox(width: 48),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UiHelpers.sectionTitle("Coaching Details"),
                                _coachingDetails(context, provider),
                              ],
                            ),
                          ),

                          
                        ],
                        
                      ),
                      largeDesttop: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UiHelpers.sectionTitle("Teacher Details"),
                                _teacherDetails(context, provider),
                              ],
                            ),
                          ),
                          const SizedBox(width: 48),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UiHelpers.sectionTitle("Coaching Details"),
                                _coachingDetails(context, provider),
                              ],
                            ),
                          ),

                          
                        ],
                        
                      ),
                    ),

                    const SizedBox(height: 40),

                    provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : UiHelpers.customButton(context, "Submit", () async {
                            if (provider.formKey.currentState!.validate()) {
                              if (provider.teacherImageUrl == null) {
                                UiHelpers.showSnackbar(
                                    context, "Please upload a teacher image");
                                return;
                              }
                              if (provider.coachingImageUrl == null) {
                                UiHelpers.showSnackbar(
                                    context, "Please upload a coaching image");
                                return;
                              }

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
                              UiHelpers.showSnackbar(context,
                                  "Please fix errors before submitting.");
                            }
                          }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _teacherDetails(
      BuildContext context, OrganizationSignupProvider provider) {
    return Column(
      children: [
        UiHelpers.customTextField(
          context,
          hintText: "Full Name",
          controller: provider.fullNameController,
          prefixIcon: const Icon(Icons.person),
          validator: (val) =>
              val == null || val.trim().isEmpty ? 'Full Name is required' : null,
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
      ],
    );
  }

  Widget _coachingDetails(
      BuildContext context, OrganizationSignupProvider provider) {
    return Column(
      children: [
        UiHelpers.customTextField(
          context,
          hintText: "Coaching Name",
          controller: provider.coachingNameController,
          prefixIcon: const Icon(Icons.business),
          validator: (val) =>
              val == null || val.trim().isEmpty ? 'Coaching name is required' : null,
        ),
        const SizedBox(height: 16),
        UiHelpers.customTextField(
          context,
          hintText: "Coaching Address",
          controller: provider.coachingAddressController,
          prefixIcon: const Icon(Icons.location_on),
          validator: (val) =>
              val == null || val.trim().isEmpty ? 'Address is required' : null,
        ),
        const SizedBox(height: 24),
        UiHelpers.sectionTitle("Upload Images"),
        const SizedBox(height: 10),
        ImagePickerWidget(
          title: "Upload teacher image",
          isLoading: provider.isUploadingTeacherImage,
          onImageSelected: provider.pickTeacherImage,
        ),
        const SizedBox(height: 24),
        ImagePickerWidget(
          title: "Upload coaching image",
          isLoading: provider.isUploadingCoachingImage,
          onImageSelected: provider.pickCoachingImage,
        ),
      ],
    );
  }
}
