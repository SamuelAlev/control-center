import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';

/// Client-side port for the live turn relay (`messaging.watchSpaceTurns`).
///
/// A thin client subscribes once per open space; the stream opens with a
/// [TurnRelaySeed] carrying every in-flight turn's full snapshot, then emits
/// [TurnRelayUpdates] batches as the server's dispatch stack streams. The
/// client folds these into its local `ActiveStreamRegistry`, which the agent
/// turn bubbles already render from.
///
/// Deliberately NOT part of `MessagingRepository`: this surface exists only on
/// RPC-backed clients (the server owns the registry in-process), so a
/// dedicated port keeps the shared repository interface — and its many test
/// fakes — untouched.
abstract class SpaceTurnRelayPort {
  /// Live turn events for [spaceId]: a seed frame, then update batches.
  Stream<SpaceTurnEvent> watchSpaceTurns(String spaceId);
}
