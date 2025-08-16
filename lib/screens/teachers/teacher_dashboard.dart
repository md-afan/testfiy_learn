import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_routes.dart';
import '../../theme/color_pelette.dart';
import '../../utils/helpers.dart';
import '../../utils/responsive.dart';
import '../../widgets/state_box.dart';
import '../../widgets/tab_buttom.dart';
import '../../widgets/sticky_widget.dart';
import 'widgets/test_list_screen.dart';
import 'widgets/studnet_list_screen.dart';
import 'widgets/all_activity_list.dart';
import '../../providers/teachers/teacher_dashboard_proivder.dart';
import "package:go_router/go_router.dart";

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context
        .read<TeacherDashboardProvider>()
        .fetchAndListenTeacherDetails());
  }

  void _setTab(int index) {
    setState(() => _tabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherDashboardProvider>();

    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(
        context,
        "Dashboard",
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.teacherNotifications),
            icon: const Icon(Icons.notifications,
                color: AppColors.iconsPrimary, size: 30),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.teacherProfile),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.transparent,
                backgroundImage: (provider.profileUrl != null &&
                        provider.profileUrl!.isNotEmpty)
                    ? CachedNetworkImageProvider(provider.profileUrl!)
                    : const AssetImage('assets/images/default_user.png')
                        as ImageProvider,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.refreshDashboard,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ResponsiveLayout(
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
      BuildContext context, TeacherDashboardProvider provider) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Welcome back, ${provider.name ?? 'Loading...'}!",
                          style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 4),
                      Text(
                          "Coaching Name: ${provider.coachingName ?? 'Loading...'}",
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text("Coaching code: ${provider.code ?? 'Loading...'}",
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    StatBox(
                      count: provider.totalStudents.toString(),
                      label: "Students",
                      color: AppColors.primaryComman,
                      icon: Icons.group,
                    ),
                    StatBox(
                      count: provider.totalTests.toString(),
                      label: "Tests",
                      color: AppColors.tertiaryComman,
                      icon: Icons.assignment,
                    ),
                    StatBox(
                      count: "32030",
                      label: "Earnings",
                      color: AppColors.secondaryComman,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                UiHelpers.customButton(context, "+ Create new test", () {
                  context.go(AppRoutes.createNewTests);
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        StickyTopPositioned(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TabButton(
                    label: 'All',
                    index: 0,
                    currentIndex: _tabIndex,
                    onTap: _setTab),
                TabButton(
                    label: 'Students',
                    index: 1,
                    currentIndex: _tabIndex,
                    onTap: _setTab),
                TabButton(
                    label: 'Tests',
                    index: 2,
                    currentIndex: _tabIndex,
                    onTap: _setTab),
                TabButton(
                    label: 'Earnings',
                    index: 3,
                    currentIndex: _tabIndex,
                    onTap: _setTab),
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
                Text(
                  _tabIndex == 0
                      ? 'Recent Activity'
                      : _tabIndex == 1
                          ? 'Upcoming Tests'
                          : 'Completed Tests',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _getTabContent(provider),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _getTabContent(TeacherDashboardProvider provider) {
    if (provider.uid == null || provider.code == null) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (_tabIndex) {
      case 0:
        return AllActivityList(
            uid: provider.uid!, coachingCode: provider.code!);
      case 1:
        return StudentsListScreen(coachingCode: provider.code!);
      case 2:
        return TestListScreen(uid: provider.uid!, coachingCode: provider.code!);
      case 3:
        return const Center(child: Text('Earnings will be shown here.'));
      default:
        return const SizedBox.shrink();
    }
  }
}
