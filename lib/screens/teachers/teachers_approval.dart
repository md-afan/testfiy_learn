import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../utils/helpers.dart';

class TeacherApprovalScreen extends StatefulWidget {
  const TeacherApprovalScreen({super.key});

  @override
  State<TeacherApprovalScreen> createState() => _TeacherApprovalScreenState();
}

class _TeacherApprovalScreenState extends State<TeacherApprovalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(
        context,
        'Pending Teacher Approvals',
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teachers')
            .where('isApproved', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No pending teachers',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final teachers = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: teachers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              final data = teacher.data() as Map<String, dynamic>;
              final coachingCodes = (data['coachingCodes'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: data['teacherImageUrl'] != null
                              ? NetworkImage(data['teacherImageUrl'])
                              : null,
                          child: data['teacherImageUrl'] == null
                              ? const Icon(Icons.person, size: 28)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['fullName'] ?? 'Unnamed Teacher',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                data['email'] ?? 'No email',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green),
                          onPressed: () => _confirmApproval(
                              context, teacher.id, coachingCodes),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.info_outline),
                          label: const Text("See Details"),
                          onPressed: () => _showTeacherDetails(data),
                        ),
                        const SizedBox(width: 8),
                        if (coachingCodes.isNotEmpty)
                          TextButton.icon(
                            icon: const Icon(Icons.school_outlined),
                            label: Text(
                                '${coachingCodes.length} coaching${coachingCodes.length == 1 ? '' : 's'}'),
                            onPressed: () =>
                                _showCoachingCodes(context, coachingCodes),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmApproval(
      BuildContext context, String teacherId, List<String> codes) {
    final count = codes.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Approve Teacher"),
        content: Text(
          "Are you sure you want to approve this teacher?\n\n"
          "They are enrolled in $count coaching${count == 1 ? '' : 's'}.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text("Approve"),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await FirebaseFirestore.instance
                  .collection('teachers')
                  .doc(teacherId)
                  .update({'isApproved': true});

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ Teacher approved and enrolled in $count coaching${count == 1 ? '' : 's'}.',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCoachingCodes(BuildContext context, List<String> coachingCodes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                'Coaching Codes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                itemCount: coachingCodes.length,
                itemBuilder: (context, index) {
                  final code = coachingCodes[index];
                  return ListTile(
                    leading: const Icon(Icons.chevron_right),
                    title: Text(code),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/coaching-details/$code');
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTeacherDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Teacher Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow("Full Name", data['fullName']),
              _detailRow("Email", data['email']),
              _detailRow("Phone", data['phone']),
              _detailRow("Created At", data['createdAt']?.toDate().toString()),
              _detailRow("UID", data['uid']),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ",
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
