import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class TopRankCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const TopRankCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: user['bg'] ?? Colors.grey.shade300,
                backgroundImage: CachedNetworkImageProvider(
                  user['avatarUrl'] ??
                      "https://mohdbinsufiyan.vercel.app/assets/media/mypic.jpg",
                ),
              ),
              Positioned(
                bottom: -4,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Text(
                    '${user['rank']}',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '₹${user['reward']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user['name'],
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'SC: ${user['score']} • ${user['time']} min',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
