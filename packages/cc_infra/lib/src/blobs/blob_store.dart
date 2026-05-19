import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Reference prefix for a stored blob. A metadata value carrying this prefix is
/// a pointer into the store, not inline data.
const String blobRefScheme = 'blob:sha256:';

/// Builds the canonical reference for [hash].
String blobRefFor(String hash) => '$blobRefScheme$hash';

/// The sha256 hex of a `blob:sha256:<hex>` reference, or null when [ref] is not
/// one (or carries a hash that is not 64 lowercase hex characters — anything
/// else would be a path-traversal attempt, since the hash becomes a filename).
String? blobHashOf(String? ref) {
  if (ref == null || !ref.startsWith(blobRefScheme)) {
    return null;
  }
  final hash = ref.substring(blobRefScheme.length);
  return _isSha256Hex(hash) ? hash : null;
}

bool _isSha256Hex(String s) =>
    s.length == 64 && RegExp(r'^[0-9a-f]{64}$').hasMatch(s);

/// A stored blob: its content hash, canonical reference and size.
class StoredBlob {
  /// Creates a [StoredBlob].
  const StoredBlob({
    required this.hash,
    required this.ref,
    required this.bytes,
    required this.mediaType,
  });

  /// Lowercase sha256 hex of the content.
  final String hash;

  /// `blob:sha256:<hash>` — what gets persisted in message metadata.
  final String ref;

  /// Size of the stored content in bytes.
  final int bytes;

  /// The MIME type recorded alongside the content.
  final String mediaType;
}

/// Content-addressed storage for binary payloads an agent produced — today,
/// the screenshots `computer_use` / `browser_use` / `mobile_use` return.
///
/// **Why this exists.** A tool-result image arrives as base64 in the model's
/// message content. Persisting that inline would put megabytes of base64 into
/// `conversation_messages` — a row every transcript query drags along, in a
/// column FTS indexes, for content no query ever matches on. Blobs move the
/// bytes out and leave a 71-character reference behind.
///
/// **Why per workspace, not global.** A single global blob directory would
/// dedup a screenshot shared across sessions. Control Center cannot: a
/// screenshot is workspace-scoped data, and workspace isolation here is
/// structural — everything belonging to one workspace lives in that
/// workspace's directory and is deleted with it. A global store would outlive
/// the workspace whose agent produced it and would need a `WHERE`-clause
/// equivalent to keep separate, which is exactly the convention the database
/// split replaced. Dedup within a workspace still works, and that is where the
/// repeats actually are (an agent screenshotting an unchanged screen).
class BlobStore {
  /// Creates a [BlobStore] whose per-workspace directory comes from
  /// [workspaceDir].
  ///
  /// The layout is deliberately NOT computed here: `cc_infra` does not depend
  /// on `cc_persistence`, and the workspace directory convention belongs to
  /// the package that owns it (`workspaceDirPath`). The composition root
  /// supplies the resolver, so there is one definition of where a workspace's
  /// files live rather than a copy that can drift.
  ///
  /// [maxBytes] bounds a single blob; anything larger is refused rather than
  /// stored, because the caller has a text fallback and the store does not.
  BlobStore({
    required String Function(String workspaceId) workspaceDir,
    this.maxBytes = 24 * 1024 * 1024,
  }) : _workspaceDir = workspaceDir;

  final String Function(String workspaceId) _workspaceDir;

  /// Largest single blob accepted, in bytes.
  final int maxBytes;

  /// Absolute path of [workspaceId]'s blob directory.
  String directoryFor(String workspaceId) =>
      p.join(_workspaceDir(workspaceId), 'blobs');

  /// Absolute path a blob with [hash] occupies in [workspaceId].
  ///
  /// Returns null for a hash that is not 64 lowercase hex characters. The hash
  /// becomes a path segment, so this is the traversal guard: it is checked here
  /// rather than at each call site, because a call site that forgets is a
  /// filesystem escape.
  String? pathFor(String workspaceId, String hash) =>
      _isSha256Hex(hash) ? p.join(directoryFor(workspaceId), hash) : null;

  /// Stores [bytes] and returns its reference. Idempotent at the content level:
  /// writing the same bytes twice keeps one file.
  ///
  /// Returns null when the payload is empty or over [maxBytes].
  Future<StoredBlob?> put(
    String workspaceId,
    Uint8List bytes, {
    String mediaType = 'application/octet-stream',
  }) async {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      return null;
    }
    final hash = sha256.convert(bytes).toString();
    final path = pathFor(workspaceId, hash)!;
    final file = File(path);
    // Content-addressed: identical bytes are already the right bytes, so an
    // existing file is never rewritten. This also makes concurrent writes of
    // the same screenshot safe without a lock.
    if (!file.existsSync()) {
      await Directory(p.dirname(path)).create(recursive: true);
      // Write-then-rename so a crash mid-write cannot leave a truncated file
      // sitting at a name that claims to be that content's hash.
      final tmp = File('$path.${DateTime.now().microsecondsSinceEpoch}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      try {
        await tmp.rename(path);
      } on FileSystemException {
        // Lost a race with another writer of the same content — theirs is
        // byte-identical by construction, so drop ours.
        try {
          await tmp.delete();
        } on FileSystemException {
          // Nothing to clean up.
        }
      }
    }
    await _writeMeta(workspaceId, hash, mediaType);
    return StoredBlob(
      hash: hash,
      ref: blobRefFor(hash),
      bytes: bytes.length,
      mediaType: mediaType,
    );
  }

  /// Stores base64-encoded [data]. Returns null when it is not valid base64,
  /// is empty, or exceeds [maxBytes].
  Future<StoredBlob?> putBase64(
    String workspaceId,
    String data, {
    String mediaType = 'image/png',
  }) async {
    final Uint8List bytes;
    try {
      bytes = base64Decode(data);
    } on FormatException {
      return null;
    }
    return put(workspaceId, bytes, mediaType: mediaType);
  }

  /// The file holding [hash] in [workspaceId], or null when absent.
  File? fileFor(String workspaceId, String hash) {
    final path = pathFor(workspaceId, hash);
    if (path == null) {
      return null;
    }
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  /// The recorded MIME type for [hash], defaulting to `image/png` when the
  /// sidecar is missing (every blob written today is an image, and a wrong
  /// content-type is a rendering bug where a missing one is a download).
  Future<String> mediaTypeFor(String workspaceId, String hash) async {
    final path = pathFor(workspaceId, hash);
    if (path == null) {
      return 'image/png';
    }
    final meta = File('$path.type');
    try {
      if (meta.existsSync()) {
        final value = (await meta.readAsString()).trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    } on FileSystemException {
      // Fall through to the default.
    }
    return 'image/png';
  }

  /// Reads [hash]'s bytes, or null when absent.
  Future<Uint8List?> read(String workspaceId, String hash) async {
    final file = fileFor(workspaceId, hash);
    if (file == null) {
      return null;
    }
    try {
      return await file.readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  /// Total bytes currently stored for [workspaceId] (0 when none).
  int sizeOf(String workspaceId) {
    final dir = Directory(directoryFor(workspaceId));
    if (!dir.existsSync()) {
      return 0;
    }
    var total = 0;
    for (final entity in dir.listSync()) {
      if (entity is File && !entity.path.endsWith('.type')) {
        try {
          total += entity.lengthSync();
        } on FileSystemException {
          // Raced with an eviction; skip it.
        }
      }
    }
    return total;
  }

  /// Evicts least-recently-modified blobs until the workspace's total is at or
  /// below [budgetBytes]. Returns how many bytes were reclaimed.
  ///
  /// Screenshots accumulate without bound otherwise: an agent driving a browser
  /// for an hour can write hundreds of frames, and nothing in the transcript
  /// deletes them — a compacted-away tool result leaves its blob behind.
  Future<int> evictTo(String workspaceId, int budgetBytes) async {
    final dir = Directory(directoryFor(workspaceId));
    if (!dir.existsSync()) {
      return 0;
    }
    final files = <({File file, DateTime modified, int size})>[];
    var total = 0;
    for (final entity in dir.listSync()) {
      if (entity is! File || entity.path.endsWith('.type')) {
        continue;
      }
      try {
        final stat = entity.statSync();
        files.add((file: entity, modified: stat.modified, size: stat.size));
        total += stat.size;
      } on FileSystemException {
        continue;
      }
    }
    if (total <= budgetBytes) {
      return 0;
    }
    files.sort((a, b) => a.modified.compareTo(b.modified));
    var reclaimed = 0;
    for (final entry in files) {
      if (total - reclaimed <= budgetBytes) {
        break;
      }
      try {
        await entry.file.delete();
        final meta = File('${entry.file.path}.type');
        if (meta.existsSync()) {
          await meta.delete();
        }
        reclaimed += entry.size;
      } on FileSystemException {
        continue;
      }
    }
    return reclaimed;
  }

  Future<void> _writeMeta(
    String workspaceId,
    String hash,
    String mediaType,
  ) async {
    final path = pathFor(workspaceId, hash);
    if (path == null) {
      return;
    }
    try {
      await File('$path.type').writeAsString(mediaType, flush: true);
    } on FileSystemException {
      // The sidecar is an optimization; `mediaTypeFor` defaults without it.
    }
  }
}
