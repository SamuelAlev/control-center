/// Evidence-preserving history rendering and observation masking.
///
/// Report 3C: a summarizer cannot preserve evidence it never receives. The old
/// serializer kept user text and assistant narration, reduced tool calls to
/// names, and dropped tool arguments, every tool result and all system-role
/// steering — so a unique fact lived in a tool result, a source path in the
/// arguments, and a constraint in steering, and none of the three reached the
/// summary. This module builds the bounded, provenance-bearing representation
/// instead.
///
/// Report 3D: masking replaces a STALE observation's text with a reference to
/// the durable original, keeping the tool_use/tool_result pair intact. Only a
/// safely recoverable observation (one that carries a
/// [ToolOutputReference]) is ever masked; everything else is left verbatim.
library;

import 'dart:convert';

import 'package:cc_harness/src/context/harness_token_accounting.dart';
import 'package:cc_harness/src/context/pinned_evidence.dart';
import 'package:cc_harness/src/context/still_in_flight.dart';
import 'package:cc_harness/src/context/token_estimator.dart';
import 'package:cc_harness/src/context/tool_output_reference.dart';
import 'package:cc_harness/src/context/tool_result_elision.dart';
import 'package:cc_harness/src/messages.dart';

export 'package:cc_harness/src/context/pinned_evidence.dart';

/// Marks the injected anchored-summary user message so a later compaction pass
/// recognizes it and re-anchors (updates) rather than re-summarizing.
const String harnessSummaryMarker = '[conversation-summary]';

/// The activation metadata a fold must carry forward: every name recorded on a
/// message (the loop tags the tool-result message of an activation turn) plus
/// every name a surviving tool result references.
///
/// This is the union the replacement message must preserve — dropping it makes
/// an activated tool uncallable on the next native request.
List<String> collectActivatedToolNames(List<HarnessMessage> messages) {
  final names = <String>{};
  for (final m in messages) {
    names.addAll(m.activatedToolNames);
    for (final b in m.content) {
      if (b is HarnessToolResultBlock) {
        names.addAll(b.toolReferences);
      }
    }
  }
  return names.toList()..sort();
}

/// Tools whose call arguments name the file the agent is working on.
///
/// Used to protect the code currently being edited from masking and from being
/// dropped out of the summarizer's bounded evidence: a summary is appropriate
/// for completed exploration, not as a substitute for the exact edit anchor.
const Set<String> editToolNames = {
  'edit',
  'write',
  'notebookedit',
  'multiedit',
  'multi_edit',
  'apply_patch',
  'applypatch',
  'str_replace',
  'str_replace_editor',
  'create_file',
  'replace',
};

/// Argument keys that carry a file path across the various edit/read tools.
const List<String> _pathArgKeys = [
  'file_path',
  'filePath',
  'path',
  'filename',
  'file',
  'target_file',
  'target',
];

/// Argument keys, beyond the path keys, that name what a call touched: kept in
/// a nested call's digest ([identifyingToolArgs]).
const List<String> _identifyingArgKeys = [
  'paths',
  'edits',
  'command',
  'url',
  'query',
  'pattern',
  'glob',
  'cwd',
  'id',
  'name',
];

/// How many characters of one identifying string a digest keeps.
const int _identifyingValueChars = 256;

/// How many items of one identifying list a digest keeps.
const int _identifyingListItems = 16;

/// The arguments of a call that identify what it touched (its paths, command,
/// URL or query), clipped for a [HarnessNestedToolCall] digest.
///
/// Payload arguments (file contents, replacement text) are dropped: the digest
/// exists so evidence can say WHICH files a script edited, and the path keys
/// are the same ones the evidence reads from a direct call. List items keep
/// their strings or, for objects such as a batch edit's entries, their path
/// keys.
Map<String, Object?> identifyingToolArgs(Map<String, dynamic> args) {
  Object? clip(Object? value) => switch (value) {
    final String s when s.length > _identifyingValueChars =>
      '${s.substring(0, _identifyingValueChars)}…',
    String() || num() || bool() || null => value,
    _ => null,
  };
  final kept = <String, Object?>{};
  for (final key in [..._pathArgKeys, ..._identifyingArgKeys]) {
    final value = args[key];
    if (value == null) {
      continue;
    }
    if (value is List) {
      final items = <Object?>[];
      for (final item in value.take(_identifyingListItems)) {
        if (item is Map) {
          final paths = <String, Object?>{
            for (final pathKey in _pathArgKeys)
              if (item[pathKey] case final Object v) pathKey: clip(v),
          }..removeWhere((_, v) => v == null);
          if (paths.isNotEmpty) {
            items.add(paths);
          }
        } else if (clip(item) case final Object v) {
          items.add(v);
        }
      }
      if (items.isNotEmpty) {
        kept[key] = items;
      }
      continue;
    }
    if (clip(value) case final Object v) {
      kept[key] = v;
    }
  }
  return kept;
}

/// The file path a call's arguments name, by the same keys for a direct call
/// and a nested one.
String? _pathOf(Map<String, Object?> args) {
  for (final key in _pathArgKeys) {
    final raw = args[key];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
  }
  return null;
}

/// Whether any nested call recorded on [block] is a state-carrying tool whose
/// output must survive pruning and masking ([pruneProtectedTools]): a script
/// that wrote the checklist is as protected as a direct `todo_write`.
bool nestedCallsProtected(HarnessToolResultBlock block) => block.nestedCalls
    .any((c) => pruneProtectedTools.contains(normalizeHarnessToolName(c.name)));

/// The file paths the nested calls recorded on [block] named.
Iterable<String> _nestedPaths(HarnessToolResultBlock block) sync* {
  for (final call in block.nestedCalls) {
    final path = _pathOf(call.args);
    if (path != null) {
      yield path;
    }
  }
}

/// Bounds for the evidence-bearing history handed to a summarizer.
///
/// Every bound is in characters because the estimator is char-based and the
/// budget is about what the summarizer prompt can hold, not what the model
/// bills. The total is the real guard; the per-class caps stop one enormous
/// tool result from crowding everything else out.
class HarnessEvidenceBudget {
  /// Creates an evidence budget.
  const HarnessEvidenceBudget({
    this.totalChars = 24000,
    this.authoritativeChars,
    this.protectedChars,
    this.userChars = 4000,
    this.systemChars = 4000,
    this.assistantChars = 2000,
    this.toolArgsChars = 400,
    this.toolResultChars = 1200,
  }) : assert(totalChars > 0, 'total budget must be positive');

  /// Whole rendered evidence budget (the guard that actually binds).
  final int totalChars;

  /// The pinned block's one budget (the person's requests and steering, and
  /// the loop's system steering), across carried and new items alike
  /// ([fitPinnedEvidence]). Null derives a scale-free share of [totalChars].
  ///
  /// Pinned evidence is never tail-bounded away, but it is still bounded:
  /// unbounded "must survive" categories are exactly how an error-heavy
  /// history overflows the summarizer prompt.
  final int? authoritativeChars;

  /// Cap on protected observations (diagnostics and active-edit results).
  /// Null derives a scale-free share of [totalChars].
  final int? protectedChars;

  /// Cap on one user turn. The original request has none of its own: the
  /// pinned budget decides how much of it fits.
  final int userChars;

  /// Cap on one system-role steering turn.
  final int systemChars;

  /// Cap on one assistant answer.
  final int assistantChars;

  /// Cap on one tool call's serialized arguments.
  final int toolArgsChars;

  /// Cap on one tool-result excerpt.
  final int toolResultChars;

  /// Share of [totalChars] the pinned block may occupy.
  int get authoritativeShare => authoritativeChars ?? (totalChars * 2 ~/ 5);

  /// Share of [totalChars] protected observations may occupy.
  int get protectedShare => protectedChars ?? (totalChars * 3 ~/ 10);

  /// The default budget.
  static const HarnessEvidenceBudget defaults = HarnessEvidenceBudget();

  /// Returns a copy with selected fields overridden.
  HarnessEvidenceBudget copyWith({
    int? totalChars,
    int? authoritativeChars,
    int? protectedChars,
    int? userChars,
    int? systemChars,
    int? assistantChars,
    int? toolArgsChars,
    int? toolResultChars,
  }) => HarnessEvidenceBudget(
    totalChars: totalChars ?? this.totalChars,
    authoritativeChars: authoritativeChars ?? this.authoritativeChars,
    protectedChars: protectedChars ?? this.protectedChars,
    userChars: userChars ?? this.userChars,
    systemChars: systemChars ?? this.systemChars,
    assistantChars: assistantChars ?? this.assistantChars,
    toolArgsChars: toolArgsChars ?? this.toolArgsChars,
    toolResultChars: toolResultChars ?? this.toolResultChars,
  );
}

/// One tool call's identity and edit target, indexed by `tool_use` id.
class _CallInfo {
  const _CallInfo(this.name, this.path);
  final String name;
  final String? path;
}

class _EvidenceItem {
  _EvidenceItem({
    required this.text,
    required this.protected,
    this.handles = const [],
  });
  final String text;

  /// Kept even when trimming: active-edit evidence and diagnostics.
  final bool protected;

  /// Real recovery handles carried by this item, so a category that must drop
  /// it can name a handle instead of losing the original silently.
  final List<String> handles;
}

/// Truncates [text] to [max] characters, keeping both ends and naming how much
/// was dropped so a reader can tell an excerpt from the whole. Never cuts
/// inside a data envelope ([clipKeepingEnvelopes]).
String _clip(String text, int max) => clipKeepingEnvelopes(text, max);

/// The heading an observation-like message (one that is data, not
/// instructions) is shown under, by where it came from.
String _dataHeading(HarnessMessageOrigin origin) => switch (origin) {
  HarnessMessageOrigin.notice => '# Notice (server, last observed)',
  HarnessMessageOrigin.wake => '# Wake (data)',
  HarnessMessageOrigin.peer => '# Peer message (data)',
  HarnessMessageOrigin.person => '# User',
};

/// Indexes the tool calls in [history] by id, capturing the name and the file
/// path an edit/read call targets.
Map<String, _CallInfo> _toolCallIndex(List<HarnessMessage> history) {
  final index = <String, _CallInfo>{};
  for (final m in history) {
    for (final b in m.content) {
      if (b is! HarnessToolUseBlock) {
        continue;
      }
      final path = _pathOf(b.input);
      index.putIfAbsent(
        b.id,
        () => _CallInfo(normalizeHarnessToolName(b.name), path),
      );
    }
  }
  return index;
}

/// The set of file paths the agent's most recent edit/write calls touched.
///
/// Scans from the newest turn backwards so a file edited early and since
/// abandoned is not treated as active forever; the scan stops once it has
/// gathered targets from [lookback] edit calls.
Set<String> collectActiveEditTargets(
  List<HarnessMessage> history, {
  int lookback = 8,
}) {
  final targets = <String>{};
  var seen = 0;
  // A script's edits are nested calls recorded on its result block; they count
  // exactly as direct edit calls do.
  Iterable<(String, Map<String, Object?>)> editsIn(HarnessMessage m) sync* {
    for (final b in m.content) {
      if (b is HarnessToolUseBlock) {
        yield (b.name, b.input);
      } else if (b is HarnessToolResultBlock) {
        for (final call in b.nestedCalls) {
          yield (call.name, call.args);
        }
      }
    }
  }

  for (var i = history.length - 1; i >= 0 && seen < lookback; i--) {
    for (final (name, args) in editsIn(history[i])) {
      if (!editToolNames.contains(normalizeHarnessToolName(name))) {
        continue;
      }
      seen++;
      final path = _pathOf(args);
      if (path != null) {
        targets.add(path);
      }
      if (seen >= lookback) {
        break;
      }
    }
  }
  return targets;
}

/// Renders a harness message span into a bounded, evidence-bearing transcript.
///
/// Preserved, in trust order:
/// - the PINNED block ([evidencePinBegin] … [evidencePinEnd], one budget,
///   [fitPinnedEvidence]): the person's original request (the conversation's
///   first message), every later message of the person (a request after a
///   summary, steering sent mid-run, a queued follow-up:
///   [HarnessMessageOrigin.person], and the texts a snapshot page carries in
///   [HarnessMessage.carriedPersonTexts]) and the loop's own system steering;
/// - assistant answer text plus each tool call WITH its arguments, so source
///   paths, symbols and identifiers survive;
/// - tool results as OBSERVATIONS labelled with the tool name and outcome, and
///   carrying the recovery handle of the durable original when one exists;
/// - server notices, wake frames and peers' messages, whatever role carries
///   them, as data like an observation: never pinned.
///
/// Observations are explicitly distinguished from assistant narration so a
/// summary cannot turn "the agent thought the tests passed" into "tests
/// passed". When the span exceeds [HarnessEvidenceBudget.totalChars] the oldest
/// unpinned, non-protected items are dropped (newest evidence first) and
/// replaced by a single omission line naming the count.
///
/// Every message's text has the pin markers neutralised
/// ([neutraliseEvidenceMarkers]): only this serializer and the compactor
/// write them, so no tool output, page, file, model text or message can
/// forge or close the pinned block.
String serializeHarnessHistory(
  List<HarnessMessage> messages, {
  String selfAgentName = 'assistant',
  HarnessEvidenceBudget budget = HarnessEvidenceBudget.defaults,
  Set<String> activeEditTargets = const {},
}) {
  if (messages.isEmpty) {
    return '';
  }
  final calls = _toolCallIndex(messages);
  final pinned = <PinnedEvidenceItem>[];
  final items = <_EvidenceItem>[];
  // The conversation's original request: its first message, unless the span
  // starts with a summary (which carries the original in its own block).
  var requestOpen = true;
  void pinPerson(String text) {
    final body = neutraliseEvidenceMarkers(text.trim());
    if (body.isEmpty) {
      return;
    }
    if (requestOpen) {
      requestOpen = false;
      // Whole: the pinned budget decides how much of it fits.
      pinned.add(PinnedEvidenceItem.request(body));
      return;
    }
    pinned.add(PinnedEvidenceItem.person(_clip(body, budget.userChars)));
  }

  void addData(HarnessMessageOrigin origin, String text) {
    items.add(
      _EvidenceItem(
        text:
            '${_dataHeading(origin)}\n'
            '${_clip(neutraliseEvidenceMarkers(text), budget.toolResultChars)}',
        protected: false,
      ),
    );
  }

  for (var index = 0; index < messages.length; index++) {
    final m = messages[index];
    final origin = m.origin;
    switch (m.role) {
      case HarnessRole.user:
        // A snapshot page's person texts are the person's words: pinned,
        // whatever the page's own text says.
        m.carriedPersonTexts.forEach(pinPerson);
        final text = m.textContent.trim();
        if (text.isEmpty) {
          continue;
        }
        if (origin == null && text.startsWith(harnessSummaryMarker)) {
          // The original request is already pinned inside this summary. Do not
          // promote the next untagged user turn into a second "original".
          requestOpen = false;
          continue;
        }
        if (origin == HarnessMessageOrigin.person ||
            (origin == null && index == 0)) {
          pinPerson(text);
          continue;
        }
        requestOpen = false;
        if (origin != null) {
          addData(origin, text);
          continue;
        }
        items.add(
          _EvidenceItem(
            text:
                '# User\n'
                '${_clip(neutraliseEvidenceMarkers(text), budget.userChars)}',
            protected: false,
          ),
        );
      case HarnessRole.system:
        final text = m.textContent.trim();
        // A "Still in flight" block is last-observed state, rebuilt from
        // live state after every compaction: pinning it would carry stale
        // statuses forward as authoritative steering.
        if (text.isEmpty || isStillInFlightBlock(text)) {
          continue;
        }
        // A notice, a wake frame or a peer's message is data: summarised or
        // dropped like an observation, never pinned.
        if (origin != null && origin != HarnessMessageOrigin.person) {
          addData(origin, text);
          continue;
        }
        // The loop's and the owner's steering: kept verbatim, bounded, pinned.
        pinned.add(
          PinnedEvidenceItem.steering(
            _clip(neutraliseEvidenceMarkers(text), budget.systemChars),
          ),
        );
      case HarnessRole.assistant:
        final text = neutraliseEvidenceMarkers(m.textContent.trim());
        final lines = <String>[];
        var touchesActiveEdit = false;
        for (final b in m.content) {
          if (b is! HarnessToolUseBlock) {
            continue;
          }
          final name = normalizeHarnessToolName(b.name);
          final path = calls[b.id]?.path;
          if (path != null && activeEditTargets.contains(path)) {
            touchesActiveEdit = true;
          }
          lines.add(
            '(call: $name '
            '${_clip(neutraliseEvidenceMarkers(b.encodedInput), budget.toolArgsChars)})',
          );
        }
        final body = [
          if (text.isNotEmpty) _clip(text, budget.assistantChars),
          ...lines,
        ];
        if (body.isEmpty) {
          continue;
        }
        items.add(
          _EvidenceItem(
            text: '# $selfAgentName\n${body.join('\n')}',
            protected: touchesActiveEdit,
          ),
        );
      case HarnessRole.tool:
        final lines = <String>[];
        final handleList = <String>[];
        var protectedObservation = false;
        for (final b in m.content) {
          if (b is! HarnessToolResultBlock) {
            continue;
          }
          if (b.content == elidedResultMarker) {
            continue;
          }
          final call = calls[b.toolUseId];
          final name = call?.name ?? 'tool';
          final path = call?.path;
          final isActiveEdit =
              (path != null && activeEditTargets.contains(path)) ||
              _nestedPaths(b).any(activeEditTargets.contains);
          if (isActiveEdit || b.isError) {
            protectedObservation = true;
          }
          if (b.outputReference != null) {
            handleList.add(b.outputReference!.handle);
          }
          final recovery = b.outputReference != null
              ? '\n${maskedObservationMarker(b.outputReference!)}'
              : '';
          // The calls a script made are evidence of what it touched, as a
          // direct call's arguments are.
          final nested = b.nestedCalls.isEmpty
              ? ''
              : '\n${_clip(neutraliseEvidenceMarkers([for (final c in b.nestedCalls) '(nested call: ${normalizeHarnessToolName(c.name)} ${jsonEncode(c.args)}${c.isError ? ', error' : ''})'].join('\n')), budget.toolArgsChars * 4)}';
          lines.add(
            '# Observation ($name, ${b.isError ? 'error' : 'ok'})'
            '${isActiveEdit ? ' [active edit]' : ''}\n'
            '${_clip(neutraliseEvidenceMarkers(b.content), budget.toolResultChars)}'
            '$nested$recovery',
          );
        }
        if (lines.isEmpty) {
          continue;
        }
        items.add(
          _EvidenceItem(
            text: lines.join('\n'),
            protected: protectedObservation,
            handles: handleList,
          ),
        );
    }
  }

  // ---- Bounded category allocation ----
  // EVERY category is bounded, including the ones that must not be dropped
  // silently: an unbounded "pinned"/"protected" bucket is exactly how an
  // error-heavy history overflows the summarizer prompt. Dropped items are
  // named, and any real recovery handle they carried is preserved in the loss
  // marker so nothing disappears without a reference.
  final protectedItems = items.where((i) => i.protected).toList();
  final general = items.where((i) => !i.protected).toList();

  // Pinned: one budget. The original request whole, then the newest.
  final authText = fitPinnedEvidence(
    pinned,
    budget: budget.authoritativeShare,
  );

  // Protected observations: newest-first, so the latest diagnostics win.
  final protKept = _fitHead(
    protectedItems.reversed.toList(),
    budget.protectedShare,
  ).reversed.toList();
  final protDropped = protectedItems.sublist(
    0,
    protectedItems.length - protKept.length,
  );
  final protText = _renderItems(protKept);

  // General evidence: newest-first within what the other categories left.
  final remaining = budget.totalChars - authText.length - protText.length;
  final generalKept = _fitHead(
    general.reversed.toList(),
    remaining < 0 ? 0 : remaining,
  ).reversed.toList();
  final generalDropped = general.sublist(
    0,
    general.length - generalKept.length,
  );

  final buffer = StringBuffer();
  if (authText.isNotEmpty) {
    // The pin markers make section identity STRUCTURAL: ordinary Markdown
    // headings inside the request (`# Goal`, `## Acceptance`) can no longer
    // terminate the pinned section and let the budget drop it.
    buffer
      ..writeln(evidencePinBegin)
      ..writeln(authText)
      ..writeln(evidencePinEnd)
      ..writeln();
  }
  if (protDropped.isNotEmpty) {
    buffer
      ..writeln(
        _lossMarker(protDropped, 'diagnostic/active-edit observation(s)'),
      )
      ..writeln();
  }
  if (generalDropped.isNotEmpty) {
    buffer
      ..writeln(_lossMarker(generalDropped, 'older message(s)'))
      ..writeln();
  }
  if (generalKept.isNotEmpty) {
    buffer
      ..writeln(_renderItems(generalKept))
      ..writeln();
  }
  if (protText.isNotEmpty) {
    buffer
      ..writeln(protText)
      ..writeln();
  }
  final digest = buffer.toString().trim();

  // Machine-readable activation metadata travels WITH the summary text: a
  // summarizer must not be the only thing standing between an activated tool
  // and its loss.
  final activated = collectActivatedToolNames(messages);
  if (activated.isEmpty) {
    return digest;
  }
  return '$digest\n\n$evidenceActivationPrefix'
      '${activated.join(', ')}';
}

/// Keeps items in order while they fit [maxChars] (head-keep).
List<_EvidenceItem> _fitHead(List<_EvidenceItem> ordered, int maxChars) {
  final kept = <_EvidenceItem>[];
  var used = 0;
  for (final i in ordered) {
    final cost = i.text.length + 1;
    if (used + cost > maxChars) {
      break;
    }
    kept.add(i);
    used += cost;
  }
  return kept;
}

/// Renders [items]' texts, one blank line apart.
String _renderItems(List<_EvidenceItem> items) {
  final buffer = StringBuffer();
  for (final i in items) {
    buffer
      ..writeln(i.text)
      ..writeln();
  }
  return buffer.toString().trimRight();
}

/// An explicit marker for evidence dropped by the budget, naming any real
/// recovery handles it carried — never a fabricated one.
String _lossMarker(List<_EvidenceItem> dropped, String label) {
  final handles = <String>[for (final i in dropped) ...i.handles];
  final recovery = handles.isEmpty
      ? ''
      : '; originals recoverable via read_output(handle: '
            '${handles.map((h) => '"$h"').join(', ')})';
  return '[${dropped.length} $label omitted to stay within the evidence '
      'budget$recovery]';
}

/// The outcome of a masking pass (or a planning scan when apply is false).
class HarnessMaskResult {
  /// Creates a mask result.
  const HarnessMaskResult({
    required this.maskedCount,
    required this.reclaimedTokens,
    required this.handles,
    this.earliestIndex = -1,
  });

  /// No mask applied.
  static const HarnessMaskResult none = HarnessMaskResult(
    maskedCount: 0,
    reclaimedTokens: 0,
    handles: [],
  );

  /// How many observation blocks were (or would be) replaced by a reference.
  final int maskedCount;

  /// Estimated tokens removed by the masking.
  final int reclaimedTokens;

  /// The handles of the masked originals, in order (empty in plan mode).
  final List<String> handles;

  /// The earliest message index that changes, or -1 when nothing changes.
  final int earliestIndex;

  /// Whether anything changes.
  bool get changed => maskedCount > 0;
}

/// Replaces STALE, safely-recoverable observations in [history] with a
/// reference handle, in place (or, with [apply] false, reports what a pass
/// WOULD reclaim without touching [history]).
///
/// A result is masked only when ALL of these hold:
/// - it is older than the newest [keepTurns] user turns;
/// - it carries a [ToolOutputReference] (the original is durably recoverable);
/// - it is not already masked or elided;
/// - it is not an error (an unresolved diagnostic is signal, not scenery);
/// - its tool is not a protected state-carrying tool (`skill`, `todo_write`,
///   `exit_plan_mode`, …);
/// - it does not target a file the agent is currently editing;
/// - it is at least [minObservationTokens] estimated tokens (below that the
///   reference costs more than the text it replaces).
///
/// The tool_use/tool_result pair is never split: only a result's own text is
/// replaced, and the message, its role and its `toolUseId` are preserved.
HarnessMaskResult maskStaleObservations(
  List<HarnessMessage> history, {
  required int keepTurns,
  required int minObservationTokens,
  bool apply = true,
  TokenEstimator estimator = TokenEstimator.instance,
}) {
  if (history.isEmpty) {
    return HarnessMaskResult.none;
  }
  // The newest `keepTurns` user turns (and everything after them) are the
  // region the agent is actively reasoning about. Zero retained turns means the
  // whole history is eligible — handled explicitly, because indexing
  // `userIndices[length - 0]` would throw a RangeError and take the run down.
  final userIndices = <int>[
    for (var i = 0; i < history.length; i++)
      if (history[i].role == HarnessRole.user) i,
  ];
  final maskBefore = keepTurns <= 0
      ? history.length
      : (userIndices.length > keepTurns
            ? userIndices[userIndices.length - keepTurns]
            : 0);
  if (maskBefore <= 0) {
    return HarnessMaskResult.none;
  }

  final calls = _toolCallIndex(history);
  final activeEditTargets = collectActiveEditTargets(history);
  var masked = 0;
  var reclaimed = 0;
  var earliest = -1;
  final handles = <String>[];

  for (var i = 0; i < maskBefore; i++) {
    final m = history[i];
    if (m.role != HarnessRole.tool) {
      continue;
    }
    final rebuilt = <HarnessContentBlock>[];
    var changed = false;
    for (final b in m.content) {
      if (b is! HarnessToolResultBlock) {
        rebuilt.add(b);
        continue;
      }
      final ref = b.outputReference;
      if (ref == null ||
          b.isError ||
          b.content == elidedResultMarker ||
          isMaskedObservation(b.content)) {
        rebuilt.add(b);
        continue;
      }
      final call = calls[b.toolUseId];
      final name = call?.name ?? '';
      if (pruneProtectedTools.contains(name) || nestedCallsProtected(b)) {
        rebuilt.add(b);
        continue;
      }
      final path = call?.path;
      if ((path != null && activeEditTargets.contains(path)) ||
          _nestedPaths(b).any(activeEditTargets.contains)) {
        rebuilt.add(b);
        continue;
      }
      final tokens = estimateHarnessBlock(b, estimator: estimator);
      if (tokens < minObservationTokens) {
        rebuilt.add(b);
        continue;
      }
      final marker = maskedObservationMarker(ref);
      // The reference says how many leading chars of the original are already
      // inline here (the ingestion-time preview). Keep exactly that head so the
      // most readable part of the observation survives and the marker adds no
      // duplicate of it.
      final preview = ref.previewChars;
      final replacement = preview > 0 && preview < b.content.length
          ? '${b.content.substring(0, preview)}\n$marker'
          : marker;
      reclaimed += tokens - estimator.estimate(replacement);
      masked++;
      if (earliest < 0) {
        earliest = i;
      }
      if (apply) {
        handles.add(ref.handle);
        // `copyWith` (not the raw constructor) so `images`, `outputReference`
        // and `toolReferences` all survive: the mask must stay recoverable and
        // must not silently drop a tool activation.
        rebuilt.add(b.copyWith(content: replacement));
        changed = true;
      } else {
        rebuilt.add(b);
      }
    }
    if (apply && changed) {
      // copyWith (not the raw constructor): the message's activation metadata
      // must survive the mask.
      history[i] = m.copyWith(content: rebuilt);
    }
  }

  if (masked == 0) {
    return HarnessMaskResult.none;
  }
  return HarnessMaskResult(
    maskedCount: masked,
    reclaimedTokens: reclaimed,
    handles: handles,
    earliestIndex: earliest,
  );
}
