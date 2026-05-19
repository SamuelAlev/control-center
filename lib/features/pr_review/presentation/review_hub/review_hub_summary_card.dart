import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/review_hub_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The CodeRabbit-style AI summary card: headline, per-area walkthrough and
/// risk notes from the finalized review's structured metadata. Falls back to
/// the summary's markdown body when no structured walkthrough was authored,
/// and to a hint when no review has been finalized yet.
class ReviewHubSummaryCard extends ConsumerWidget {
  /// Creates a [ReviewHubSummaryCard].
  const ReviewHubSummaryCard({super.key, required this.channelId});

  /// The review channel whose latest summary to render.
  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(reviewHubSummaryProvider(channelId));

    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ds.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ds.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.sparkles, size: 14, color: ds.accent),
              const SizedBox(width: 8),
              Text(
                l10n.reviewHubAiSummary,
                style: TextStyle(
                  color: ds.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (summary.walkthrough != null && !summary.walkthrough!.isAbsent)
            ..._walkthrough(context, summary.walkthrough!)
          else
            StyledMarkdownBody(data: summary.markdown),
        ],
      ),
    );
  }

  List<Widget> _walkthrough(
    BuildContext context,
    ReviewWalkthroughSummary walkthrough,
  ) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    return [
      if (walkthrough.headline.isNotEmpty)
        Text(
          walkthrough.headline,
          style: TextStyle(
            color: ds.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      for (final area in walkthrough.areas) ...[
        const SizedBox(height: 8),
        Text(
          area.title,
          style: TextStyle(
            color: ds.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        for (final bullet in area.bullets)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: BoxDecoration(
                    color: ds.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    bullet,
                    style: TextStyle(color: ds.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
      if (walkthrough.riskNotes.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          l10n.reviewHubRisks,
          style: TextStyle(
            color: ds.warn,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        for (final risk in walkthrough.riskNotes)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text(
              risk,
              style: TextStyle(color: ds.textSecondary, fontSize: 12),
            ),
          ),
      ],
    ];
  }
}
