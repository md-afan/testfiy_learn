import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/app_routes.dart';
import '../../../utils/secure_locally_storage.dart';
import '../../../utils/enryped_decryped.dart';
import '../../../constants/role_constants.dart';

/// 🔥 Stream to get unread notifications count for current teacher
Stream<int> unreadNotificationCountStream(String uid) {
  return FirebaseFirestore.instance
      .collection('teachers')
      .doc(uid)
      .collection('notifications')
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snap) => snap.size);
}

class TeacherDrawer extends StatelessWidget {
  const TeacherDrawer({super.key});

  Future<Map<String, String?>> _getLocalData() async {
    final uid = await LocalStorage.getLocalStorage('uid');
    final imageUrl = await LocalStorage.getLocalStorage('photoURL');
    final encrypted = await LocalStorage.getLocalStorage('role');
    final decryptedRole = await EncryptionHelper.decrypt(encrypted.toString());

    return {
      'uid': uid,
      'imageUrl': imageUrl ??  "https://mohdbinsufiyan.vercel.app/assets/media/mypic.jpg",
      'role': decryptedRole,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: _getLocalData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final uid = data['uid'] ?? '';
        final imageUrl = data['imageUrl'] ?? '';
        final role = data['role'] ?? 'Teacher';

        return _buildTeacherDrawerUI(context,
            uid: uid, imageUrl: imageUrl, role: role);
      },
    );
  }
}

Widget _buildTeacherDrawerUI(
  BuildContext context, {
  required String uid,
  required String imageUrl,
  required String role,
}) {
  final String currentRoute = GoRouterState.of(context).uri.toString();
  bool isAdmin = RoleConstants.isAdmin(role);

  Widget buildDrawerItem({
    required IconData icon,
    required String label,
    required String route,
    int badgeCount = 0,
    Widget? leadingIcon,
  }) {
    final bool isActive = currentRoute == route;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isActive ? Colors.white.withOpacity(0.08) : Colors.transparent,
        child: ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              leadingIcon ??
                  Icon(icon, color: isActive ? Colors.amber : Colors.white),
              if (badgeCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.amber : Colors.white,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () {
            if (!isActive) context.go(route);
          },
        ),
      ),
    );
  }

  return Container(
    width: 250,
    color: Theme.of(context).colorScheme.primary,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              DrawerHeader(
                decoration:
                    BoxDecoration(color: Theme.of(context).colorScheme.primary),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageUrl.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  height: 44,
                                  width: 44,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: 44,
                                    width: 44,
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      ClipOval(
                                    child: Image.asset(
                                      'assets/images/default_image.png',
                                      height: 44,
                                      width: 44,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              )
                            : ClipOval(
                                child: Image.asset(
                                  'assets/images/default_image.png',
                                  height: 44,
                                  width: 44,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Mohd Sufiyan",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(isAdmin ? 'Coaching Admin' : "Teacher",
                          style:
                              const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              buildDrawerItem(
                  icon: Icons.home,
                  label: 'Home',
                  route: AppRoutes.teacherDashboard),
              buildDrawerItem(
                  icon: Icons.assignment,
                  label: 'Tests',
                  route: AppRoutes.teachertests),
              buildDrawerItem(
                  icon: Icons.add,
                  label: 'Create',
                  route: AppRoutes.createNewTests),
              StreamBuilder<int>(
                stream: unreadNotificationCountStream(uid),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return buildDrawerItem(
                    icon: Icons.notifications,
                    label: 'Notifications',
                    route: AppRoutes.teacherNotifications,
                    badgeCount: count,
                  );
                },
              ),
              buildDrawerItem(
                  icon: Icons.personal_injury_outlined,
                  label: 'Students',
                  route: AppRoutes.teacherShowStudent),
              if (isAdmin)
                buildDrawerItem(
                    icon: Icons.approval,
                    label: 'Approval',
                    route: AppRoutes.teachersApproval),
              buildDrawerItem(
                  icon: Icons.wallet,
                  label: 'Wallet',
                  route: AppRoutes.teacherWallet),
              buildDrawerItem(
                icon: Icons.person,
                label: 'Profile',
                route: AppRoutes.teacherProfile,
                leadingIcon: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey,
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (shouldLogout == true) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              }
            },
          ),
        ),
      ],
    ),
  );
}
