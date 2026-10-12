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

import 'package:cc_harness/src/context/harness_token_accounting.dart';
import 'package:cc_harness/src/context/token_estimator.dart';
import 'package:cc_harness/src/context/tool_output_reference.dart';
import 'package:cc_harness/src/context/tool_result_elision.dart';
import 'package:cc_harness/src/messages.dart';

/// Marks the injected anchored-summary user message so a later compaction pass
/// recognizes it and re-anchors (updates) rather than re-summarizing.
const String harnessSummaryMarker = '[conversation-summary]';

/// Opens the authoritative evidence block (original request + system steering).
///
/// Section identity is STRUCTURAL, not inferred from Markdown: an ordinary
/// request (`# Goal … ## Acceptance …`) contains its own headings, and treating
/// those as section ends would move the requirements into the droppable region.
/// Parsing the block by these markers keeps the payload verbatim for the model
/// while making it impossible for ordinary Markdown to unpin it.
const String evidencePinBegin = '<!--omp:authoritative-->';

/// Closes the authoritative evidence block.
const String evidencePinEnd = '<!--omp:end-authoritative-->';

/// Prefixes the machine-readable activated-tool list appended to a digest.
const String evidenceActivationPrefix = '<!--omp:activated-tools--> ';

/// Splits [text] into the pinned authoritative block and the rest.
///
/// Returns the inner text without the markers; the caller re-frames it when
/// emitting. When the opening marker is missing there is nothing pinned. A
/// missing closing marker (e.g. a truncated carry) pins the remainder — the
/// safe direction, since pinning too much never drops instructions.
({String pinned, String rest}) splitPinnedEvidence(String text) {
  final begin = text.indexOf(evidencePinBegin);
  if (begin < 0) {
    return (pinned: '', rest: text.trim());
  }
  final bodyStart = begin + evidencePinBegin.length;
  final end = text.indexOf(evidencePinEnd, bodyStart);
  final bodyEnd = end < 0 ? text.length : end;
  final pinned = text.substring(bodyStart, bodyEnd).trim();
  final rest =
      (end < 0
              ? text.substring(0, begin)
              : '${text.substring(0, begin)}\n'
                    '${text.substring(end + evidencePinEnd.length)}')
          .trim();
  return (pinned: pinned, rest: rest);
}

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

  /// Cap on the authoritative block (the original request + system steering).
  /// Null derives a scale-free share of [totalChars].
  ///
  /// Authoritative evidence is PINNED and never tail-bounded away, but it is
  /// still bounded: unbounded "must survive" categories are exactly how an
  /// error-heavy history overflows the summarizer prompt.
  final int? authoritativeChars;

  /// Cap on protected observations (diagnostics and active-edit results).
  /// Null derives a scale-free share of [totalChars].
  final int? protectedChars;

  /// Cap on one user turn.
  final int userChars;

  /// Cap on one system-role steering turn.
  final int systemChars;

  /// Cap on one assistant answer.
  final int assistantChars;

  /// Cap on one tool call's serialized arguments.
  final int toolArgsChars;

  /// Cap on one tool-result excerpt.
  final int toolResultChars;

  /// Share of [totalChars] the authoritative block may occupy.
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
    required this.established,
    required this.protected,
    this.handles = const [],
  });
  final String text;

  /// Always kept: the original request and system steering.
  final bool established;

  /// Kept even when trimming: active-edit evidence and diagnostics.
  final bool protected;

  /// Real recovery handles carried by this item, so a category that must drop
  /// it can name a handle instead of losing the original silently.
  final List<String> handles;
}

/// Truncates [text] to [max] characters, keeping both ends and naming how much
/// was dropped so a reader can tell an excerpt from the whole.
String _clip(String text, int max) {
  final trimmed = text.trim();
  if (max <= 0 || trimmed.length <= max) {
    return trimmed;
  }
  final head = max * 3 ~/ 4;
  final tail = max - head;
  final omitted = trimmed.length - head - tail;
  return '${trimmed.substring(0, head)}…[truncated $omitted chars]…'
      '${trimmed.substring(trimmed.length - tail)}';
}

/// Indexes the tool calls in [history] by id, capturing the name and the file
/// path an edit/read call targets.
Map<String, _CallInfo> _toolCallIndex(List<HarnessMessage> history) {
  final index = <String, _CallInfo>{};
  for (final m in history) {
    for (final b in m.content) {
      if (b is! HarnessToolUseBlock) {
        continue;
      }
      String? path;
      for (final key in _pathArgKeys) {
        final raw = b.input[key];
        if (raw is String && raw.trim().isNotEmpty) {
          path = raw.trim();
          break;
        }
      }
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
  for (var i = history.length - 1; i >= 0 && seen < lookback; i--) {
    for (final b in history[i].content) {
      if (b is! HarnessToolUseBlock) {
        continue;
      }
      if (!editToolNames.contains(normalizeHarnessToolName(b.name))) {
        continue;
      }
      seen++;
      for (final key in _pathArgKeys) {
        final raw = b.input[key];
        if (raw is String && raw.trim().isNotEmpty) {
          targets.add(raw.trim());
          break;
        }
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
/// - the ORIGINAL request (the first user turn) and every system-role steering
///   turn, verbatim (bounded per message);
/// - assistant answer text plus each tool call WITH its arguments, so source
///   paths, symbols and identifiers survive;
/// - tool results as OBSERVATIONS labelled with the tool name and outcome, and
///   carrying the recovery handle of the durable original when one exists.
///
/// Observations are explicitly distinguished from assistant narration so a
/// summary cannot turn "the agent thought the tests passed" into "tests
/// passed". When the span exceeds [HarnessEvidenceBudget.totalChars] the oldest
/// non-established, non-protected items are dropped (newest evidence first) and
/// replaced by a single omission line naming the count.
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
  final items = <_EvidenceItem>[];
  var firstUserSeen = false;

  for (final m in messages) {
    switch (m.role) {
      case HarnessRole.user:
        final text = m.textContent.trim();
        if (text.isEmpty) {
          continue;
        }
        if (text.startsWith(harnessSummaryMarker)) {
          // The original request is already pinned inside this summary. Do not
          // promote the first subsequent user turn into a second "original":
          // repeated folds would spend the authoritative budget on that turn
          // and eventually truncate the actual requirements.
          firstUserSeen = true;
          continue;
        }
        final isOriginal = !firstUserSeen;
        firstUserSeen = true;
        items.add(
          _EvidenceItem(
            text:
                '${isOriginal ? '# User (original request)' : '# User'}\n'
                '${_clip(text, budget.userChars)}',
            established: isOriginal,
            protected: isOriginal,
          ),
        );
      case HarnessRole.system:
        final text = m.textContent.trim();
        if (text.isEmpty) {
          continue;
        }
        // Critical instructions live here. Kept verbatim, bounded, and never
        // trimmed away.
        items.add(
          _EvidenceItem(
            text: '# System steering\n${_clip(text, budget.systemChars)}',
            established: true,
            protected: true,
          ),
        );
      case HarnessRole.assistant:
        final text = m.textContent.trim();
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
            '(call: $name ${_clip(b.encodedInput, budget.toolArgsChars)})',
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
            established: false,
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
          final isActiveEdit = path != null && activeEditTargets.contains(path);
          if (isActiveEdit || b.isError) {
            protectedObservation = true;
          }
          if (b.outputReference != null) {
            handleList.add(b.outputReference!.handle);
          }
          final recovery = b.outputReference != null
              ? '\n${maskedObservationMarker(b.outputReference!)}'
              : '';
          lines.add(
            '# Observation ($name, ${b.isError ? 'error' : 'ok'})'
            '${isActiveEdit ? ' [active edit]' : ''}\n'
            '${_clip(b.content, budget.toolResultChars)}$recovery',
          );
        }
        if (lines.isEmpty) {
          continue;
        }
        items.add(
          _EvidenceItem(
            text: lines.join('\n'),
            established: false,
            protected: protectedObservation,
            handles: handleList,
          ),
        );
    }
  }

  // ---- Bounded category allocation ----
  // EVERY category is bounded, including the ones that must not be dropped
  // silently: an unbounded "authoritative"/"protected" bucket is exactly how an
  // error-heavy history overflows the summarizer prompt. Dropped items are
  // named, and any real recovery handle they carried is preserved in the loss
  // marker so nothing disappears without a reference.
  final established = items.where((i) => i.established).toList();
  final protectedItems = items
      .where((i) => !i.established && i.protected)
      .toList();
  final general = items.where((i) => !i.established && !i.protected).toList();

  // Authoritative: head-keep (the original request comes first).
  final authKept = _fitHead(established, budget.authoritativeShare);
  final authText = _renderItems(authKept);
  final authDropped = established.sublist(authKept.length);

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
    // terminate the authoritative section and let the budget drop it.
    buffer
      ..writeln(evidencePinBegin)
      ..writeln(authText)
      ..writeln(evidencePinEnd)
      ..writeln();
  }
  if (authDropped.isNotEmpty) {
    buffer
      ..writeln(_lossMarker(authDropped, 'authoritative instruction(s)'))
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
      if (pruneProtectedTools.contains(name)) {
        rebuilt.add(b);
        continue;
      }
      final path = call?.path;
      if (path != null && activeEditTargets.contains(path)) {
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
