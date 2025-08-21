import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:testify_learn_application/constants/app_routes.dart';
import '../../utils/helpers.dart';
import '../../providers/comman providers/theme_provider.dart';

import './app_permission.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isNotificationsEnabled = true;
  String appVersion = "";

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
    _loadAppVersion();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isNotificationsEnabled = prefs.getBool('isNotificationsEnabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationsEnabled', value);
    setState(() => isNotificationsEnabled = value);
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = "${info.version} (${info.buildNumber})";
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    context.go('/login');
  }

  void _openPermissions() {
    // Just a placeholder - you can open app settings using `app_settings` package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Redirecting to app permissions...")),
    );
    // Example with app_settings package: AppSettings.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(
        context,
        'Settings',
        automaticallyImplyLeading: true,
      ),
      body: ListView(
        children: [
          // 🌙 Dark Mode
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(value),
            secondary: const Icon(Icons.dark_mode),
          ),

          // 🔔 Notifications
          SwitchListTile(
            title: const Text('Notifications'),
            value: isNotificationsEnabled,
            onChanged: _toggleNotifications,
            secondary: const Icon(Icons.notifications),
          ),

          const Divider(),

          // 🔑 Change Password
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Change Password'),
            onTap: () => context.push(AppRoutes.changePassword),
          ),

          // 📱 Permissions
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('App Permissions'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PermissionsScreen()));
            },
          ),

          // 📩 Contact Support
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Contact Support'),
            onTap: () {
              // Example action: open email support
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Contacting support...")),
              );
            },
          ),

          // 📜 Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {
              // context.push(AppRoutes.privacyPolicy);
            },
          ),

          // 📄 Terms & Conditions
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('Terms & Conditions'),
            onTap: () {
              // context.push(AppRoutes.termsAndConditions);
            },
          ),

          const Divider(),

          // 🚪 Logout
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: _logout,
          ),

          const Divider(),

          // ℹ️ App Version
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: Text(appVersion.isEmpty ? "Loading..." : appVersion),
          ),
        ],
      ),
    );
  }
}
