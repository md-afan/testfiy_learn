import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/text_card.dart';
import '../../constants/app_routes.dart';
import '../../utils/helpers.dart';
import '../../providers/comman providers/enrolled_stundets_provider.dart';
import '../../widgets/global_shimmer_screen.dart';

class EnrolledStudentsScreen extends StatefulWidget {
  final String testId;
  const EnrolledStudentsScreen({super.key, required this.testId});

  @override
  State<EnrolledStudentsScreen> createState() => _EnrolledStudentsScreenState();
}

class _EnrolledStudentsScreenState extends State<EnrolledStudentsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final provider =
        Provider.of<EnrolledStudentsProvider>(context, listen: false);
    provider.init(widget.testId);

    _scrollController.addListener(() {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll - 200) {
        provider.fetchStudents();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnrolledStudentsProvider>(
      builder: (context, provider, _) {
        final uids = provider.studentUids;
        final studentCache = provider.studentCache;
        final enrolledAtMap = provider.enrolledAtMap;

        return Scaffold(
          appBar: UiHelpers.customAppBarForScreen(
            context,
            "Enrolled (${provider.totalStudents}) students",
            automaticallyImplyLeading: true,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await provider.fetchStudents(isRefresh: true);
            },
            child: provider.isLoading && uids.isEmpty
                ? TestCardShimmer(
                    count: 10,
                    hiddenBottomLable:true
                  )
                : uids.isEmpty
                    ? const Center(
                        child: Text("No students enrolled yet."),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: uids.length + (provider.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == uids.length) {
                            if (provider.hasMore && provider.isLoading) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          }

                          final uid = uids[index];
                          final student = studentCache[uid];

                          if (student == null) {
                            // fallback shimmer placeholder
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }

                          final name = student['fullName'] ?? 'Unnamed';
                          final imageUrl = student['profileImageUrl'] ??
                              "https://mohdbinsufiyan.vercel.app/assets/media/mypic.jpg";

                          String enrolledDate = "";
                          final enrolledTs = enrolledAtMap[uid];
                          if (enrolledTs != null) {
                            final dateTime = enrolledTs.toDate();
                            enrolledDate =
                                "${dateTime.day}-${dateTime.month}-${dateTime.year}";
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: TestCard(
                              title: name,
                              subTitle: enrolledDate.isNotEmpty
                                  ? 'Enrolled on $enrolledDate'
                                  : 'Enrollment date unknown',
                              imagesUrl: imageUrl,
                              onTap: () {
                                context
                                    .push('${AppRoutes.studentDetails}/$uid');
                              },
                            ),
                          );
                        },
                      ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
