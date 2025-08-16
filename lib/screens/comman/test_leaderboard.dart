import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/leaaderboard_listtile.dart';
import '../../widgets/top_rank_card.dart';

class TestLeaderboardScreen extends StatefulWidget {
  final String testId;
  final Map<String, dynamic> testData;

  const TestLeaderboardScreen({
    super.key,
    required this.testId,
    required this.testData,
  });

  @override
  State<TestLeaderboardScreen> createState() => _TestLeaderboardScreenState();
}

class _TestLeaderboardScreenState extends State<TestLeaderboardScreen> {
  late String testName;
  List<Map<String, dynamic>> leaderboardData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    testName = widget.testData['testName'] ?? 'Test';
    fetchLeaderboard();
  }

  String formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> fetchLeaderboard() async {
    final leaderboardRef = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.testId)
        .collection('leaderboard');

    final snapshot = await leaderboardRef.orderBy('rank').get();

    if (snapshot.docs.isEmpty) {
      setState(() {
        isLoading = false;
        leaderboardData = [];
      });
      return;
    }

    List<Map<String, dynamic>> tempList = [];

    for (final doc in snapshot.docs) {
      final d = doc.data();
      final int seconds = d['timeTaken'] is String
          ? int.tryParse(d['timeTaken']) ?? 0
          : (d['timeTaken'] ?? 0);

      String? name ;
      String? avatarUrl;

      try {
        final studentSnap = await FirebaseFirestore.instance
            .collection('students')
            .doc(doc.id)
            .get();

        if (studentSnap.exists) {
          final s = studentSnap.data() ?? {};

          name = s['fullName'] ?? "Anonymous";

          avatarUrl = s['profileImageUrl'] ??
              "https://mohdbinsufiyan.vercel.app/assets/media/mypic.jpg";
          ;
        }
      } catch (e) {
        debugPrint("⚠️ Error fetching student details for ${doc.id}: $e");
      }

      tempList.add({
        'uid': doc.id,
        'name': name,
        'avatarUrl': avatarUrl,
        'score': d['score'] ?? 0,
        'timeTaken': seconds,
        'time': formatSeconds(seconds),
        'rank': d['rank'] ?? 0,
        'reward': d['reward'] ?? 0,
      });
    }

    setState(() {
      leaderboardData = tempList;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topThree = leaderboardData.take(3).toList();
    final others = leaderboardData.length > 3
        ? leaderboardData.sublist(3)
        : <Map<String, dynamic>>[];

    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : leaderboardData.isEmpty
                ? const Center(
                    child: Text(
                      "Leaderboard is preparing,\nPlease wait a few minutes...",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : Column(
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              testName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: topThree
                              .map((user) => TopRankCard(
                                    user: {
                                      ...user,
                                      // ✅ Pass avatar via CachedNetworkImage in your widget
                                      'avatarWidget': CachedNetworkImage(
                                        imageUrl: user['avatarUrl'],
                                        placeholder: (c, u) =>
                                            const CircularProgressIndicator(),
                                        errorWidget: (c, u, e) =>
                                            const Icon(Icons.error),
                                      ),
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 700),
                              child: others.isEmpty
                                  ? const Center(
                                      child: Text("No data available"),
                                    )
                                  : ListView.builder(
                                      itemCount: others.length,
                                      itemBuilder: (ctx, i) {
                                        final user = others[i];
                                        return LeaderboardListTile(
                                          user: {
                                            ...user,
                                            // ✅ Provide avatarUrl directly, use CachedNetworkImage inside tile
                                            'avatarUrl': user['avatarUrl'],
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
