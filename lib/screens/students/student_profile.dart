import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_routes.dart';
import '../../services/firebase_notification.dart';
import '../../utils/cloudinary.dart';
import '../../utils/secure_locally_storage.dart';
import '../../utils/subscribe_enrolled_quizes_or_published.dart';
import '../../widgets/modern_detials_row.dart';
import '../../widgets/sliver_profile_appbar.dart';
import '../../providers/students/profile_provider.dart';
import '../../widgets/text_card.dart';
import '../../widgets/global_shimmer_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  String? uid;
  String? coachingCode;
  bool isUploadingImage = false;
  bool isUploadingCoverImage = false;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final localUid = await LocalStorage.getLocalStorage('uid');
    final localCoachingCode =
        await LocalStorage.getLocalStorage('coachingCode');
    if (localUid != null) {
      setState(() {
        uid = localUid;
        coachingCode = localCoachingCode;
      });

      final provider = context.read<StudentProfileProvider>();
      provider.fetchStudentProfile(localUid);
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await unSubscribeToAllQuizTopics(uid.toString(), false);
      await FirebaseNotification.unSubscribeToCoaching(
          coachingCode.toString(), false);
      await FirebaseNotification.removeTokenFromFirestore(
          uid.toString(), false);
      await FirebaseAuth.instance.signOut();
      await LocalStorage.clearLocalStorage();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  Future<void> _pickAndUploadImage(bool isProfile) async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() =>
        isProfile ? isUploadingImage = true : isUploadingCoverImage = true);

    final file = File(picked.path);
    final url =
        await uploadImageToCloudinary(file, folderName: 'testify_learn/images');

    final provider = context.read<StudentProfileProvider>();
    if (uid != null) {
      if (isProfile) {
        await provider.updateProfileImage(url.toString(), uid!);
      } else {
        await provider.updateCoverImages(url.toString(), uid!);
      }
    }

    setState(() =>
        isProfile ? isUploadingImage = false : isUploadingCoverImage = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                isProfile ? "Profile image updated" : "Cover image updated")),
      );
    }
  }

  void _showImagePickerBottomSheet(bool isProfile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(isProfile);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text("Cancel"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderBox({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProfileProvider>(
      builder: (__, provider, _) {
        final student = provider.student;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => provider.refreshStudentProfile(uid!),
            child: GlobalShimmerScreen(
              isLoading: provider.isLoading && student == null,
              child: CustomScrollView(
                slivers: [
                  SliverProfileAppBar(
                    title: "Profile",
                    name: student?.fullName ?? "Loading...",
                    email: student?.email ?? "Loading...",
                    profileImageUrl: student?.profileImageUrl ?? "",
                    coverImageUrl: student?.coverImageUrl ??
                        'https://mohdbinsufiyan.vercel.app/assets/media/mypic.jpg',
                    onProfileImageTap: () => _showImagePickerBottomSheet(true),
                    isUploadingImage: isUploadingImage,
                    onCoverImageTap: () => _showImagePickerBottomSheet(false),
                    isUploadingCoverImages: isUploadingCoverImage,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () =>
                            context.push('${AppRoutes.editStudentInfo}/$uid'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () => context.push(AppRoutes.settings),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Personal Details",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              if (student != null) ...[
                                ModernDetailRow(
                                    icon: Icons.phone,
                                    label: "Phone",
                                    value: student.phone),
                                ModernDetailRow(
                                    icon: Icons.class_,
                                    label: "Class",
                                    value: student.studentClass),
                                ModernDetailRow(
                                    icon: Icons.location_city,
                                    label: "City",
                                    value: student.city),
                                ModernDetailRow(
                                    icon: Icons.calendar_today,
                                    label: "Date of Birth",
                                    value: student.dob),
                                ModernDetailRow(
                                    icon: Icons.person,
                                    label: "Gender",
                                    value: student.gender),
                                ModernDetailRow(
                                    icon: Icons.star,
                                    label: "Skills",
                                    value: student.skills),
                                ModernDetailRow(
                                    icon: Icons.info_outline,
                                    label: "About",
                                    value: student.about),
                              ] else ...[
                                _buildPlaceholderBox(height: 20, width: 150),
                                const SizedBox(height: 10),
                                _buildPlaceholderBox(height: 20, width: 200),
                                const SizedBox(height: 10),
                                _buildPlaceholderBox(height: 20, width: 180),
                              ],
                              const SizedBox(height: 30),
                              const Text("Joined in Coachings or Organizations",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              if (student?.coachingCodes.isNotEmpty ?? false)
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: provider.fetchCoachingDataBatched(
                                      student!.coachingCodes),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Column(
                                        children: List.generate(
                                          2,
                                          (index) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: _buildPlaceholderBox(
                                                height: 80,
                                                width: double.infinity),
                                          ),
                                        ),
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return Center(
                                          child:
                                              Text('Error: ${snapshot.error}'));
                                    }
                                    if (!snapshot.hasData ||
                                        snapshot.data!.isEmpty) {
                                      return const Center(
                                          child: Text(
                                              'No coaching data available.'));
                                    }

                                    final coachingList = snapshot.data!;

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: coachingList.map((coaching) {
                                        return TestCard(
                                          title: coaching['name'] ?? "",
                                          subTitle:
                                              "Code: ${coaching['code'] ?? '-'}",
                                          imagesUrl: coaching['logoUrl'],
                                          onTap: () => context.push(
                                              '${AppRoutes.organization}/${coaching['code']}'),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
