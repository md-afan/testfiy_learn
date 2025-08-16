import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../constants/app_routes.dart';
import '../../../widgets/text_card.dart';
import '../../../providers/alll_activity_provider.dart';

class AllActivityList extends StatefulWidget {
  final String uid;
  final String coachingCode;

  const AllActivityList({
    super.key,
    required this.uid,
    required this.coachingCode,
  });

  @override
  State<AllActivityList> createState() => _AllActivityListState();
}

class _AllActivityListState extends State<AllActivityList> {
  @override
  void initState() {
    super.initState();
    // ✅ Call loadActivities once after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AllActivityProvider>(context, listen: false)
          .loadActivities(widget.uid, widget.coachingCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AllActivityProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text('Error: ${provider.error}'));
        }

        final allData = provider.allData;
        if (allData.isEmpty) {
          return const Center(child: Text('No activity found.'));
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allData.length,
          separatorBuilder: (_, __) => const SizedBox(height: 0),
          itemBuilder: (context, index) {
            final item = allData[index];
            final data = item['data'] as Map<String, dynamic>;

            // ✅ Safe createdAt
            final dynamic createdAtRaw = item['createdAt'];
            String createdAtStr = '';
            if (createdAtRaw is Timestamp) {
              createdAtStr =
                  DateFormat.yMMMd().add_Hm().format(createdAtRaw.toDate());
            } else if (createdAtRaw is int) {
              createdAtStr = DateFormat.yMMMd().add_Hm().format(
                    DateTime.fromMillisecondsSinceEpoch(createdAtRaw),
                  );
            }

            if (item['type'] == 'quiz') {
              // ✅ Safe testDateTime
              String formattedTestDate = "N/A";
              final dynamic testTime = data['testDateTime'];
              if (testTime is Timestamp) {
                formattedTestDate =
                    DateFormat("dd MMM, hh:mm a").format(testTime.toDate());
              } else if (testTime is int) {
                formattedTestDate = DateFormat("dd MMM, hh:mm a").format(
                  DateTime.fromMillisecondsSinceEpoch(testTime),
                );
              }

              return TestCard(
                title: data['title'] ?? 'Untitled Test',
                subTitle: "Test Date: $formattedTestDate",
                bottomTitle: "Created on $createdAtStr",
                icon: Icons.assignment,
                onTap: () {
                  context.push('${AppRoutes.testDetails}/${item['id']}');
                },
              );
            } else {
              return TestCard(
                title: data['fullName'] ?? 'Unnamed Student',
                subTitle: data['email'] ?? 'No email',
                bottomTitle: 'Joined on $createdAtStr',
                imagesUrl: data["profileImageUrl"] ??
                    "https://mohdbinsufiyan.vercel.app/assets/media/mypic.jpg",
                onTap: () {
                  context.push('${AppRoutes.studentDetails}/${item['id']}');
                },
              );
            }
          },
        );
      },
    );
  }
}
