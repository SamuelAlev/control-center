import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/review_hub/review_hub_view.dart';
import 'package:flutter/widgets.dart';

/// The unified review surface — one tab (`pr.review`), one review.
///
/// The Review Hub merges the former "Findings" (AI reviewer consensus →
/// `review_node` messages → verdict) and "Review Studio" (deterministic
/// cohorts, multi-axis dashboard, contract/visual diffs, blast radius) modes
/// into a single model: findings routed into deterministic areas, an AI
/// summary on top and a per-area deep dive.
class PrReviewTab extends StatefulWidget {
  /// Creates a [PrReviewTab].
  const PrReviewTab({super.key, required this.pr});

  /// The pull request under review.
  final PullRequest pr;

  @override
  State<PrReviewTab> createState() => _PrReviewTabState();
}

class _PrReviewTabState extends State<PrReviewTab> {
  @override
  Widget build(BuildContext context) {
    return ReviewHubView(pr: widget.pr);
  }
}
