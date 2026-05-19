import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';

/// Client-side port for the live turn relay (`messaging.watchChannelTurns`).
///
/// A thin client subscribes once per open channel; the stream opens with a
/// [TurnRelaySeed] carrying every in-flight turn's full snapshot, then emits
/// [TurnRelayUpdates] batches as the server's dispatch stack streams. The
/// client folds these into its local `ActiveStreamRegistry`, which the agent
/// turn bubbles already render from.
///
/// Deliberately NOT part of `MessagingRepository`: this surface exists only on
/// RPC-backed clients (the server owns the registry in-process), so a
/// dedicated port keeps the shared repository interface — and its many test
/// fakes — untouched.
abstract class ChannelTurnRelayPort {
  /// Live turn events for [channelId]: a seed frame, then update batches.
  Stream<ChannelTurnEvent> watchChannelTurns(String channelId);
}
