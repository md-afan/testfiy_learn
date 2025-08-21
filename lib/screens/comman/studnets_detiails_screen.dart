import 'dart:async'; // Added missing import
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../widgets/sliver_profile_appbar.dart';

class StudentDetailsScreen extends StatefulWidget {
  final String studentId;

  const StudentDetailsScreen({super.key, required this.studentId});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  Map<String, dynamic>? studentData;
  List<Map<String, dynamic>> quizSubmissions = [];
  bool isLoading = true;
  String? errorMsg;

  // Coaching filter state
  List<String> coachingCodes = [];
  String? selectedCoachingCode;
  Map<String, int> coachingStudentsCount = {};
  bool isLoadingCoachingData = false;
  String? coachingErrorMsg;
  StreamSubscription? _coachingSubscription;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _coachingSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    try {
      // Fetch student data
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .get();

      if (!studentDoc.exists) {
        setState(() {
          errorMsg = "Student not found.";
          isLoading = false;
        });
        return;
      }

      // Get student data
      final student = studentDoc.data()!;
      setState(() {
        studentData = student;
      });

      // Get coaching codes from student data
      final List<String> studentCoachingCodes =
          (student['coachingCodes'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();

      // Fetch quiz submissions
      final submissionSnaps = await FirebaseFirestore.instance
          .collectionGroup('submissions')
          .where("studentId", isEqualTo: widget.studentId)
          .get();

      final List<Map<String, dynamic>> submissionData = [];

      for (var doc in submissionSnaps.docs) {
        final data = doc.data();
        final quizRef = doc.reference.parent.parent;

        if (quizRef != null) {
          final quizSnap = await quizRef.get();
          data['title'] = quizSnap['title'] ?? 'Untitled';
        } else {
          data['title'] = 'Unknown Quiz';
        }

        submissionData.add(data);
      }

      // Load coaching data with realtime updates
      await _loadCoachingData(studentCoachingCodes);

      setState(() {
        quizSubmissions = submissionData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = "Failed to load data: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  Future<void> _loadCoachingData(List<String> studentCoachingCodes) async {
    if (studentCoachingCodes.isEmpty) {
      setState(() {
        coachingCodes = [];
        coachingStudentsCount = {};
        selectedCoachingCode = null;
        isLoadingCoachingData = false;
      });
      return;
    }

    setState(() {
      isLoadingCoachingData = true;
      coachingErrorMsg = null;
    });

    try {
      // Cancel any existing subscription
      _coachingSubscription?.cancel();

      // Setup realtime listeners for each coaching
      for (final code in studentCoachingCodes) {
        _setupCoachingListener(code);
      }

      setState(() {
        coachingCodes = studentCoachingCodes;
        selectedCoachingCode =
            studentCoachingCodes.isNotEmpty ? studentCoachingCodes.first : null;
        isLoadingCoachingData = false;
      });
    } catch (e) {
      setState(() {
        coachingErrorMsg = "Failed to load coachings: ${e.toString()}";
        isLoadingCoachingData = false;
      });
    }
  }

  void _setupCoachingListener(String coachingCode) {
    _coachingSubscription = FirebaseFirestore.instance
        .collection('coachings')
        .doc(coachingCode)
        .collection('students')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        coachingStudentsCount[coachingCode] = snapshot.docs.length;
      });
    }, onError: (e) {
      debugPrint("Error listening to coaching $coachingCode: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final profileUrl = (studentData?['profileImageUrl'] ?? '').toString();

    return Scaffold(
      // appBar: UiHelpers.customAppBarForScreen(
      //   context,
      //   "Student Details",
      //   automaticallyImplyLeading: true,
      // ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
              ? Center(
                  child: Text(
                    errorMsg!,
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: CustomScrollView(
                    slivers: [
                      SliverProfileAppBar(
                        showBackButton: true,
                        expandedHeight: 240,
                        title: "Profile",
                        name: studentData!['fullName'] ?? "Students",
                        email: studentData!['email'] ?? '',
                        coverImageUrl:
                            'https://mohdbinsufiyan.vercel.app/assets/media/mypic.jpg',
                        profileImageUrl:
                            'https://mohdbinsufiyan.vercel.app/assets/media/mypic.jpg',
                      ),

                      // Profile Header

                      // Content Section
                      SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Coaching Filter Section
                            _buildCoachingFilterSection(theme),
                            const SizedBox(height: 24),

                            // Stats Cards
                            _buildStatsSection(theme),
                            const SizedBox(height: 24),

                            // Student Information
                            _buildInfoSection(theme),
                            const SizedBox(height: 24),

                            // Quiz Submissions
                            _buildSubmissionsSection(theme),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCoachingFilterSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "COACHING INFORMATION",
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
          ),
          child: Column(
            children: [
              if (coachingErrorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    coachingErrorMsg!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ),
              Row(
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Coaching Code:",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (isLoadingCoachingData)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (coachingCodes.isEmpty)
                    Text(
                      "No coachings found",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButton<String>(
                        value: selectedCoachingCode,
                        underline: const SizedBox(),
                        style: theme.textTheme.bodyLarge,
                        dropdownColor: theme.colorScheme.surface,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.onSurface,
                        ),
                        items: coachingCodes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedCoachingCode = newValue;
                          });
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (selectedCoachingCode != null && !isLoadingCoachingData)
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Students in coaching:",
                      style: theme.textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                      ),
                      child: Text(
                        "${coachingStudentsCount[selectedCoachingCode] ?? 0}",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PERFORMANCE OVERVIEW",
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.quiz_outlined,
                label: "Quizzes Completed",
                value: quizSubmissions.length.toString(),
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: Icons.star_outline,
                label: "Total Rewards",
                value: _calculateTotalReward().toString(),
                color: colors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "STUDENT INFORMATION",
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
          ),
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.person_outline,
                title: "Full Name",
                value: studentData!['fullName'] ?? '',
              ),
              const Divider(height: 0),
              _InfoTile(
                icon: Icons.email_outlined,
                title: "Email",
                value: studentData!['email'] ?? '',
              ),
              const Divider(height: 0),
              _InfoTile(
                icon: Icons.calendar_month_outlined,
                title: "Joined Date",
                value: DateFormat.yMMMd().add_Hm().format(
                      (studentData!['createdAt'] as Timestamp).toDate(),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "QUIZ SUBMISSIONS",
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
              ),
              child: Text(
                "${quizSubmissions.length} results",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (quizSubmissions.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 56,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  "No quiz submissions yet",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ...quizSubmissions.map((quiz) {
            final date = quiz['submittedAt'] is Timestamp
                ? (quiz['submittedAt'] as Timestamp).toDate()
                : DateTime.now();

            return _QuizCard(
              title: quiz['title'] ?? 'Untitled',
              date: date,
              score: quiz['score'] ?? 0,
              total: quiz['total'] ?? 0,
            );
          }).toList(),
      ],
    );
  }

  int _calculateTotalReward() {
    int total = 0;
    for (var q in quizSubmissions) {
      final reward = q['reward'];
      if (reward is int) {
        total += reward;
      } else if (reward is num) {
        total += reward.toInt();
      }
    }
    return total;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final String title;
  final DateTime date;
  final int score;
  final int total;

  const _QuizCard({
    required this.title,
    required this.date,
    required this.score,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = total > 0 ? (score / total * 100).round() : 0;
    final color = percentage >= 80
        ? Colors.green
        : percentage >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$score/$total",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat.yMMMMd().add_jm().format(date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: total > 0 ? score / total : 0,
              backgroundColor: theme.colorScheme.surfaceVariant,
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Score",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  "$percentage%",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
