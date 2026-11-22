import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/conversation_work_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_kind_text.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where a pause at a usage limit stands. Once its wake settles the server
/// stamps the row (`outcome`, `settledAt`, `skipKind`), and the card reads
/// that; until then it reads the live wake.
enum LimitParkState {
  /// The pause waits for its person's Resume: a person's run never resumes
  /// by itself. Also the state while its wake is not listed (yet, or not to
  /// this viewer).
  held,

  /// Its person resumed it: the run starts at the wake's time (30 seconds
  /// after the reset, or at once when the reset has passed).
  pending,

  /// Settled: the run resumed.
  resumed,

  /// Settled: a person cancelled it.
  cancelled,

  /// Settled: it expired before it ran.
  expired,

  /// Settled: it was skipped (`skipKind` says why).
  skipped,

  /// Settled with an outcome this version does not name.
  unknown,
}

/// The state of a `limit_park` row: its stamped outcome, else [wake]'s state.
LimitParkState limitParkStateOf(Map<String, dynamic> meta, WakeView? wake) {
  final outcome = meta['outcome'];
  if (outcome is String && outcome.isNotEmpty) {
    return switch (outcome) {
      'resumed' => LimitParkState.resumed,
      'cancelled' => LimitParkState.cancelled,
      'expired' => LimitParkState.expired,
      'skipped' => LimitParkState.skipped,
      _ => LimitParkState.unknown,
    };
  }
  return wake == null || wake.state == WakeState.held
      ? LimitParkState.held
      : LimitParkState.pending;
}

/// The card a person's run leaves when it stops at a provider's usage limit
/// (`metadata.kind: limit_park`): "Paused at the provider's usage limit",
/// when it resets or resumes, and Resume (only when the server says this
/// viewer may: the wake's `can_release`) and Cancel while it waits. Once
/// settled it says how it ended and when.
class LimitParkCard extends ConsumerWidget {
  /// Creates the card.
  const LimitParkCard({
    super.key,
    required this.message,
    required this.workspaceId,
  });

  /// The system row.
  final Message message;

  /// The active workspace.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final meta = message.metadata ?? const <String, dynamic>{};
    final wakeId = meta['wakeId'] as String?;
    final provider = inertText(
      (meta['provider'] as String?)?.trim().isNotEmpty == true
          ? meta['provider'] as String
          : '—',
      singleLine: true,
    );
    final settled = meta['outcome'] is String;
    final wakes = workspaceId.isEmpty || settled
        ? const <WakeView>[]
        : ref
                  .watch(
                    conversationWakesProvider((
                      workspaceId: workspaceId,
                      conversationId: message.conversationId,
                    )),
                  )
                  .asData
                  ?.value ??
              const <WakeView>[];
    final wake = wakes.where((w) => w.id == wakeId).firstOrNull;
    final state = limitParkStateOf(meta, wake);
    DateTime? when(String key) => DateTime.tryParse(meta[key] as String? ?? '');
    final at = switch (state) {
      LimitParkState.held => when('resetsAt') ?? when('resumesAt'),
      LimitParkState.pending => wake?.notBefore ?? when('resumesAt'),
      _ => when('settledAt'),
    };
    final time = at == null ? '—' : workTimeLabel(context, at);
    final sentence = switch (state) {
      LimitParkState.held => l10n.workFeedLimitParkHeld(provider, time),
      LimitParkState.pending => l10n.workFeedLimitParkPending(provider, time),
      LimitParkState.resumed =>
        at == null
            ? l10n.workFeedLimitParkResumed(provider)
            : l10n.workFeedLimitParkOutcomeResumed(provider, time),
      LimitParkState.cancelled => l10n.workFeedLimitParkOutcomeCancelled(
        provider,
        time,
      ),
      LimitParkState.expired => l10n.workFeedLimitParkOutcomeExpired(
        provider,
        time,
      ),
      LimitParkState.skipped => l10n.workFeedLimitParkOutcomeSkipped(
        provider,
        time,
      ),
      LimitParkState.unknown => l10n.workFeedLimitParkGone(provider),
    };
    final detail = switch (state) {
      LimitParkState.skipped => KindSentence(
        sentence: wakeKindSentence(l10n, meta['skipKind'] as String?),
        lead: l10n.wakeKindUnknown,
        kind: meta['skipKind'] as String? ?? '',
      ),
      LimitParkState.unknown => KindSentence(
        sentence: null,
        lead: l10n.wakeKindUnknown,
        kind: meta['outcome'] as String,
      ),
      // Unresumed, the pause expires 7 days after the reset and its messages
      // go back to their writers.
      LimitParkState.held => switch (wake?.expiresAt) {
        final expires? => WorkTime(
          at: expires,
          text: l10n.workFeedLimitParkExpires(workTimeLabel(context, expires)),
          style: CcTypography.caption.copyWith(color: ds.textTertiary),
        ),
        null => null,
      },
      _ => null,
    };
    final live = settled ? null : wake;
    final waiting = !settled;
    final textStyle = CcTypography.bodySm.copyWith(
      color: waiting ? ds.textPrimary : ds.textTertiary,
    );
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: waiting ? ds.panel : null,
        border: Border.all(color: waiting ? ds.warn : ds.borderSecondary),
      ),
      child: Row(
        children: [
          Icon(
            switch (state) {
              LimitParkState.held || LimitParkState.pending => AppIcons.gauge,
              LimitParkState.resumed => AppIcons.circleCheck,
              _ => AppIcons.circleX,
            },
            size: 16,
            color: waiting ? ds.warn : ds.textTertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (at == null)
                  Text(sentence, style: textStyle)
                else
                  WorkTime(at: at, text: sentence, style: textStyle),
                ?detail,
              ],
            ),
          ),
          if (live != null) ...[
            if (state == LimitParkState.held && live.canRelease) ...[
              const SizedBox(width: AppSpacing.sm),
              CcButton(
                icon: AppIcons.play,
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                onPressed: () => _resume(context, ref, live),
                child: Text(l10n.workFeedLimitParkResume),
              ),
            ],
            if (state == LimitParkState.held && !live.canRelease) ...[
              const SizedBox(width: AppSpacing.sm),
              CcTooltip(
                message: l10n.wakeStripResumeOnlyTheirs,
                child: Icon(AppIcons.user, size: 14, color: ds.textTertiary),
              ),
            ],
            const SizedBox(width: AppSpacing.xs),
            CcButton(
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              onPressed: () => _cancel(context, ref, live),
              child: Text(l10n.workFeedLimitParkCancel),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _resume(BuildContext context, WidgetRef ref, WakeView w) async {
    try {
      await ref
          .read(conversationWakesRepositoryProvider)
          .release(w.workspaceId, wakeId: w.id);
    } on Object catch (e) {
      if (context.mounted) {
        showWorkFailure(context, e);
      }
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, WakeView w) async {
    final l10n = AppLocalizations.of(context);
    try {
      final cancelled = await ref
          .read(conversationWakesRepositoryProvider)
          .cancel(w.workspaceId, w.id);
      if (!cancelled && context.mounted) {
        showWorkNotice(context, l10n.wakeRefusalSettled);
      }
    } on Object catch (e) {
      if (context.mounted) {
        showWorkFailure(context, e);
      }
    }
  }
}
