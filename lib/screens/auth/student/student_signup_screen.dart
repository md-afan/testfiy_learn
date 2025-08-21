import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth/signup_students_provider.dart';
import '../../../utils/helpers.dart';
import '../../../utils/responsive.dart';
import '../../../constants/app_routes.dart';

class StudentSignup extends StatefulWidget {
  const StudentSignup({super.key});

  @override
  State<StudentSignup> createState() => _StudentSignupState();
}

class _StudentSignupState extends State<StudentSignup> {
  final _formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signupProvider = context.watch<SignupStudentsProvider>();

    return Scaffold(
      appBar: UiHelpers.customAuthAppBar(context, "Sign In", () {
        context.replace(AppRoutes.login);
      }),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: ResponsiveLayout(
          mobile: _buildForm(signupProvider),
          tablet: Center(
              child: SizedBox(width: 500, child: _buildForm(signupProvider))),
          desktop: Center(
              child: SizedBox(width: 500, child: _buildForm(signupProvider))),
          largeDesttop: Center(
              child: SizedBox(width: 500, child: _buildForm(signupProvider))),
        ),
      ),
    );
  }

  Widget _buildForm(SignupStudentsProvider provider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Create Student Account",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Fill in your personal details",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          UiHelpers.sectionTitle("Student Details"),
          const SizedBox(height: 12),

          /// Full name
          UiHelpers.customTextField(
            context,
            hintText: "Full Name",
            controller: fullNameController,
            prefixIcon: const Icon(Icons.person),
            validator: (value) =>
                value == null || value.isEmpty ? 'Full name is required' : null,
          ),
          const SizedBox(height: 16),

          /// Email
          UiHelpers.customTextField(
            context,
            hintText: "Email Address",
            controller: emailController,
            prefixIcon: const Icon(Icons.email),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => value == null || !value.contains('@')
                ? 'Enter a valid email'
                : null,
          ),
          const SizedBox(height: 16),

          /// Phone
          UiHelpers.customTextField(
            context,
            hintText: "Phone Number",
            controller: phoneController,
            prefixIcon: const Icon(Icons.phone),
            keyboardType: TextInputType.phone,
            validator: (value) => value == null || value.length != 10
                ? 'Enter a 10-digit phone number'
                : null,
          ),
          const SizedBox(height: 16),

          /// Password
          UiHelpers.customTextField(
            context,
            hintText: "Password",
            controller: passwordController,
            prefixIcon: const Icon(Icons.lock),
            obscureText: provider.obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                provider.obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: provider.togglePasswordVisibility,
            ),
            validator: (value) => value != null && value.length < 6
                ? 'Password must be at least 6 characters'
                : null,
          ),
          const SizedBox(height: 32),

          /// Submit Button
          provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : UiHelpers.customButton(
                  context,
                  "Create Account",
                  () => provider.registerStudent(
                    context: context,
                    fullName: fullNameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    password: passwordController.text.trim(),
                    formKey: _formKey,
                  ),
                ),

          const SizedBox(height: 24),

          /// Divider
          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text("Or sign up with"),
              ),
              Expanded(child: Divider()),
            ],
          ),
        ],
      ),
    );
  }
}
