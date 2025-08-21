import 'package:flutter/material.dart';

@immutable
class ShimmerTheme extends ThemeExtension<ShimmerTheme> {
  final Color baseColor;
  final Color highlightColor;

  const ShimmerTheme({
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  ShimmerTheme copyWith({
    Color? baseColor,
    Color? highlightColor,
  }) {
    return ShimmerTheme(
      baseColor: baseColor ?? this.baseColor,
      highlightColor: highlightColor ?? this.highlightColor,
    );
  }

  @override
  ShimmerTheme lerp(ThemeExtension<ShimmerTheme>? other, double t) {
    if (other is! ShimmerTheme) return this;
    return ShimmerTheme(
      baseColor: Color.lerp(baseColor, other.baseColor, t)!,
      highlightColor: Color.lerp(highlightColor, other.highlightColor, t)!,
    );
  }
}
