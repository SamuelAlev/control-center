import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_message_send_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A message the user sent while the space's workspace was still provisioning.
/// Parked until the space flips to [SpaceProvisioningStatus.ready], then
/// flushed through the normal send path.
class PendingSpaceSend {
  /// Creates a pending send.
  const PendingSpaceSend({
    required this.content,
    this.structuredMentions,
    this.entityRefs,
    this.attachments = const [],
  });

  /// Message body.
  final String content;

  /// `@agent` mentions parsed from the composer.
  final List<StructuredMention>? structuredMentions;

  /// `#entity` refs parsed from the composer.
  final List<EntityRef>? entityRefs;

  /// Files and pictures attached to the submission.
  ///
  /// Parked with the words rather than dropped: a message queued behind
  /// provisioning used to arrive later with its text intact and its screenshots
  /// gone, which reads to the agent as a question about pictures nobody sent.
  final List<ComposerAttachment> attachments;
}

/// In-memory, per-space queue of messages typed while the space's
/// conversation workspace is still provisioning (repos + overlay + `.mcp.json`).
///
/// The user types freely; submissions are parked here instead of dispatched.
/// When the space's provisioning status transitions to `ready`, the entire
/// queue drains through the normal send path. While `failed`, the queue holds
/// (the banner's Retry re-provisions and once that succeeds the queue flushes).
///
/// Kept alive (not auto-disposed) so a queued message still sends even if the
/// user navigates away before provisioning completes.
class PendingSpaceSendsNotifier extends Notifier<List<PendingSpaceSend>> {
  /// Creates a queue bound to [spaceId].
  PendingSpaceSendsNotifier(this.spaceId);

  /// The space this queue belongs to.
  final String spaceId;

  @override
  List<PendingSpaceSend> build() {
    ref.listen<SpaceProvisioningStatus>(
      spaceProvisioningStatusProvider(spaceId),
      (prev, next) {
        if (next == SpaceProvisioningStatus.ready &&
            prev != SpaceProvisioningStatus.ready) {
          _flushAll();
        }
      },
    );
    return const [];
  }

  /// Parks a submission to be dispatched when the space is ready.
  void enqueue({
    required String content,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    List<ComposerAttachment> attachments = const [],
  }) {
    final trimmed = content.trim();
    // Emptiness is judged on text AND attachments, the same way the send path
    // judges it: a parked message that is nothing but a screenshot is still a
    // message.
    if (trimmed.isEmpty && attachments.isEmpty) {
      return;
    }
    state = [
      ...state,
      PendingSpaceSend(
        content: trimmed,
        structuredMentions: structuredMentions,
        entityRefs: entityRefs,
        attachments: attachments,
      ),
    ];
  }

  /// Drains the queue through the SAME send path the input bar uses.
  ///
  /// Not `sendAndDispatch` directly: that skips the blob upload, so every
  /// picture in a parked message reached the agent as a filename and nothing
  /// else.
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
            .read(spaceMessageSendProvider.notifier)
            .send(
              content: item.content,
              spaceId: spaceId,
              workspaceId: workspaceId,
              structuredMentions: item.structuredMentions,
              entityRefs: item.entityRefs,
              attachments: item.attachments,
            ),
      );
    }
  }
}

/// Per-space pending-send state (see [PendingSpaceSendsNotifier]).
final pendingSpaceSendsProvider =
    NotifierProvider.family<
      PendingSpaceSendsNotifier,
      List<PendingSpaceSend>,
      String
    >(PendingSpaceSendsNotifier.new);

/// Triggers a host-side re-provision of a space's workspace after a failure.
/// Calls `messaging.retrySpaceProvisioning`, which re-runs the background
/// worktree + overlay + `.mcp.json` setup and flips the status back to
/// `provisioning` → `ready`/`failed`.
final retrySpaceProvisioningProvider =
    Provider<Future<void> Function(String spaceId)>((ref) {
      return (spaceId) => ref.read(rpcClientProvider).call(
        'messaging.retrySpaceProvisioning',
        {'space_id': spaceId},
      );
    });

/// Stops a space's in-flight workspace preparation.
///
/// Calls `messaging.cancelSpaceProvisioning`, which KILLS the running
/// clone/fetch on the host — not merely the client's waiting — checks out no
/// further repo and flips the space to `cancelled` (from where the banner's
/// Retry re-provisions).
final cancelSpaceProvisioningProvider =
    Provider<Future<void> Function(String spaceId)>((ref) {
      return (spaceId) => ref.read(rpcClientProvider).call(
        'messaging.cancelSpaceProvisioning',
        {'space_id': spaceId},
      );
    });
