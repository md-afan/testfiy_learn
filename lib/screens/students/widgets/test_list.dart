import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../widgets/text_card.dart';
import 'package:testify_learn_application/constants/app_routes.dart';
import '../../../providers/students/studnets_tests_list_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestListScreen extends StatefulWidget {
  final bool isRefreshing;
  final String coachingCode;
  final String uid;
  final String filter;

  const TestListScreen({
    super.key,
    this.isRefreshing = false,
    required this.coachingCode,
    required this.uid,
    required this.filter,
  });

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider =
        Provider.of<StudentTestListProvider>(context, listen: false);

    if (!_initialized) {
      provider.setParams(
        coachingCode: widget.coachingCode,
        uid: widget.uid,
        filter: widget.filter,
      );
      provider.loadTests();
      _initialized = true;
    }

    // 🔄 If isRefreshing is true, trigger refresh
    if (widget.isRefreshing) {
      provider.refreshTests();
    }
  }

  @override
  void didUpdateWidget(covariant TestListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔄 Detect when isRefreshing changes from false → true
    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      final provider =
          Provider.of<StudentTestListProvider>(context, listen: false);
      provider.refreshTests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentTestListProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.tests.isEmpty) {
          return TestCardShimmer(count: 6);
        }

        if (provider.errorMessage.isNotEmpty) {
          return Center(child: Text(provider.errorMessage));
        }

        if (provider.tests.isEmpty) {
          return Center(child: Text("No ${widget.filter} tests found."));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(5),
          shrinkWrap: true,
          itemCount: provider.tests.length + (provider.hasMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == provider.tests.length) {
              if (!provider.isFetchingMore) {
                provider.fetchMoreTests();
              }
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final doc = provider.tests[index];
            final data = doc.data();

            String createdAtStr = '';
            final createdAt = data['createdAt'];
            if (createdAt is Timestamp) {
              createdAtStr =
                  DateFormat.yMMMd().add_Hm().format(createdAt.toDate());
            }

            String testDateStr = "Unknown";
            final testDate = data['testDateTime'];
            if (testDate is Timestamp) {
              testDateStr =
                  DateFormat("dd MMM yyyy, hh:mm a").format(testDate.toDate());
            }

            return TestCard(
              title: data['title'] ?? 'Untitled',
              subTitle: "Test Date: $testDateStr",
              bottomTitle: 'Created on $createdAtStr',
              icon: Icons.description,
              onTap: () {
                context.push(
                  '${AppRoutes.testDetaistTostudents}/${doc.id}/${widget.uid}',
                );
              },
            );
          },
        );
      },
    );
  }
}
