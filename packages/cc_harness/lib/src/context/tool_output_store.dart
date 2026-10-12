/// The port for durable tool-output storage, plus the two shipped
/// implementations a host does not have to write.
///
/// **The seam this replaces.** Before this, an over-long tool output was cut in
/// the loop and the dropped text existed only in the UI event
/// (`LoopToolCallResult`) — the model could never get it back. The contract
/// here is deliberately narrow so the loop can hold it: `put` an original,
/// `read` a bounded slice of it by handle, nothing more.
///
/// **Failure is a first-class outcome.** [ToolOutputStore.put] returns `null`
/// — never a fabricated handle — when it could not store (no store wired, no
/// workspace scope, I/O error, output past the store's ceiling). Callers then
/// compact inline and say the original was not stored. A store that throws
/// instead would make an efficiency feature into a run-ending failure, which is
/// the wrong trade for an observation nobody has lost yet.
///
/// This file imports the tool context only to derive a scope; it is not
/// imported by the message layer, so no cycle is introduced.
library;

import 'dart:convert';
import 'dart:math';

import 'package:cc_harness/src/context/tool_output_reference.dart';
import 'package:cc_harness/src/tools/tool.dart';

/// The write half of the port: what to store and whose it is.
class ToolOutputWrite {
  /// Creates a [ToolOutputWrite].
  const ToolOutputWrite({
    required this.scope,
    required this.toolName,
    required this.content,
    this.isError = false,
    this.toolUseId,
  });

  /// The run scope the handle will be bound to.
  final ToolOutputScope scope;

  /// The tool that produced the output.
  final String toolName;

  /// The exact original text (never a compacted copy — that is the point).
  final String content;

  /// Whether the tool reported an error.
  final bool isError;

  /// The tool call this observation answers, when known (provenance for
  /// post-hoc inspection of the store).
  final String? toolUseId;
}

/// One bounded slice of a stored output.
class ToolOutputChunk {
  /// Creates a [ToolOutputChunk].
  const ToolOutputChunk({
    required this.text,
    required this.offsetChars,
    required this.totalChars,
    required this.byteLength,
    this.toolName = '',
  });

  /// The exact substring `[offsetChars, offsetChars + text.length)` of the
  /// original.
  final String text;

  /// Where in the original this slice starts (UTF-16 code units).
  final int offsetChars;

  /// The original's total length (UTF-16 code units).
  final int totalChars;

  /// The original's total length in UTF-8 bytes.
  final int byteLength;

  /// The tool that produced the stored output (provenance for the header the
  /// retrieval tool prints), when the store knows it.
  final String toolName;

  /// Whether the original continues past this slice.
  bool get hasMore => offsetChars + text.length < totalChars;

  /// The offset to pass to continue exactly where this slice ended.
  int get nextOffsetChars => offsetChars + text.length;
}

/// Outcome of a ranged read.
enum ToolOutputReadStatus {
  /// The slice is in [ToolOutputReadResult.chunk].
  ok,

  /// No such handle in this store (never written, or pruned).
  notFound,

  /// The handle exists but belongs to a different
  /// workspace/conversation/agent. Distinct from [notFound] on purpose: a
  /// denial is the isolation boundary working, and it must not read as a
  /// harmless typo.
  denied,

  /// No store is wired (retrieval is off for this run).
  unavailable,

  /// The handle is structurally invalid (wrong shape, path-like, too long).
  invalid,
}

/// Result of [ToolOutputStore.read].
class ToolOutputReadResult {
  /// A successful slice.
  const ToolOutputReadResult.ok(ToolOutputChunk this.chunk)
    : status = ToolOutputReadStatus.ok,
      message = null;

  /// A handle that is not in this store.
  ToolOutputReadResult.notFound(String handle)
    : status = ToolOutputReadStatus.notFound,
      chunk = null,
      message = 'no stored output for handle "$handle"';

  /// A handle bound to another scope.
  ToolOutputReadResult.denied(String detail)
    : status = ToolOutputReadStatus.denied,
      chunk = null,
      message = detail;

  /// No store wired.
  ToolOutputReadResult.unavailable(String detail)
    : status = ToolOutputReadStatus.unavailable,
      chunk = null,
      message = detail;

  /// Structurally invalid handle.
  ToolOutputReadResult.invalid(String detail)
    : status = ToolOutputReadStatus.invalid,
      chunk = null,
      message = detail;

  /// The outcome.
  final ToolOutputReadStatus status;

  /// The slice, when [status] is [ToolOutputReadStatus.ok].
  final ToolOutputChunk? chunk;

  /// Why the read failed, for the model-facing message.
  final String? message;

  /// Whether the read succeeded.
  bool get isOk => status == ToolOutputReadStatus.ok;
}

/// Durable storage for original tool outputs, addressed by opaque handle.
abstract class ToolOutputStore {
  /// Stores [write]'s original text and returns its handle, or `null` when the
  /// output was NOT stored.
  ///
  /// Implementations must not throw for expected failures (no scope, too
  /// large, at capacity, I/O error): return `null` and log. A `null` result is
  /// the caller's signal to say "original not stored" and never to advertise a
  /// handle.
  ///
  /// A store MUST NOT reclaim an entry that may still be referenced by a live
  /// or resumable transcript: at capacity it refuses the NEW write instead.
  /// Entries leave only through [clearScope] (explicit retirement) or by
  /// deleting the workspace's directory wholesale.
  Future<ToolOutputReference?> put(ToolOutputWrite write);

  /// Reads at most [limitChars] chars of the original at [offsetChars].
  ///
  /// Must answer from the caller's own [scope] only and must NOT scan other
  /// scopes to classify the failure: a handle that is not in [scope] is
  /// [ToolOutputReadStatus.notFound] — telling a run what another run holds
  /// leaks the other run's existence. A read of an entry that is present in
  /// [scope] but recorded to a different scope (a moved/tampered file) is
  /// [ToolOutputReadStatus.denied].
  Future<ToolOutputReadResult> read(
    ToolOutputScope scope,
    String handle, {
    int offsetChars = 0,
    int limitChars = kToolOutputReadDefaultChars,
  });

  /// Removes everything stored for [scope].
  ///
  /// The explicit retirement path: the host calls it when a conversation's
  /// transcript is cleared or the conversation ends, i.e. when no live
  /// reference can remain. Nothing else may delete entries, so a handle in a
  /// persisted transcript stays readable until its scope is retired.
  Future<void> clearScope(ToolOutputScope scope);

  /// Removes everything stored for every agent scope of [scope]'s
  /// conversation.
  ///
  /// A transcript is per conversation AND agent, while "the conversation was
  /// cleared" arrives without an agent id — so this is the call that makes that
  /// signal actionable, over the same tree, without touching another
  /// conversation or workspace.
  Future<void> clearConversation(ToolOutputScope scope);
}

/// Why [scope] must not be used for durable storage, or `null` when it is
/// usable.
///
/// Identities are validated, not rewritten: two different ids must never
/// resolve to one stored location (a silent cross-conversation read), so an id
/// that looks like a path or carries a control character is refused outright
/// rather than "cleaned up" into some other id's name.
String? invalidToolOutputScope(ToolOutputScope scope) {
  if (!scope.isComplete) {
    return 'no workspace id';
  }
  final ids = <(String, String?)>[
    ('workspace', scope.workspaceId),
    ('conversation', scope.conversationId),
    ('agent', scope.agentId),
  ];
  for (final (label, id) in ids) {
    if (id == null) {
      continue;
    }
    if (id.length > 200) {
      return '$label id is longer than 200 chars';
    }
    for (final unit in id.codeUnits) {
      if (unit < 0x20 || unit == 0x7f) {
        return '$label id contains a control character';
      }
    }
    if (id.contains('/') || id.contains('\\')) {
      return '$label id contains a path separator';
    }
    if (id.contains('..')) {
      return '$label id contains a parent-directory reference';
    }
  }
  return null;
}

/// In-memory store for tests and single-process sessions.
///
/// Scoped and bounded on purpose: entries are keyed by scope so one run can
/// never read another's, and a full scope refuses NEW writes rather than
/// evicting entries a live transcript may still reference.
class InMemoryToolOutputStore implements ToolOutputStore {
  /// Creates an in-memory store.
  InMemoryToolOutputStore({
    this.maxEntriesPerScope = 64,
    this.maxEntryChars = 4 * 1024 * 1024,
  });

  /// Maximum retained outputs per scope.
  final int maxEntriesPerScope;

  /// Refuse a single output longer than this (it is not stored — `put` returns
  /// null, exactly as the file adapter does past its byte ceiling).
  final int maxEntryChars;

  final Map<String, Map<String, _InMemoryEntry>> _entries = {};

  /// Number of retained entries across all scopes (test/observability
  /// surface).
  int get length {
    var total = 0;
    for (final scope in _entries.values) {
      total += scope.length;
    }
    return total;
  }

  @override
  Future<ToolOutputReference?> put(ToolOutputWrite write) async {
    if (invalidToolOutputScope(write.scope) != null) {
      return null;
    }
    if (write.content.length > maxEntryChars) {
      return null;
    }
    final bucket = _entries.putIfAbsent(
      write.scope.key,
      () => <String, _InMemoryEntry>{},
    );
    if (bucket.length >= maxEntriesPerScope) {
      // At capacity: refuse the NEW write rather than evicting an entry a live
      // transcript may still reference.
      return null;
    }
    final handle = newToolOutputHandle();
    bucket[handle] = _InMemoryEntry(
      toolName: write.toolName,
      content: write.content,
    );
    return ToolOutputReference(
      handle: handle,
      toolName: write.toolName,
      byteLength: utf8LengthOf(write.content),
      charLength: write.content.length,
    );
  }

  @override
  Future<ToolOutputReadResult> read(
    ToolOutputScope scope,
    String handle, {
    int offsetChars = 0,
    int limitChars = kToolOutputReadDefaultChars,
  }) async {
    if (!isToolOutputHandle(handle)) {
      return ToolOutputReadResult.invalid('handle must look like "out_…"');
    }
    // Own scope only: another scope's handle is simply unknown here, because
    // reporting "belongs to someone else" would disclose what that run holds.
    final entry = _entries[scope.key]?[handle];
    if (entry == null) {
      return ToolOutputReadResult.notFound(handle);
    }
    return ToolOutputReadResult.ok(
      sliceStoredOutput(
        entry.content,
        offsetChars: offsetChars,
        limitChars: limitChars,
        byteLength: utf8LengthOf(entry.content),
        toolName: entry.toolName,
      ),
    );
  }

  @override
  Future<void> clearScope(ToolOutputScope scope) async {
    _entries.remove(scope.key);
  }

  @override
  Future<void> clearConversation(ToolOutputScope scope) async {
    _entries.removeWhere(
      (key, _) => key.startsWith(scope.conversationKeyPrefix),
    );
  }
}

class _InMemoryEntry {
  const _InMemoryEntry({required this.toolName, required this.content});

  final String toolName;
  final String content;
}

/// Clamps a ranged-read request to the port's bounds.
///
/// One definition, shared by every store and by the file adapter's indexed
/// path, so `offset`/`limit` semantics cannot drift between implementations.
({int offsetChars, int limitChars}) clampToolOutputRead({
  required int offsetChars,
  required int limitChars,
}) => (
  offsetChars: offsetChars < 0 ? 0 : offsetChars,
  limitChars: limitChars < 1
      ? 1
      : (limitChars > kToolOutputReadMaxChars
            ? kToolOutputReadMaxChars
            : limitChars),
);

/// Slices [content] for a ranged read, clamping both bounds.
///
/// Shared by both stores so `offset`/`limit` semantics (and the returned
/// [ToolOutputChunk] metadata) cannot drift between them.
ToolOutputChunk sliceStoredOutput(
  String content, {
  required int offsetChars,
  required int limitChars,
  int? byteLength,
  String toolName = '',
}) {
  final request = clampToolOutputRead(
    offsetChars: offsetChars,
    limitChars: limitChars,
  );
  final start = request.offsetChars > content.length
      ? content.length
      : request.offsetChars;
  final end = start + request.limitChars > content.length
      ? content.length
      : start + request.limitChars;
  return ToolOutputChunk(
    text: content.substring(start, end),
    offsetChars: start,
    totalChars: content.length,
    byteLength: byteLength ?? utf8LengthOf(content),
    toolName: toolName,
  );
}

/// The UTF-8 byte length of [content] without allocating the encoded bytes.
///
/// A stored tool output can be megabytes; `utf8.encode(...).length` would
/// allocate a second copy of it (and, for the file adapter, that copy arrives
/// on top of the one it is about to write) purely to produce a number.
int utf8LengthOf(String content) {
  var bytes = 0;
  for (var i = 0; i < content.length; i++) {
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
      // A surrogate pair is one 4-byte code point, not two 3-byte ones.
      bytes += 4;
      i++;
    } else {
      bytes += 3;
    }
  }
  return bytes;
}

/// Whether [handle] has the shape this port hands out.
///
/// The alphabet is base64url's, so a handle can never contain a path
/// separator, a `..`, or a null byte — a handle is a name, never a path.
bool isToolOutputHandle(String handle) => _handlePattern.hasMatch(handle);

final RegExp _handlePattern = RegExp(r'^out_[A-Za-z0-9_-]{16,64}$');

/// Mints an opaque handle.
///
/// 16 random bytes from a cryptographic source: unguessable from another run's
/// transcript, so the scope check is a second line of defence rather than the
/// only one. base64url (no padding) keeps it a plain, path-safe token.
String newToolOutputHandle() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return 'out_${base64Url.encode(bytes).replaceAll('=', '')}';
}

/// The storage scope for [context], or `null` when the run has no workspace to
/// bind a handle to.
///
/// A run with no workspace cannot store: every handle must be checkable against
/// a boundary, and "no boundary" is not one. Ingestion treats `null` as
/// "not stored" — it never invents a scope.
ToolOutputScope? buildToolOutputScope(HarnessToolContext context) {
  final workspaceId = context.workspaceId;
  if (workspaceId == null || workspaceId.isEmpty) {
    return null;
  }
  return ToolOutputScope(
    workspaceId: workspaceId,
    conversationId: context.conversationId,
    agentId: context.agentId,
  );
}
