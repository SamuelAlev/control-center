import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sends messages and steering cards using already-uploaded catalog files.
class SpaceMessageSendNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Sends a message and dispatches agents.
  Future<void> send({
    required String content,
    required String spaceId,
    required String workspaceId,
    String? conversationId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    List<ComposerAttachment> attachments = const [],
  }) async {
    // An image alone is a real message — "what is wrong with this screenshot?"
    // is often typed as nothing but the screenshot — so emptiness is judged on
    // text AND attachments, not text alone.
    if (content.isEmpty && attachments.isEmpty) {
      return;
    }
    final attachmentRefs = attachmentMetadata(attachments);
    await ref
        .read(messagingServiceProvider)
        .sendAndDispatch(
          workspaceId,
          spaceId,
          content,
          conversationId: conversationId,
          structuredMentions: structuredMentions,
          entityRefs: entityRefs,
          metadata: attachmentRefs.isEmpty
              ? null
              : {'attachments': attachmentRefs},
        );
  }

  /// Converts ready draft files to catalog-backed message metadata. Repository
  /// file mentions and scratchpads stay server-side references.
  List<Map<String, dynamic>> attachmentMetadata(
    List<ComposerAttachment> attachments,
  ) {
    final demo = ref.read(isDemoServerProvider);
    return [
      for (var i = 0; i < attachments.length; i++)
        if (attachments[i].kind != 'scratchpad')
          _metadataFor(attachments[i], i, demo: demo),
    ];
  }

  Map<String, dynamic> _metadataFor(
    ComposerAttachment attachment,
    int order, {
    required bool demo,
  }) {
    final name = attachment.refName ?? attachment.label;
    final mediaType =
        attachment.mimeType ??
        (attachment.isImage ? 'image/png' : 'application/octet-stream');
    if (demo) {
      return {
        'id': attachment.id,
        'path': 'demo/${attachment.label}',
        'name': name,
        'kind': attachment.isImage ? 'image' : 'file',
        'mediaType': mediaType,
        if (attachment.sizeBytes != null) 'size': attachment.sizeBytes,
        'order': order,
      };
    }
    final fileId = attachment.fileId;
    final blobRef = attachment.blobRef;
    if (fileId != null &&
        fileId.isNotEmpty &&
        blobRef != null &&
        blobRef.startsWith('blob:sha256:') &&
        attachment.uploadState == AttachmentUploadState.ready) {
      return {
        'id': attachment.id,
        'fileId': fileId,
        'path': blobRef,
        'name': name,
        'kind': attachment.isImage ? 'image' : 'file',
        'mediaType': mediaType,
        if (attachment.sizeBytes != null) 'size': attachment.sizeBytes,
        'order': order,
      };
    }
    // The @ menu points at a server-side checkout, not this client's disk.
    if (attachment.payload?['path'] == attachment.path &&
        attachment.payload?['isDirectory'] == false &&
        attachment.path != null &&
        attachment.id == 'file:${attachment.path}') {
      return {
        'id': attachment.id,
        'path': attachment.path,
        'name': name,
        'kind': 'file',
        'mediaType': mediaType,
        'order': order,
      };
    }
    throw StateError('Attachment $name has not finished uploading');
  }
}

/// Provider for the space message send notifier.
final spaceMessageSendProvider =
    NotifierProvider<SpaceMessageSendNotifier, void>(
      SpaceMessageSendNotifier.new,
    );
