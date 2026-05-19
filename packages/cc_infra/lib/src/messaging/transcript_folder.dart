import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/messaging/json_content_extractor.dart';

/// Trailing debounce after a structural change (segment open/close, atomic
/// segment). Tool-heavy turns fire structural changes continuously; the
/// debounce coalesces them and [kStructuralFlushMaxLatency] bounds staleness.
const Duration kStructuralFlushDelay = Duration(milliseconds: 250);

/// Upper bound on how stale the persisted row may get while structural
/// changes keep re-arming the debounce.
const Duration kStructuralFlushMaxLatency = Duration(seconds: 1);

/// Throttle window for delta-only changes. The UI streams from the live
/// registry (relayed to thin clients via `messaging.watchChannelTurns` and
/// `agent_run_log.watchRunTranscript`), so mid-run DB writes are purely
/// crash-recovery insurance — a slow cadence is plenty and avoids
/// re-serializing segments on every token.
const Duration kDeltaFlushInterval = Duration(seconds: 2);

/// Folds an [AgentProcessEvent] stream into an ordered transcript, emitting a
/// [TranscriptUpdate] for every observable change.
///
/// Deliberately transport-free and persistence-free: the caller decides where
/// updates go (a live registry) and when to write the result. That is what lets
/// the same folding serve a channel turn (`AgentStreamProcessor`, keyed by
/// message id) and a subagent run (`RunTranscriptRecorder`, keyed by run id)
/// without duplicating any of the logic below — which is subtler than it looks
/// (tool pairing by call id with an orphan path, delta buffering to avoid
/// quadratic re-copies, an incremental flush-encode cache, and the tool-argument
/// echo guard).
class TranscriptFolder {
  /// Creates a folder that reports every change through [onUpdate].
  ///
  /// `structural` is false for delta-only changes (a growing text or tool
  /// output); callers use it to pick a flush cadence — see
  /// [kStructuralFlushDelay] and [kDeltaFlushInterval].
  TranscriptFolder({
    required this.onUpdate,
    this.contentExtractor = const JsonContentExtractor(),
  });

  /// Reports one observable transcript change.
  final void Function(TranscriptUpdate update, {required bool structural})
  onUpdate;

  /// Unwraps provider-specific JSON envelopes out of streamed content.
  final JsonContentExtractor contentExtractor;

  final List<TranscriptSegment> _segments = <TranscriptSegment>[];

  /// Index of the currently-open text or reasoning segment, or null.
  int? _openTextIndex;

  /// Whether [_openTextIndex] points at a reasoning (vs text) segment.
  bool _openIsReasoning = false;

  /// Buffered text for the open text/reasoning segment.
  final StringBuffer _openTextBuf = StringBuffer();

  /// Open tool segments keyed by their tool-call id (empty ids excluded).
  final Map<String, int> _openToolByCallId = <String, int>{};

  /// Partial-output accumulation per open tool segment index. Deltas append
  /// here (O(delta)); the segment materializes on close/flush — the old
  /// per-partial `outputs + delta` copyWith was quadratic over a big output.
  final Map<int, StringBuffer> _openToolBufs = <int, StringBuffer>{};

  /// Fallback for results whose tool-call id is empty / unknown.
  int? _lastOpenToolIndex;

  /// Incremental flush-encode cache: the JSON entry per segment index and the
  /// segment instance it was encoded from. Closed segments never change
  /// identity, so a flush re-encodes only open/changed indices instead of the
  /// whole transcript (the old `encodeTranscript(segments)` per flush was
  /// O(transcript²) over a turn).
  final List<Map<String, dynamic>> _encodedSegments = <Map<String, dynamic>>[];

  /// See [_encodedSegments].
  final List<TranscriptSegment?> _encodedFrom = <TranscriptSegment?>[];

  /// Index of the most recently closed **text** segment, held as a candidate
  /// for the tool-argument-echo guard while the tool calls it preceded arrive.
  /// Cleared as soon as anything other than a tool call follows the text.
  int? _argEchoCandidateIndex;

  /// What is left of [_argEchoCandidateIndex]'s text once the argument values of
  /// the tool calls seen so far have been subtracted. Whitespace-only (with
  /// [_argEchoMatched] set) means the segment was nothing but an echo.
  String _argEchoResidue = '';

  /// Whether at least one tool argument value was actually located in the
  /// candidate's text — so an ordinarily-empty text segment is never mistaken
  /// for a fully-subtracted echo.
  bool _argEchoMatched = false;

  int _transcriptChars = 0;

  /// The ordered transcript. Open segments hold a stale entry while their
  /// buffer grows — read through [materialized] or [snapshot] for exact text.
  List<TranscriptSegment> get segments => _segments;

  /// Number of segments folded so far.
  int get length => _segments.length;

  /// Running character count of the transcript (text + reasoning + tool
  /// name/inputs/outputs + error prose). Persisted alongside the segments so
  /// thin clients — which receive list rows WITHOUT segments — can still
  /// estimate context-window usage.
  int get transcriptChars => _transcriptChars;

  /// Folds [event] into the transcript.
  ///
  /// Returns false for the events the folder does not own — [UsageEvent],
  /// [DebugEvent] and [DoneEvent] — so the caller can handle cost accounting,
  /// diagnostics and stream completion itself.
  bool add(AgentProcessEvent event) {
    switch (event) {
      case TextEvent():
        _appendText(event, reasoning: false);
      case ThinkingEvent():
        _appendText(event, reasoning: true);
      case ToolCallEvent():
        _openTool(event);
      case ToolResultEvent():
        _applyToolResult(event);
      case ErrorEvent():
        _addAtomic(
          ErrorSegment(
            message: event.content,
            code: event.code,
            source: event.source,
            startedAt: event.timestamp,
          ),
        );
      case SandboxViolationEvent():
        _addAtomic(
          ViolationSegment(
            message: event.content,
            action: event.action,
            target: event.target,
            suggestedCapability: event.suggestedCapability,
            startedAt: event.timestamp,
          ),
        );
      case UsageEvent():
      case DebugEvent():
      case DoneEvent():
        return false;
    }
    return true;
  }

  /// Appends [segment] to the transcript WITHOUT reporting an update.
  ///
  /// Only for a terminal segment added after the live lane has stopped being
  /// observed (the error a failed stream ends on): it reaches the persisted
  /// transcript, and a client sees it on reload rather than mid-stream.
  void appendUnreported(TranscriptSegment segment) {
    _segments.add(segment);
  }

  void _appendText(AgentProcessEvent event, {required bool reasoning}) {
    final extracted = contentExtractor.extractContent(
      content: event.content,
      metadata: event.metadata,
    );
    if (extracted.isEmpty) {
      return;
    }
    _transcriptChars += extracted.length;

    // A switch in kind (text<->reasoning) closes the previous open segment.
    if (_openTextIndex != null && _openIsReasoning != reasoning) {
      closeOpenText(event.timestamp);
    }

    final idx = _openTextIndex;
    if (idx == null) {
      // A new text/reasoning run means the previous text segment was not
      // immediately followed by tool calls — it cannot be an argument echo.
      _clearArgEchoCandidate();
      _openTextBuf
        ..clear()
        ..write(extracted);
      _openIsReasoning = reasoning;
      final seg = reasoning
          ? ReasoningSegment(text: extracted, startedAt: event.timestamp)
          : TextSegment(text: extracted, startedAt: event.timestamp);
      _segments.add(seg);
      _openTextIndex = _segments.length - 1;
      _apply(SegmentOpened(_openTextIndex!, seg), structural: true);
    } else {
      // Accumulate in the buffer only; the segment entry stays stale until
      // close/flush ([materialized]) — replacing it per delta re-copied the
      // whole accumulated text every token (quadratic over a long answer).
      _openTextBuf.write(extracted);
      _apply(SegmentDelta(idx, extracted), structural: false);
    }
  }

  /// Closes the open text/reasoning segment, if any, stamping its duration.
  void closeOpenText(DateTime now) {
    final idx = _openTextIndex;
    if (idx == null) {
      return;
    }
    final current = _segments[idx];
    final durationMs = now.difference(current.startedAt).inMilliseconds;
    final text = _openTextBuf.toString();
    final closed = current is ReasoningSegment
        ? current.copyWith(text: text, durationMs: durationMs)
        : (current as TextSegment).copyWith(text: text, durationMs: durationMs);
    _segments[idx] = closed;
    _openTextIndex = null;
    _openTextBuf.clear();
    if (closed is TextSegment) {
      _argEchoCandidateIndex = idx;
      _argEchoResidue = text;
      _argEchoMatched = false;
    } else {
      _clearArgEchoCandidate();
    }
    _apply(SegmentClosed(idx, closed), structural: true);
  }

  void _clearArgEchoCandidate() {
    _argEchoCandidateIndex = null;
    _argEchoResidue = '';
    _argEchoMatched = false;
  }

  /// Drops an assistant text segment that turned out to be nothing but a
  /// verbatim echo of the tool arguments that followed it.
  ///
  /// Some OpenAI-compatible servers stream one tool call twice: once as
  /// `delta.content` and once as `delta.tool_calls`. MTPLX (local Qwen) does it
  /// when its streaming tool parser misses the envelope and falls back to
  /// re-parsing the raw text — the content path strips the `<tool_call>` /
  /// `<function=…>` / `<parameter=…>` tags one by one and lets their inner text
  /// through, so the transcript gets a prose bubble holding the bare command or
  /// file path immediately above the rich tool row for the same call.
  ///
  /// The subtraction is cumulative because one text segment can precede several
  /// calls: each call removes its own argument values from the residue, and only
  /// when nothing but whitespace is left — and at least one value actually
  /// matched — is the segment blanked. Any real prose in the segment leaves a
  /// non-empty residue and protects it.
  ///
  /// Blanking (rather than removing) keeps every segment index stable for the
  /// live registry and thin-client relay; an empty closed text segment renders
  /// as nothing and [currentText] already skips it, so the echo also leaves
  /// the persisted message body, its embedding, and notification previews.
  void _absorbToolArgEcho(Map<String, dynamic>? inputs) {
    final idx = _argEchoCandidateIndex;
    if (idx == null || inputs == null || inputs.isEmpty) {
      return;
    }
    var residue = _argEchoResidue;
    for (final value in inputs.values) {
      if (value is! String) {
        continue;
      }
      final needle = value.trim();
      if (needle.isEmpty) {
        continue;
      }
      final at = residue.indexOf(needle);
      if (at < 0) {
        continue;
      }
      residue = residue.replaceRange(at, at + needle.length, '');
      _argEchoMatched = true;
    }
    _argEchoResidue = residue;
    if (!_argEchoMatched || residue.trim().isNotEmpty) {
      return;
    }
    final seg = _segments[idx];
    if (seg is! TextSegment || seg.text.isEmpty) {
      _clearArgEchoCandidate();
      return;
    }
    final blanked = seg.copyWith(text: '');
    _segments[idx] = blanked;
    _transcriptChars = _transcriptChars - seg.text.length < 0
        ? 0
        : _transcriptChars - seg.text.length;
    _clearArgEchoCandidate();
    _apply(SegmentClosed(idx, blanked), structural: true);
  }

  void _openTool(ToolCallEvent event) {
    closeOpenText(event.timestamp);
    _absorbToolArgEcho(event.inputs);
    _transcriptChars +=
        event.toolName.length + (event.inputs?.toString().length ?? 0);
    final seg = ToolSegment(
      toolName: event.toolName,
      toolCallId: event.toolCallId,
      inputs: event.inputs,
      startedAt: event.timestamp,
    );
    _segments.add(seg);
    final idx = _segments.length - 1;
    if (event.toolCallId.isNotEmpty) {
      _openToolByCallId[event.toolCallId] = idx;
    }
    _lastOpenToolIndex = idx;
    _apply(SegmentOpened(idx, seg), structural: true);
  }

  void _applyToolResult(ToolResultEvent event) {
    final target =
        (event.toolCallId.isNotEmpty
            ? _openToolByCallId[event.toolCallId]
            : null) ??
        _lastOpenToolIndex;

    if (target == null || _segments[target] is! ToolSegment) {
      // Orphan result — no matching open call. Render as a terminal cell.
      _transcriptChars +=
          (event.toolName ?? 'tool').length + event.outputs.length;
      final seg = ToolSegment(
        toolName: event.toolName ?? 'tool',
        toolCallId: event.toolCallId,
        outputs: event.outputs,
        status: event.isError ? ToolSegmentStatus.error : ToolSegmentStatus.ok,
        startedAt: event.timestamp,
        durationMs: 0,
      );
      _segments.add(seg);
      final idx = _segments.length - 1;
      _apply(SegmentOpened(idx, seg), structural: true);
      _apply(SegmentClosed(idx, seg), structural: true);
      return;
    }

    final existing = _segments[target] as ToolSegment;
    if (event.isPartial) {
      // Buffer only (see _appendText): the per-partial `outputs + delta`
      // copyWith re-copied the whole accumulated output every chunk.
      _transcriptChars += event.outputs.length;
      (_openToolBufs[target] ??= StringBuffer(
        existing.outputs,
      )).write(event.outputs);
      _apply(SegmentDelta(target, event.outputs), structural: false);
      return;
    }

    final durationMs = event.timestamp
        .difference(existing.startedAt)
        .inMilliseconds;
    // The final result carries the full output; discard partial accumulation
    // (and reconcile the char counter with the authoritative final length).
    final partial = _openToolBufs.remove(target);
    _transcriptChars +=
        event.outputs.length - (partial?.length ?? existing.outputs.length);
    final closed = existing.copyWith(
      outputs: event.outputs,
      status: event.isError ? ToolSegmentStatus.error : ToolSegmentStatus.ok,
      durationMs: durationMs,
    );
    _segments[target] = closed;
    if (event.toolCallId.isNotEmpty) {
      _openToolByCallId.remove(event.toolCallId);
    }
    if (_lastOpenToolIndex == target) {
      _lastOpenToolIndex = null;
    }
    _apply(SegmentClosed(target, closed), structural: true);
  }

  void _addAtomic(TranscriptSegment segment) {
    closeOpenText(segment.startedAt);
    _clearArgEchoCandidate();
    _transcriptChars += switch (segment) {
      ErrorSegment(:final message) => message.length,
      ViolationSegment(:final message) => message.length,
      _ => 0,
    };
    _segments.add(segment);
    final idx = _segments.length - 1;
    _apply(SegmentOpened(idx, segment), structural: true);
    _apply(SegmentClosed(idx, segment), structural: true);
  }

  void _apply(TranscriptUpdate update, {required bool structural}) {
    onUpdate(update, structural: structural);
  }

  /// Marks every still-running tool segment interrupted, keeping whatever
  /// partial output accumulated before the interruption.
  void interruptRunningTools(DateTime now) {
    for (var i = 0; i < _segments.length; i++) {
      final seg = _segments[i];
      if (seg is ToolSegment && seg.status == ToolSegmentStatus.running) {
        final buffered = _openToolBufs.remove(i);
        _segments[i] = seg.copyWith(
          outputs: buffered?.toString() ?? seg.outputs,
          status: ToolSegmentStatus.interrupted,
          durationMs: now.difference(seg.startedAt).inMilliseconds,
        );
      }
    }
  }

  /// The segment at [index] with any open-buffer accumulation applied. Open
  /// text/tool segments keep a stale entry in [segments] while their buffer
  /// grows; reads materialize on demand.
  TranscriptSegment materialized(int index) {
    final seg = _segments[index];
    if (index == _openTextIndex) {
      final text = _openTextBuf.toString();
      return seg is ReasoningSegment
          ? seg.copyWith(text: text)
          : (seg as TextSegment).copyWith(text: text);
    }
    final buf = _openToolBufs[index];
    if (buf != null && seg is ToolSegment) {
      return seg.copyWith(outputs: buf.toString());
    }
    return seg;
  }

  /// A fully-materialized copy of the transcript, safe to hand out.
  List<TranscriptSegment> snapshot() => [
    for (var i = 0; i < _segments.length; i++) materialized(i),
  ];

  /// The visible answer text: every non-blank text segment, joined.
  String currentText() {
    final buf = <String>[];
    for (var i = 0; i < _segments.length; i++) {
      final seg = i == _openTextIndex ? materialized(i) : _segments[i];
      if (seg is TextSegment && seg.text.trim().isNotEmpty) {
        buf.add(seg.text.trim());
      }
    }
    return buf.join('\n\n').trim();
  }

  /// Encodes the transcript for a mid-run flush, re-encoding ONLY segments
  /// that changed since the last flush (open buffers + replaced instances).
  /// Closed segments are immutable, so identity is the change signal.
  List<Map<String, dynamic>> encodeForFlush() {
    final encoded = _encodedSegments;
    final from = _encodedFrom;
    if (encoded.length > _segments.length) {
      encoded.removeRange(_segments.length, encoded.length);
      from.removeRange(_segments.length, from.length);
    }
    for (var i = 0; i < _segments.length; i++) {
      final source = _segments[i];
      final isOpen = i == _openTextIndex || _openToolBufs.containsKey(i);
      if (i < encoded.length && !isOpen && identical(from[i], source)) {
        continue;
      }
      final json = materialized(i).toJson();
      if (i < encoded.length) {
        encoded[i] = json;
        from[i] = isOpen ? null : source;
      } else {
        encoded.add(json);
        from.add(isOpen ? null : source);
      }
    }
    return List<Map<String, dynamic>>.of(encoded);
  }

  /// The trailing error/violation prose of a turn that produced no answer text,
  /// or null when the turn did not end on a failure.
  ///
  /// Walks the transcript backwards and stops at the first visible answer, so an
  /// error the agent recovered from mid-run never marks the whole turn failed.
  String? terminalFailure() {
    for (var i = _segments.length - 1; i >= 0; i--) {
      final seg = _segments[i];
      if (seg is TextSegment && seg.text.trim().isNotEmpty) {
        return null;
      }
      if (seg is ErrorSegment && seg.message.trim().isNotEmpty) {
        return seg.message.trim();
      }
      if (seg is ViolationSegment && seg.message.trim().isNotEmpty) {
        return seg.message.trim();
      }
    }
    return null;
  }
}
