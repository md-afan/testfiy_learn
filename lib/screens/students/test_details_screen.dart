import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:testify_learn_application/constants/app_routes.dart';
import '../../utils/helpers.dart';
import '../../providers/comman providers/text_detials_provder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TestDetailsScreenToStudents extends StatefulWidget {
  final String testId;
  final String uid;

  const TestDetailsScreenToStudents({
    super.key,
    required this.testId,
    required this.uid,
  });

  @override
  State<TestDetailsScreenToStudents> createState() =>
      _TestDetailsScreenToStudentsState();
}

class _TestDetailsScreenToStudentsState
    extends State<TestDetailsScreenToStudents> {
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    // Initialize provider and fetch data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TestDetailsProvider>();
      provider.setParam(textId: widget.testId, userId: widget.uid);
      provider.initialize();
    });
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildModernQuizInfo(Map<String, dynamic> quizData) {
    final createdAt = (quizData['createdAt'] as Timestamp?)?.toDate();
    final testStart = (quizData['testDateTime'] as Timestamp?)?.toDate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(quizData['title'] ?? '',
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        const SizedBox(height: 8),
        Text(quizData['description'] ?? '',
            style: const TextStyle(fontSize: 16, color: Colors.black54)),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Colors.black87),
            const SizedBox(width: 6),
            Text(
                'Created: ${createdAt != null ? DateFormat('dd MMM yyyy • hh:mm a').format(createdAt) : ''}',
                style: const TextStyle(color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.schedule, size: 20, color: Colors.black87),
            const SizedBox(width: 6),
            Text(
                'Starts: ${testStart != null ? DateFormat('dd MMM yyyy • hh:mm a').format(testStart) : ''}',
                style: const TextStyle(color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _infoBadge(Icons.timer, "Duration: ${quizData['duration']} min"),
            _infoBadge(Icons.attach_money, "Fee: ₹${quizData['fee']}"),
            _infoBadge(Icons.question_answer,
                "Questions: ${quizData['totalQuestions']}"),
            _infoBadge(
                Icons.add_circle, "Positive: ${quizData['positiveScore']}"),
            _infoBadge(
                Icons.remove_circle, "Negative: -${quizData['negativeScore']}"),
            _infoBadge(Icons.flag, "Status: ${quizData['status']}"),
          ],
        ),
      ],
    );
  }

  void _showConfirmDialog(BuildContext context, TestDetailsProvider provider) {
    final fee = (provider.quizData?['fee'] as num?)?.toInt() ?? 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: Text('Are you sure you want to pay ₹$fee to enroll?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await provider.processPayment(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('✅ Payment successful! You are now enrolled.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Yes, Pay'),
            ),
          ],
        );
      },
    );
  }

  void _showInsufficientDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Insufficient Balance'),
          content: const Text(
              'Your wallet balance is not enouygh. Please add money to your wallet.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/wallet');
              },
              child: const Text('Go to Wallet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TestDetailsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && !provider.isRefreshing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: provider.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.quizData == null) {
          return const Scaffold(
            body: Center(child: Text('Test not found')),
          );
        }

        final quizData = provider.quizData!;
        final fee = (quizData['fee'] as num).toInt();

        return Scaffold(
          appBar: UiHelpers.customAppBarForScreen(
            context,
            quizData['title'] ?? 'Test Details',
            automaticallyImplyLeading: true,
            actions: [
              IconButton(
                icon: provider.isRefreshing
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.refresh),
                onPressed: provider.isRefreshing ? null : provider.refresh,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: provider.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernQuizInfo(quizData),
                  const SizedBox(height: 20),
                  MouseRegion(
                    onEnter: (_) => setState(() => _isHovered = true),
                    onExit: (_) => setState(() => _isHovered = false),
                    child: Material(
                      color: _isHovered
                          ? Colors.grey.shade200
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        splashColor: Colors.blue.withOpacity(0.2),
                        onTap: () {
                          context.push(
                              '${AppRoutes.enrolledStudents}/${widget.testId}');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.group, color: Colors.black87),
                              const SizedBox(width: 8),
                              Text(
                                'Enrolled Students: ${provider.totalEnrolledStudents}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Payment/Status Section
                  if (!provider.hasPaid)
                    provider.isProcessingPayment
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black87),
                              ),
                            ),
                          )
                        : UiHelpers.customButton(
                            context,
                            "Pay ₹$fee to Enroll",
                            () {
                              if (provider.walletBalance >= fee) {
                                _showConfirmDialog(context, provider);
                              } else {
                                _showInsufficientDialog(context);
                              }
                            },
                          )
                  else ...[
                    if (provider.testStatus == 'live') ...[
                      UiHelpers.customButton(
                        context,
                        'Join Live Test',
                        () {
                          context.go('${AppRoutes.takeTest}/${widget.testId}');
                        },
                        icon: Icons.play_arrow,
                      ),
                    ] else if (provider.testStatus == 'upcoming') ...[
                      const Text(
                        '✅ You are enrolled. Test is upcoming.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else if (provider.testStatus == 'completed') ...[
                      const Text(
                        '✅ Test Completed',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      UiHelpers.customButton(
                        context,
                        'View Leaderboard',
                        () {
                          context.push(
                              '${AppRoutes.testLeaderborad}/${widget.testId}');
                        },
                        icon: Icons.leaderboard,
                      ),
                      const SizedBox(height: 12),
                      UiHelpers.customButton(
                        context,
                        'Review Questions',
                        () {
                          context.push(
                            '${AppRoutes.reviewQuestion}/${widget.testId}/${widget.uid}',
                            extra: quizData['title'] ?? 'Review Questions',
                          );
                        },
                        icon: Icons.quiz,
                      ),
                    ]
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
