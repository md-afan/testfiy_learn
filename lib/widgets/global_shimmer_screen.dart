import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class GlobalShimmerScreen extends StatelessWidget {
  final bool isLoading;
  final Widget? child;
  final int? itemCount; // Optional: how many shimmer items to generate
  final double? height; // Optional: height of each shimmer item
  final EdgeInsetsGeometry padding;
  final Color baseColor;
  final Color highlightColor;

  const GlobalShimmerScreen({
    super.key,
    required this.isLoading,
    this.child,
    this.itemCount,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.baseColor = const Color(0xFFE0E0E0), // light grey
    this.highlightColor = const Color(0xFFF5F5F5), // lighter grey
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child ?? const SizedBox.shrink();
    }

    // If child is provided, shimmer that widget
    if (child != null) {
      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: IgnorePointer(child: child),
      );
    }

    // If no child but itemCount & height provided, auto-generate shimmer placeholders
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: IgnorePointer(
        child: ListView.builder(
          padding: padding,
          itemCount: itemCount ?? 5,
          itemBuilder: (_, __) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: height ?? 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
