import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cc_harness/context.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:path/path.dart' as p;

/// Durable tool-output storage, transcript-adjacent on disk.
///
/// **Why the same root as transcripts.** These outputs are the recovery half of
/// a *conversation's* transcript: a masked or truncated observation is only
/// recoverable while its original is. Putting them beside
/// `<workspaceDir>/transcripts` means deleting a workspace deletes both, the
/// same `String Function(String workspaceId)` callback serves both, and no
/// query has to remember a `workspaceId`.
///
/// **Why files and not the workspace database.** A stored output is bulk — a
/// whole build log, a whole file — written once on the hot path of a turn and
/// read rarely. The workspace database's single write connection is the thing
/// every RPC read queues behind, so a megabyte write there would tax every
/// unrelated request. On disk it is a write nobody waits on.
///
/// **Live references outrank capacity.** An entry that a persisted transcript
/// may still point at is never reclaimed to make room: at capacity the store
/// refuses the NEW write instead (`put` returns `null`, so ingestion advertises
/// no handle). Entries are removed only by [clearScope] — the host's explicit
/// retirement when a conversation's transcript is cleared — or by deleting the
/// workspace directory wholesale. There is deliberately no age-based pruning: a
/// handle is promised retrievable for as long as its transcript can be replayed,
/// and a clock cannot know when that stops.
///
/// **Identity is validated, never rewritten.** Scope ids are refused when they
/// are path-like or carry control characters, and the directory name is an
/// injective escaping of the scope (`ToolOutputScope.storageKey`), so two
/// different scopes can never share storage and no id can name a foreign one.
///
/// **Where the directory must point.** [_workspaceDir] must resolve a
/// workspace's *data* directory (the one holding its database, blobs and
/// transcripts) — never an agent-visible worktree or sandbox path. The agent
/// never receives this path, and its only handle is a read-only retrieval.
class FileToolOutputStore implements ToolOutputStore {
  /// Creates a [FileToolOutputStore].
  ///
  /// [_workspaceDir] resolves a workspace's directory — passed as a callback so
  /// this stays free of a `cc_persistence` dependency, the same seam the
  /// transcript and blob stores use. It receives the RAW workspace id (already
  /// validated); aliasing two ids onto one directory here would be a silent
  /// cross-workspace read.
  FileToolOutputStore({
    required this._workspaceDir,
    this.maxBytes = 16 * 1024 * 1024,
    this.maxEntriesPerScope = 1024,
    this.maxBytesPerScope = 128 * 1024 * 1024,
    this._newHandle = newToolOutputHandle,
  });

  final String Function(String workspaceId) _workspaceDir;

  /// Refuse to store (and to decode) a single output larger than this (UTF-8
  /// bytes).
  ///
  /// A single observation past the ceiling is compacted inline and NOT stored:
  /// `put` returns `null`, ingestion says so, and no handle is advertised. A
  /// store that accepted it anyway, or that truncated the original, would break
  /// the one promise a reference makes.
  final int maxBytes;

  /// Maximum retained outputs per conversation/agent scope.
  final int maxEntriesPerScope;

  /// Maximum retained bytes per scope, so one long conversation cannot fill the
  /// disk with originals nobody will read.
  final int maxBytesPerScope;

  final String Function() _newHandle;

  /// Per-scope admission tails: writes to one scope are serialized so two
  /// concurrent turns cannot both pass the capacity check and jointly exceed
  /// it.
  final Map<String, Future<void>> _admission = {};

  /// Per-scope retained-entry counts, seeded once from the directory.
  final Map<String, int> _entryCounts = {};

  /// Per-scope retained-byte counts, seeded once from the directory.
  final Map<String, int> _byteCounts = {};

  /// UTF-8 bytes decoded by ranged reads since construction.
  ///
  /// Observability for the bounded-access guarantee: a ranged read decodes
  /// `O(limit + indexInterval)` bytes, never the whole original, and the tests
  /// assert it rather than trusting the implementation shape.
  int decodedBytes = 0;

  @override
  Future<ToolOutputReference?> put(ToolOutputWrite write) async {
    final scopeProblem = invalidToolOutputScope(write.scope);
    if (scopeProblem != null) {
      CcInfraLog.warning('tool output store refused a scope: $scopeProblem');
      return null;
    }
    final bytes = utf8LengthOf(write.content);
    if (bytes > maxBytes) {
      CcInfraLog.warning(
        'tool output for ${write.toolName} is ${bytes ~/ 1024}KB — over the '
        '${maxBytes ~/ 1024}KB store ceiling; not stored',
      );
      return null;
    }

    final key = write.scope.key;
    final previous = _admission[key] ?? Future<void>.value();
    final gate = Completer<void>();
    _admission[key] = gate.future;
    try {
      await previous;
      return await _admit(write, bytes);
    } on Object catch (e) {
      // Storage is best-effort: a failed write costs recoverability (loudly, in
      // the compacted text), never the run.
      CcInfraLog.warning('tool output store write failed: $e');
      return null;
    } finally {
      gate.complete();
      if (identical(_admission[key], gate.future)) {
        unawaited(_admission.remove(key));
      }
    }
  }

  @override
  Future<ToolOutputReadResult> read(
    ToolOutputScope scope,
    String handle, {
    int offsetChars = 0,
    int limitChars = kToolOutputReadDefaultChars,
  }) async {
    if (!isToolOutputHandle(handle)) {
      // A handle is a name, never a path: `../../etc/passwd` never reaches the
      // filesystem as one.
      return ToolOutputReadResult.invalid('handle must look like "out_…"');
    }
    final scopeProblem = invalidToolOutputScope(scope);
    if (scopeProblem != null) {
      return ToolOutputReadResult.invalid('caller scope: $scopeProblem');
    }

    // The caller's own directory only. Scanning other scopes to answer
    // "denied" instead of "not found" would tell one run what another holds.
    final dir = _scopeDir(scope);
    if (FileSystemEntity.isLinkSync(_outputsRoot(scope.workspaceId)) ||
        FileSystemEntity.isLinkSync(dir) ||
        !Directory(dir).existsSync()) {
      return ToolOutputReadResult.notFound(handle);
    }
    final metaFile = File(p.join(dir, '$handle.json'));
    if (!metaFile.existsSync() || FileSystemEntity.isLinkSync(metaFile.path)) {
      return ToolOutputReadResult.notFound(handle);
    }

    final Map<String, dynamic> meta;
    try {
      final raw = await metaFile.readAsString();
      final decoded = raw.length > _maxMetaChars ? null : jsonDecode(raw);
      if (decoded is! Map) {
        CcInfraLog.warning('tool output metadata is unusable for $handle');
        return ToolOutputReadResult.notFound(handle);
      }
      meta = decoded.cast<String, dynamic>();
    } on Object {
      CcInfraLog.warning('tool output metadata could not be read for $handle');
      return ToolOutputReadResult.notFound(handle);
    }

    final recorded = ToolOutputScope.fromJson(
      (meta['scope'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    if (recorded != scope) {
      // Present in this scope's directory but recorded to another scope: a
      // moved or tampered entry. Refuse without naming the other scope.
      CcInfraLog.warning('tool output $handle is recorded to a foreign scope');
      return ToolOutputReadResult.denied(
        'stored entry is recorded to a different workspace/conversation/agent',
      );
    }

    final textFile = File(p.join(dir, '$handle.txt'));
    final resolvedText = _resolveInside(dir, textFile.path);
    if (resolvedText == null) {
      // Missing, a symlink, or (via a planted link in the tree) outside the
      // scope directory: none of those is a stored original we wrote.
      return ToolOutputReadResult.notFound(handle);
    }

    try {
      return ToolOutputReadResult.ok(
        _sliceFile(
          resolvedText,
          meta: meta,
          offsetChars: offsetChars,
          limitChars: limitChars,
        ),
      );
    } on Object catch (e) {
      CcInfraLog.warning('tool output read failed for $handle: $e');
      return ToolOutputReadResult.unavailable(
        'the stored output could not be read',
      );
    }
  }

  @override
  Future<void> clearScope(ToolOutputScope scope) async {
    if (invalidToolOutputScope(scope) != null) {
      return;
    }
    _resetCounts();
    if (FileSystemEntity.isLinkSync(_outputsRoot(scope.workspaceId))) {
      return;
    }
    final dir = Directory(_scopeDir(scope));
    if (!dir.existsSync() || FileSystemEntity.isLinkSync(dir.path)) {
      return;
    }
    try {
      await dir.delete(recursive: true);
    } on Object catch (e) {
      CcInfraLog.warning('tool output clear failed for ${scope.label}: $e');
    }
  }

  @override
  Future<void> clearConversation(ToolOutputScope scope) async {
    if (invalidToolOutputScope(scope) != null) {
      return;
    }
    _resetCounts();
    final root = Directory(_outputsRoot(scope.workspaceId));
    if (!root.existsSync() || FileSystemEntity.isLinkSync(root.path)) {
      return;
    }
    // Every agent scope of this conversation shares the conversation's
    // storage-key prefix; the escapes never emit `.`, so the prefix cannot
    // straddle two conversations.
    final prefix = '${scope.conversationStorageKey}.';
    try {
      for (final entity in root.listSync(followLinks: false)) {
        if (entity is! Directory ||
            FileSystemEntity.isLinkSync(entity.path) ||
            !p.basename(entity.path).startsWith(prefix)) {
          continue;
        }
        await entity.delete(recursive: true);
      }
    } on Object catch (e) {
      CcInfraLog.warning('tool output conversation clear failed: $e');
    }
  }

  void _resetCounts() {
    _entryCounts.clear();
    _byteCounts.clear();
  }

  /// The admission decision plus the write, under the scope's gate.
  Future<ToolOutputReference?> _admit(ToolOutputWrite write, int bytes) async {
    final key = write.scope.key;
    final dir = _scopeDir(write.scope);
    if (FileSystemEntity.isLinkSync(dir) ||
        FileSystemEntity.isLinkSync(p.dirname(dir))) {
      CcInfraLog.warning('tool output store refused a linked directory');
      return null;
    }
    _seedCounts(key, dir);

    final entries = _entryCounts[key] ?? 0;
    final used = _byteCounts[key] ?? 0;
    if (entries >= maxEntriesPerScope) {
      CcInfraLog.warning(
        'tool output scope ${write.scope.label} is at its retention cap '
        '($maxEntriesPerScope entries); not storing a new observation — '
        'existing handles stay readable',
      );
      return null;
    }
    if (used + bytes > maxBytesPerScope) {
      CcInfraLog.warning(
        'tool output scope ${write.scope.label} is at its retention cap '
        '(${maxBytesPerScope ~/ (1024 * 1024)}MB); not storing a new '
        'observation — existing handles stay readable',
      );
      return null;
    }

    final handle = _newHandle();
    final textPath = p.join(dir, '$handle.txt');
    final metaPath = p.join(dir, '$handle.json');
    final textStage = File('$textPath.stage');
    final metaStage = File('$metaPath.stage');
    // Both payloads land in staging files first, then both are renamed. A
    // failure anywhere before the second rename leaves no reachable handle, and
    // the rollback removes the half-published pair rather than leaving an
    // orphaned original that no metadata points at.
    try {
      // A symlinked scope directory or outputs root would let a write land
      // outside the workspace's own tree, so both are checked before creating
      // anything.
      if (FileSystemEntity.isLinkSync(dir) ||
          FileSystemEntity.isLinkSync(p.dirname(dir))) {
        CcInfraLog.warning('tool output store refused a linked directory');
        return null;
      }
      await Directory(dir).create(recursive: true);
      if (!_isRealDirectory(dir)) {
        CcInfraLog.warning('tool output scope path is not a directory');
        return null;
      }
      final index = buildUtf8Index(write.content, interval: _indexInterval);
      await textStage.writeAsString(write.content, flush: true);
      await metaStage.writeAsString(
        jsonEncode(_meta(write, handle, bytes, index.offsets, index.chars)),
        flush: true,
      );
      await textStage.rename(textPath);
      try {
        await metaStage.rename(metaPath);
      } on Object {
        await _deleteQuietly(textPath);
        rethrow;
      }
      _entryCounts[key] = entries + 1;
      _byteCounts[key] = used + bytes;
      return ToolOutputReference(
        handle: handle,
        toolName: write.toolName,
        byteLength: bytes,
        charLength: write.content.length,
      );
    } on Object {
      await _deleteQuietly(textStage.path);
      await _deleteQuietly(metaStage.path);
      rethrow;
    }
  }

  /// Decodes and slices the stored original, bounded by the byte index.
  ToolOutputChunk _sliceFile(
    String path, {
    required Map<String, dynamic> meta,
    required int offsetChars,
    required int limitChars,
  }) {
    final file = File(path);
    final actualBytes = file.lengthSync();
    final metaBytes = (meta['bytes'] as num?)?.toInt();
    final metaChars = (meta['chars'] as num?)?.toInt();
    final toolName = meta['tool'] as String? ?? '';
    final request = clampToolOutputRead(
      offsetChars: offsetChars,
      limitChars: limitChars,
    );

    final index = _readIndex(meta, metaChars, metaBytes);
    final indexUsable =
        index != null && metaBytes != null && actualBytes == metaBytes;
    if (indexUsable) {
      const interval = _indexInterval;
      final totalChars = metaChars!;
      if (request.offsetChars >= totalChars) {
        return ToolOutputChunk(
          text: '',
          offsetChars: totalChars,
          totalChars: totalChars,
          byteLength: metaBytes,
          toolName: toolName,
        );
      }
      final startSlot = request.offsetChars ~/ interval;
      final endChar = math.min(
        totalChars,
        request.offsetChars + request.limitChars,
      );
      var endSlot = (endChar + interval - 1) ~/ interval;
      // A checkpoint inside a surrogate pair points to the pair's beginning.
      // Include the next interval so the pair can be decoded in full.
      if (endSlot < index.offsets.length && index.chars[endSlot] < endChar) {
        endSlot++;
      }
      final startByte = index.offsets[startSlot];
      final endByte = endSlot >= index.offsets.length
          ? metaBytes
          : index.offsets[endSlot];
      final window = _readBytes(path, startByte, endByte);
      // Checkpoints are code-point boundaries, including when a requested
      // UTF-16 offset falls between the halves of a surrogate pair.
      final decoded = utf8.decode(window, allowMalformed: true);
      final localStart = request.offsetChars - index.chars[startSlot];
      final available = decoded.length - localStart;
      final take = math.min(request.limitChars, available < 0 ? 0 : available);
      return ToolOutputChunk(
        text: take <= 0 ? '' : decoded.substring(localStart, localStart + take),
        offsetChars: request.offsetChars,
        totalChars: totalChars,
        byteLength: metaBytes,
        toolName: toolName,
      );
    }

    // No usable index (written by an older build, a tampered length, or a
    // corrupt index): decode the whole original. Slower, but exact — and a
    // bounded ceiling keeps a tampered file from exhausting memory.
    if (actualBytes > maxBytes) {
      throw const FormatException('stored output exceeds the read ceiling');
    }
    final content = _decodeAll(path, actualBytes);
    return sliceStoredOutput(
      content,
      offsetChars: request.offsetChars,
      limitChars: request.limitChars,
      byteLength: actualBytes,
      toolName: toolName,
    );
  }

  String _decodeAll(String path, int actualBytes) {
    final bytes = _readBytes(path, 0, actualBytes);
    return utf8.decode(bytes, allowMalformed: true);
  }

  List<int> _readBytes(String path, int start, int end) {
    if (end <= start) {
      return const [];
    }
    final random = File(path).openSync();
    try {
      random.setPositionSync(start);
      final window = random.readSync(end - start);
      decodedBytes += window.length;
      return window;
    } finally {
      random.closeSync();
    }
  }

  /// The byte and UTF-16 offsets of every `k * [_indexInterval]` checkpoint,
  /// or `null` when the stored index cannot be trusted. A checkpoint between
  /// surrogate halves refers to the beginning of that pair.
  ///
  /// `null` degrades to a full decode, never to a wrong slice: the index is an
  /// optimisation, so any inconsistency means "ignore it".
  ({List<int> offsets, List<int> chars})? _readIndex(
    Map<String, dynamic> meta,
    int? metaChars,
    int? metaBytes,
  ) {
    if (metaChars == null ||
        metaChars < 0 ||
        metaBytes == null ||
        metaBytes < 0) {
      return null;
    }
    final index = (meta['index'] as Map?)?.cast<String, dynamic>();
    if (index == null || index['interval'] != _indexInterval) {
      return null;
    }
    final rawOffsets = index['offsets'];
    final rawChars = index['chars'];
    if (rawOffsets is! List || rawChars is! List) {
      return null;
    }
    final expected = 1 + metaChars ~/ _indexInterval;
    if (rawOffsets.length != expected || rawChars.length != expected) {
      return null;
    }
    final offsets = <int>[];
    final chars = <int>[];
    for (var i = 0; i < expected; i++) {
      final byte = rawOffsets[i];
      final char = rawChars[i];
      final slot = i * _indexInterval;
      if (byte is! int ||
          char is! int ||
          byte < 0 ||
          byte > metaBytes ||
          (i == 0 ? byte != 0 || char != 0 : char < slot - 1 || char > slot) ||
          (i > 0 && (byte < offsets.last || char < chars.last))) {
        return null;
      }
      offsets.add(byte);
      chars.add(char);
    }
    return (offsets: offsets, chars: chars);
  }

  Map<String, dynamic> _meta(
    ToolOutputWrite write,
    String handle,
    int bytes,
    List<int> offsets,
    List<int> chars,
  ) => {
    'handle': handle,
    'tool': write.toolName,
    'bytes': bytes,
    'chars': write.content.length,
    'isError': write.isError,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    if (write.toolUseId != null) 'toolUseId': write.toolUseId,
    'scope': write.scope.toJson(),
    'index': {'interval': _indexInterval, 'offsets': offsets, 'chars': chars},
  };

  /// `<workspaceDir(ws)>/outputs`.
  String _outputsRoot(String workspaceId) =>
      p.join(_workspaceDir(workspaceId), 'outputs');

  /// `<workspaceDir(ws)>/outputs/<scope.storageKey>`.
  String _scopeDir(ToolOutputScope scope) =>
      p.join(_outputsRoot(scope.workspaceId), scope.storageKey);

  void _seedCounts(String key, String dir) {
    if (_entryCounts.containsKey(key)) {
      return;
    }
    var entries = 0;
    var bytes = 0;
    if (FileSystemEntity.isDirectorySync(dir) &&
        !FileSystemEntity.isLinkSync(dir)) {
      try {
        for (final entity in Directory(dir).listSync(followLinks: false)) {
          if (entity is! File || !entity.path.endsWith('.txt')) {
            continue;
          }
          entries++;
          bytes += entity.lengthSync();
        }
      } on Object catch (e) {
        CcInfraLog.warning('tool output scope scan failed: $e');
      }
    }
    _entryCounts[key] = entries;
    _byteCounts[key] = bytes;
  }

  /// The canonical path of [path] when it is a real file inside [root], else
  /// `null`.
  ///
  /// Both halves matter: a symlink (even one that resolves inside) is not
  /// something this store wrote, and a link planted inside the directory must
  /// not turn a read into an arbitrary-file read.
  String? _resolveInside(String root, String path) {
    try {
      if (FileSystemEntity.isLinkSync(path)) {
        CcInfraLog.warning('tool output path is a symlink; refusing to read');
        return null;
      }
      final file = File(path);
      if (!file.existsSync()) {
        return null;
      }
      final resolvedRoot = Directory(root).resolveSymbolicLinksSync();
      final resolved = file.resolveSymbolicLinksSync();
      return p.isWithin(resolvedRoot, resolved) ? resolved : null;
    } on Object {
      return null;
    }
  }

  static bool _isRealDirectory(String path) {
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    return type == FileSystemEntityType.directory;
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (file.existsSync() && !FileSystemEntity.isLinkSync(path)) {
        await file.delete();
      }
    } on Object {
      // A staging file left behind is litter, not corruption: it is never named
      // by a handle.
    }
  }
}

/// The sparse UTF-8 index granularity (characters between checkpoints).
///
/// 4096 balances two costs: the index costs one `int` per 4096 chars in the
/// metadata file, and a ranged read decodes at most one interval before the
/// requested range plus one after it — so a 12000-char slice of a 16MB original
/// touches ~20KB instead of 16MB.
const int _indexInterval = 4096;

/// A metadata file larger than this is not one this store wrote.
const int _maxMetaChars = 8 * 1024 * 1024;

/// Byte offsets and UTF-16 positions of every `interval`-th code unit of
/// [content]. A checkpoint between surrogate halves points to the beginning
/// of the pair: there is no UTF-8 byte boundary between those code units.
///
/// One pass, no intermediate strings: the same walk yields the total byte
/// length, so the index costs no extra encode.
({int bytes, List<int> offsets, List<int> chars}) buildUtf8Index(
  String content, {
  int interval = _indexInterval,
}) {
  if (interval < 1) {
    throw ArgumentError.value(interval, 'interval', 'must be positive');
  }
  final offsets = <int>[0];
  final chars = <int>[0];
  var bytes = 0;
  var i = 0;
  var nextCheckpoint = interval;
  while (i < content.length) {
    final startChar = i;
    final startByte = bytes;
    final unit = content.codeUnitAt(i);
    if (unit < 0x80) {
      bytes += 1;
    } else if (unit < 0x800) {
      bytes += 2;
    } else if (unit >= 0xD800 &&
        unit <= 0xDBFF &&
        i + 1 < content.length &&
        content.codeUnitAt(i + 1) >= 0xDC00 &&
        content.codeUnitAt(i + 1) <= 0xDFFF) {
      bytes += 4;
      i++;
    } else {
      // The UTF-8 encoder replaces an unpaired surrogate with U+FFFD.
      bytes += 3;
    }
    i++;
    while (nextCheckpoint <= i) {
      final splitPair = nextCheckpoint < i;
      offsets.add(splitPair ? startByte : bytes);
      chars.add(splitPair ? startChar : i);
      nextCheckpoint += interval;
    }
  }
  return (bytes: bytes, offsets: offsets, chars: chars);
}
