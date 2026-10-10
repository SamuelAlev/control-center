import 'dart:collection';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:collection/collection.dart' show ListEquality;
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Queued steering cards for a conversation (the strip below the trail), in
/// delivery order.
///
/// Derived from the SAME windowed feed the trail renders — a queued card IS a
/// conversation message row — so there is no second subscription and the strip
/// cannot disagree with the feed: when the server flips a row to `injected`
/// the card leaves the strip and the bubble appears in the trail in the same
/// emission.
///
/// The window re-emits on every flush of a streaming turn, so the result is
/// value-comparable: the shared const empty list when nothing is queued (the
/// usual case) and an element-wise-equal list otherwise. Riverpod filters
/// updates with `==`, so the strip and the composer above which it docks no
/// longer rebuild per token for a queue that did not change.
final steeringQueueProvider = Provider.autoDispose
    .family<List<Message>, ConversationRef>((ref, key) {
      final window = ref.watch(spaceFeedWindowedProvider(key)).asData?.value;
      if (window == null) {
        return const <Message>[];
      }
      final queued = window.messages.where((m) => m.isSteeringQueued).toList();
      if (queued.isEmpty) {
        return const <Message>[];
      }
      queued.sort((a, b) => a.steerOrder.compareTo(b.steerOrder));
      return _SteeringQueue(queued);
    });

/// An unmodifiable queue snapshot that compares by its messages.
final class _SteeringQueue extends UnmodifiableListView<Message> {
  _SteeringQueue(List<Message> super.source) : _messages = source;

  final List<Message> _messages;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SteeringQueue &&
          const ListEquality<Message>().equals(_messages, other._messages);

  @override
  int get hashCode => const ListEquality<Message>().hash(_messages);
}

/// Whether any live run in the conversation can take mid-run steering (built-in harness).
/// False for external-CLI transports (`claude -p`, …): their cards still queue and convert
/// at run end, but a "steer now" button would promise an injection nothing can perform, so
/// the strip hides it.
/// Stamped by the composer at ENQUEUE time — the one moment the server's answer is
/// authoritative (it holds the live dispatch table) — rather than polled: the flag only
/// changes when a run starts or ends, and a per-rebuild capability read would be a
/// subscription in disguise.
class SteeringSteerableNotifier extends Notifier<bool?> {
  /// Creates a flag bound to [key].
  SteeringSteerableNotifier(this.key);

  /// The conversation this flag describes.
  final ConversationRef key;

  @override
  bool? build() => null;

  /// Overwrites the flag (the composer stamps it at enqueue time).
  void set(bool value) {
    state = value;
  }
}

/// Provides the per-conversation "a live run can inject mid-run" flag
/// (null until the server has answered for this conversation).
final steeringSteerableProvider =
    NotifierProvider.family<SteeringSteerableNotifier, bool?, ConversationRef>(
      SteeringSteerableNotifier.new,
    );

/// Edits a queued steering card server-side.
Future<bool> editSteeringCard(
  WidgetRef ref, {
  required String workspaceId,
  required ConversationRef key,
  required String messageId,
  required String content,
}) => ref
    .read(messagingServiceProvider)
    .editSteering(
      workspaceId: workspaceId,
      spaceId: key.spaceId,
      conversationId: key.conversationId,
      messageId: messageId,
      content: content,
    );

/// Deletes a queued steering card server-side.
Future<bool> deleteSteeringCard(
  WidgetRef ref, {
  required String workspaceId,
  required ConversationRef key,
  required String messageId,
}) => ref
    .read(messagingServiceProvider)
    .deleteSteering(
      workspaceId: workspaceId,
      spaceId: key.spaceId,
      conversationId: key.conversationId,
      messageId: messageId,
    );

/// Persists a manual order for the conversation's queued cards.
Future<void> reorderSteeringCards(
  WidgetRef ref, {
  required String workspaceId,
  required ConversationRef key,
  required List<String> orderedIds,
}) => ref
    .read(messagingServiceProvider)
    .reorderSteering(
      workspaceId: workspaceId,
      spaceId: key.spaceId,
      conversationId: key.conversationId,
      orderedIds: orderedIds,
    );

/// Jump-to-front delivery of a queued card ("steer now").
Future<bool> deliverSteeringCard(
  WidgetRef ref, {
  required String workspaceId,
  required ConversationRef key,
  required String messageId,
}) => ref
    .read(messagingServiceProvider)
    .deliverSteering(
      workspaceId: workspaceId,
      spaceId: key.spaceId,
      conversationId: key.conversationId,
      messageId: messageId,
    );
