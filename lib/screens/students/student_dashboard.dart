import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testify_learn_application/widgets/global_shimmer_screen.dart';
import '../../providers/students/studnet_dashboard_provider.dart';
import '../../utils/helpers.dart';
import '../../theme/color_pelette.dart';
import '../../widgets/state_box.dart';
import '../../widgets/tab_buttom.dart';
import '../../widgets/sticky_widget.dart';
import '../../utils/responsive.dart';
import './widgets/test_list.dart';
import '../../constants/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:testify_learn_application/theme/shimmer_theme.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();
    final provider =
        Provider.of<StudentDashboardProvider>(context, listen: false);
    provider.loadLocalData().then((_) => provider.fetchAllData());
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentDashboardProvider>(context);

    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(
        context,
        "Dashboard",
        actions: [
          IconButton(
            onPressed: () {
              context.push(AppRoutes.studentnotifications);
            },
            icon: const Icon(
              Icons.notifications,
              color: AppColors.iconsPrimary,
              size: 30,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.refreshData,
        child: ResponsiveLayout(
          mobile: _dashboardBody(context, provider),
          tablet: _dashboardBody(context, provider),
          desktop: _dashboardBody(context, provider),
          largeDesttop: Row(
            children: [
              Expanded(flex: 2, child: _dashboardBody(context, provider)),
              const VerticalDivider(width: 1),
              const Expanded(child: Center(child: Text("Extra Panel"))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardBody(
      BuildContext context, StudentDashboardProvider provider) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                provider.isLoading
                    ? _buildWelcomeSectionShimmer(context)
                    : _buildWelcomeSection(context, provider),
                const SizedBox(height: 20),
                provider.isLoading
                    ? StatBoxShimmer(
                        count: 3,
                      )
                    : Row(
                        children: [
                          StatBox(
                            count: provider.testsTaken.toString(),
                            label: "Tests Taken",
                            color: AppColors.primaryComman,
                            icon: Icons.assignment,
                          ),
                          StatBox(
                            count: provider.testsWon.toString(),
                            label: "Tests Won",
                            color: AppColors.tertiaryComman,
                            icon: Icons.emoji_events,
                          ),
                          StatBox(
                            count: provider.rank.toString(),
                            label: "Rank",
                            color: AppColors.secondaryComman,
                            icon: Icons.leaderboard,
                          ),
                        ],
                      )
              ],
            ),
          ),
        ),
        StickyTopPositioned(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: provider.isLoading
                ? TabButtonShimmer(count: 3)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TabButton(
                        label: 'New tests',
                        index: 0,
                        currentIndex: provider.tabIndex,
                        onTap: provider.setTab,
                      ),
                      TabButton(
                        label: 'Enroll tests',
                        index: 1,
                        currentIndex: provider.tabIndex,
                        onTap: provider.setTab,
                      ),
                      TabButton(
                        label: 'Completed tests',
                        index: 2,
                        currentIndex: provider.tabIndex,
                        onTap: provider.setTab,
                      ),
                    ],
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlobalShimmerScreen(
                  isLoading: provider.isLoading,
                  child: Text(
                    provider.tabIndex == 0
                        ? 'New Tests'
                        : provider.tabIndex == 1
                            ? 'Enrolled Tests'
                            : 'Completed Tests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                if (provider.coachingCode != null)
                  TestListScreen(
                    uid: provider.uid,
                    isRefreshing: provider.isLoading,
                    coachingCode: provider.coachingCode!,
                    filter: provider.tabIndex == 0
                        ? 'upcoming'
                        : provider.tabIndex == 1
                            ? 'enrolled'
                            : 'completed',
                    key: ValueKey(
                        "${provider.tabIndex}_${provider.uid}_${provider.coachingCode}"),
                  )
                else
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(
      BuildContext context, StudentDashboardProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome back, Affan!",
            style: Theme.of(context).textTheme.displaySmall,
          ),
          SizedBox(
            height: 10,
          ),
          InkWell(
            onTap: () {
              context
                  .push('${AppRoutes.organization}/${provider.coachingCode}');
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                if (provider.coachingImageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: provider.coachingImageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox(
                        width: 60,
                        height: 60,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.school, size: 60),
                    ),
                  )
                else
                  const Icon(Icons.school, size: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (provider.coachingName != null)
                        Text(
                          provider.coachingName!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      Text(
                        "Coaching Code: ${provider.coachingCode}",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// shimmer widget for _buildWelcomeSection
Widget _buildWelcomeSectionShimmer(BuildContext context) {
  final shimmerTheme = Theme.of(context).extension<ShimmerTheme>()!;
  final theme = Theme.of(context).colorScheme;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Text shimmer
        Shimmer.fromColors(
          baseColor: shimmerTheme.baseColor,
          highlightColor: shimmerTheme.highlightColor,
          child: Container(
            height: 24,
            width: double.infinity,
            decoration: BoxDecoration(
                color: theme.surface, borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(height: 20),

        // Coaching row shimmer
        Row(
          children: [
            // Image shimmer
            Shimmer.fromColors(
              baseColor: shimmerTheme.baseColor,
              highlightColor: shimmerTheme.highlightColor,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Text shimmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: shimmerTheme.baseColor,
                    highlightColor: shimmerTheme.highlightColor,
                    child: Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Shimmer.fromColors(
                    baseColor: shimmerTheme.baseColor,
                    highlightColor: shimmerTheme.highlightColor,
                    child: Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ],
    ),
  );
}
