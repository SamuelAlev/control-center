import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A message the user sent while the channel's workspace was still provisioning.
/// Parked until the channel flips to [ChannelProvisioningStatus.ready], then
/// flushed through the normal send path.
class PendingChannelSend {
  /// Creates a pending send.
  const PendingChannelSend({
    required this.content,
    this.structuredMentions,
    this.entityRefs,
  });

  /// Message body.
  final String content;

  /// `@agent` mentions parsed from the composer.
  final List<StructuredMention>? structuredMentions;

  /// `#entity` refs parsed from the composer.
  final List<EntityRef>? entityRefs;
}

/// In-memory, per-channel queue of messages typed while the channel's
/// conversation workspace is still provisioning (repos + overlay + `.mcp.json`).
///
/// The user types freely; submissions are parked here instead of dispatched.
/// When the channel's provisioning status transitions to `ready`, the entire
/// queue drains through the normal send path. While `failed`, the queue holds
/// (the banner's Retry re-provisions and once that succeeds the queue flushes).
///
/// Kept alive (not auto-disposed) so a queued message still sends even if the
/// user navigates away before provisioning completes.
class PendingChannelSendsNotifier extends Notifier<List<PendingChannelSend>> {
  /// Creates a queue bound to [channelId].
  PendingChannelSendsNotifier(this.channelId);

  /// The channel this queue belongs to.
  final String channelId;

  @override
  List<PendingChannelSend> build() {
    ref.listen<ChannelProvisioningStatus>(
      channelProvisioningStatusProvider(channelId),
      (prev, next) {
        if (next == ChannelProvisioningStatus.ready &&
            prev != ChannelProvisioningStatus.ready) {
          _flushAll();
        }
      },
    );
    return const [];
  }

  /// Parks a submission to be dispatched when the channel is ready.
  void enqueue({
    required String content,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
  }) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }
    state = [
      ...state,
      PendingChannelSend(
        content: trimmed,
        structuredMentions: structuredMentions,
        entityRefs: entityRefs,
      ),
    ];
  }

  void _flushAll() {
    if (state.isEmpty) {
      return;
    }
    final workspaceId = ref.requireWorkspaceId();
    final pending = state;
    state = const [];
    for (final item in pending) {
      unawaited(
        ref
            .read(messagingServiceProvider)
            .sendAndDispatch(
              workspaceId,
              channelId,
              item.content,
              structuredMentions: item.structuredMentions,
              entityRefs: item.entityRefs,
            ),
      );
    }
  }
}

/// Per-channel pending-send state (see [PendingChannelSendsNotifier]).
final pendingChannelSendsProvider =
    NotifierProvider.family<
      PendingChannelSendsNotifier,
      List<PendingChannelSend>,
      String
    >(PendingChannelSendsNotifier.new);

/// Triggers a host-side re-provision of a channel's workspace after a failure.
/// Calls `messaging.retryChannelProvisioning`, which re-runs the background
/// worktree + overlay + `.mcp.json` setup and flips the status back to
/// `provisioning` → `ready`/`failed`.
final retryChannelProvisioningProvider =
    Provider<Future<void> Function(String channelId)>((ref) {
      return (channelId) => ref.read(rpcClientProvider).call(
        'messaging.retryChannelProvisioning',
        {'channel_id': channelId},
      );
    });
