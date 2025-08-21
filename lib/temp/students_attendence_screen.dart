import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../utils/helpers.dart';
import '../../widgets/state_box.dart';
import '../../providers/comman providers/enrolled_stundets_provider.dart';
import '../../widgets/text_card.dart';
import '../../widgets/global_shimmer_screen.dart';

class StudentsAttandanceScreen extends StatefulWidget {
  final String quizId;
  const StudentsAttandanceScreen({super.key, required this.quizId});

  @override
  State<StudentsAttandanceScreen> createState() =>
      _StudentsAttandanceScreenState();
}

class _StudentsAttandanceScreenState extends State<StudentsAttandanceScreen> {
  String quizTitle = '';
  DateTime? testStartTime;
  Duration timeLeft = Duration.zero;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    _fetchQuizInfo();
    Future.microtask(() =>
        Provider.of<EnrolledStudentsProvider>(context, listen: false)
            .init(widget.quizId));
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnrolledStudentsProvider>(
      builder: (context, provider, _) {
        final presentCount = provider.studentUids.where((uid) {
          final data = provider.studentCache[uid];
          return data?['isPresent'] == true;
        }).length;

        final absentCount = provider.studentUids.length - presentCount;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              provider.isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: GlobalShimmerScreen(
                          isLoading: provider.isLoading,
                          child: Container(
                            width: double.infinity,
                            height: 40,
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(4)),
                          )),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        quizTitle.isNotEmpty ? quizTitle : " ",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ),
              const SizedBox(height: 12),
              provider.isLoading
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 20),
                      child: StatBoxShimmer(
                        count: 3,
                      ),
                    )
                  : _headerSection(presentCount, absentCount),
              _tableHeader(),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent - 200) {
                      provider.fetchStudents();
                    }
                    return false;
                  },
                  child: provider.isLoading && provider.studentUids.isEmpty
                      ? TestCardShimmer(count: 10)
                      : RefreshIndicator(
                          onRefresh: () async {
                            await provider.fetchStudents(isRefresh: true);
                          },
                          child: provider.studentUids.isEmpty
                              ? const Center(
                                  child: Text("No enrolled students found."))
                              : ListView.separated(
                                  itemCount: provider.studentUids.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final uid = provider.studentUids[index];
                                    final data = provider.studentCache[uid];
                                    if (data == null) {
                                      return const ListTile(
                                          title: Text("Loading..."));
                                    }
                                    return ListTile(
                                      leading: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: Colors.deepPurple,
                                        backgroundImage:
                                            (data['profileImageUrl'] ?? '')
                                                    .isNotEmpty
                                                ? NetworkImage(
                                                    data['profileImageUrl'])
                                                : null,
                                        child: (data['profileImageUrl'] ?? '')
                                                .isEmpty
                                            ? Text(
                                                (index + 1)
                                                    .toString()
                                                    .padLeft(2, '0'),
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )
                                            : null,
                                      ),
                                      title: Text(data['fullName'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      subtitle: Text(data['email'] ?? '',
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                      trailing: Switch(
                                        value: data['isPresent'] == true,
                                        onChanged: (val) async {
                                          await FirebaseFirestore.instance
                                              .collection('quizzes')
                                              .doc(widget.quizId)
                                              .collection('enrolledStudents')
                                              .doc(uid)
                                              .update({'isPresent': val});
                                          provider.studentCache[uid]![
                                              'isPresent'] = val;
                                          provider.notifyListeners();
                                        },
                                        activeColor: Colors.deepPurple,
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _headerSection(int presentCount, int absentCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
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
}
