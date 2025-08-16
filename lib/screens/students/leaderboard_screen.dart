import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/helpers.dart';
import '../../providers/students/rank_proivder.dart';
import '../../widgets/global_shimmer_screen.dart'; // your shimmer widget

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardProvider>().init();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 150) {
        context.read<LeaderboardProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<LeaderboardProvider>().refreshLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaderboardProvider>(
      builder: (context, provider, _) {
        final leaderboardData = provider.leaderboardData;
        final topThree = leaderboardData.take(3).toList();
        final others = leaderboardData.length > 3
            ? leaderboardData.sublist(3)
            : <Map<String, dynamic>>[];

        return Scaffold(
          appBar: UiHelpers.customAppBarForScreen(
            context,
            provider.selectedTestName.isEmpty
                ? 'LEADERBOARD'
                : provider.selectedTestName,
            actions: [
              if (provider.tests.isNotEmpty)
                provider.isLoadingTests
                    ? const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : _buildModernDropdown(context, provider),
            ],
          ),
          body: Container(
            color: Colors.grey[100],
            child: SafeArea(
              child: GlobalShimmerScreen(
                isLoading: provider.isLoadingLeaderboard &&
                    leaderboardData.isEmpty,
                child: leaderboardData.isEmpty
                    ? _buildEmptyLeaderboard()
                    : RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: Column(
                          children: [
                            // Podium Section
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (topThree.length >= 2)
                                    _buildPodiumUser(topThree[1], 2),
                                  if (topThree.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: _buildPodiumUser(topThree[0], 1),
                                    ),
                                  if (topThree.length >= 3)
                                    _buildPodiumUser(topThree[2], 3),
                                ],
                              ),
                            ),
                            const Divider(height: 0, thickness: 1),
                            // Rankings Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              color: Colors.white,
                              child: Row(
                                children: [
                                  Text(
                                    "RANKINGS",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "${leaderboardData.length} Participants",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Rankings List
                            Expanded(
                              child: ListView.separated(
                                controller: _scrollController,
                                padding: EdgeInsets.zero,
                                itemCount: others.length +
                                    (provider.isLoadingMore ? 1 : 0),
                                separatorBuilder: (_, __) => const Divider(
                                  height: 0,
                                  thickness: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: Color(0xFFEEEEEE),
                                ),
                                itemBuilder: (context, index) {
                                  if (index >= others.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    );
                                  }
                                  final user = others[index];
                                  final rank = 4 + index;
                                  return _buildLeaderboardItem(user, rank);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyLeaderboard() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.leaderboard_outlined,
              size: 60, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            "No leaderboard available",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Select a completed test to view results",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown(
      BuildContext context, LeaderboardProvider provider) {
    final tests = provider.tests;
    return PopupMenuButton<String>(
      icon:
          const Icon(Icons.filter_list_rounded, color: Colors.white, size: 24),
      tooltip: 'Select Test',
      onSelected: provider.selectTest,
      itemBuilder: (_) => tests.map((test) {
        final selected = test['id'] == provider.selectedTestId;
        return PopupMenuItem<String>(
          value: test['id'],
          child: Row(
            children: [
              if (selected)
                Icon(Icons.check_rounded,
                    color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  test['displayName'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPodiumUser(Map<String, dynamic> user, int rank) {
    final medalColors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: medalColors[rank]!, width: 2.5),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: user['avatarUrl'] ?? '',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.person, size: 40),
                ),
              ),
            ),
            Positioned(
              bottom: -12,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: medalColors[rank],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text("$rank",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('₹${user['reward'] ?? 0}',
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.green)),
        Text(user['name'] ?? 'Anonymous',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center),
        Text('SC: ${user['score'] ?? 0} • ${user['time'] ?? '--:--'} min',
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> user, int rank) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('$rank',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: rank <= 3 ? Colors.amber[700] : Colors.grey[700])),
          ),
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFFF5F5F5)),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: user['avatarUrl'] ?? '',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(Icons.person),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] ?? 'Anonymous',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 15)),
                const SizedBox(height: 4),
                Text('${user['score'] ?? 0} score • ${user['time'] ?? '--:--'}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          Text('₹${user['reward'] ?? 0}',
              style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }
}
