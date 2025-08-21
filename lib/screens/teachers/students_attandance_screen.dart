import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../utils/helpers.dart';
import '../../widgets/state_box.dart';

class Student {
  final String uid;
  final String name;
  final String email;
  final String profileImageUrl;
  bool isPresent;

  Student({
    required this.uid,
    required this.name,
    required this.email,
    required this.profileImageUrl,
    this.isPresent = false,
  });
}

class StudentsAttandanceScreen extends StatefulWidget {
  final String quizId;
  const StudentsAttandanceScreen({super.key, required this.quizId});

  @override
  State<StudentsAttandanceScreen> createState() =>
      _StudentsAttandanceScreenState();
}

class _StudentsAttandanceScreenState extends State<StudentsAttandanceScreen> {
  List<Student> students = [];
  bool isLoading = true;

  String quizTitle = '';
  DateTime? testStartTime;
  Duration timeLeft = Duration.zero;
  Timer? countdownTimer;

  int get presentCount => students.where((s) => s.isPresent).length;
  int get absentCount => students.length - presentCount;

  @override
  void initState() {
    super.initState();
    _fetchQuizInfo();
    _fetchEnrolledStudents();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchQuizInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        quizTitle = data['title'] ?? '';

        final startTimestamp = data['testDateTime'];
        if (startTimestamp != null && startTimestamp is Timestamp) {
          testStartTime = startTimestamp.toDate();
          _startCountdown();
        }

        setState(() {});
      }
    } catch (e) {
      print('❌ Error fetching quiz info: $e');
    }
  }

  void _startCountdown() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (testStartTime == null) return;

      final now = DateTime.now();
      final diff = testStartTime!.difference(now);

      setState(() {
        timeLeft = diff.isNegative ? Duration.zero : diff;
      });

      if (diff.isNegative) countdownTimer?.cancel();
    });
  }

  bool get _showCountdown =>
      testStartTime != null && timeLeft.inDays < 1 && timeLeft > Duration.zero;

  Future<void> _fetchEnrolledStudents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .collection('enrolledStudents')
          .get();

      List<Student> fetchedStudents = [];

      for (var doc in snapshot.docs) {
        final uid = doc.id;
        final isPresent = doc.data()['isPresent'] ?? false;

        final studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(uid)
            .get();

        if (studentDoc.exists) {
          final data = studentDoc.data()!;
          fetchedStudents.add(Student(
            uid: uid,
            name: data['fullName'] ?? '',
            email: data['email'] ?? '',
            profileImageUrl: data['profileImageUrl'] ?? '',
            isPresent: isPresent,
          ));
        }
      }

      setState(() {
        students = fetchedStudents;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching students: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateAttendance(String uid, bool isPresent) async {
    try {
      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .collection('enrolledStudents')
          .doc(uid)
          .update({'isPresent': isPresent});
    } catch (e) {
      print('❌ Failed to update attendance for $uid: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiHelpers.customAppBarForScreen(
        context,
        "Attendance",
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          isLoading ? _headerShimmer() : _headerSection(),
          _tableHeader(),
          Expanded(child: _studentList()),
        ],
      ),
    );
  }

  Widget _headerSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quizTitle.isNotEmpty ? quizTitle : "Loading test title...",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatBox(
                count: presentCount.toString(),
                label: "Present",
                color: Colors.green,
                icon: Icons.check_circle,
              ),
              StatBox(
                count: absentCount.toString(),
                label: "Absent",
                color: Colors.red,
                icon: Icons.cancel,
              ),
              StatBox(
                count: testStartTime == null
                    ? "--"
                    : _showCountdown
                        ? _formatDuration(timeLeft)
                        : DateFormat('dd MMM yyyy').format(testStartTime!),
                label: _showCountdown ? "to start" : "Scheduled",
                color: Colors.blue.shade300,
                icon: Icons.timer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 16, width: 180, color: Colors.white),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                3,
                (index) => Container(
                  height: 60,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        children: const [
          SizedBox(width: 8),
          Expanded(
              flex: 1,
              child:
                  Text("S.No", style: TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
              flex: 3,
              child:
                  Text("Name", style: TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
              flex: 2,
              child: Text("Status",
                  style: TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _studentList() {
    if (isLoading) {
      return ListView.separated(
        itemCount: 6,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              title: Container(height: 14, width: 120, color: Colors.white),
              subtitle: Container(height: 12, width: 80, color: Colors.white),
              trailing: Container(
                height: 20,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => isLoading = true);
        await _fetchEnrolledStudents();
      },
      child: students.isEmpty
          ? const Center(child: Text("No enrolled students found."))
          : ListView.separated(
              itemCount: students.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final s = students[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.deepPurple,
                      backgroundImage: s.profileImageUrl.isNotEmpty
                          ? NetworkImage(s.profileImageUrl)
                          : null,
                      child: s.profileImageUrl.isEmpty
                          ? Text(
                              (index + 1).toString().padLeft(2, '0'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    title: Text(s.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle:
                        Text(s.email, style: TextStyle(color: Colors.grey)),
                    trailing: Switch(
                      value: s.isPresent,
                      onChanged: (val) {
                        setState(() => s.isPresent = val);
                        _updateAttendance(s.uid, val);
                      },
                      activeColor: Colors.deepPurple,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
