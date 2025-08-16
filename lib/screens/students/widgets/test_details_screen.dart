import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/helpers.dart';

class StudentTestDetailsScreen extends StatelessWidget {
  final String testId;

  const StudentTestDetailsScreen({super.key, required this.testId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(context, 'Test Details',
          automaticallyImplyLeading: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quizzes')
            .doc(testId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Test not found."));
          }

          final testData = snapshot.data!.data() as Map<String, dynamic>;

          final String title = testData['title'] ?? 'N/A';
          final String date = testData['date'] ?? 'N/A';
          final int duration = testData['duration'] ?? 0;
          final int fee = testData['fee'] ?? 0;
          final String status = testData['status'] ?? '';
          final bool isPaid = testData['isPaid'] ?? false;

          // Widget getStatusWidget() {
          //   if (status == "completed" && isPaid) {
          //     return LeaderboardSection(testId: testId, testData: testData);
          //   } else if (status == "live") {
          //     return LiveTestSection(testId: testId);
          //   } else if (status == "upcoming" && isPaid) {
          //     return UpcomingPaidSection(testId: testId);
          //   } else {
          //     return const Text("No available action", style: TextStyle(color: Colors.red));
          //   }
          // }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text("📘 Title: $title",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("📅 Date: $date"),
                Text("⏱ Duration: $duration mins"),
                Text("💰 Fee: ₹$fee"),
                Text("📌 Status: $status"),
                const Divider(height: 30),
                // getStatusWidget(),
              ],
            ),
          );
        },
      ),
    );
  }
}
