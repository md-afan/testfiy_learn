import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/app_routes.dart';
import '../../../utils/secure_locally_storage.dart';

/// ✅ Stream to get unread notifications count for student
Stream<int> unreadNotificationCountStream(String uid) {
  return FirebaseFirestore.instance
      .collection('students')
      .doc(uid)
      .collection('notifications')
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snap) => snap.size);
}

class StudentDrawer extends StatelessWidget {
  const StudentDrawer({super.key});

  Future<Map<String, String?>> _getLocalData() async {
    final uid = await LocalStorage.getLocalStorage('uid');
    final imageUrl = await LocalStorage.getLocalStorage('photoURL');
    final name = await LocalStorage.getLocalStorage('fullName');
    return {
      'uid': uid,
      'imageUrl': imageUrl ??
          "https://mohdbinsufiyan.vercel.app/assets/media/mypic.jpg",
      'name': name,
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
        final name = data['name'] ?? 'Student';

        return _buildStudentDrawerUI(
          context,
          uid: uid,
          imageUrl: imageUrl,
          name: name,
        );
      },
    );
  }
}

Widget _buildStudentDrawerUI(
  BuildContext context, {
  required String uid,
  required String imageUrl,
  required String name,
}) {
  final String currentRoute = GoRouterState.of(context).uri.toString();

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
    color: Colors.deepPurple,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.deepPurple),
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
                                  placeholder: (context, url) =>
                                      const CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.grey,
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
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Student',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              buildDrawerItem(
                icon: Icons.home,
                label: 'Home',
                route: AppRoutes.studentDashboard,
              ),
              buildDrawerItem(
                icon: Icons.assignment,
                label: 'Tests',
                route: AppRoutes.studentTest,
              ),
              buildDrawerItem(
                icon: Icons.leaderboard,
                label: 'Rank',
                route: AppRoutes.studentLeaderboard,
              ),

              StreamBuilder<int>(
                stream: unreadNotificationCountStream(uid),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return buildDrawerItem(
                    icon: Icons.notifications,
                    label: 'Notifications',
                    route: AppRoutes.studentnotifications,
                    badgeCount: count,
                  );
                },
              ),

              buildDrawerItem(
                icon: Icons.wallet,
                label: 'Wallet',
                route: AppRoutes.studentWallet,
              ),

              // 👤 Profile image as icon
              buildDrawerItem(
                icon: Icons.person,
                label: 'Profile',
                route: AppRoutes.studentProfile,
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
              buildDrawerItem(
                icon: Icons.settings,
                label: 'Settings',
                route: AppRoutes.settings,
              ),
            ],
          ),
        ),

        // 🔴 Logout
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
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
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
