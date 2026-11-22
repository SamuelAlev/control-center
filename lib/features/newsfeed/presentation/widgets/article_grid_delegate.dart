import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/article_card.dart';
import 'package:flutter/rendering.dart';

/// Grid of [ArticleCard]s: columns at most [maxCrossAxisExtent] wide, each
/// tile exactly as tall as a card's 16:9 thumbnail plus [bodyHeight].
///
/// A fixed aspect ratio left empty space under the title whenever the
/// column was wide; sizing from the content keeps the card tight at every
/// width and text scale.
class ArticleGridDelegate extends SliverGridDelegate {
  /// Creates an [ArticleGridDelegate].
  const ArticleGridDelegate({required this.bodyHeight});

  /// Widest a column may be before another one is added.
  static const double maxCrossAxisExtent = 340;

  /// Gap between tiles on both axes.
  static const double spacing = AppSpacing.lg;

  /// Height below the thumbnail, from [ArticleCard.bodyHeight].
  final double bodyHeight;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final count = math.max(
      1,
      (constraints.crossAxisExtent / (maxCrossAxisExtent + spacing)).ceil(),
    );
    final width = math.max(
      0.0,
      (constraints.crossAxisExtent - spacing * (count - 1)) / count,
    );
    final thumbnail =
        math.max(0.0, width - 2 * ArticleCard.borderWidth) * 9 / 16;
    final height = thumbnail + bodyHeight;
    return SliverGridRegularTileLayout(
      crossAxisCount: count,
      mainAxisStride: height + spacing,
      crossAxisStride: width + spacing,
      childMainAxisExtent: height,
      childCrossAxisExtent: width,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(ArticleGridDelegate oldDelegate) =>
      oldDelegate.bodyHeight != bodyHeight;
}
