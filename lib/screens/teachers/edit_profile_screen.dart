import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../utils/helpers.dart';
import '../../providers/teachers/teacher_profile_provider.dart';

class EditTeacherInfoScreen extends StatefulWidget {
  final String uid;

  const EditTeacherInfoScreen({
    super.key,
    required this.uid,
  });

  @override
  State<EditTeacherInfoScreen> createState() => _EditTeacherInfoScreenState();
}

class _EditTeacherInfoScreenState extends State<EditTeacherInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController dobController;
  late TextEditingController aboutController;
  late TextEditingController skillsController;

  String selectedGender = '';
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final teacher = context.read<TeacherProfileProvider>().teacher;

    nameController = TextEditingController(text: teacher?.fullName ?? '');
    phoneController = TextEditingController(text: teacher?.phone ?? '');
    dobController = TextEditingController(text: teacher?.dob ?? '');
    aboutController = TextEditingController(text: teacher?.about ?? '');
    skillsController = TextEditingController(text: teacher?.skills ?? '');
    selectedGender = teacher?.gender ?? '';
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    dobController.dispose();
    aboutController.dispose();
    skillsController.dispose();
    super.dispose();
  }

  Future<void> _pickDOB() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: dobController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(dobController.text)
          : DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isSaving = true);

      final updatedTeacher =
          context.read<TeacherProfileProvider>().teacher!.copyWith(
                fullName: nameController.text.trim(),
                phone: phoneController.text.trim(),
                dob: dobController.text.trim(),
                gender: selectedGender,
                about: aboutController.text.trim(),
                skills: skillsController.text.trim(),
              );

      try {
        await context
            .read<TeacherProfileProvider>()
            .updateTeacherProfile(updatedTeacher, widget.uid);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $e")),
        );
      } finally {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherProvider = context.watch<TeacherProfileProvider>();

    if (teacherProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (teacherProvider.teacher == null) {
      return const Scaffold(
        body: Center(child: Text("No teacher data found")),
      );
    }

    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(
        context,
        "Edit Profile Info",
        actions: [
          IconButton(
            icon: isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Icon(Icons.check),
            onPressed: isSaving ? null : _saveChanges,
          ),
        ],
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              UiHelpers.customTextField(
                context,
                controller: nameController,
                hintText: "Name",
                prefixIcon: const Icon(Icons.person),
                validator: (value) =>
                    value!.trim().isEmpty ? "Name is required" : null,
              ),
              const SizedBox(height: 16),
              UiHelpers.customTextField(
                context,
                controller: phoneController,
                hintText: "Phone",
                prefixIcon: const Icon(Icons.phone),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Phone is required";
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                    return "Enter a valid 10-digit phone number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDOB,
                child: AbsorbPointer(
                  child: UiHelpers.customTextField(
                    context,
                    controller: dobController,
                    hintText: "Date of Birth",
                    prefixIcon: const Icon(Icons.calendar_today),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "DOB is required";
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedGender.isNotEmpty ? selectedGender : null,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  labelText: "Gender",
                  border: OutlineInputBorder(),
                ),
                items: ['Male', 'Female', 'Other']
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedGender = value ?? '';
                  });
                },
                validator: (value) =>
                    value == null || value.isEmpty ? "Select gender" : null,
              ),
              const SizedBox(height: 16),
              UiHelpers.customTextField(
                context,
                controller: aboutController,
                hintText: "About",
                prefixIcon: const Icon(Icons.info_outline),
                validator: (value) => null,
              ),
              const SizedBox(height: 16),
              UiHelpers.customTextField(
                context,
                controller: skillsController,
                hintText: "Skills",
                prefixIcon: const Icon(Icons.star),
                validator: (value) => null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
