import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/conversation_work_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/held_steering_group.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/wake_card.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_kind_text.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/features/messaging/providers/steering_queue_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What waits in the conversation, above the composer: its pending and held
/// wakes (goal continuations, schedules, watches, replies and messages from
/// other agents, limit resets, recoveries) and the steering messages a
/// person's Stop held. Renders nothing when nothing waits.
///
/// Every control is the server's to allow: Deliver now and Resume show only
/// on a wake whose `can_release` is true; Cancel on any wake (the server
/// refuses what the caller may not do).
class ConversationWakeStrip extends ConsumerWidget {
  /// Creates the strip.
  const ConversationWakeStrip({
    super.key,
    required this.spaceId,
    required this.conversationId,
  });

  /// The space the conversation belongs to.
  final String spaceId;

  /// The conversation.
  final String conversationId;

  /// The most rows shown before the strip scrolls.
  static const double maxHeight = 200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final key = (workspaceId: workspaceId, conversationId: conversationId);
    final wakes =
        ref.watch(conversationWakesProvider(key)).asData?.value ??
        const <WakeView>[];
    final held = ref.watch(
      heldSteeringProvider((spaceId: spaceId, conversationId: conversationId)),
    );
    if (wakes.isEmpty && held.isEmpty) {
      return const SizedBox.shrink();
    }
    final ds = context.ds;
    final releasable = wakes
        .where((w) => w.state == WakeState.held && w.canRelease)
        .length;
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: ds.surface,
        border: Border.all(color: ds.borderPrimary),
      ),
      constraints: const BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (wakes.isNotEmpty)
              _Header(
                count: wakes.length,
                onResumeAll: releasable > 1
                    ? () => _releaseAll(context, ref, workspaceId)
                    : null,
              ),
            for (final wake in wakes)
              WakeCard(
                key: ValueKey(wake.id),
                wake: wake,
                sourceAgentName: wake.sourceAgentId == null
                    ? null
                    : ref.watch(
                        workAgentNameProvider((
                          workspaceId: workspaceId,
                          agentId: wake.sourceAgentId!,
                        )),
                      ),
                onCancel: () => _cancel(context, ref, wake),
                onDeliverNow: () => _deliverNow(context, ref, wake),
                onResume: () => _release(context, ref, wake),
              ),
            if (held.isNotEmpty) ...[
              if (wakes.isNotEmpty)
                Container(height: 1, color: ds.borderSecondary),
              HeldSteeringGroup(
                cards: held,
                onRelease: () => _releaseHeld(context, ref, workspaceId),
                onDelete: (card) =>
                    _deleteHeld(context, ref, workspaceId, card),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    WakeView wake,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final cancelled = await ref
          .read(conversationWakesRepositoryProvider)
          .cancel(wake.workspaceId, wake.id);
      if (!cancelled && context.mounted) {
        showWorkNotice(context, l10n.wakeRefusalSettled);
      }
    } on Object catch (e) {
      if (context.mounted) {
        showWorkFailure(context, e);
      }
    }
  }

  Future<void> _deliverNow(
    BuildContext context,
    WidgetRef ref,
    WakeView wake,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final receipt = await ref
          .read(conversationWakesRepositoryProvider)
          .deliverNow(wake.workspaceId, wake.id);
      if (context.mounted) {
        showWorkNotice(context, wakeReceiptSentence(l10n, receipt));
      }
    } on Object catch (e) {
      if (context.mounted) {
        showWorkFailure(context, e);
      }
    }
  }

  Future<void> _release(
    BuildContext context,
    WidgetRef ref,
    WakeView wake,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final count = await ref
          .read(conversationWakesRepositoryProvider)
          .release(wake.workspaceId, wakeId: wake.id);
      if (context.mounted) {
        showWorkNotice(context, l10n.wakeReleased(count));
      }
    } on Object catch (e) {
      if (context.mounted) {
        showWorkFailure(context, e);
      }
    }
  }

  Future<void> _releaseAll(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final count = await ref
          .read(conversationWakesRepositoryProvider)
          .release(workspaceId, conversationId: conversationId);
      if (context.mounted) {
        showWorkNotice(context, l10n.wakeReleased(count));
      }
    } on Object catch (e) {
      if (context.mounted) {
        showWorkFailure(context, e);
      }
    }
  }

  Future<void> _releaseHeld(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final count = await ref
          .read(heldSteeringRepositoryProvider)
          .release(
            workspaceId: workspaceId,
            spaceId: spaceId,
            conversationId: conversationId,
          );
      if (context.mounted) {
        showWorkNotice(context, l10n.heldSteeringReleased(count));
      }
    } on Object catch (e) {
      if (context.mounted) {
        showWorkFailure(context, e);
      }
    }
  }

  Future<void> _deleteHeld(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
    Message card,
  ) async {
    try {
      await deleteSteeringCard(
        ref,
        workspaceId: workspaceId,
        key: (spaceId: spaceId, conversationId: conversationId),
        messageId: card.id,
      );
    } on Object catch (e) {
      if (context.mounted) {
        showWorkFailure(context, e);
      }
    }
  }
}

/// What a Deliver now did, in one sentence.
String wakeReceiptSentence(AppLocalizations l10n, WakeReceipt receipt) =>
    switch (receipt) {
      WakeStarted() => l10n.wakeReceiptStarted,
      WakePushed() => l10n.wakeReceiptPushed,
      WakeWaiting(:final kind) => l10n.wakeReceiptWaiting(
        wakeKindSentence(l10n, kind) ?? '${l10n.wakeKindUnknown} $kind',
      ),
      WakeSkipped(:final kind) => l10n.wakeReceiptSkipped(
        wakeKindSentence(l10n, kind) ?? '${l10n.wakeKindUnknown} $kind',
      ),
      WakeDuplicate() => l10n.wakeReceiptDuplicate,
    };

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onResumeAll});

  final int count;
  final VoidCallback? onResumeAll;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: [
          Icon(AppIcons.clock, size: 12, color: ds.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              l10n.wakeStripHeader(count),
              style: CcTypography.caption.copyWith(color: ds.textTertiary),
            ),
          ),
          if (onResumeAll != null)
            CcButton(
              icon: AppIcons.play,
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              onPressed: onResumeAll,
              child: Text(l10n.wakeStripResumeAll),
            ),
        ],
      ),
    );
  }
}
