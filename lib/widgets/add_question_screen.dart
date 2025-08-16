import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/helpers.dart';

class AddQuestionsScreen extends StatefulWidget {
  final int totalQuestions;
  final String quizId;
  final bool isEditing;

  const AddQuestionsScreen({
    super.key,
    required this.totalQuestions,
    required this.quizId,
    this.isEditing = false,
  });

  @override
  State<AddQuestionsScreen> createState() => _AddQuestionsScreenState();
}

class _AddQuestionsScreenState extends State<AddQuestionsScreen> {
  int currentIndex = 0;
  final questionController = TextEditingController();
  final List<TextEditingController> optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int selectedOption = 0;
  bool _isLoading = false;

  List<DocumentSnapshot> existingQuestions = [];
  bool questionsLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExistingQuestions();
    }
  }

  Future<void> _loadExistingQuestions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .collection('questions')
          .orderBy('questionText') // Optional: consistent order
          .get();

      existingQuestions = snapshot.docs;
      _fillControllersForIndex(0);

      setState(() {
        questionsLoaded = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading questions: $e')),
      );
    }
  }

  void _fillControllersForIndex(int index) {
    final question = existingQuestions[index].data() as Map<String, dynamic>;
    questionController.text = question['questionText'] ?? '';
    final options = question['options'] ?? List.filled(4, '');
    for (int i = 0; i < optionControllers.length; i++) {
      optionControllers[i].text = options[i] ?? '';
    }
    selectedOption = question['correctOptionIndex'] ?? 0;
  }

  Future<void> _nextQuestion() async {
    if (questionController.text.isEmpty ||
        optionControllers.any((c) => c.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final questionData = {
        'questionText': questionController.text.trim(),
        'options': optionControllers.map((e) => e.text.trim()).toList(),
        'correctOptionIndex': selectedOption,
      };

      if (widget.isEditing) {
        final docId = existingQuestions[currentIndex].id;
        await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(widget.quizId)
            .collection('questions')
            .doc(docId)
            .update(questionData);
      } else {
        await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(widget.quizId)
            .collection('questions')
            .add(questionData);
      }

      if (currentIndex + 1 == widget.totalQuestions) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Questions updated successfully!'
                : 'Test submitted and published!'),
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          currentIndex++;
          questionController.clear();
          for (var c in optionControllers) {
            c.clear();
          }
          selectedOption = 0;

          if (widget.isEditing) {
            _fillControllersForIndex(currentIndex);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving question: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    questionController.dispose();
    for (var c in optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing && !questionsLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(
        context,
        widget.isEditing ? 'Edit Questions' : 'Add Questions',
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Question ${currentIndex + 1} of ${widget.totalQuestions}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: (currentIndex + 1) / widget.totalQuestions,
                      minHeight: 6,
                      backgroundColor: Colors.grey[300],
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 16),

                    // Question input
                    SizedBox(
                      height: 80,
                      child: TextField(
                        controller: questionController,
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          labelText: 'Question Text',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Option fields with radio
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      itemBuilder: (_, i) {
                        return RadioListTile<int>(
                          title: TextField(
                            controller: optionControllers[i],
                            decoration: InputDecoration(
                              hintText: 'Option ${String.fromCharCode(65 + i)}',
                            ),
                          ),
                          value: i,
                          groupValue: selectedOption,
                          onChanged: (val) =>
                              setState(() => selectedOption = val!),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // Add/Submit Button or Loader
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: 300,
                            child: UiHelpers.customButton(
                              context,
                              currentIndex + 1 == widget.totalQuestions
                                  ? (widget.isEditing ? 'Update' : 'Submit')
                                  : (widget.isEditing ? 'Next' : 'Add Another'),
                              _nextQuestion,
                            ),
                          ),

                    const SizedBox(height: 20),
                    const Divider(),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '📌 Instructions:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '• Enter your question in the box above.\n'
                        '• Fill all 4 options and select the correct one.\n'
                        '• Click "Next" or "Add Another" to continue.\n'
                        '• After the last question, click "Submit" or "Update".',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
