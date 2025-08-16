import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/teachers/students_provider.dart';
import '../../constants/app_routes.dart';
import '../../widgets/text_card.dart';
import '../../utils/helpers.dart';
import '../../utils/secure_locally_storage.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? coachingCode;

  @override
  void initState() {
    super.initState();
    _loadCoachingCode();

    _scrollController.addListener(() {
      final provider = context.read<StudentsProvider>();
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !provider.isLoading &&
          provider.hasMore &&
          coachingCode != null) {
        provider.loadMoreStudents(coachingCode!);
      }
    });
  }

  Future<void> _loadCoachingCode() async {
    final code = await LocalStorage.getLocalStorage("coachingCode");
    if (code != null) {
      setState(() {
        coachingCode = code.toString();
      });
      context.read<StudentsProvider>().loadStudents(coachingCode!);
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) _searchController.clear();
    });
  }

  Future<void> _onRefresh() async {
    if (coachingCode != null) {
      await context.read<StudentsProvider>().refresh(coachingCode!);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.withValues(alpha: 0.3),
            highlightColor: Colors.grey.withValues(alpha: 0.1),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentsProvider>();

    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(
        context,
        "Students",
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
        bottom: _isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: coachingCode == null
            ? _buildShimmerList()
            : provider.isLoading && provider.students.isEmpty
                ? _buildShimmerList()
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: Builder(builder: (context) {
                      final filteredDocs = _searchController.text.trim().isEmpty
                          ? provider.students
                          : provider.students.where((doc) {
                              final data =
                                  doc.data() as Map<String, dynamic>? ?? {};
                              final fullName = (data['fullName'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              final email = (data['email'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              final q = _searchController.text.toLowerCase();
                              return fullName.contains(q) || email.contains(q);
                            }).toList();

                      if (filteredDocs.isEmpty) {
                        return const Center(
                            child: Text("No matching students found."));
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 16),
                        itemCount:
                            filteredDocs.length + (provider.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == filteredDocs.length &&
                              provider.hasMore) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final doc = filteredDocs[index];
                          final data =
                              doc.data() as Map<String, dynamic>? ?? {};

                          String createdAtStr = "";
                          final timestamp = data['createdAt'];
                          if (timestamp is Timestamp) {
                            createdAtStr = DateFormat.yMMMd()
                                .add_Hm()
                                .format(timestamp.toDate());
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
                                context.push(
                                    '${AppRoutes.studentDetails}/${doc.id}');
                              },
                            ),
                          );
                        },
                      );
                    }),
                  ),
      ),
    );
  }
}
