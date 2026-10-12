/// Opaque, scope-bound references to durably stored original tool outputs.
///
/// **Why a reference instead of the text.** A bounded observation is a promise
/// that the model can still get at what was dropped. Truncating without one
/// makes every later `read`/`search`/`bash` a re-run (or, worse, a guess): the
/// *Token Reduction Is Not Cost Reduction* study found a configuration that cut
/// delivered tool-output tokens by 38% yet raised cost, because the work moved
/// into retrieval the model had to redo. A reference is what makes the cut
/// honest — the original stays exactly where it was written, and the handle in
/// the marker names a bounded, authorized way back to it.
///
/// **Why the scope is not in the reference.** The handle is opaque on purpose:
/// a leaked transcript must not hand a reader another run's data. Which
/// workspace/conversation/agent a handle belongs to is recorded at *write* time
/// and enforced on every read, so a handle copied into a different run is
/// denied rather than resolved.
///
/// This file is pure data (no `dart:io`, no messages/tool imports) so the
/// message layer can carry a reference without an import cycle.
library;

/// The run scope a stored tool output belongs to.
///
/// All three parts are compared on every read. A missing [conversationId] or
/// [agentId] is a distinct scope (`null` is not a wildcard): a handle created
/// with no conversation must not be readable by a run that has one.
class ToolOutputScope {
  /// Creates a [ToolOutputScope].
  const ToolOutputScope({
    required this.workspaceId,
    this.conversationId,
    this.agentId,
  });

  /// Rebuilds from [toJson]'s output.
  factory ToolOutputScope.fromJson(Map<String, dynamic> json) =>
      ToolOutputScope(
        workspaceId: json['workspace'] as String? ?? '',
        conversationId: json['conversation'] as String?,
        agentId: json['agent'] as String?,
      );

  /// The workspace the run belongs to. Required: an unscoped run stores
  /// nothing, because there is no boundary to enforce.
  final String workspaceId;

  /// The conversation the run belongs to, when known.
  final String? conversationId;

  /// The agent that produced the output, when known.
  final String? agentId;

  /// Whether this scope has the minimum needed to bind a handle
  /// ([workspaceId] non-empty).
  bool get isComplete => workspaceId.isNotEmpty;

  /// An injective key for in-memory maps.
  ///
  /// Length-prefixed parts, because `null` and `''` are DIFFERENT scopes: a
  /// run with no conversation must not read (or overwrite) a run whose
  /// conversation id happens to be the empty string, and joining raw values
  /// with a delimiter would let `('a', 'b#c')` alias `('a#b', 'c')`.
  String get key =>
      '${_part(workspaceId)}${_part(conversationId)}'
      '${_part(agentId)}';

  /// An injective, filesystem-safe directory name for this scope.
  ///
  /// Every character outside `[A-Za-z0-9-]` is escaped as `_<4 hex digits>`
  /// (and `_` itself is escaped), so the mapping is reversible — two different
  /// scopes can never land in the same directory, and no id can contribute a
  /// path separator, a `.`, or a `..` to the path it names. Hashing would be
  /// stable but only *probably* collision-free; an escaping is exactly
  /// collision-free.
  ///
  /// `'.'` is never emitted by [conversationStorageKey] or [_encodedPart], so
  /// it is an unambiguous separator — which is what lets a conversation's
  /// whole directory set be retired by prefix.
  String get storageKey => '$conversationStorageKey.${_encodedPart(agentId)}';

  /// The [storageKey] prefix shared by every agent scope of this conversation.
  String get conversationStorageKey => _encodedPart(conversationId);

  /// The [key] prefix shared by every agent scope of this conversation.
  ///
  /// Self-delimiting, so a prefix match selects exactly this workspace and
  /// conversation and no other.
  String get conversationKeyPrefix =>
      '${_part(workspaceId)}${_part(conversationId)}';

  /// A short label for messages (`conversation#agent`). Display only — never a
  /// path: it is not injective.
  String get label =>
      '${conversationId ?? 'default'}${agentId == null ? '' : '#$agentId'}';

  static String _part(String? value) =>
      value == null ? 'n' : 'v${value.length}:$value';

  static String _encodedPart(String? value) {
    if (value == null) {
      return 'n';
    }
    final buffer = StringBuffer('v')
      ..write(value.length)
      ..write('_');
    for (final unit in value.codeUnits) {
      if (_plainUnit(unit)) {
        buffer.writeCharCode(unit);
      } else {
        buffer
          ..write('_')
          ..write(unit.toRadixString(16).padLeft(4, '0'));
      }
    }
    return buffer.toString();
  }

  /// `0-9`, `A-Z`, `a-z`, `-` — everything else (including `.` and `_`, which
  /// would otherwise be ambiguous with the escape) is escaped.
  static bool _plainUnit(int unit) =>
      (unit >= 0x30 && unit <= 0x39) ||
      (unit >= 0x41 && unit <= 0x5A) ||
      (unit >= 0x61 && unit <= 0x7A) ||
      unit == 0x2D;

  /// Serializes for storage alongside a stored output.
  Map<String, dynamic> toJson() => {
    'workspace': workspaceId,
    'conversation': conversationId,
    'agent': agentId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolOutputScope &&
          other.workspaceId == workspaceId &&
          other.conversationId == conversationId &&
          other.agentId == agentId;

  @override
  int get hashCode => Object.hash(workspaceId, conversationId, agentId);

  @override
  String toString() => 'ToolOutputScope($label in $workspaceId)';
}

/// An opaque handle to a durably stored original tool output, plus the exact
/// size metadata a compactor needs to account for what it is hiding.
class ToolOutputReference {
  /// Creates a [ToolOutputReference].
  const ToolOutputReference({
    required this.handle,
    required this.toolName,
    required this.byteLength,
    required this.charLength,
    this.previewChars = 0,
  });

  /// Rebuilds from [toJson]'s output. Tolerant: a transcript written by an
  /// older harness restores as a reference with empty size metadata rather
  /// than a parse failure.
  factory ToolOutputReference.fromJson(Map<String, dynamic> json) =>
      ToolOutputReference(
        handle: json['handle'] as String? ?? '',
        toolName: json['tool'] as String? ?? '',
        byteLength: (json['bytes'] as num?)?.toInt() ?? 0,
        charLength: (json['chars'] as num?)?.toInt() ?? 0,
        previewChars: (json['preview'] as num?)?.toInt() ?? 0,
      );

  /// The opaque handle to read the original with (`read_output(handle: …)`).
  final String handle;

  /// The tool whose output this was (for the marker text and accounting).
  final String toolName;

  /// Exact original size in UTF-8 bytes.
  final int byteLength;

  /// Exact original size in UTF-16 code units.
  final int charLength;

  /// How many leading chars of the original are still inline **in place of the
  /// text this reference replaced**, or `0` when nothing was cut.
  ///
  /// A compacted observation keeps a head and puts the marker where the rest
  /// was, so a later masking pass must leave at least that head alone or the
  /// text it claims to have replaced would be duplicated. A reference attached
  /// to an observation that was stored for future masking without being cut
  /// (the observation still fits inline) reports `0`: the whole text is
  /// present, so a mask may replace all of it.
  final int previewChars;

  /// Returns a copy with selected fields overridden.
  ToolOutputReference copyWith({int? previewChars}) => ToolOutputReference(
    handle: handle,
    toolName: toolName,
    byteLength: byteLength,
    charLength: charLength,
    previewChars: previewChars ?? this.previewChars,
  );

  /// Serializes for the transcript.
  Map<String, dynamic> toJson() => {
    'handle': handle,
    'tool': toolName,
    'bytes': byteLength,
    'chars': charLength,
    if (previewChars > 0) 'preview': previewChars,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolOutputReference &&
          other.handle == handle &&
          other.toolName == toolName &&
          other.byteLength == byteLength &&
          other.charLength == charLength &&
          other.previewChars == previewChars;

  @override
  int get hashCode =>
      Object.hash(handle, toolName, byteLength, charLength, previewChars);

  @override
  String toString() =>
      'ToolOutputReference($handle, $toolName, $charLength chars)';
}

/// Default `limit` (chars) for one `ToolOutputStore` ranged read: ~3k tokens of
/// dense text — enough for a full test failure block or a wide grep, small
/// enough that retrieving is always cheaper than re-running the tool.
const int kToolOutputReadDefaultChars = 12000;

/// Hard ceiling on one ranged read, so a model cannot re-inflate the window it
/// just gave up by asking for the whole original in one call.
const int kToolOutputReadMaxChars = 40000;

/// Prefix of every inline truncation marker.
const String omittedOutputPrefix = '[output omitted';

/// The marker left where an over-long observation was cut.
///
/// With a [reference] the marker names the exact handle and resume offset, so
/// the cut is recoverable in one bounded call. Without one it says so outright:
/// an observation that cannot be recovered must not look like one that can.
String omittedOutputMarker(
  ToolOutputReference? reference, {
  required int omittedChars,
  required int resumeOffsetChars,
}) {
  final head = '$omittedOutputPrefix: $omittedChars chars';
  if (reference == null) {
    return '$head (original not stored)]';
  }
  return '$head; resume with read_output(handle: "${reference.handle}", '
      'offset: $resumeOffsetChars)]';
}

/// Prefix of every masked-observation marker.
///
/// A masking pass replaces a stale observation's text with a marker while
/// keeping its `tool_use` / `tool_result` pair intact — providers reject a
/// result with no call, so a mask that deletes the pair is a broken history.
/// Re-masking checks against this prefix so a mask is never masked twice.
const String maskedObservationPrefix = '[masked observation';

/// The marker a masking pass writes in place of a stale, recoverable
/// observation.
String maskedObservationMarker(
  ToolOutputReference reference, {
  int limitChars = kToolOutputReadDefaultChars,
}) =>
    '$maskedObservationPrefix: ${reference.toolName} output stored '
    '(${reference.charLength} chars) — read it again with '
    'read_output(handle: "${reference.handle}", offset: 0, limit: $limitChars)]';

/// Whether [content] is a masked-observation marker (so a compactor can skip
/// re-masking it and a reader can tell a mask from an empty result).
bool isMaskedObservation(String content) =>
    content.startsWith(maskedObservationPrefix);
