import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  Map<String, bool> permissionsStatus = {
    "Camera": false,
    "Microphone": false,
    "Storage": false,
    "Notification": false,
  };

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final camera = await Permission.camera.isGranted;
    final mic = await Permission.microphone.isGranted;
    final storage = await Permission.storage.isGranted;
    final notif = await Permission.notification.isGranted;

    setState(() {
      permissionsStatus = {
        "Camera": camera,
        "Microphone": mic,
        "Storage": storage,
        "Notification": notif,
      };
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isGranted) {
      _checkPermissions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permission denied. Open settings to enable.")),
      );
    }
  }

  Widget _buildPermissionTile(String name, Permission permission) {
    return SwitchListTile(
      title: Text(name),
      value: permissionsStatus[name] ?? false,
      onChanged: (value) {
        if (value) {
          _requestPermission(permission);
        } else {
          AppSettings.openAppSettings();
        }
      },
      secondary: Icon(
        name == "Camera"
            ? Icons.camera_alt
            : name == "Microphone"
                ? Icons.mic
                : name == "Storage"
                    ? Icons.sd_storage
                    : Icons.notifications,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Permissions"),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildPermissionTile("Camera", Permission.camera),
          _buildPermissionTile("Microphone", Permission.microphone),
          _buildPermissionTile("Storage", Permission.storage),
          _buildPermissionTile("Notification", Permission.notification),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Open System Settings"),
            subtitle: const Text("Manage all permissions manually"),
            onTap: () => AppSettings.openAppSettings(),
          ),
        ],
      ),
    );
  }
}
