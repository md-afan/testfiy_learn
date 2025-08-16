import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/add_question_screen.dart';
import '../../utils/helpers.dart';

class EditTestScreen extends StatefulWidget {
  final String quizId;

  const EditTestScreen({super.key, required this.quizId});

  @override
  State<EditTestScreen> createState() => _EditTestScreenState();
}

class _EditTestScreenState extends State<EditTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _positiveScoreController = TextEditingController();
  final _negativeScoreController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? selectedFee;
  String? selectedDuration;
  String? selectedMCQ;
  bool _isLoading = false;

  final List<int> feeOptions = [15, 25, 50, 75, 100];
  final List<String> durationOptions = ['20', '30', '40', '50', '60'];
  final List<String> mcqOptions = [
    '10 (mcq)',
    '20 (mcq)',
    '30 (mcq)',
    '40 (mcq)',
    '50 (mcq)'
  ];

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    setState(() => _isLoading = true);
    final doc = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _titleController.text = data['title'] ?? '';
      selectedFee = (data['fee'] as num?)?.toInt();
      selectedDuration = data['duration'];
      selectedMCQ = '${data['totalQuestions']} (mcq)';
      _positiveScoreController.text =
          (data['positiveScore'] ?? 1).toString();
      _negativeScoreController.text =
          (data['negativeScore'] ?? 0).toString();
      _descriptionController.text = data['description'] ?? '';

      final dateTime = data['testDateTime'];
      if (dateTime is Timestamp) {
        DateTime dt = dateTime.toDate();
        TimeOfDay tod = TimeOfDay.fromDateTime(dt);

        _dateController.text = "${dt.day.toString().padLeft(2, '0')}-"
            "${dt.month.toString().padLeft(2, '0')}-"
            "${dt.year} ${tod.format(context)}";
      } else if (dateTime is String) {
        _dateController.text = dateTime;
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateQuiz() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        int totalQuestions =
            int.tryParse(selectedMCQ?.split(' ').first ?? '0') ?? 0;

        final parts = _dateController.text.split(' ');
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        final meridian = parts[2].toLowerCase();

        int hour = int.parse(timeParts[0]);
        if (meridian == 'pm' && hour < 12) hour += 12;
        if (meridian == 'am' && hour == 12) hour = 0;

        final dateTime = DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
          hour,
          int.parse(timeParts[1]),
        );

        await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(widget.quizId)
            .update({
          'title': _titleController.text.trim(),
          'fee': selectedFee,
          'duration': selectedDuration,
          'totalQuestions': totalQuestions,
          'testDateTime': Timestamp.fromDate(dateTime),
          'status': 'upcoming',
          'positiveScore':
              double.tryParse(_positiveScoreController.text.trim()) ?? 1.0,
          'negativeScore':
              double.tryParse(_negativeScoreController.text.trim()) ?? 0.0,
          'description': _descriptionController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Test updated successfully")),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  void _navigateToEditQuestions() {
    final totalQuestions =
        int.tryParse(selectedMCQ?.split(' ').first ?? '0') ?? 0;

    if (totalQuestions > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddQuestionsScreen(
            totalQuestions: totalQuestions,
            quizId: widget.quizId,
            isEditing: true,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select MCQs first")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(
        context,
        "Edit Test",
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: _isLoading && _titleController.text.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(_titleController, 'Test Title',
                                prefixIcon: const Icon(Icons.title)),
                            _buildDatePicker(),
                            _buildDropdown<int>(
                              'Fee (₹)',
                              selectedFee,
                              feeOptions,
                              (val) => setState(() => selectedFee = val),
                              prefixIcon: const Icon(Icons.attach_money),
                              displayLabel: (val) => '₹$val',
                            ),
                            _buildDropdown<String>(
                              'Duration (min)',
                              selectedDuration,
                              durationOptions,
                              (val) => setState(() => selectedDuration = val),
                              prefixIcon: const Icon(Icons.timer),
                            ),
                            _buildDropdown<String>(
                              'MCQ',
                              selectedMCQ,
                              mcqOptions,
                              (val) => setState(() => selectedMCQ = val),
                              prefixIcon: const Icon(Icons.help_outline),
                            ),
                            _buildNumberField(_positiveScoreController,
                                'Score for Correct Answer', Icons.add_circle),
                            _buildNumberField(_negativeScoreController,
                                'Score for Wrong Answer', Icons.remove_circle),
                            _buildDescriptionField(),
                            const SizedBox(height: 20),
                            if (_isLoading)
                              const Center(child: CircularProgressIndicator())
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: UiHelpers.customButton(
                                      context,
                                      "Update Test",
                                      _updateQuiz,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: UiHelpers.customButton(
                                      context,
                                      "Edit Questions",
                                      _navigateToEditQuestions,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {Widget? prefixIcon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildNumberField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: false),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          if (double.tryParse(value.trim()) == null) {
            return 'Enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: "Test Description",
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.description),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a description';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _dateController,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Test Date & Time',
          suffixIcon: Icon(Icons.calendar_today),
          prefixIcon: Icon(Icons.event),
          border: OutlineInputBorder(),
        ),
        onTap: () async {
          FocusScope.of(context).unfocus();

          DateTime? date = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
          );

          if (date != null) {
            TimeOfDay? time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );

            if (time != null) {
              final combined = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );

              final formatted = "${combined.day.toString().padLeft(2, '0')}-"
                  "${combined.month.toString().padLeft(2, '0')}-"
                  "${combined.year} ${time.format(context)}";

              _dateController.text = formatted;
            }
          }
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please select date and time';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown<T>(
    String hint,
    T? value,
    List<T> options,
    ValueChanged<T?> onChanged, {
    Widget? prefixIcon,
    String Function(T)? displayLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<T>(
        value: options.contains(value) ? value : null,
        items: options
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                      displayLabel != null ? displayLabel(e) : e.toString()),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: hint,
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon,
        ),
        validator: (val) => val == null ? 'Please select $hint' : null,
      ),
    );
  }
}
