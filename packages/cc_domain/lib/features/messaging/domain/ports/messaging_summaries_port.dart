import 'package:cc_domain/features/messaging/domain/value_objects/channel_activity.dart';

/// Client-side port for the server-computed messaging aggregates:
/// per-channel activity signals (`messaging.watchChannelActivity`).
///
/// Deliberately NOT part of `MessagingRepository`: these are read-model
/// projections that exist to keep list subscriptions off the wire; the server
/// computes them straight from SQL, and only RPC-backed clients consume them.
abstract class MessagingSummariesPort {
  /// Activity signals for every channel in the bound workspace. The
  /// [workspaceId] is informational (the host binds the authoritative
  /// workspace per session) — it keys client-side caching.
  Stream<List<ChannelActivity>> watchChannelActivity(String workspaceId);
}
