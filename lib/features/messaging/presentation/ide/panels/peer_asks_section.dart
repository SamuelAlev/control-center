import 'package:cc_domain/features/dispatch/domain/repositories/conversation_peer_asks_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/conversation_work_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_hover_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_kind_text.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/collapsible_sidebar_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The questions this conversation's agents asked other agents
/// (`peerAsks.watchForConversation`): to whom, of what kind, when, until
/// when, and Cancel on a pending one. Hidden when there are none; settled
/// asks stay for a glance, capped so they never crowd out pending ones.
class PeerAsksSection extends ConsumerWidget {
  /// Creates the section.
  const PeerAsksSection({
    super.key,
    required this.workspaceId,
    required this.conversationId,
  });

  /// The active workspace.
  final String workspaceId;

  /// The conversation.
  final String conversationId;

  /// Settled asks shown under the pending ones.
  static const visibleSettled = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asks =
        ref
            .watch(
              conversationPeerAsksProvider((
                workspaceId: workspaceId,
                conversationId: conversationId,
              )),
            )
            .asData
            ?.value ??
        const <PeerAskView>[];
    if (asks.isEmpty) {
      return const SizedBox.shrink();
    }
    final pending = asks
        .where((a) => a.status == PeerAskStatus.pending)
        .toList();
    final settled = asks
        .where((a) => a.status != PeerAskStatus.pending)
        .take(visibleSettled);
    return CollapsibleSidebarSection(
      icon: AppIcons.messageCircleQuestion,
      label: l10n.peerAsksSection,
      count: pending.isEmpty ? null : '${pending.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final ask in [...pending, ...settled])
            PeerAskRow(key: ValueKey(ask.id), ask: ask),
        ],
      ),
    );
  }
}

/// One ask: recipient, kind and status chips, when asked and when it
/// expires, and Cancel while it is pending.
class PeerAskRow extends ConsumerWidget {
  /// Creates the row.
  const PeerAskRow({super.key, required this.ask});

  /// The ask.
  final PeerAskView ask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final name =
        ref.watch(
          workAgentNameProvider((
            workspaceId: ask.workspaceId,
            agentId: ask.recipientAgentId,
          )),
        ) ??
        l10n.workAgentUnknown;
    final pending = ask.status == PeerAskStatus.pending;
    final caption = CcTypography.caption.copyWith(color: ds.textTertiary);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      child: WorkHoverRow(
        actions: [
          if (pending)
            CcIconButton(
              icon: AppIcons.x,
              size: CcButtonSize.sm,
              tooltip: l10n.peerAskCancel,
              onPressed: () => _cancel(context, ref),
            ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  AppIcons.messageCircleQuestion,
                  size: 14,
                  color: pending ? ds.textSecondary : ds.textQuaternary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.peerAskTo(name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.bodySm.copyWith(
                      color: pending ? ds.textPrimary : ds.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                CcBadge(label: peerAskKindLabel(l10n, ask.kind)),
                const SizedBox(width: AppSpacing.xs),
                CcBadge(
                  label: peerAskStatusLabel(l10n, ask.status),
                  variant: switch (ask.status) {
                    PeerAskStatus.pending => CcBadgeVariant.brand,
                    PeerAskStatus.answered => CcBadgeVariant.success,
                    PeerAskStatus.failed => CcBadgeVariant.danger,
                    PeerAskStatus.expired => CcBadgeVariant.warning,
                    PeerAskStatus.cancelled => CcBadgeVariant.neutral,
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 14 + AppSpacing.xs,
                top: 2,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                children: [
                  WorkTime(
                    at: ask.createdAt,
                    text: l10n.peerAskAsked(
                      workTimeLabel(context, ask.createdAt),
                    ),
                  ),
                  if (pending)
                    WorkTime(
                      at: ask.expiresAt,
                      text: l10n.peerAskExpires(
                        workTimeLabel(context, ask.expiresAt),
                      ),
                    ),
                  if (pending && ask.promisedAt != null)
                    Text(l10n.peerAskPromised, style: caption),
                  if (ask.mode == PeerAskMode.background)
                    Text(l10n.peerAskBackground, style: caption),
                ],
              ),
            ),
            if (ask.status == PeerAskStatus.failed &&
                (ask.error?.trim().isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 14 + AppSpacing.xs,
                  top: 2,
                ),
                child: KindSentence(
                  sentence: peerAskFailureSentence(l10n, ask.error),
                  lead: l10n.wakeKindUnknown,
                  kind: ask.error!.split(':').first.trim(),
                  style: caption,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      final cancelled = await ref
          .read(conversationPeerAsksRepositoryProvider)
          .cancel(ask.workspaceId, ask.id);
      if (!cancelled && context.mounted) {
        showWorkNotice(context, l10n.peerAskAlreadySettled);
      }
    } on Object catch (e) {
      if (context.mounted) {
        showWorkFailure(context, e);
      }
    }
  }
}
