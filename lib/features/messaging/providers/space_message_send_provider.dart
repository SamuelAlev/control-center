import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:control_center/core/providers/media_proxy_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/utils/app_log.dart';

import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/shared/widgets/attachments/local_media.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Sends a space message, uploading anything attached to it first.
///
/// A provider rather than a helper on the composer's widget because it has TWO
/// callers that must behave identically: the input bar, and the queue that
/// parks submissions while a space is still provisioning. When the upload lived
/// on the widget, the queue flushed straight to `sendAndDispatch` and every
/// picture in a parked message was silently lost.
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
    final images = attachments.where((a) => a.isImage).toList();
    if (content.isEmpty && images.isEmpty) {
      return;
    }
    final stored = await _storeAttachments(workspaceId, attachments);
    await ref
        .read(messagingServiceProvider)
        .sendAndDispatch(
          workspaceId,
          spaceId,
          content,
          conversationId: conversationId,
          structuredMentions: structuredMentions,
          entityRefs: entityRefs,
          metadata: stored.isEmpty ? null : {'attachments': stored},
        );
  }

  /// Uploads every attachment to the host and records what came back.
  ///
  /// **Everything travels, not just pictures.** The device and the server are
  /// routinely not the same machine — a paired laptop, a phone, a VPS behind
  /// the relay — so a host path is meaningless on the far side. The bytes go
  /// up; the message keeps a content-addressed reference. That reference is
  /// also what every LATER reader resolves from: a preview opened tomorrow, or
  /// by another member, has no access to the sender's disk.
  ///
  /// The message row keeps the reference and never the bytes: an inline base64
  /// screenshot would sit in `conversation_messages` forever, in a column the
  /// FTS index reads, for content no search can match.
  ///
  /// A file too large to carry (past [_maxUploadBytes], which the store would
  /// refuse anyway) is still RECORDED, by path. It is the honest degradation:
  /// the reference stays clickable on the machine that sent it and says so
  /// nowhere else, which beats dropping it silently.
  ///
  /// Best-effort per attachment: one that fails to upload is dropped with the
  /// rest of the message still sent. Losing an attachment is bad; losing the
  /// question the person typed alongside it is worse.
  Future<List<Map<String, dynamic>>> _storeAttachments(
    String workspaceId,
    List<ComposerAttachment> attachments,
  ) async {
    if (attachments.isEmpty) {
      return const [];
    }
    // demo: NO bytes ever move. A public demo writes as little as possible to
    // its host, so every attachment is recorded by name with a `demo:` path —
    // the chip and the metadata are real, the upload is fiction. This also
    // covers a pasted screenshot, which a demo visitor can still paste.
    if (ref.read(isDemoServerProvider)) {
      return [
        for (var i = 0; i < attachments.length; i++)
          {
            'id': attachments[i].id,
            'path': 'demo/${attachments[i].label}',
            'name': attachments[i].refName ?? attachments[i].label,
            'kind': attachments[i].isImage ? 'image' : 'file',
            'mediaType':
                attachments[i].mimeType ??
                (attachments[i].isImage
                    ? 'image/png'
                    : 'application/octet-stream'),
            if (attachments[i].sizeBytes != null)
              'size': attachments[i].sizeBytes,
            'order': i,
          },
      ];
    }
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < attachments.length; i++) {
      final attachment = attachments[i];
      // The REFERENCE name, so the caption under an attachment matches the
      // word the message text points at. Two names for one attachment reads as
      // two attachments.
      final name = attachment.refName ?? attachment.label;
      final kind = attachment.isImage ? 'image' : 'file';
      final mediaType =
          attachment.mimeType ??
          (attachment.isImage ? 'image/png' : 'application/octet-stream');

      final bytes = await _bytesFor(attachment);
      if (bytes == null || bytes.isEmpty) {
        final path = attachment.path;
        if (path == null || path.isEmpty) {
          AppLog.d(
            'composer',
            'attachment $name has neither bytes nor a path; dropped',
          );
          continue;
        }
        AppLog.d('composer', 'attachment $name not uploaded; recorded by path');
        out.add({
          'id': attachment.id,
          'path': path,
          'name': name,
          'kind': kind,
          'mediaType': mediaType,
          if (attachment.sizeBytes != null) 'size': attachment.sizeBytes,
          'order': i,
        });
        continue;
      }

      final stored = await _upload(
        workspaceId: workspaceId,
        bytes: bytes,
        mediaType: mediaType,
      );
      if (stored != null) {
        out.add({
          'id': attachment.id,
          'path': stored.ref,
          'name': name,
          'kind': kind,
          'mediaType': mediaType,
          'size': stored.bytes,
          // The sender's own path, kept as a hint for the agent when it DOES
          // share this filesystem. Never the thing a preview resolves from.
          if (attachment.path != null) 'localPath': attachment.path,
          'order': i,
        });
      }
    }
    return out;
  }

  /// Largest attachment carried to the server.
  ///
  /// Matches the blob store's own ceiling, so the refusal happens here — before
  /// a file is read into memory — rather than after it has crossed the wire.
  static const int _maxUploadBytes = 24 * 1024 * 1024;

  /// The bytes to upload for [attachment], reading them off disk when the
  /// composer did not already hold them.
  ///
  /// The composer deliberately keeps only a PICTURE's bytes in memory (see
  /// `ComposerDropTarget`) — a chip on a toolbar is no reason to hold a video.
  /// Send is where that changes: this is the moment the file has to leave the
  /// machine, so it is read once, here, and bounded.
  Future<List<int>?> _bytesFor(ComposerAttachment attachment) async {
    final held = attachment.bytes;
    if (held != null && held.isNotEmpty) {
      return held;
    }
    final path = attachment.path;
    if (path == null || path.isEmpty) {
      return null;
    }
    return readLocalBytes(path, maxBytes: _maxUploadBytes);
  }

  /// Uploads one picture to the host, over whichever lane this connection has.
  ///
  /// **Two lanes, and the choice is forced by the transport, not by taste.**
  ///
  /// *HTTP (`POST /blob`)* whenever the connection has a bulk base — loopback,
  /// LAN, Tailnet, a reachable VPS. It has to be HTTP there, because those
  /// connections carry RPC over `WsRemoteTransport`, which caps a single
  /// inbound frame at 256 KB and CLOSES the connection past it. A base64
  /// screenshot on that socket never arrived: it dropped the link, the call
  /// failed, the metadata came back empty, and the message went out carrying
  /// only the filenames its text had expanded to. HTTP also spares the 33%
  /// base64 tax and a multi-megabyte JSON parse on the server's main isolate.
  ///
  /// *RPC (`blob.put`)* when there is no bulk base at all. That is the
  /// BROKERED RELAY case — a server behind NAT, reached through the signalling
  /// broker — where there is no HTTP origin to POST to. It is safe there for
  /// the same reason it was unsafe above: the relay is not a WebSocket. It runs
  /// `ChunkedRelaySession`, which splits a frame into 16 KB sealed pieces with
  /// credit-based backpressure and reassembles up to 128 MB, so a large frame
  /// is exactly what it is built to carry.
  ///
  /// The fallback is deliberately gated on "no bulk lane" rather than "HTTP
  /// failed": retrying over RPC on a WebSocket connection would push the very
  /// frame that closes the socket.
  ///
  /// Returns null (and says why in the log) rather than throwing: one picture
  /// that will not upload must not take the question the person typed with it.
  Future<({String ref, int bytes})?> _upload({
    required String workspaceId,
    required List<int> bytes,
    required String mediaType,
  }) async {
    final proxy = ref.read(mediaProxyConfigProvider);
    if (proxy == null) {
      return _uploadOverRpc(
        workspaceId: workspaceId,
        bytes: bytes,
        mediaType: mediaType,
      );
    }
    try {
      final response = await http.post(
        Uri.parse(proxy.blobUploadUrl(workspaceId: workspaceId)),
        headers: {'content-type': mediaType},
        body: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      );
      if (response.statusCode != 200) {
        AppLog.d(
          'composer',
          'image upload failed: HTTP ${response.statusCode} '
              '${response.body.trim()}',
        );
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return null;
      }
      final ref_ = decoded['ref'];
      final size = decoded['bytes'];
      if (ref_ is! String || ref_.isEmpty) {
        return null;
      }
      return (ref: ref_, bytes: size is int ? size : bytes.length);
    } on Object catch (e) {
      AppLog.d('composer', 'image upload failed: $e');
      return null;
    }
  }

  /// The relay lane: `blob.put`, carrying the bytes as base64 in a JSON-RPC
  /// argument, chunked by `ChunkedRelaySession` on the way across.
  ///
  /// Only reached on a connection with no HTTP origin — see [_upload] for why
  /// this must never be attempted on a WebSocket one.
  Future<({String ref, int bytes})?> _uploadOverRpc({
    required String workspaceId,
    required List<int> bytes,
    required String mediaType,
  }) async {
    try {
      final result = await ref.read(rpcClientProvider).call('blob.put', {
        'workspace_id': workspaceId,
        'data': base64Encode(bytes),
        'media_type': mediaType,
      });
      final blobRef = result['ref'];
      final size = result['bytes'];
      if (blobRef is! String || blobRef.isEmpty) {
        return null;
      }
      return (ref: blobRef, bytes: size is int ? size : bytes.length);
    } on Object catch (e) {
      AppLog.d('composer', 'image upload over the relay failed: $e');
      return null;
    }
  }
}

/// Provider for the space message send notifier.
final spaceMessageSendProvider =
    NotifierProvider<SpaceMessageSendNotifier, void>(
      SpaceMessageSendNotifier.new,
    );
