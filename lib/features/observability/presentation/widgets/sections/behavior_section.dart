import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/providers/friction_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User-friction analytics (PRD 06, feature #5).
///
/// Surfaces frustration signals — yelling, profanity, anguish, negation,
/// repetition, blame — extracted locally from the operator's own messages, so
/// the workspace can read its own conversation health at a glance. These are a
/// quality signal about the experience, not a measure of the agents.
/// Non-scrolling; the parent tab owns the scroll view.
class BehaviorSection extends ConsumerWidget {
  /// Creates a [BehaviorSection].
  const BehaviorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final report = ref.watch(workspaceFrictionProvider);
    final totals = report.totals;
    final hasSignals = totals.totalSignals > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.obsBehaviorCaption,
          style: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.lg,
          children: [
            ObsStatTile(
              label: l10n.obsBehaviorMessagesAnalyzed,
              value: fmtCount(report.messageCount),
              icon: AppIcons.messageSquare,
            ),
            ObsStatTile(
              label: l10n.obsBehaviorTotalSignals,
              value: fmtCount(totals.totalSignals),
              tone: hasSignals ? ObsTone.warning : ObsTone.neutral,
              icon: AppIcons.triangleAlert,
            ),
            ObsStatTile(
              label: l10n.obsBehaviorYelling,
              value: fmtCount(totals.yelling),
              tone: totals.yelling > 0 ? ObsTone.warning : ObsTone.neutral,
              icon: AppIcons.zap,
            ),
            ObsStatTile(
              label: l10n.obsBehaviorProfanity,
              value: fmtCount(totals.profanity),
              tone: totals.profanity > 0 ? ObsTone.warning : ObsTone.neutral,
              icon: AppIcons.ban,
            ),
            ObsStatTile(
              label: l10n.obsBehaviorAnguish,
              value: fmtCount(totals.anguish),
              tone: totals.anguish > 0 ? ObsTone.warning : ObsTone.neutral,
              icon: AppIcons.flame,
            ),
            ObsStatTile(
              label: l10n.obsBehaviorNegation,
              value: fmtCount(totals.negation),
              tone: totals.negation > 0 ? ObsTone.warning : ObsTone.neutral,
              icon: AppIcons.circleAlert,
            ),
            ObsStatTile(
              label: l10n.obsBehaviorRepetition,
              value: fmtCount(totals.repetition),
              tone: totals.repetition > 0 ? ObsTone.warning : ObsTone.neutral,
              icon: AppIcons.refreshCw,
            ),
            ObsStatTile(
              label: l10n.obsBehaviorBlame,
              value: fmtCount(totals.blame),
              tone: totals.blame > 0 ? ObsTone.warning : ObsTone.neutral,
              icon: AppIcons.skull,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        ObsSection(
          title: l10n.obsBehaviorConversationsTitle,
          subtitle: l10n.obsBehaviorConversationsSubtitle,
          icon: AppIcons.messageSquare,
          child: report.byConversation.isEmpty
              ? Text(
                  l10n.obsBehaviorNoSignals,
                  style: CcTypography.body.copyWith(color: t.textTertiary),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final conv in report.byConversation)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ConversationFrictionRow(friction: conv),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// One row in the most-frustrated-conversations list.
class _ConversationFrictionRow extends StatelessWidget {
  const _ConversationFrictionRow({required this.friction});

  final ConversationFriction friction;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final signals = friction.metrics.totalSignals;
    final tone = _signalTone(signals);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ObsStatusDot(tone: tone, size: 8),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                friction.channelName,
                style: CcTypography.body.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                l10n.obsBehaviorMessagesCount(fmtCount(friction.messageCount)),
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          l10n.obsBehaviorSignalsCount(fmtCount(signals)),
          style: CcTypography.monoNum.copyWith(
            color: tone == ObsTone.neutral
                ? t.textSecondary
                : obsToneColor(t, tone),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Maps a conversation's signal count to a tone: quiet under five, warning up
  /// to fifteen, danger beyond.
  static ObsTone _signalTone(int signals) {
    if (signals <= 0) {
      return ObsTone.neutral;
    }
    if (signals >= 15) {
      return ObsTone.danger;
    }
    if (signals >= 5) {
      return ObsTone.warning;
    }
    return ObsTone.neutral;
  }
}
