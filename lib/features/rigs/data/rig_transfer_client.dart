// The client half of a rig's clipboard and file lanes.
//
// These ride HTTP, not RPC, and that is not a style choice: the RPC socket
// closes a connection on an inbound frame over 256 KB (a DoS guard that is
// right for JSON commands), so a pasted screenshot on that lane would not be
// slow — it would drop the whole session. Bytes go the same way rig frames,
// meeting audio and proxied media already go.
//
// Everything here talks to `cc_server`, never to a guest: the client has no
// route to a VM and no business having one. It hands the server bytes and
// gets bytes back, and the server owns every decision about where they land.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_file_transfer.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:http/http.dart' as http;

/// One file on its way into a guest, as the client holds it.
///
/// A separate type from `RigFilePayload` (which is the SERVER's shape) only
/// because the client never needs its validation — the server re-checks every
/// limit, and duplicating them here would mean two places to keep in step.
class RigOutgoingFile {
  /// Creates a [RigOutgoingFile].
  const RigOutgoingFile({
    required this.name,
    required this.bytes,
    this.mediaType,
  });

  /// The file's name as the host knew it.
  final String name;

  /// Its contents.
  final Uint8List bytes;

  /// MIME type when the drop reported one.
  final String? mediaType;
}

/// The outcome of a clipboard write.
class RigTransferAck {
  /// Creates a [RigTransferAck].
  const RigTransferAck({required this.ok, required this.summary});

  /// A failure with a sentence to show.
  factory RigTransferAck.failed(String summary) =>
      RigTransferAck(ok: false, summary: summary);

  /// Whether it landed.
  final bool ok;

  /// What happened, in one line, written for a person.
  final String summary;
}

/// Reads and writes a rig's clipboard and files over the server's transfer
/// lanes.
class RigTransferClient {
  /// Creates a [RigTransferClient] against [proxy]'s server.
  RigTransferClient({required this.proxy, http.Client? client})
    : _client = client ?? http.Client();

  /// The connected server's proxy config, which mints and signs every URL
  /// this client uses.
  final MediaProxyConfig proxy;
  final http.Client _client;

  /// The deadline for a clipboard round trip.
  ///
  /// Longer than it looks because of what is behind it: the server asks the
  /// GUEST, whose X selection owner may be an application that is busy. The
  /// guest gives up at 4s and the server at 12s, so anything shorter here
  /// would report a timeout for a request that was still going to succeed.
  static const Duration _clipboardTimeout = Duration(seconds: 20);

  /// The deadline for a file transfer. Generous: this is a real copy into a
  /// virtual machine, and the ceiling is a 256 MB file.
  static const Duration _filesTimeout = Duration(minutes: 6);

  /// Reads [selection] off the rig's clipboard, or null when it could not be
  /// read at all (no server, no such rig, a transport failure).
  ///
  /// Null and [RigClipboardData.empty] are different answers and the caller
  /// wants both: empty means "nothing has been copied in there", null means
  /// "we could not ask".
  Future<RigClipboardData?> readClipboard({
    required String workspaceId,
    required String rigId,
    RigClipboardSelection selection = RigClipboardSelection.clipboard,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              proxy.rigClipboardUrl(
                workspaceId: workspaceId,
                rigId: rigId,
                selection: selection.wire,
              ),
            ),
          )
          .timeout(_clipboardTimeout);
      if (response.statusCode != 200) {
        AppLog.d(
          'rig-transfer',
          'clipboard read for $rigId returned ${response.statusCode}',
        );
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return RigClipboardData.fromJson(decoded);
    } on Object catch (e) {
      AppLog.d('rig-transfer', 'clipboard read for $rigId failed: $e');
      return null;
    }
  }

  /// Puts [data] on the rig's clipboard.
  Future<RigTransferAck> writeClipboard({
    required String workspaceId,
    required String rigId,
    required RigClipboardData data,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(
              proxy.rigClipboardUrl(workspaceId: workspaceId, rigId: rigId),
            ),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(data.toJson()),
          )
          .timeout(_clipboardTimeout);
      if (response.statusCode != 200) {
        return RigTransferAck.failed(
          'The machine did not accept the paste (HTTP '
          '${response.statusCode}).',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const RigTransferAck(ok: true, summary: '');
      }
      return RigTransferAck(
        ok: decoded['ok'] as bool? ?? false,
        summary: decoded['summary'] is String
            ? decoded['summary'] as String
            : '',
      );
    } on Object catch (e) {
      AppLog.d('rig-transfer', 'clipboard write for $rigId failed: $e');
      return RigTransferAck.failed('The paste could not be sent: $e');
    }
  }

  /// Copies [files] into the rig, delivering them as a drop at ([x], [y])
  /// when the surface can do that.
  Future<RigDropResult> dropFiles({
    required String workspaceId,
    required String rigId,
    required List<RigOutgoingFile> files,
    int? x,
    int? y,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(
              proxy.rigFilesUrl(workspaceId: workspaceId, rigId: rigId),
            ),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({
              'files': [
                for (final f in files)
                  {
                    'name': f.name,
                    'bytes': base64Encode(f.bytes),
                    if (f.mediaType != null) 'media_type': f.mediaType,
                  },
              ],
              'x': ?x,
              'y': ?y,
            }),
          )
          .timeout(_filesTimeout);
      if (response.statusCode != 200) {
        return RigDropResult.error(
          'The machine did not accept the files (HTTP '
          '${response.statusCode}).',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return RigDropResult.error('The machine answered unintelligibly.');
      }
      return RigDropResult.fromJson(decoded);
    } on Object catch (e) {
      AppLog.d('rig-transfer', 'drop into $rigId failed: $e');
      return RigDropResult.error('The files could not be copied in: $e');
    }
  }

  /// Reads the file at [guestPath] out of the rig, or null when it is not
  /// readable.
  Future<Uint8List?> readFile({
    required String workspaceId,
    required String rigId,
    required String guestPath,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              proxy.rigFilesUrl(
                workspaceId: workspaceId,
                rigId: rigId,
                guestPath: guestPath,
              ),
            ),
          )
          .timeout(_filesTimeout);
      if (response.statusCode != 200) {
        AppLog.d(
          'rig-transfer',
          'file read of $guestPath returned ${response.statusCode}',
        );
        return null;
      }
      return response.bodyBytes;
    } on Object catch (e) {
      AppLog.d('rig-transfer', 'file read of $guestPath failed: $e');
      return null;
    }
  }

  /// Releases the underlying HTTP client.
  void close() => _client.close();
}
