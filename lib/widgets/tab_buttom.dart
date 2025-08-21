import 'package:flutter/material.dart';
import './global_shimmer_screen.dart';

class TabButton extends StatelessWidget {
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const TabButton({
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.deepPurple
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodySmall!.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class TabButtonShimmer extends StatelessWidget {
  final int count; // number of shimmer tabs

  const TabButtonShimmer({super.key, this.count = 3});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        count,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: GlobalShimmerScreen(
              isLoading: true,
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
