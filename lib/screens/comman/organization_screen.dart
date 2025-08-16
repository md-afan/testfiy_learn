import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../widgets/state_box.dart';
import '../../widgets/sliver_profile_appbar.dart';
import '../../providers/comman providers/organization_provider.dart';

class OrganizationScreen extends StatelessWidget {
  final String coachingCode;

  const OrganizationScreen({super.key, required this.coachingCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider(
      create: (_) => CoachingDetailsProvider(coachingCode: coachingCode),
      child: Consumer<CoachingDetailsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Scaffold(
              body: _buildCustomShimmer(context),
            );
          }

          if (provider.error != null) {
            return Scaffold(
              body: Center(child: Text("Error: ${provider.error}")),
            );
          }

          final coaching = provider.coachingData ?? {};
          final teacher = provider.teacherData ?? {};
          final studentCount = provider.studentsCount;
          final teacherCount = provider.teachersCount;
          final testsCount = provider.testsCount;

          return Scaffold(
            body: RefreshIndicator(
              onRefresh: provider.refresh,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double maxWidth =
                      constraints.maxWidth > 800 ? 800 : constraints.maxWidth;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: maxWidth,
                      child: CustomScrollView(
                        slivers: [
                          SliverProfileAppBar(
                            title: "Organization Details",
                            name: coaching['name'] ?? "Coaching Name",
                            email: 'Code : ${coaching['code'] ?? coachingCode}',
                            showBackButton: true,
                            profileImageUrl: teacher['teacherImageUrl'],
                            coverImageUrl: coaching['logoUrl'] ?? '',
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      StatBox(
                                        count: studentCount.toString(),
                                        label: "Students",
                                        color: Colors.blue,
                                        icon: Icons.people_alt,
                                      ),
                                      StatBox(
                                        count: teacherCount.toString(),
                                        label: "Teachers",
                                        color: Colors.orangeAccent,
                                        icon: Icons.school,
                                      ),
                                      StatBox(
                                        count: testsCount.toString(),
                                        label: "Tests",
                                        color: Colors.purple,
                                        icon: Icons.assignment,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    "Coaching Information",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _infoRow(
                                    context,
                                    Icons.location_on,
                                    "Address",
                                    coaching['address'] ?? "Not specified",
                                  ),
                                  _infoRow(
                                    context,
                                    Icons.phone,
                                    "Contact",
                                    coaching['contact'] ?? "Not available",
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    "Admin Information",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _infoRow(
                                    context,
                                    Icons.person,
                                    "Name",
                                    teacher['fullName'] ?? "Not specified",
                                  ),
                                  _infoRow(
                                    context,
                                    Icons.email,
                                    "Email",
                                    teacher['email'] ?? "Not available",
                                  ),
                                  _infoRow(
                                    context,
                                    Icons.phone_android,
                                    "Phone",
                                    teacher['phone'] ?? "Not available",
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// ================== Custom Shimmer While Loading ==================
  Widget _buildCustomShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 200,
            color: Colors.grey.shade300,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Stat boxes shimmer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(3, (index) {
                    return Container(
                      width: 100,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                // Section titles + rows shimmer
                _shimmerLine(width: 180, height: 20),
                const SizedBox(height: 16),
                ...List.generate(2, (_) => _shimmerInfoRow()),
                const SizedBox(height: 24),
                _shimmerLine(width: 180, height: 20),
                const SizedBox(height: 16),
                ...List.generate(3, (_) => _shimmerInfoRow()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerLine({double width = double.infinity, double height = 14}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _shimmerInfoRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerLine(width: 120),
                const SizedBox(height: 6),
                _shimmerLine(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
