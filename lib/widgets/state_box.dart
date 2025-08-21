import 'package:flutter/material.dart';
import './global_shimmer_screen.dart';

class StatBox extends StatelessWidget {
  final String count;
  final String label;
  final Color color;
  final IconData icon;

  const StatBox({
    super.key,
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              count,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class StatBoxShimmer extends StatelessWidget {
  final int count; // Number of shimmer boxes to show
  const StatBoxShimmer({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(count, (index) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            // padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: GlobalShimmerScreen(
              isLoading: true,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.surface, // keep your theme color
                  borderRadius: BorderRadius.circular(16), // rounded corners
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
