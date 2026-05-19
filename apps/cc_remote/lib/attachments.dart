// Attaching a picture or a file to a message from the phone.
//
// **Why the phone needs its own lane.** cc_remote is a browser PWA: there is no
// filesystem to name, so a path is not a thing it can send. Whatever is
// attached here exists only as bytes in the tab, and those bytes have to reach
// the server before the message does — otherwise the message names a file that
// exists nowhere the agent can reach, which is exactly the failure the
// desktop's upload lane exists to prevent.
//
// **Two lanes, and the transport forces the choice.**
//
// *HTTP (`POST /blob`)* whenever the pairing has an origin — LAN, tailnet, a
// reachable tunnel. It has to be HTTP there, because that connection carries
// JSON-RPC over a WebSocket whose inbound frames the server caps at 256 KB and
// CLOSES past: a base64 screenshot on that socket does not arrive late, it
// drops the link and takes the message with it.
//
// *RPC (`blob.put`)* when there is no origin at all. That is the BROKERED RELAY
// — a server behind NAT reached through the signalling broker — where there is
// no endpoint to POST to. It is safe there for the same reason it is unsafe
// above: the relay is not a WebSocket. It runs `ChunkedRelaySession`, which
// splits a frame into 16 KB sealed pieces with credit-based backpressure, so a
// large frame is precisely what it is built to carry. It is still the slow
// lane, and the ceiling here is lower than the store's to say so.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/file_reference.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_remote/debug_log.dart';
import 'package:cc_remote/media_proxy.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

/// Largest attachment carried over the HTTP lane, matching the blob store's own
/// ceiling so the refusal happens before the bytes cross the wire.
const int kMaxAttachmentBytes = 24 * 1024 * 1024;

/// Largest attachment carried over the brokered relay.
///
/// Deliberately far below [kMaxAttachmentBytes]: base64 adds a third, the relay
/// moves it in 16 KB sealed chunks, and a phone on a bad link would sit on a
/// spinner for minutes with no way to tell whether anything was happening.
/// Refusing loudly at 4 MB is the better failure.
const int kMaxRelayAttachmentBytes = 4 * 1024 * 1024;

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
    unawaited(_readFiles(input).then(settle, onError: (Object e) {
      rlog('attachments', 'read failed: $e');
      settle(const []);
    }));
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

/// Uploads [picked] and returns the attachment entries a message's metadata
/// carries, in the order they were picked.
///
/// One that will not upload is dropped and named in the log rather than taking
/// the whole send with it: losing a picture is bad, losing the question typed
/// alongside it is worse. The caller sees a short list and can say so.
Future<List<MessageAttachment>> uploadAttachments({
  required List<PickedAttachment> picked,
  required String workspaceId,
  required RemoteRpcClient client,
  required RemoteMediaEndpoint? endpoint,
}) async {
  final out = <MessageAttachment>[];
  for (var i = 0; i < picked.length; i++) {
    final attachment = picked[i];
    final ref = await _upload(
      attachment: attachment,
      workspaceId: workspaceId,
      client: client,
      endpoint: endpoint,
    );
    if (ref == null) {
      continue;
    }
    out.add(
      MessageAttachment(
        id: 'phone-$i-${attachment.name}',
        path: ref,
        // The name is what the message's `@[file:…]` token carries, so it has
        // to be a name a token CAN carry: a `]` in a filename would close the
        // reference early and the reader would never find it.
        name: sanitizeFileRefName(attachment.name),
        kind: attachment.isImage ? AttachmentKind.image : AttachmentKind.file,
        size: attachment.bytes.length,
        order: i,
        mediaType: attachment.mediaType,
      ),
    );
  }
  return out;
}

/// Whether [bytes] is small enough for the lane this connection has.
///
/// Public so the picker can refuse before anything is uploaded and say which
/// ceiling applies — "too large" is unhelpful when the limit moves with the
/// path the phone happens to be on.
bool attachmentFitsLane(int bytes, {required bool hasHttpOrigin}) =>
    bytes > 0 &&
    bytes <= (hasHttpOrigin ? kMaxAttachmentBytes : kMaxRelayAttachmentBytes);

Future<String?> _upload({
  required PickedAttachment attachment,
  required String workspaceId,
  required RemoteRpcClient client,
  required RemoteMediaEndpoint? endpoint,
}) async {
  if (!attachmentFitsLane(
    attachment.bytes.length,
    hasHttpOrigin: endpoint != null,
  )) {
    rlog(
      'attachments',
      '${attachment.name} is ${attachment.bytes.length}B — over the '
          '${endpoint != null ? 'HTTP' : 'relay'} ceiling; dropped',
    );
    return null;
  }
  if (endpoint == null) {
    return _uploadOverRpc(
      attachment: attachment,
      workspaceId: workspaceId,
      client: client,
    );
  }
  try {
    final response = await http.post(
      Uri.parse(endpoint.blobUploadUrl(workspaceId: workspaceId)),
      headers: {'content-type': attachment.mediaType},
      body: attachment.bytes,
    );
    if (response.statusCode != 200) {
      rlog(
        'attachments',
        'upload of ${attachment.name} failed: HTTP ${response.statusCode}',
      );
      return null;
    }
    final decoded = jsonDecode(response.body);
    final ref = decoded is Map ? decoded['ref'] : null;
    return ref is String && ref.isNotEmpty ? ref : null;
  } on Object catch (e) {
    rlog('attachments', 'upload of ${attachment.name} failed: $e');
    return null;
  }
}

/// The relay lane: `blob.put`, carrying the bytes as base64 in a JSON-RPC
/// argument and chunked by `ChunkedRelaySession` on the way across.
///
/// Only reached on a connection with no HTTP origin — see the library comment
/// for why this must never be attempted on a WebSocket one.
Future<String?> _uploadOverRpc({
  required PickedAttachment attachment,
  required String workspaceId,
  required RemoteRpcClient client,
}) async {
  try {
    final result = await client.call('blob.put', {
      'workspace_id': workspaceId,
      'data': base64Encode(attachment.bytes),
      'media_type': attachment.mediaType,
    });
    final ref = result['ref'];
    return ref is String && ref.isNotEmpty ? ref : null;
  } on Object catch (e) {
    rlog('attachments', 'relay upload of ${attachment.name} failed: $e');
    return null;
  }
}
