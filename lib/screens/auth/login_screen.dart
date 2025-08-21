import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth/login_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/responsive.dart';
import '../../constants/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);

    return Scaffold(
      appBar: UiHelpers.customAuthAppBar(context, "Get Started", () {
        context.push(AppRoutes.role);
      }),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ResponsiveLayout(
                mobile: _form(loginProvider),
                tablet: Center(
                    child: SizedBox(width: 500, child: _form(loginProvider))),
                desktop: Center(
                    child: SizedBox(width: 500, child: _form(loginProvider))),
                largeDesttop: Center(
                    child: SizedBox(width: 500, child: _form(loginProvider))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(LoginProvider loginProvider) {
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

          // Email
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

          // Password
          const Text("Password", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          UiHelpers.customTextField(
            context,
            hintText: "Password",
            controller: passwordController,
            prefixIcon: const Icon(Icons.lock),
            obscureText: loginProvider.obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(loginProvider.obscurePassword
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () => loginProvider.togglePassword(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6)
                return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Login button
          loginProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : UiHelpers.customButton(context, "Sign In", () {
                  if (_formKey.currentState!.validate()) {
                    loginProvider.loginWithEmail(
                      context,
                      emailController.text,
                      passwordController.text,
                    );
                  }
                }),

          if (loginProvider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(loginProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 12),

          Center(
            child: TextButton(
              onPressed: () => context.push(AppRoutes.resetPassword),
              child: const Text(
                "Forgot your password?",
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Divider
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

          // Google login
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton("Google", "assets/images/google.jpg", () {
                loginProvider.loginWithGoogle(context);
              }),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don’t have an account? "),
              GestureDetector(
                onTap: () =>
                    context.push(AppRoutes.role), // go to role/signup page
                child: Text(
                  "Sign up",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
