import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_hover_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_kind_text.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// One waiting wake in the queue strip: what raised it (a chip), its
/// headline, when it is due or why it is held, and its actions on hover.
///
/// The headline is the server's short line about the wake; the payload never
/// reaches a client. Both are data and render as plain text.
class WakeCard extends StatelessWidget {
  /// Creates the card.
  const WakeCard({
    super.key,
    required this.wake,
    required this.sourceAgentName,
    required this.onCancel,
    required this.onDeliverNow,
    required this.onResume,
  });

  /// The wake.
  final WakeView wake;

  /// The name of the agent a reply, message or finished work came from.
  final String? sourceAgentName;

  /// Cancels (or, for a recovery wake, dismisses) the wake.
  final VoidCallback onCancel;

  /// Delivers a pending wake now.
  final VoidCallback onDeliverNow;

  /// Resumes a held wake.
  final VoidCallback onResume;

  bool get _held => wake.state == WakeState.held;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final reason = wakeKindSentence(l10n, wake.stateReason);
    final expiresAt = wake.expiresAt;
    final secondary = <Widget>[
      if (_held && wake.stateReason != null)
        Flexible(
          child: KindSentence(
            sentence: reason,
            lead: l10n.wakeKindUnknown,
            kind: wake.stateReason!,
          ),
        )
      else if (!_held)
        WorkTime(
          at: wake.notBefore,
          text: wake.notBefore.isAfter(now)
              ? l10n.wakeStripDue(workTimeLabel(context, wake.notBefore))
              : l10n.wakeStripDueNow,
        ),
      if (!_held && wake.stateReason != null && reason != null)
        Flexible(
          child: Text(
            reason,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CcTypography.caption.copyWith(color: ds.textTertiary),
          ),
        ),
      if (expiresAt != null)
        WorkTime(
          at: expiresAt,
          text: l10n.wakeStripExpires(workTimeLabel(context, expiresAt)),
        ),
      if (wake.attempt > 0)
        Text(
          l10n.wakeStripAttempt(wake.attempt + 1),
          style: CcTypography.caption.copyWith(color: ds.textTertiary),
        ),
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: WorkHoverRow(
        actions: _actions(l10n),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (_held) ...[
                  CcTooltip(
                    message: wake.canRelease
                        ? l10n.wakeStripHeld
                        : l10n.wakeStripResumeOnlyTheirs,
                    child: CcBadge(
                      label: l10n.wakeStripHeld,
                      variant: CcBadgeVariant.warning,
                      icon: AppIcons.pause,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  flex: 0,
                  child: CcBadge(
                    label: wakeOriginLabel(
                      l10n,
                      wake.reason,
                      agentName: sourceAgentName,
                    ),
                    icon: wakeOriginIcon(wake.reason),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    inertText(wake.headline, singleLine: true),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.bodySm.copyWith(
                      color: ds.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (secondary.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 2),
                child: Row(
                  children: [
                    for (var i = 0; i < secondary.length; i++) ...[
                      if (i > 0)
                        Text(
                          ' · ',
                          style: CcTypography.caption.copyWith(
                            color: ds.textQuaternary,
                          ),
                        ),
                      secondary[i],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(AppLocalizations l10n) {
    final recovery = wake.reason == WakeReason.recovery;
    return [
      if (_held && wake.canRelease)
        CcIconButton(
          icon: AppIcons.play,
          size: CcButtonSize.sm,
          tooltip: l10n.wakeStripResume,
          onPressed: onResume,
        ),
      if (!_held && wake.canRelease)
        CcIconButton(
          icon: AppIcons.send,
          size: CcButtonSize.sm,
          tooltip: l10n.wakeStripDeliverNow,
          onPressed: onDeliverNow,
        ),
      CcIconButton(
        icon: AppIcons.x,
        size: CcButtonSize.sm,
        tooltip: recovery ? l10n.wakeStripDismiss : l10n.wakeStripCancel,
        onPressed: onCancel,
      ),
    ];
  }
}
