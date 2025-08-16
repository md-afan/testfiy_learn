import 'package:flutter/material.dart';
import '../../widgets/add_question_screen.dart';
import '../../utils/helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/secure_locally_storage.dart';

class CreateTestScreen extends StatefulWidget {
  const CreateTestScreen({super.key});

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _positiveScoreController = TextEditingController();
  final _negativeScoreController = TextEditingController();

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
    '50 (mcq)',
  ];

  Future<DateTime> _parseDateTime(String input) async {
    final parts = input.split(' ');
    final dateParts = parts[0].split('-');
    final timeParts = parts[1].split(':');
    final meridian = parts[2].toLowerCase();

    int hour = int.parse(timeParts[0]);
    if (meridian == 'pm' && hour < 12) hour += 12;
    if (meridian == 'am' && hour == 12) hour = 0;

    return DateTime(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
      hour,
      int.parse(timeParts[1]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(context, "Create Test"),
      body: SafeArea(
        child: SingleChildScrollView(
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
                      _buildTextField(
                        _titleController,
                        'Test Title',
                        prefixIcon: const Icon(Icons.title),
                      ),
                      _buildTextField(
                        _subjectController,
                        'Subject',
                        prefixIcon: const Icon(Icons.subject),
                      ),
                      _buildDatePicker(),
                      _buildFeeDropdown(),
                      _buildDropdown(
                        'Duration (min)',
                        selectedDuration,
                        durationOptions,
                        (val) => setState(() => selectedDuration = val),
                        prefixIcon: const Icon(Icons.timer),
                      ),
                      _buildDropdown(
                        'MCQ',
                        selectedMCQ,
                        mcqOptions,
                        (val) => setState(() => selectedMCQ = val),
                        prefixIcon: const Icon(Icons.help_outline),
                      ),
                      _buildNumberField(
                        _positiveScoreController,
                        "Score for Correct Answer",
                        Icons.add_circle,
                        isDouble: true,
                      ),
                      _buildNumberField(
                        _negativeScoreController,
                        "Score for Wrong Answer",
                        Icons.remove_circle,
                        isDouble: true,
                      ),
                      _buildDescriptionField(),
                      const SizedBox(height: 20),
                      Center(
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : UiHelpers.customButton(
                                context,
                                "Add Questions",
                                () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() => _isLoading = true);
                                    try {
                                      final totalQuestions = int.tryParse(
                                            selectedMCQ?.split(' ').first ??
                                                '0',
                                          ) ??
                                          0;
                                      final uid =
                                          await LocalStorage.getLocalStorage(
                                              "uid");
                                      final code =
                                          await LocalStorage.getLocalStorage(
                                              "coachingCode");
                                      final DateTime dateTime =
                                          await _parseDateTime(
                                              _dateController.text.trim());

                                      final quizRef = await FirebaseFirestore
                                          .instance
                                          .collection('quizzes')
                                          .add({
                                        'title': _titleController.text.trim(),
                                        'subject':
                                            _subjectController.text.trim(),
                                        'fee': selectedFee ?? 0,
                                        'duration': selectedDuration,
                                        'isPublished': false,
                                        'totalQuestions': totalQuestions,
                                        'testDateTime':
                                            Timestamp.fromDate(dateTime),
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                        'createdBy': uid,
                                        'coachingCode': code,
                                        'status': "upcoming",
                                        // ✅ new fields
                                        'positiveScore': double.tryParse(
                                                _positiveScoreController.text
                                                    .trim()) ??
                                            1.0,
                                        'negativeScore': double.tryParse(
                                                _negativeScoreController.text
                                                    .trim()) ??
                                            0.0,
                                        'description':
                                            _descriptionController.text.trim(),
                                      });

                                      setState(() => _isLoading = false);

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddQuestionsScreen(
                                            totalQuestions: totalQuestions,
                                            quizId: quizRef.id,
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      setState(() => _isLoading = false);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Failed to create test: $e")),
                                      );
                                    }
                                  }
                                },
                              ),
                      ),
                      const SizedBox(height: 30),
                      const Divider(),
                      const Text(
                        "Note:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Make sure all details are correct before proceeding. You will be redirected to add all questions immediately.",
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Warning: Once you start adding questions, you must complete the process. You cannot return to edit the test settings later.",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
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

  Widget _buildDropdown(
    String hint,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged, {
    Widget? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        items: options
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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

  Widget _buildFeeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<int>(
        value: selectedFee,
        items: feeOptions
            .map((fee) => DropdownMenuItem(
                  value: fee,
                  child: Text("₹$fee"),
                ))
            .toList(),
        onChanged: (val) => setState(() => selectedFee = val),
        decoration: const InputDecoration(
          labelText: "Fee (₹)",
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.attach_money),
        ),
        validator: (val) => val == null ? 'Please select Fee' : null,
      ),
    );
  }

  Widget _buildNumberField(
      TextEditingController controller, String label, IconData icon,
      {bool isDouble = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: isDouble),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          if (isDouble && double.tryParse(value) == null) {
            return 'Enter a valid number';
          }
          if (!isDouble && int.tryParse(value) == null) {
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
}
