import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../utils/helpers.dart';
import '../../../providers/students/profile_provider.dart';

class EditStudentProfileScreen extends StatefulWidget {
  final String uid;

  const EditStudentProfileScreen({super.key, required this.uid});

  @override
  State<EditStudentProfileScreen> createState() =>
      _EditStudentProfileScreenState();
}

class _EditStudentProfileScreenState extends State<EditStudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Initialize controllers immediately to avoid late-init errors on dispose
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController classController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  String selectedGender = '';
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final provider =
          Provider.of<StudentProfileProvider>(context, listen: false);
      await provider.fetchStudentProfile(widget.uid);
      _fillControllersFromProvider();
    });
  }

  void _fillControllersFromProvider() {
    final student =
        Provider.of<StudentProfileProvider>(context, listen: false).student;
    if (student != null) {
      nameController.text = student.fullName ?? '';
      phoneController.text = student.phone ?? '';
      dobController.text = student.dob ?? '';
      selectedGender = (student.gender ?? '').isNotEmpty
          ? student.gender!
          : ''; // keep empty so validator triggers
      aboutController.text = student.about ?? '';
      skillsController.text = student.skills ?? '';
      classController.text = student.studentClass ?? '';
      cityController.text = student.city ?? '';
      setState(() {});
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    dobController.dispose();
    aboutController.dispose();
    skillsController.dispose();
    classController.dispose();
    cityController.dispose();
    super.dispose();
  }

  bool _isValidPastDate(String input) {
    try {
      final parsed = DateFormat('yyyy-MM-dd').parseStrict(input);
      return parsed.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  DateTime _initialDobDate() {
    try {
      if (dobController.text.isNotEmpty) {
        return DateFormat('yyyy-MM-dd').parseStrict(dobController.text);
      }
    } catch (_) {}
    // default to ~18 years ago
    final now = DateTime.now();
    return DateTime(now.year - 18, 1, 1);
    // firstDate/lastDate will clamp as needed
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _initialDobDate(),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);
    final provider = Provider.of<StudentProfileProvider>(context, listen: false);

    final updatedStudent = provider.student!.copyWith(
      fullName: nameController.text.trim(),
      phone: phoneController.text.trim(),
      dob: dobController.text.trim(),
      gender: selectedGender.trim(),
      about: aboutController.text.trim(),
      skills: skillsController.text.trim(),
      studentClass: classController.text.trim(),
      city: cityController.text.trim(),
    );

    await provider.updateStudentProfile(updatedStudent, widget.uid);

    if (provider.error.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error)),
      );
    }
    if (mounted) setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentProfileProvider>(context);

    if (provider.isLoading || provider.student == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(
        context,
        "Edit Profile",
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: isSaving
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator())
                : const Icon(Icons.check),
            onPressed: isSaving ? null : _saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name (required)
              UiHelpers.customTextField(
                context,
                controller: nameController,
                hintText: "Name",
                prefixIcon: const Icon(Icons.person),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? "Name is required"
                        : null,
              ),
              const SizedBox(height: 12),

              // Phone (10 digits)
              UiHelpers.customTextField(
                context,
                controller: phoneController,
                hintText: "Phone",
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone),
                validator: (value) {
                  final v = (value ?? '').trim();
                  final reg = RegExp(r'^\d{10}$');
                  if (!reg.hasMatch(v)) return "Enter a valid 10-digit number";
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // DOB (picker + validation)
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: UiHelpers.customTextField(
                    context,
                    controller: dobController,
                    hintText: "Date of Birth (yyyy-MM-dd)",
                    prefixIcon: const Icon(Icons.calendar_today),
                    validator: (value) =>
                        (value == null || value.isEmpty)
                            ? "DOB is required"
                            : (_isValidPastDate(value)
                                ? null
                                : "Enter a valid past date (yyyy-MM-dd)"),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Gender (dropdown + required)
              DropdownButtonFormField<String>(
                value: selectedGender.isNotEmpty ? selectedGender : null,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() {
                  selectedGender = value ?? '';
                }),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  hintText: "Gender",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty)
                        ? "Select gender"
                        : null,
              ),
              const SizedBox(height: 12),

              // Class (optional -> still pass validator)
              UiHelpers.customTextField(
                context,
                controller: classController,
                hintText: "Class",
                prefixIcon: const Icon(Icons.class_),
                validator: (_) => null,
              ),
              const SizedBox(height: 12),

              // City (optional)
              UiHelpers.customTextField(
                context,
                controller: cityController,
                hintText: "City",
                prefixIcon: const Icon(Icons.location_city),
                validator: (_) => null,
              ),
              const SizedBox(height: 12),

              // Skills (optional)
              UiHelpers.customTextField(
                context,
                controller: skillsController,
                hintText: "Skills",
                prefixIcon: const Icon(Icons.star),
                validator: (_) => null,
              ),
              const SizedBox(height: 12),

              // About (optional)
              UiHelpers.customTextField(
                context,
                controller: aboutController,
                hintText: "About",
                prefixIcon: const Icon(Icons.info_outline),
                validator: (_) => null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
