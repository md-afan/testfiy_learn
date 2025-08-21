import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/helpers.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_routes.dart';
import '../../services/firebase_notification.dart';

class TestDetailsScreen extends StatefulWidget {
  final String testId;
  const TestDetailsScreen({super.key, required this.testId});

  @override
  State<TestDetailsScreen> createState() => _TestDetailsScreenState();
}

class _TestDetailsScreenState extends State<TestDetailsScreen> {
  late final Stream<DocumentSnapshot> _quizStream;
  late final Stream<QuerySnapshot> _enrolledStream;

  final List<DocumentSnapshot> _questions = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _perPage = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _quizStream = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.testId)
        .snapshots();

    _enrolledStream = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.testId)
        .collection("enrolledStudents")
        .snapshots();

    _scrollController.addListener(_onScroll);
    _fetchQuestions();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _fetchQuestions();
    }
  }

  Future<void> _fetchQuestions() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.testId)
        .collection('questions')
        .orderBy('questionText')
        .limit(_perPage);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
      _questions.addAll(snapshot.docs);
      if (snapshot.docs.length < _perPage) _hasMore = false;
    } else {
      _hasMore = false;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteTest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Test?"),
        content: const Text("Are you sure you want to delete this test?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Yes, Delete",
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final questionsRef = FirebaseFirestore.instance
            .collection('quizzes')
            .doc(widget.testId)
            .collection('questions');

        final questionsSnapshot = await questionsRef.get();
        for (var doc in questionsSnapshot.docs) {
          await doc.reference.delete();
        }

        await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(widget.testId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Test deleted successfully")),
          );
          context.pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete test: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _quizStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('Test not found.')));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final isPublished = data['isPublished'] ?? false;
        final status = data['status'] ?? '';
        final isLive = status == "live";
        final isCompleted = status == "completed";
        final isLocked = isLive || isCompleted;

        return Scaffold(
          appBar: UiHelpers.customAppBarForScreen(
            context,
            "Test Details",
            actions: [
              if (!isLocked)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      context.push('${AppRoutes.editTest}/${widget.testId}'),
                  tooltip: "Edit Test",
                ),
              if (!isLocked)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteTest,
                  tooltip: "Delete Test",
                ),
            ],
            automaticallyImplyLeading: true,
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: _buildModernQuizInfo(data),
                ),
                const SizedBox(height: 20),
                if (!isLocked) _buildSwitchTile("Published", isPublished),
                const SizedBox(height: 24),
                Text("Questions",
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _buildQuestionsList(),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchTile(String label, bool initialValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        Switch(
          value: initialValue,
          onChanged: (val) async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(val ? "Publish Test?" : "Unpublish Test?"),
                content: Text(val
                    ? "Are you sure you want to publish this test?"
                    : "Are you sure you want to unpublish this test?"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("Cancel")),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("Yes")),
                ],
              ),
            );

            if (confirm == true) {
              await FirebaseFirestore.instance
                  .collection('quizzes')
                  .doc(widget.testId)
                  .update({'isPublished': val});
              await FirebaseNotification.subscribeToQuizTopics(
                  widget.testId, true);
              // setState(() {});
            }
          },
        )
      ],
    );
  }

  Widget _buildQuestionsList() {
    if (_questions.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_questions.isEmpty) {
      return const Text("No questions available.");
    }

    return Column(
      children: List.generate(_questions.length, (index) {
        final data = _questions[index].data() as Map<String, dynamic>;
        final List options = data['options'] ?? [];
        final int correctIndex = data['correctOptionIndex'] ?? -1;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Q${index + 1}: ${data['questionText'] ?? ''}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 10),
              ...List.generate(options.length, (i) {
                final bool isCorrect = i == correctIndex;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    "${String.fromCharCode(65 + i)}. ${options[i]}",
                    style: TextStyle(
                      fontWeight:
                          isCorrect ? FontWeight.bold : FontWeight.normal,
                      color: isCorrect ? Colors.green.shade800 : null,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  String formatDateTime(dynamic value) {
    if (value is Timestamp) {
      return DateFormat.yMMMd().add_jm().format(value.toDate());
    }
    return value?.toString() ?? 'Unknown';
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
    String createdAt = '';
    if (quizData['createdAt'] != null) {
      DateTime dt = (quizData['createdAt'] as Timestamp).toDate();
      createdAt = DateFormat('dd MMM yyyy • hh:mm a').format(dt);
    }
    String testStart = '';
    if (quizData['testDateTime'] != null) {
      DateTime dt = (quizData['testDateTime'] as Timestamp).toDate();
      testStart = DateFormat('dd MMM yyyy • hh:mm a').format(dt);
    }

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
            Text('Created: $createdAt',
                style: const TextStyle(color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.schedule, size: 20, color: Colors.black87),
            const SizedBox(width: 6),
            Text('Starts: $testStart',
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
            StreamBuilder<QuerySnapshot>(
              stream: _enrolledStream,
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return GestureDetector(
                  onTap: () {
                    context.push(
                        "${AppRoutes.studentsAttandance}/${widget.testId}");
                  },
                  child: _infoBadge(Icons.group, "Enrolled: $count"),
                );
              },
            ),
            if (quizData['status'] == 'completed') ...[
              GestureDetector(
                onTap: () {
                  context.push("${AppRoutes.testLeaderborad}/${widget.testId}");
                },
                child: _infoBadge(Icons.leaderboard, "View Leaderborad"),
              )
            ]
          ],
        ),
      ],
    );
  }
}
