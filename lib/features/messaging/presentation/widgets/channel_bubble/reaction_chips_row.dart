import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/providers/channel_reactions_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aggregated reaction chips ("👍 2") below a message (PRD 16 §15). Reads the
/// single channel-wide [messageReactionsProvider] (no per-message
/// subscription); tapping a chip toggles that emoji for the current user.
class ReactionChipsRow extends ConsumerWidget {
  /// Creates a [ReactionChipsRow].
  const ReactionChipsRow({
    super.key,
    required this.channelId,
    required this.messageId,
    this.alignEnd = false,
  });

  /// The owning channel.
  final String channelId;

  /// The message these chips summarize.
  final String messageId;

  /// Whether to right-align the chips (matches the bubble's side).
  final bool alignEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chips = ref.watch(
      messageReactionsProvider((channelId: channelId, messageId: messageId)),
    );
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final chip in chips)
            _ReactionChip(
              channelId: channelId,
              messageId: messageId,
              chip: chip,
            ),
        ],
      ),
    );
  }
}

class _ReactionChip extends ConsumerWidget {
  const _ReactionChip({
    required this.channelId,
    required this.messageId,
    required this.chip,
  });

  final String channelId;
  final String messageId;
  final ReactionChip chip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = resolveTokens(context);
    final l10n = AppLocalizations.of(context);

    return CcTappable(
      onPressed: () => toggleChannelReaction(
        ref.read(rpcClientProvider),
        channelId: channelId,
        messageId: messageId,
        emoji: chip.emoji,
      ),
      semanticLabel: l10n.reactionToggleTooltip(chip.emoji),
      borderRadius: AppRadii.brMd,
      builder: (context, states) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: chip.mine ? t.accentSoft : t.hover,
          borderRadius: AppRadii.brMd,
          border: Border.all(color: chip.mine ? t.accent : t.borderSecondary),
        ),
        child: Text(
          '${chip.emoji} ${chip.count}',
          style: TextStyle(
            fontSize: 12,
            color: chip.mine ? t.accent : t.textSecondary,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
