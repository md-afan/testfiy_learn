import 'package:flutter/material.dart';

class LeaderboardListTile extends StatelessWidget {
  final Map<String, dynamic> user;

  const LeaderboardListTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade300,
          child: Text('${user['rank']}'),
        ),
        title: Text(
          user['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('SC: ${user['score']} • ${user['time']} min'),
        trailing: Text(
          '₹${user['reward']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
