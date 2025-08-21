import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:testify_learn_application/theme/shimmer_theme.dart';

class GlobalShimmerScreen extends StatelessWidget {
  final bool isLoading;
  final Widget? child;
  final int? itemCount; // Optional: how many shimmer items to generate
  final double? height; // Optional: height of each shimmer item
  final EdgeInsetsGeometry padding;

  const GlobalShimmerScreen({
    super.key,
    required this.isLoading,
    this.child,
    this.itemCount,
    this.height,
    this.padding = const EdgeInsets.all(16),
    // lighter grey
  });

  @override
  Widget build(BuildContext context) {
    final shimmerTheme = Theme.of(context).extension<ShimmerTheme>()!;
    if (!isLoading) {
      return child ?? const SizedBox.shrink();
    }

    // If child is provided, shimmer that widget
    if (child != null) {
      return Shimmer.fromColors(
        baseColor: shimmerTheme.baseColor,
        highlightColor: shimmerTheme.highlightColor,
        child: IgnorePointer(child: child),
      );
    }

    // If no child but itemCount & height provided, auto-generate shimmer placeholders
    return Shimmer.fromColors(
      baseColor: shimmerTheme.baseColor,
      highlightColor: shimmerTheme.highlightColor,
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
