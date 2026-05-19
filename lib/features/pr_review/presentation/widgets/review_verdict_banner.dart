import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders the per-PR `ReviewVerdict` (SHIP / HOLD / BLOCK) as a colored
/// banner above the findings list.
///
/// Reads the latest `review_summary` message in the channel and decodes its
/// metadata via [ReviewVerdict.fromMetadata]. Renders nothing when no
/// finalized summary exists yet.
class ReviewVerdictBanner extends ConsumerWidget {
  /// Creates a [ReviewVerdictBanner].
  const ReviewVerdictBanner({super.key, required this.channelId});

  /// Channel whose latest summary should be inspected.
  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMessages = ref.watch(channelMessagesProvider(channelId));
    return asyncMessages.maybeWhen(
      data: _renderBanner,
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _renderBanner(List<ChannelMessage> messages) {
    final summaries =
        messages
            .where((m) => m.messageType == ChannelMessageType.reviewSummary)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (summaries.isEmpty) {
      return const SizedBox.shrink();
    }
    final verdict = ReviewVerdict.fromMetadata(summaries.first.metadata);
    if (verdict == null) {
      return const SizedBox.shrink();
    }
    return _Banner(verdict: verdict);
  }
}

class _Banner extends StatefulWidget {
  const _Banner({required this.verdict});
  final ReviewVerdict verdict;

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final v = widget.verdict;
    final (label, color, icon) = switch (v.overall) {
      ReviewVerdictOverall.ship => (
        'SHIP',
        Colors.green.shade600,
        AppIcons.circleCheck,
      ),
      ReviewVerdictOverall.hold => (
        'HOLD',
        tokens.fgWarningPrimary,
        AppIcons.triangleAlert,
      ),
      ReviewVerdictOverall.block => (
        'BLOCK',
        tokens.fgErrorPrimary,
        AppIcons.octagonAlert,
      ),
    };
    final confPct = (v.confidence * 100).round();

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border(
            left: BorderSide(color: color, width: 3),
            bottom: BorderSide(color: tokens.borderSecondary),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  'Verdict: $label',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$confPct% confidence',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: tokens.textTertiary),
                ),
                const Spacer(),
                _CountChip(
                  label: AppLocalizations.of(context).p0,
                  count: v.p0Count,
                  color: tokens.fgErrorPrimary,
                ),
                const SizedBox(width: 4),
                _CountChip(
                  label: AppLocalizations.of(context).p1,
                  count: v.p1Count,
                  color: tokens.fgWarningPrimary,
                ),
                const SizedBox(width: 4),
                _CountChip(
                  label: AppLocalizations.of(context).p2,
                  count: v.p2Count,
                  color: tokens.fgBrandPrimary,
                ),
                const SizedBox(width: 4),
                _CountChip(
                  label: AppLocalizations.of(context).p3,
                  count: v.p3Count,
                  color: tokens.textTertiary,
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                  size: 14,
                  color: tokens.textTertiary,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Text(
                v.explanation,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: tokens.textPrimary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
