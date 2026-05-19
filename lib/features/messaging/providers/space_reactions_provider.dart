import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The fixed emoji palette offered by the add-reaction affordance (PRD 16
/// §15). Deliberately small and fixed — not a full emoji picker.
const List<String> kReactionPalette = ['👍', '👎', '🎉', '❤️', '👀', '✅'];

/// One reaction row from `reactions.watchForSpace`.
class MessageReaction {
  /// Creates a [MessageReaction].
  const MessageReaction({
    required this.id,
    required this.spaceId,
    required this.messageId,
    required this.principalId,
    required this.principalType,
    required this.emoji,
    required this.createdAt,
  });

  /// Parses one entry of the `reactions` list.
  factory MessageReaction.fromWire(Map<String, dynamic> wire) =>
      MessageReaction(
        id: wire['id'] as String? ?? '',
        spaceId: wire['space_id'] as String? ?? '',
        messageId: wire['message_id'] as String? ?? '',
        principalId: wire['principal_id'] as String? ?? '',
        principalType: wire['principal_type'] as String? ?? '',
        emoji: wire['emoji'] as String? ?? '',
        createdAt:
            DateTime.tryParse(wire['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  /// The reaction row id.
  final String id;

  /// The owning space.
  final String spaceId;

  /// The reacted-to message.
  final String messageId;

  /// The reacting principal's id.
  final String principalId;

  /// The reacting principal's type (`user` | `agent`).
  final String principalType;

  /// The reaction emoji.
  final String emoji;

  /// When the reaction was added.
  final DateTime createdAt;
}

/// ONE space-wide subscription backing every message's reaction chips — no
/// per-message subscriptions (PRD 16 §15 "keep it lightweight").
final spaceReactionsProvider = StreamProvider.autoDispose
    .family<List<MessageReaction>, String>((ref, spaceId) {
      final client = ref.watch(rpcClientProvider);
      return client
          .subscribe('reactions.watchForSpace', {'space_id': spaceId})
          .map((data) {
            final raw = data['reactions'];
            if (raw is! List) {
              return const <MessageReaction>[];
            }
            return [
              for (final r in raw)
                if (r is Map)
                  MessageReaction.fromWire(r.cast<String, dynamic>()),
            ];
          });
    });

/// One aggregated reaction chip: an emoji, its count and whether the current
/// user is among the reactors.
typedef ReactionChip = ({String emoji, int count, bool mine});

/// Identifies one message's reactions within a space.
typedef MessageReactionsArgs = ({String spaceId, String messageId});

/// Per-message aggregated reaction chips, derived client-side from the single
/// [spaceReactionsProvider] subscription for the space. Ordered by the
/// fixed palette first, then any other emoji by first appearance.
final messageReactionsProvider = Provider.autoDispose
    .family<List<ReactionChip>, MessageReactionsArgs>((ref, args) {
      final all =
          ref.watch(spaceReactionsProvider(args.spaceId)).value ??
          const <MessageReaction>[];
      final myUserId = ref.watch(currentUserIdProvider);

      final byEmoji = <String, List<MessageReaction>>{};
      for (final r in all) {
        if (r.messageId != args.messageId) {
          continue;
        }
        (byEmoji[r.emoji] ??= []).add(r);
      }
      if (byEmoji.isEmpty) {
        return const [];
      }
      final order = [
        ...kReactionPalette.where(byEmoji.containsKey),
        ...byEmoji.keys.where((e) => !kReactionPalette.contains(e)),
      ];
      return [
        for (final emoji in order)
          (
            emoji: emoji,
            count: byEmoji[emoji]!.length,
            mine: byEmoji[emoji]!.any(
              (r) => r.principalType == 'user' && r.principalId == myUserId,
            ),
          ),
      ];
    });

/// Toggles [emoji] on [messageId] for the current user via `reactions.toggle`.
Future<void> toggleSpaceReaction(
  RemoteRpcClient rpcClient, {
  required String spaceId,
  required String messageId,
  required String emoji,
}) {
  return rpcClient.call('reactions.toggle', {
    'space_id': spaceId,
    'message_id': messageId,
    'emoji': emoji,
  });
}
