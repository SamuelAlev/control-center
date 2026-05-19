/// Design token scale that maps size steps to concrete pixel values.
///
/// Each field represents a step in the sizing scale, from extra-small
/// (xs3) to extra-large (xl8).
class Scale {
  /// Creates a [Scale] with the given size steps.
  const Scale({
    required this.xs3,
    required this.xs2,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xl2,
    required this.xl3,
    required this.xl4,
    required this.xl5,
    required this.xl6,
    required this.xl7,
    required this.xl8,
  });

  /// Extra-extra-extra small size step.
  final double xs3;
  /// Extra-extra small size step.
  final double xs2;
  /// Extra small size step.
  final double xs;
  /// Small size step.
  final double sm;
  /// Medium size step.
  final double md;
  /// Large size step.
  final double lg;
  /// Extra large size step.
  final double xl;
  /// Extra-extra large size step.
  final double xl2;
  /// Extra-extra-extra large size step.
  final double xl3;
  /// 4x large size step.
  final double xl4;
  /// 5x large size step.
  final double xl5;
  /// 6x large size step.
  final double xl6;
  /// 7x large size step.
  final double xl7;
  /// 8x large size step.
  final double xl8;
}
