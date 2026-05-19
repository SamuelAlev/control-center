import 'dart:async';

import 'package:control_center/core/providers/media_proxy_provider.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/utils/write_stream_to_file.dart'
    as writer;
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// What became of a backup download.
enum BackupDownloadOutcome {
  /// Written to a path the person chose.
  saved,

  /// Handed to the browser, which saves it wherever it saves things. The web
  /// build has no writable path to offer — there is no file picker that returns
  /// one — so the honest report is "your browser has it", not a fake path.
  handedToBrowser,

  /// The save dialog was dismissed.
  cancelled,
}

/// The result of a download: what happened, and where it landed when there is
/// a place to name.
typedef BackupDownload = ({BackupDownloadOutcome outcome, String? path});

/// Reports how much of a transfer has moved. [total] is null when the server
/// did not declare a length — a progress bar then has to be indeterminate
/// rather than guess a denominator.
typedef BackupProgress = void Function(int transferred, int? total);

/// Whether this client can move backup bytes at all.
///
/// False on a relay-only connection, where the RPC socket rides the broker and
/// there is no HTTP origin to reach — the same lane the composer's image upload
/// degrades on. The UI disables the transfer controls and says why rather than
/// offering a button that cannot work.
final backupTransferAvailableProvider = Provider<bool>(
  (ref) => ref.watch(mediaProxyConfigProvider) != null,
);

/// Moves backup bytes between this device and the server.
final backupTransferProvider = Provider<BackupTransfer>(BackupTransfer.new);

/// Downloads backups to this device and uploads one back to be restored.
///
/// The RPC ops (`workspace.export`, `workspace.import`) speak in paths on the
/// SERVER, which is a complete answer only when the server is this machine.
/// This is the lane for every other topology: bytes over the same signed HTTP
/// surface the media proxy and blob store already use, so a backup taken by a
/// box in a rack can be collected onto a laptop, and a file on that laptop can
/// be handed back to restore from.
class BackupTransfer {
  /// Creates a [BackupTransfer] bound to [_ref].
  BackupTransfer(this._ref);

  final Ref _ref;

  /// Overridable HTTP client seam, so tests drive the transfer without a socket.
  static http.Client Function() clientFactory = http.Client.new;

  /// Where a saved download goes, as a path — or null when the person dismissed
  /// the dialog. A seam for the same reason [clientFactory] is one: a test has
  /// no native save dialog to answer, and reaching into the platform singleton
  /// to fake one leaks into every other test in the process.
  static Future<String?> Function(String suggestedName) chooseSaveLocation =
      _nativeSaveLocation;

  static Future<String?> _nativeSaveLocation(String suggestedName) async =>
      (await getSaveLocation(suggestedName: suggestedName))?.path;

  MediaProxyConfig get _proxy {
    final proxy = _ref.read(mediaProxyConfigProvider);
    if (proxy == null) {
      // Guarded by [backupTransferAvailableProvider] at every call site; this
      // is the backstop, not the message a person is meant to read.
      throw StateError(
        'This connection has no HTTP lane, so backup files cannot be '
        'transferred over it.',
      );
    }
    return proxy;
  }

  /// Downloads [workspaceId]'s database to a location the person picks.
  Future<BackupDownload> downloadWorkspace({
    required String workspaceId,
    required String suggestedName,
    BackupProgress? onProgress,
  }) => _download(
    url: _proxy.backupWorkspaceUrl(workspaceId: workspaceId),
    suggestedName: suggestedName,
    onProgress: onProgress,
  );

  /// Downloads install snapshot [name] as one archive.
  Future<BackupDownload> downloadSnapshot({
    required String name,
    BackupProgress? onProgress,
  }) => _download(
    url: _proxy.backupSnapshotUrl(name: name),
    suggestedName: '$name.zip',
    onProgress: onProgress,
  );

  /// Uploads [file] and has the server adopt it as [workspaceId]'s database.
  ///
  /// Streamed rather than buffered: a workspace database is not a screenshot,
  /// and reading one into the client's heap to post it would put the whole
  /// history in memory on a phone. Throws with the server's own sentence when
  /// it refuses the file — "this is not a workspace database" is the only
  /// useful thing to say, and only the server can say it.
  Future<void> restoreFromFile({
    required String workspaceId,
    required XFile file,
    BackupProgress? onProgress,
  }) async {
    final client = clientFactory();
    try {
      final request = http.StreamedRequest(
        'POST',
        Uri.parse(_proxy.backupRestoreUrl(workspaceId: workspaceId)),
      )..headers['content-type'] = 'application/octet-stream';
      final total = await file.length();
      request.contentLength = total;

      // The send and the body have to run concurrently — `send` completes only
      // once the response arrives, which cannot happen until the sink closes.
      final pending = client.send(request);
      unawaited(
        request.sink
            // Counted as it is handed to the socket, which is as close to "sent"
            // as this layer can honestly get: the OS buffers underneath, so the
            // bar reaching full means the bytes are gone from here, not that the
            // server has them. The response is what says that.
            .addStream(_counted(file.openRead(), total, onProgress))
            .whenComplete(request.sink.close),
      );
      final response = await pending;
      final body = await response.stream.bytesToString();
      if (response.statusCode != 200) {
        throw _failure(response.statusCode, body);
      }
    } finally {
      client.close();
    }
  }

  Future<BackupDownload> _download({
    required String url,
    required String suggestedName,
    BackupProgress? onProgress,
  }) async {
    if (kIsWeb) {
      // No writable path exists in a browser tab, and the response already
      // carries `Content-Disposition: attachment` — so the browser's own
      // download machinery is not a fallback here, it is the mechanism.
      openExternalUrl(url);
      return (outcome: BackupDownloadOutcome.handedToBrowser, path: null);
    }

    final path = await chooseSaveLocation(suggestedName);
    if (path == null) {
      return (outcome: BackupDownloadOutcome.cancelled, path: null);
    }

    final client = clientFactory();
    try {
      final response = await client.send(http.Request('GET', Uri.parse(url)));
      if (response.statusCode != 200) {
        throw _failure(
          response.statusCode,
          await response.stream.bytesToString(),
        );
      }
      // Piped to disk as it arrives. Collecting it first would mean holding a
      // whole install's databases in memory to write them out again.
      await writeFile(
        _counted(response.stream, response.contentLength, onProgress),
        path,
      );
      return (outcome: BackupDownloadOutcome.saved, path: path);
    } finally {
      client.close();
    }
  }

  /// Wraps [source], reporting how much has flowed through it.
  ///
  /// Throttled on purpose. A 2 GB file arrives in tens of thousands of chunks,
  /// and a `setState` per chunk is tens of thousands of rebuilds to move one
  /// bar a fraction of a pixel — the transfer would spend more time painting
  /// than transferring. One update per [_progressInterval] is already past what
  /// a person can read, and the final count is always emitted so the bar lands
  /// on full instead of stopping at whatever the last tick caught.
  Stream<List<int>> _counted(
    Stream<List<int>> source,
    int? total,
    BackupProgress? onProgress,
  ) async* {
    if (onProgress == null) {
      yield* source;
      return;
    }
    var transferred = 0;
    var lastReport = DateTime.now();
    onProgress(0, total);
    await for (final chunk in source) {
      transferred += chunk.length;
      final now = DateTime.now();
      if (now.difference(lastReport) >= _progressInterval) {
        lastReport = now;
        onProgress(transferred, total);
      }
      yield chunk;
    }
    onProgress(transferred, total);
  }

  /// How often a transfer reports progress.
  static const Duration _progressInterval = Duration(milliseconds: 100);

  /// Turns a failed response into something the UI can localize.
  ///
  /// Deliberately not prose. A 403 here means a specific missing role and a
  /// 404 means the host has no backup surface at all, and both sentences belong
  /// in the l10n table with every other user-facing string — a provider has no
  /// BuildContext to write them from.
  BackupTransferException _failure(int status, String body) {
    final trimmed = body.trim();
    return BackupTransferException(
      statusCode: status,
      // The restore route answers with the adopter's own message ("this is not
      // a workspace database"), which is the only useful thing to say and the
      // only thing the server knows. Bounded: a stray HTML error page is not a
      // sentence to put in a toast.
      serverMessage: trimmed.isNotEmpty && trimmed.length < 500 ? trimmed : null,
    );
  }
}

/// A backup transfer the server refused.
///
/// Carries the status and, when the server said something worth repeating, its
/// own message. The UI decides the words; see `describeBackupTransferError`.
class BackupTransferException implements Exception {
  /// Creates a [BackupTransferException].
  const BackupTransferException({required this.statusCode, this.serverMessage});

  /// The HTTP status the server answered with.
  final int statusCode;

  /// The server's own explanation, when it gave one.
  final String? serverMessage;

  @override
  String toString() => serverMessage ?? 'HTTP $statusCode';
}

/// How a saved download reaches the disk. Overridable so a test can assert the
/// bytes that arrived without owning a writable path.
Future<void> Function(Stream<List<int>>, String) writeFile =
    writer.writeStreamToFile;
