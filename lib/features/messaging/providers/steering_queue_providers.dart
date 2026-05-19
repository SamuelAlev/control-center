import 'package:cc_domain/core/domain/entities/message.dart';
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
final steeringQueueProvider = Provider.autoDispose
    .family<List<Message>, ConversationRef>((ref, key) {
      final window = ref.watch(spaceFeedWindowedProvider(key)).asData?.value;
      if (window == null) {
        return const <Message>[];
      }
      final queued = window.messages.where((m) => m.isSteeringQueued).toList()
        ..sort((a, b) => a.steerOrder.compareTo(b.steerOrder));
      return queued;
    });

/// Whether any live run in the conversation can take mid-run steering
/// (built-in harness). False for external-CLI transports (`claude -p`, …):
/// their cards still queue and convert at run end, but a "steer now" button
/// would promise an injection nothing can perform, so the strip hides it.
///
/// Stamped by the composer at ENQUEUE time — the one moment the server's
/// answer is authoritative (it holds the live dispatch table) — rather than
/// polled: the flag only changes when a run starts or ends, and a per-rebuild
/// capability read would be a subscription in disguise.
///
/// Null is a THIRD state and not the same as false: nobody has asked yet.
/// A queued card outlives the client that typed it (a reload, a second device,
/// a card enqueued from the phone), and defaulting those to "not steerable"
/// silently retired the affordance for runs that could take it perfectly well.
/// The strip shows the button on null and the delivery call is the check: it
/// returns false when no live session took the card, and the caller says so
/// rather than pretending. Only a definite false — the server, about this
/// conversation's runs — hides it.
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
