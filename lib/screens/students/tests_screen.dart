import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../widgets/tests_card_widget.dart';
import '../../widgets/global_shimmer_screen.dart';
import '../../providers/comman providers/tests_provider.dart';
import '../../utils/helpers.dart';
import '../../constants/app_routes.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TestScreenProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Provider.of<TestScreenProvider>(context, listen: false).disposeProvider();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      Provider.of<TestScreenProvider>(context, listen: false).loadMoreData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(context, "Tests"),
      body: Consumer<TestScreenProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: Column(
              children: [
                _buildFilterChips(provider),
                Expanded(
                  child: GlobalShimmerScreen(
                    isLoading: provider.isLoading,
                    child: _buildTestList(provider),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(TestScreenProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: provider.filters
              .asMap()
              .entries
              .map((entry) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: provider.selectedFilter == entry.key,
                      selectedColor: Colors.deepPurple,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      labelStyle: TextStyle(
                        color: provider.selectedFilter == entry.key
                            ? Colors.white
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      onSelected: (_) => provider.setFilter(entry.key),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTestList(TestScreenProvider provider) {
    if (provider.isLoading) {
      // Placeholder shimmer items for loading
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    if (provider.allTests.isEmpty && !provider.isRefreshing) {
      return const Center(child: Text('No tests available'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: provider.allTests.length + (provider.hasMoreData ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == provider.allTests.length && provider.hasMoreData) {
          return _buildLoadMoreIndicator(provider);
        }

        final doc = provider.allTests[i];
        return _TestItem(
          doc: doc,
          provider: provider,
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator(TestScreenProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: provider.isFetchingMore
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: () => provider.loadMoreData(),
                child: const Icon(Icons.plus_one_sharp),
              ),
      ),
    );
  }
}

class _TestItem extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final TestScreenProvider provider;

  const _TestItem({
    required this.doc,
    required this.provider,
  });

  @override
  State<_TestItem> createState() => __TestItemState();
}

class __TestItemState extends State<_TestItem> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final testId = widget.doc.id;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quizzes')
          .doc(testId)
          .collection('enrolledStudents')
          .doc(widget.provider.uid)
          .snapshots(),
      builder: (context, enrolledSnapshot) {
        if (!enrolledSnapshot.hasData) return const SizedBox.shrink();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('quizzes')
              .doc(testId)
              .collection('enrolledStudents')
              .snapshots(),
          builder: (context, countSnapshot) {
            if (!countSnapshot.hasData) return const SizedBox.shrink();

            return _buildTestCard(
              data: data,
              testId: testId,
              enrolledData:
                  enrolledSnapshot.data!.data() as Map<String, dynamic>?,
              enrolledCount: countSnapshot.data!.size,
            );
          },
        );
      },
    );
  }

  Widget _buildTestCard({
    required Map<String, dynamic> data,
    required String testId,
    required Map<String, dynamic>? enrolledData,
    required int enrolledCount,
  }) {
    final testStatus =
        (data['status'] ?? 'upcoming').toString().trim().toLowerCase();
    final fee =
        int.tryParse(data['fee']?.toString().replaceAll('₹', '') ?? '0') ?? 0;
    final isPaid = enrolledData?['hasPaid'] ?? false;

    // Apply filter
    if (widget.provider.shouldSkipCard(testStatus, isPaid, true)) {
      return const SizedBox.shrink();
    }

    String datePart = 'Unknown';
    String timePart = 'Unknown';

    if (data['testDateTime'] is Timestamp) {
      final dateTime = (data['testDateTime'] as Timestamp).toDate();
      datePart = DateFormat('dd-MM-yyyy').format(dateTime);
      timePart = DateFormat('hh:mm a').format(dateTime);
    } else if (data['testDateTime'] is String) {
      try {
        final dateTime = DateTime.parse(data['testDateTime']);
        datePart = DateFormat('dd-MM-yyyy').format(dateTime);
        timePart = DateFormat('hh:mm a').format(dateTime);
      } catch (_) {}
    }

    final cardInfo = widget.provider.getStudentCardInfo(
      testStatus: testStatus,
      isPaid: isPaid,
      fee: fee,
      context: context,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isProcessing,
            child: TestCard(
              subject: data['title'] ?? 'Untitled Test',
              date: datePart,
              time: timePart,
              duration: data['duration'] ?? 'Unknown',
              mcqCount: data['totalQuestions']?.toString() ?? '0',
              status: cardInfo.statusLabel,
              actionLabel: cardInfo.actionLabel,
              actionColor: cardInfo.statusColor,
              extraInfo: 'Enrolled: $enrolledCount students',
              onPressed: () => widget.provider.handleStudentAction(
                context: context,
                testStatus: testStatus,
                isPaid: isPaid,
                fee: fee,
                testId: testId,
                data: data,
              ),
              secondActionLabel: "View",
              secondOnPressed: () => context.push(
                  '${AppRoutes.testDetaistTostudents}/$testId/${widget.provider.uid}'),
            ),
          ),
          if (testStatus == 'live')
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
