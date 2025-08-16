import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/helpers.dart';


class ReviewQuestionsScreen extends StatefulWidget {
  final String quizId;
  final String studentId;
  final String title;

  const ReviewQuestionsScreen(
      {super.key,
      required this.quizId,
      required this.studentId,
      required this.title});

  @override
  State<ReviewQuestionsScreen> createState() => _ReviewQuestionsScreenState();
}

class _ReviewQuestionsScreenState extends State<ReviewQuestionsScreen> {
  final int _pageSize = 5;
  final List<Map<String, dynamic>> _questions = [];
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;

  Map<String, dynamic> _submittedAnswers = {};
  Map<String, dynamic> _submissionMeta = {};

  @override
  void initState() {
    super.initState();
    _fetchSubmittedAnswers();
    _fetchQuestions();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !_isLoading &&
          _hasMore) {
        _fetchQuestions();
      }
    });
  }

  Future<void> _fetchSubmittedAnswers() async {
    final doc = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .collection('submissions')
        .doc(widget.studentId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _submittedAnswers = Map<String, dynamic>.from(data['answers'] ?? {});
        _submissionMeta = {
          'score': data['score'],
          'timeTaken': data['timeTaken'],
          'duration': data['duration'],
          'submittedAt': data['submittedAt'],
        };
      });
    }
  }

  Future<void> _fetchQuestions() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .collection('questions')
        .limit(_pageSize);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _lastDocument = snapshot.docs.last;
        _questions.addAll(snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }));
      });
    } else {
      setState(() => _hasMore = false);
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(context, widget.title,
          automaticallyImplyLeading: true),
      body: Column(
        children: [
          if (_submissionMeta.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Score: ${_submissionMeta['score']}",
                      style: theme.textTheme.titleMedium),
                  Text("Time Taken: ${_submissionMeta['timeTaken']} seconds"),
                  Text("Allowed Duration: ${_submissionMeta['duration']} mins"),
                  Text("Submitted At: ${DateFormat.yMMMMd().add_jm().format(
                        (_submissionMeta['submittedAt'] as Timestamp).toDate(),
                      )}"),
                  const Divider(),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _questions.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _questions.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final question = _questions[index];
                final questionId = question['id'];
                final selectedAnswer = _submittedAnswers[questionId];
                final options = List<String>.from(question['options'] ?? []);
                final correctIndex = question['correctOptionIndex'];
                final explanation = question['explanation'] ?? '';

                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Q${index + 1}: ${question['questionText']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...options.asMap().entries.map((entry) {
                        final optIndex = entry.key;
                        final optText = entry.value;
                        final isSelected = selectedAnswer == optIndex;
                        final isCorrect = correctIndex == optIndex;

                        IconData icon;
                        Color iconColor;
                        Color? bgColor;

                        if (isSelected && isCorrect) {
                          icon = Icons.check_circle;
                          iconColor = Colors.green;
                          bgColor = Colors.green.shade50;
                        } else if (isSelected && !isCorrect) {
                          icon = Icons.cancel;
                          iconColor = Colors.red;
                          bgColor = Colors.red.shade50;
                        } else if (!isSelected && isCorrect) {
                          icon = Icons.check_circle_outline;
                          iconColor = Colors.green;
                          bgColor = Colors.green.shade100;
                        } else {
                          icon = Icons.radio_button_unchecked;
                          iconColor = Colors.grey;
                          bgColor = null;
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Icon(icon, color: iconColor),
                              const SizedBox(width: 10),
                              Expanded(child: Text(optText)),
                            ],
                          ),
                        );
                      }),
                      if (explanation.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          "Explanation:",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          explanation,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
