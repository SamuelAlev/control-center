// Resolving what a sent message carried — the answers, not the drawing.
//
// Split from `message_attachment_strip.dart` because two surfaces need the same
// answers and only one of them is the strip: the bubble's BODY resolves each
// inline `@[file:…]` reference here so clicking the word in the sentence opens
// exactly what clicking the card under it does. Keeping the resolution beside
// the cards would have made the text surface import the card widgets to reach
// it.
library;

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_media.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';

/// Reads the attachments off [message]'s metadata, in send order.
///
/// A one-line alias for the shared-kernel accessor, kept because it reads
/// better at the call sites in this feature and because the transcript and the
/// dispatch path must never disagree about what a message carried.
List<MessageAttachment> messageAttachmentsOf(Message message) =>
    message.attachments;

/// The host URL [attachment]'s bytes are served from, or null when it was never
/// uploaded (nothing to fetch), there is no active workspace, or the connection
/// exposes no media proxy.
///
/// Every uploaded attachment resolves through the host, whatever its type: the
/// bytes live there, and the sender's disk is not something a later reader can
/// reach.
String? messageAttachmentUrl(
  BuildContext context, {
  required MessageAttachment attachment,
  required String? workspaceId,
}) => !attachment.isUploaded || workspaceId == null || workspaceId.isEmpty
    ? null
    : MediaProxyScope.blobUrlOf(
        context,
        workspaceId: workspaceId,
        ref: attachment.path,
      );

/// [attachments] keyed by the `@[file:<name>]` name the message text points at.
///
/// Feeds the transcript's inline reference chips, so clicking the word in the
/// sentence and clicking the card above it open the same thing. A later
/// duplicate name loses to the first: within one message the composer
/// guarantees these are unique, and a hand-typed collision should resolve to
/// something rather than to nothing.
Map<String, ComposerAttachment> messageAttachmentsByRefName(
  BuildContext context, {
  required List<MessageAttachment> attachments,
  required String? workspaceId,
}) {
  final out = <String, ComposerAttachment>{};
  for (final attachment in attachments) {
    out.putIfAbsent(
      attachment.name,
      () => sentAttachmentAsComposerAttachment(
        attachment,
        url: messageAttachmentUrl(
          context,
          attachment: attachment,
          workspaceId: workspaceId,
        ),
      ),
    );
  }
  return out;
}

/// Rebuilds the composer's attachment model from what the message kept, so a
/// sent attachment opens in the SAME preview a draft one does.
ComposerAttachment sentAttachmentAsComposerAttachment(
  MessageAttachment attachment, {
  String? url,
}) => ComposerAttachment(
  // Namespaced away from the composer's own ids: this is a REPLAY of something
  // already sent, and it must never collide in the preview registry with a
  // live draft attachment that happens to share a path.
  id: 'sent:${attachment.path}',
  kind: attachment.isImage ? 'image' : 'file',
  label: attachment.name,
  // A blob reference is not a path anything can open. Only the degraded
  // never-uploaded case carries a real one, and it resolves on the sending
  // machine alone.
  path: attachment.isUploaded ? null : attachment.path,
  mimeType: attachment.mediaType ?? mediaTypeForFileName(attachment.name),
  sizeBytes: attachment.size,
  remoteUrl: url,
);
