import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/teachers/students_provider.dart';
import '../../../constants/app_routes.dart';
import '../../../widgets/text_card.dart';

class StudentsListScreen extends StatelessWidget {
  final String searchQuery;
  final String coachingCode;

  const StudentsListScreen({
    Key? key,
    this.searchQuery = '',
    required this.coachingCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentsProvider>();

    // Trigger initial load if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.students.isEmpty && !provider.isLoading) {
        provider.loadStudents(coachingCode);
      }
    });

    if (provider.isLoading && provider.students.isEmpty) {
      return TestCardShimmer(count: 10,);
    }

    final filteredDocs = searchQuery.isEmpty
        ? provider.students
        : provider.students.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final fullName = (data['fullName'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final q = searchQuery.toLowerCase();
            return fullName.contains(q) || email.contains(q);
          }).toList();

    if (filteredDocs.isEmpty) {
      return const Center(child: Text("No matching students found."));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredDocs.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final doc = filteredDocs[index];
        final data = doc.data() as Map<String, dynamic>;

        String createdAtStr = "";
        final timestamp = data['createdAt'];
        if (timestamp is Timestamp) {
          createdAtStr = DateFormat.yMMMd().add_Hm().format(timestamp.toDate());
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TestCard(
            title: data['fullName'] ?? 'Untitled',
            subTitle: data['email'] ?? 'No email',
            bottomTitle: 'Joined on $createdAtStr',
            imagesUrl: data["profileImageUrl"] ??
                "https://mohdbinsufiyan.vercel.app/assets/media/mypic.jpg",
            onTap: () {
              context.push('${AppRoutes.studentDetails}/${doc.id}');
            },
          ),
        );
      },
    );
  }
}
