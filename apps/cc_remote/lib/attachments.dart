// Phone attachment uploads use the local encrypted resource capability on
// direct and relay paths. No remote HTTP endpoint or base64 RPC upload lane.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/file_reference.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_remote/debug_log.dart';
import 'package:cc_remote/media_proxy.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

/// Largest attachment carried over the HTTP lane, matching the blob store's own
/// ceiling so the refusal happens before the bytes cross the wire.
const int kMaxAttachmentBytes = 24 * 1024 * 1024;

/// A file the person picked, held as bytes because a browser tab has nothing
/// else to hold.
class PickedAttachment {
  /// Creates a [PickedAttachment].
  const PickedAttachment({
    required this.name,
    required this.bytes,
    required this.mediaType,
  });

  /// The file's name, used as the `@[file:<name>]` reference in the message.
  final String name;

  /// The file's contents.
  final Uint8List bytes;

  /// MIME type the browser reported, or a generic fallback.
  final String mediaType;

  /// Whether this is a picture rather than some other file.
  bool get isImage => mediaType.startsWith('image/');
}

/// Opens the browser's file picker and reads what comes back.
///
/// [accept] is the input's `accept` attribute — `image/*` for the camera-roll
/// affordance, empty for anything. Returns an empty list when the person
/// cancels, which is indistinguishable from picking nothing and is treated the
/// same way.
Future<List<PickedAttachment>> pickAttachments({String accept = ''}) async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept
    ..multiple = true
    // Off-screen rather than `display: none`: some mobile browsers refuse to
    // open the picker for an input that is not laid out.
    ..style.position = 'fixed'
    ..style.left = '-10000px';
  web.document.body?.append(input);
  final done = Completer<List<PickedAttachment>>();
  // `cancel` is not delivered everywhere, so the completer is also settled by
  // `change`; whichever lands first wins and the other is ignored.
  void settle(List<PickedAttachment> value) {
    if (!done.isCompleted) {
      done.complete(value);
    }
  }

  input.onchange = (web.Event _) {
    unawaited(
      _readFiles(input).then(
        settle,
        onError: (Object e) {
          rlog('attachments', 'read failed: $e');
          settle(const []);
        },
      ),
    );
  }.toJS;
  input.oncancel = (web.Event _) {
    settle(const []);
  }.toJS;
  input.click();
  final picked = await done.future;
  input.remove();
  return picked;
}

Future<List<PickedAttachment>> _readFiles(web.HTMLInputElement input) async {
  final files = input.files;
  if (files == null) {
    return const [];
  }
  final out = <PickedAttachment>[];
  for (var i = 0; i < files.length; i++) {
    final file = files.item(i);
    if (file == null) {
      continue;
    }
    final buffer = await file.arrayBuffer().toDart;
    final bytes = buffer.toDart.asUint8List();
    if (bytes.isEmpty) {
      continue;
    }
    out.add(
      PickedAttachment(
        name: file.name,
        bytes: bytes,
        mediaType: file.type.isEmpty ? 'application/octet-stream' : file.type,
      ),
    );
  }
  return out;
}

/// Uploads one draft file and preserves the catalog identity required to claim
/// it when the message is sent. Failure never consumes the picked file.
Future<MessageAttachment> uploadAttachment({
  required PickedAttachment picked,
  required String workspaceId,
  required RemoteMediaEndpoint endpoint,
  required int order,
  http.Client? client,
}) async {
  if (!attachmentFitsLane(picked.bytes.length)) {
    throw const FormatException(
      'Attachment exceeds the encrypted upload limit',
    );
  }
  final response = await (client?.post ?? http.post)(
    Uri.parse(endpoint.blobUploadUrl(workspaceId: workspaceId)),
    headers: {
      'content-type': picked.mediaType,
      'x-cc-file-name': Uri.encodeComponent(picked.name),
    },
    body: picked.bytes,
  );
  if (response.statusCode != 200) {
    throw http.ClientException(
      'Attachment upload: HTTP ${response.statusCode}',
    );
  }
  final decoded = jsonDecode(response.body);
  final ref = decoded is Map ? decoded['ref'] : null;
  final fileId = decoded is Map ? decoded['file_id'] : null;
  if (ref is! String || fileId is! String || fileId.isEmpty) {
    throw const FormatException(
      'Upload did not return a catalog file identity',
    );
  }
  return MessageAttachment(
    id: fileId,
    fileId: fileId,
    path: ref,
    name: sanitizeFileRefName(picked.name),
    kind: picked.isImage ? AttachmentKind.image : AttachmentKind.file,
    size: picked.bytes.length,
    order: order,
    mediaType: picked.mediaType,
  );
}

/// Bounded by the server's blob store, regardless of direct or relay path.
bool attachmentFitsLane(int bytes) => bytes > 0 && bytes <= kMaxAttachmentBytes;
