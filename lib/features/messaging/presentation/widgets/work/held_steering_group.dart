import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/file_reference.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_hover_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The holder a held card names (`steerHeldBy`): `stop` for a person's Stop
/// (also a card with no marker), or `limit:` and the run id for a pause at
/// a usage limit.
String heldByOf(Message card) {
  final by = card.metadata?['steerHeldBy'];
  return by is String && by.isNotEmpty ? by : 'stop';
}

/// Whether [card] is held at a usage-limit pause rather than by a Stop.
bool isHeldAtLimit(Message card) => heldByOf(card).startsWith('limit:');

/// The held steering messages, one group per holder.
///
/// A held message is sent only by the person who wrote it (`sender_id`).
/// The cards held for their writers (a person's Stop, or a run that ended at
/// a usage limit with no pause) come with "Send held messages" only for a
/// viewer who wrote one of them: `steering.release` with `held_by: stop`
/// sends that viewer's cards and keeps everyone else's, which stay here
/// marked as someone else's. A usage-limit pause holds only the cards of
/// the person whose run it is (every other writer's are Stop-held at once):
/// they go out when that person resumes it, or come back to them as a
/// Stop's if it expires unresumed 7 days after the reset. The server refuses
/// to release them by hand (`steering_held_by_limit`), so their group offers
/// no send and says when the limit resets (`steerLimitResetsAt`). Anyone may
/// delete any card, on hover.
class HeldSteeringGroup extends ConsumerWidget {
  /// Creates the group.
  const HeldSteeringGroup({
    super.key,
    required this.cards,
    required this.onRelease,
    required this.onDelete,
  });

  /// The held cards, in queue order. Never empty.
  final List<Message> cards;

  /// Releases the viewer's own cards held for their writers.
  final VoidCallback onRelease;

  /// Deletes one held card.
  final ValueChanged<Message> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final viewerId = ref.watch(currentUserIdProvider);
    final users = ref.watch(usersByIdProvider).value;
    bool mine(Message card) => viewerId != null && card.senderId == viewerId;
    String? author(Message card) {
      if (mine(card)) {
        return null;
      }
      final name = users?[card.senderId]?.displayName.trim() ?? '';
      return name.isEmpty
          ? l10n.heldSteeringFromSomeoneElse
          : l10n.heldSteeringFromPerson(inertText(name, singleLine: true));
    }

    final byStop = cards.where((c) => !isHeldAtLimit(c)).toList();
    final pauses = <String, List<Message>>{};
    for (final card in cards.where(isHeldAtLimit)) {
      (pauses[heldByOf(card)] ??= []).add(card);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (byStop.isNotEmpty) ...[
          _header(
            context,
            l10n.heldSteeringHeader(byStop.length),
            canSend: byStop.any(mine),
          ),
          if (!byStop.every(mine))
            _note(context, Text(l10n.heldSteeringOnlyWriterSends)),
          for (final card in byStop) _card(context, l10n, card, author(card)),
        ],
        for (final group in pauses.values) ...[
          _header(
            context,
            l10n.heldSteeringLimitHeader(group.length),
            canSend: false,
          ),
          _limitNote(context, l10n, group),
          for (final card in group) _card(context, l10n, card, author(card)),
        ],
      ],
    );
  }

  /// What becomes of a pause's cards: the limit's reset (the earliest any of
  /// them carries) when known, and that they are sent when the person the
  /// run works for resumes it.
  Widget _limitNote(
    BuildContext context,
    AppLocalizations l10n,
    List<Message> group,
  ) {
    final resets = [
      for (final card in group)
        ?DateTime.tryParse(
          card.metadata?['steerLimitResetsAt'] as String? ?? '',
        ),
    ]..sort();
    return _note(
      context,
      resets.isEmpty
          ? Text(l10n.heldSteeringLimitNote)
          : WorkTime(
              at: resets.first,
              text: l10n.heldSteeringLimitResetsAt(
                workTimeLabel(context, resets.first),
              ),
            ),
    );
  }

  Widget _note(BuildContext context, Widget child) => Padding(
    padding: const EdgeInsetsDirectional.only(
      start: AppSpacing.md,
      end: AppSpacing.md,
      bottom: AppSpacing.xs,
    ),
    child: DefaultTextStyle.merge(
      style: CcTypography.caption.copyWith(color: context.ds.textTertiary),
      child: child,
    ),
  );

  Widget _header(BuildContext context, String text, {required bool canSend}) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          CcBadge(
            label: l10n.wakeStripHeld,
            variant: CcBadgeVariant.warning,
            icon: AppIcons.pause,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(color: ds.textTertiary),
            ),
          ),
          if (canSend)
            CcButton(
              icon: AppIcons.send,
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: onRelease,
              child: Text(l10n.heldSteeringResume),
            ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    AppLocalizations l10n,
    Message card,
    String? author,
  ) => Padding(
    key: ValueKey(card.id),
    padding: const EdgeInsetsDirectional.only(
      start: AppSpacing.md,
      end: AppSpacing.md,
      bottom: AppSpacing.xs,
    ),
    child: WorkHoverRow(
      actions: [
        CcIconButton(
          icon: AppIcons.trash2,
          variant: CcButtonVariant.destructive,
          size: CcButtonSize.sm,
          tooltip: l10n.heldSteeringDelete,
          onPressed: () => onDelete(card),
        ),
      ],
      child: Row(
        children: [
          Expanded(
            child: Text(
              inertText(_displayText(card), singleLine: true),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.bodySm.copyWith(
                color: context.ds.textSecondary,
              ),
            ),
          ),
          if (author != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              author,
              maxLines: 1,
              style: CcTypography.caption.copyWith(
                color: context.ds.textTertiary,
              ),
            ),
          ],
        ],
      ),
    ),
  );

  static String _displayText(Message card) {
    final text = expandFileRefs(card.content, (name) => name).trim();
    if (text.isNotEmpty) {
      return text;
    }
    return [for (final a in card.attachments) a.name].join(', ');
  }
}
