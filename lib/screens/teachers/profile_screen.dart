import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/teachers/teacher_profile_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/secure_locally_storage.dart';
import '../../services/firebase_notification.dart';
import '../../utils/subscribe_enrolled_quizes_or_published.dart';
import '../../constants/app_routes.dart';
import '../../widgets/modern_detials_row.dart';
import '../../widgets/sliver_profile_appbar.dart';
import '../../widgets/global_shimmer_screen.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  bool isProfileImage = false;
  bool isCoverImage = false;
  String uid = '';
  final ImagePicker picker = ImagePicker();
  final String suggestInfo = "Add this info";

  @override
  void initState() {
    super.initState();
    _loadUID();
  }

  void _loadUID() async {
    final localUid = await LocalStorage.getLocalStorage("uid");
    if (mounted) {
      setState(() => uid = localUid ?? '');
      if (uid.isNotEmpty) {
        Provider.of<TeacherProfileProvider>(context, listen: false)
            .fetchTeacherProfile(uid);
      }
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final file = File(image.path);
    setState(() {
      if (isProfile) {
        isProfileImage = true;
      } else {
        isCoverImage = true;
      }
    });

    final provider =
        Provider.of<TeacherProfileProvider>(context, listen: false);
    await provider.updateImage(file, uid);

    setState(() {
      isProfileImage = false;
      isCoverImage = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('${isProfile ? 'Profile' : 'Cover'} image updated')),
    );
  }

  void _showImagePicker(bool isProfile) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Choose from gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(isProfile);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, String coachingCode) async {
    try {
      await unSubscribeToAllQuizTopics(uid, true);
      await FirebaseNotification.unSubscribeToCoaching(coachingCode, true);
      await FirebaseNotification.removeTokenFromFirestore(uid, true);
      await FirebaseAuth.instance.signOut();
      await LocalStorage.clearLocalStorage();
      if (context.mounted) context.go(AppRoutes.login);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer<TeacherProfileProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.isLoading && provider.teacher == null;

        return Scaffold(
          body: GlobalShimmerScreen(
            isLoading: isLoading,
            child: CustomScrollView(
              slivers: [
                SliverProfileAppBar(
                  title: "Profile",
                  name: provider.teacher?.fullName ?? "Loading...",
                  email: provider.teacher?.email ?? "Loading...",
                  profileImageUrl: provider.teacher?.teacherImageUrl ?? "",
                  coverImageUrl: provider.teacher?.coachingImageUrl ?? "",
                  onProfileImageTap: () => _showImagePicker(true),
                  onCoverImageTap: () => _showImagePicker(false),
                  isUploadingImage: isProfileImage || isCoverImage,
                  showBackButton: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        if (provider.teacher != null) {
                          context.push('/edit-teacher-info/$uid');
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () => context.push(AppRoutes.settings),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: UiHelpers.sectionTitle("Teacher Info"),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          children: [
                            ModernDetailRow(
                                icon: Icons.phone,
                                label: "Phone",
                                value: provider.teacher?.phone ?? suggestInfo),
                            ModernDetailRow(
                              icon: Icons.calendar_today,
                              label: "Date of Birth",
                              value: provider.teacher?.dob.isNotEmpty == true
                                  ? provider.teacher!.dob
                                  : suggestInfo,
                            ),
                            ModernDetailRow(
                              icon: Icons.person,
                              label: "Gender",
                              value: provider.teacher?.gender.isNotEmpty == true
                                  ? provider.teacher!.gender
                                  : suggestInfo,
                            ),
                            ModernDetailRow(
                              icon: Icons.star,
                              label: "Skills",
                              value: provider.teacher?.skills.isNotEmpty == true
                                  ? provider.teacher!.skills
                                  : suggestInfo,
                            ),
                            ModernDetailRow(
                              icon: Icons.info_outline,
                              label: "About",
                              value: provider.teacher?.about.isNotEmpty == true
                                  ? provider.teacher!.about
                                  : suggestInfo,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: UiHelpers.sectionTitle("Coaching Info"),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          children: [
                            ModernDetailRow(
                              icon: Icons.school,
                              label: "Coaching Name",
                              value: provider.teacher?.coachingName ??
                                  suggestInfo,
                            ),
                            ModernDetailRow(
                              icon: Icons.code,
                              label: "Coaching Code",
                              value:
                                  provider.teacher?.coachingCode ?? suggestInfo,
                            ),
                            ModernDetailRow(
                              icon: Icons.location_on,
                              label: "Address",
                              value: provider.teacher?.coachingAddress ??
                                  suggestInfo,
                            ),
                            ModernDetailRow(
                              icon: Icons.quiz,
                              label: "Total Quizzes",
                              value: '0',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (provider.teacher != null)
                        TextButton.icon(
                          onPressed: () =>
                              _logout(context, provider.teacher!.coachingCode),
                          icon: const Icon(Icons.logout,
                              color: Colors.redAccent),
                          label: const Text("Logout",
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
