import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_message_send_provider.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A message the user sent while the space's workspace was still provisioning.
/// Parked until the space flips to [SpaceProvisioningStatus.ready], then
/// flushed through the normal send path.
class PendingSpaceSend {
  /// Creates a pending send.
  const PendingSpaceSend({
    required this.content,
    required this.workspaceId,
    this.structuredMentions,
    this.entityRefs,
    this.attachments = const [],
  });

  /// Message body.
  final String content;

  /// Workspace where the files were staged, even if selection changes later.
  final String workspaceId;

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
  bool _flushing = false;

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
    required String workspaceId,
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
        workspaceId: workspaceId,
        content: trimmed,
        structuredMentions: structuredMentions,
        entityRefs: entityRefs,
        attachments: [
          for (final a in attachments)
            a.copyWith(clearBytes: true, clearPath: a.fileId != null),
        ],
      ),
    ];
  }

  /// Drains catalog-backed attachments through the normal message path.
  void _flushAll() {
    if (state.isEmpty || _flushing) {
      return;
    }
    _flushing = true;
    unawaited(_flushReady());
  }

  Future<void> _flushReady() async {
    final pending = state;
    state = const [];
    try {
      for (var i = 0; i < pending.length; i++) {
        final item = pending[i];
        try {
          await ref
              .read(spaceMessageSendProvider.notifier)
              .send(
                content: item.content,
                spaceId: spaceId,
                workspaceId: item.workspaceId,
                structuredMentions: item.structuredMentions,
                entityRefs: item.entityRefs,
                attachments: item.attachments,
              );
        } on Object {
          // A failed send keeps its uploaded files and remains queued rather
          // than disappearing without a message.
          state = [...pending.skip(i), ...state];
          return;
        }
      }
    } finally {
      _flushing = false;
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
    Provider<Future<void> Function(String workspaceId, String spaceId)>((ref) {
      return RemoteMessagingRepository(
        ref.watch(rpcClientProvider),
      ).retrySpaceProvisioning;
    });

/// Stops a space's in-flight workspace preparation.
///
/// Calls `messaging.cancelSpaceProvisioning`, which KILLS the running
/// clone/fetch on the host — not merely the client's waiting — checks out no
/// further repo and flips the space to `cancelled` (from where the banner's
/// Retry re-provisions).
final cancelSpaceProvisioningProvider =
    Provider<Future<void> Function(String workspaceId, String spaceId)>((ref) {
      return RemoteMessagingRepository(
        ref.watch(rpcClientProvider),
      ).cancelSpaceProvisioning;
    });
