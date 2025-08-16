import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../utils/secure_locally_storage.dart';
import '../../utils/helpers.dart';
import '../../constants/app_routes.dart';

class QuizAttendScreen extends StatefulWidget {
  final String quizId;
  const QuizAttendScreen({super.key, required this.quizId});

  @override
  State<QuizAttendScreen> createState() => _QuizAttendScreenState();
}

class _QuizAttendScreenState extends State<QuizAttendScreen> {
  List<Map<String, dynamic>> questions = [];
  Map<String, int> selectedAnswers = {};
  bool loading = true;
  int currentIndex = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool hasPlayedTenSecSound = false;
  bool hasPlayedOneMinSound = false;

  Timer? timer;
  Duration remainingTime = Duration.zero;
  late DateTime quizEndTime;
  int durationInMinutes = 0;
  bool isQuizDataLoading = true;
  bool _isSubmitted = false;

  String title = '';
  double positiveScore = 1.0;
  double negativeScore = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeQuizData();
  }

  Future<void> _initializeQuizData() async {
    final uid = await LocalStorage.getLocalStorage("uid");
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .get();

    if (!doc.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quiz not found")),
      );
      return;
    }

    final enrolledDoc = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .collection('enrolledStudents')
        .doc(uid)
        .get();

    if (!enrolledDoc.exists || (enrolledDoc.data()?['isPresent'] != true)) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Access Denied"),
          content:
              const Text("You are marked absent and cannot attempt this quiz."),
          actions: [
            TextButton(
              onPressed: () => context.go(AppRoutes.studentTest),
              child: const Text("Go Back"),
            ),
          ],
        ),
      );
      return;
    }

    final submissionDoc = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .collection('submissions')
        .doc(uid)
        .get();

    if (submissionDoc.exists) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Already Submitted"),
          content: const Text("You have already submitted this quiz."),
          actions: [
            TextButton(
              onPressed: () => context.go(AppRoutes.studentTest),
              child: const Text("Go Back"),
            ),
          ],
        ),
      );
      return;
    }

    final data = doc.data()!;
    title = data['title'] ?? 'Quiz';
    durationInMinutes = int.tryParse(data['duration'].toString()) ?? 0;
    positiveScore = (data['positiveScore'] is num)
        ? (data['positiveScore'] as num).toDouble()
        : 1.0;
    negativeScore = (data['negativeScore'] is num)
        ? (data['negativeScore'] as num).toDouble()
        : 0.0;

    DateTime startTime;
    final testDateTimeRaw = data['testDateTime'];
    if (testDateTimeRaw is Timestamp) {
      startTime = testDateTimeRaw.toDate();
    } else {
      startTime = DateTime.now();
    }

    quizEndTime = startTime.add(Duration(minutes: durationInMinutes));
    final now = DateTime.now();

    if (now.isBefore(startTime)) {
      final waitTime = startTime.difference(now);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Quiz will start in ${_formatTime(waitTime)}")),
      );
      setState(() => isQuizDataLoading = false);
      return;
    }

    remainingTime = quizEndTime.difference(now);
    _startTimer();
    await _loadQuestions();
    setState(() {
      isQuizDataLoading = false;
      loading = false;
    });
  }

  Future<void> _loadQuestions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .collection('questions')
        .get();

    questions =
        snapshot.docs.map((doc) => {"id": doc.id, ...doc.data()}).toList();
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      final now = DateTime.now();
      final diff = quizEndTime.difference(now);

      if (!mounted) return;
      setState(() {
        remainingTime = diff.inSeconds > 0 ? diff : Duration.zero;
      });

      if (diff.inSeconds == 30 && !hasPlayedOneMinSound) {
        hasPlayedOneMinSound = true;
        try {
          await _audioPlayer.play(AssetSource('sounds/timer.mp3'));
        } catch (_) {}
      }

      if (diff.inSeconds == 10 && !hasPlayedTenSecSound) {
        hasPlayedTenSecSound = true;
        try {
          await _audioPlayer.play(AssetSource('sounds/timer.mp3'));
        } catch (_) {}
      }

      if (diff.inSeconds <= 0) {
        t.cancel();
        _audioPlayer.dispose();
        _submitQuiz(auto: true);
      }
    });
  }

  Future<void> _submitQuiz({bool auto = false}) async {
    if (_isSubmitted) return;
    _isSubmitted = true;
    timer?.cancel();

    final uid = await LocalStorage.getLocalStorage("uid");
    if (uid == null) return;

    double score = 0;
    final Map<String, dynamic> answers = {};

    for (var q in questions) {
      final questionId = q["id"];
      final correctIndex = q["correctOptionIndex"] is int
          ? q["correctOptionIndex"]
          : int.tryParse(q["correctOptionIndex"].toString());

      final selectedIndex = selectedAnswers[questionId];

      if (selectedIndex == null) continue;

      answers[questionId] = selectedIndex;
      if (selectedIndex == correctIndex) {
        score += positiveScore;
      } else {
        score -= negativeScore;
      }
    }

    final timeTaken = durationInMinutes * 60 - remainingTime.inSeconds;

    await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .collection('submissions')
        .doc(uid)
        .set({
      "answers": answers,
      "score": score,
      "totalScore": questions.length * positiveScore,
      "timeTaken": timeTaken,
      "title": title,
      "duration": durationInMinutes,
      "submittedAt": FieldValue.serverTimestamp(),
      "studentId": uid,
    });

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(auto ? "Time's Up!" : "Quiz Submitted"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Score: $score / ${questions.length * positiveScore}"),
            Text("Time Taken: $timeTaken seconds"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.studentTest),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _confirmSubmission() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Submit Quiz?"),
        content: const Text("Are you sure you want to submit the quiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitQuiz();
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isQuizDataLoading || loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQ = questions[currentIndex];
    final options = List<String>.from(currentQ["options"] ?? []);

    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(
        context,
        title,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 18),
                const SizedBox(width: 4),
                Text(
                  _formatTime(remainingTime),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _confirmSubmission,
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (currentIndex + 1) / questions.length,
                  minHeight: 6,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Attempted: ${selectedAnswers.length} / ${questions.length}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "Q${currentIndex + 1} of ${questions.length}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currentQ['questionText'] ?? '',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                ...options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final opt = entry.value;
                  final isSelected = selectedAnswers[currentQ["id"]] == index;

                  return GestureDetector(
                    onTap: () =>
                        setState(() => selectedAnswers[currentQ["id"]] = index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.deepPurple.shade100
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? Colors.deepPurple
                              : Colors.grey.shade400,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected ? Colors.deepPurple : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              opt,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected
                                      ? Colors.deepPurple
                                      : Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (currentIndex > 0)
                      ElevatedButton(
                        onPressed: () => setState(() => currentIndex -= 1),
                        child: const Text("Previous"),
                      ),
                    if (currentIndex < questions.length - 1)
                      ElevatedButton(
                        onPressed: () => setState(() => currentIndex += 1),
                        child: const Text("Next"),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
