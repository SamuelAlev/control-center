import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/services/tool_display_name.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/script_calls.dart';
import 'package:cc_remote/syntax/diff_highlighter.dart';
import 'package:cc_remote/widgets/phone_markdown.dart';
import 'package:cc_remote/widgets/script_calls_list.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

part 'agent_transcript_details.dart';
part 'agent_transcript_scripts.dart';

/// Renders an agent turn's transcript as one **continuous, inline flow** —
/// reasoning, tool calls (with inputs/outputs), errors, sandbox violations and
/// the answer text, all in the chronological order they were emitted, rather
/// than collapsing the process and printing the answer separately at the end.
/// Updates live from the turn relay, not from the list row.
///
/// A call a script made renders inside the row of the call that ran the
/// script, drawn by the same row a direct call gets; one whose script is not
/// in [segments] keeps a row of its own.
///
/// Material-free (cc_ui only), so it renders on the phone PWA.
class AgentTranscript extends StatefulWidget {
  /// Creates an [AgentTranscript].
  const AgentTranscript({
    required this.segments,
    required this.isLive,
    super.key,
  });

  /// The decoded transcript segments (reasoning/tool/error/violation).
  final List<TranscriptSegment> segments;

  /// Whether the agent is still emitting (the host sets `streamComplete`).
  final bool isLive;

  @override
  State<AgentTranscript> createState() => _AgentTranscriptState();
}

class _AgentTranscriptState extends State<AgentTranscript> {
  /// Rows the user has expanded to inspect inputs/outputs, by the segment's
  /// position in the transcript: tool call ids repeat (local models reuse
  /// `call_0`), and two rows sharing one must not open together.
  final Set<String> _expanded = {};

  void _update(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final segments = widget.segments;
    if (segments.isEmpty && !widget.isLive) {
      return const SizedBox.shrink();
    }
    final nested = foldNestedCalls(segments);
    final folded = {for (final calls in nested.values) ...calls};
    final children = <Widget>[];
    for (var i = 0; i < segments.length; i++) {
      if (folded.contains(i)) {
        continue;
      }
      final seg = segments[i];
      final row = _row(t, seg, i, [
        for (final c in nested[i] ?? const <int>[])
          if (segments[c] case final ToolSegment call) (c, call),
      ]);
      if (row == null) {
        continue;
      }
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 8));
      }
      children.add(row);
    }
    if (widget.isLive) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 8));
      }
      children.add(_liveTail(t));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// The "still working" footer shown while the turn streams.
  Widget _liveTail(DesignSystemTokens t) {
    return Row(
      children: [
        Icon(AppIcons.loader, size: 12, color: t.fgTertiary),
        const SizedBox(width: 5),
        Text(
          AppLocalizations.of(context).working,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: t.fgTertiary,
          ),
        ),
      ],
    );
  }

  Widget? _row(
    DesignSystemTokens t,
    TranscriptSegment seg,
    int index,
    List<(int, ToolSegment)> calls,
  ) {
    return switch (seg) {
      final ToolSegment s => _tool(t, s, index, calls: calls),
      final ReasoningSegment s => _reasoning(t, s),
      final ErrorSegment s when s.isAuthentication => _authFailure(
        context,
        t,
        s,
      ),
      ErrorSegment(isSandboxUnavailable: true) => _sandboxUnavailable(context),
      final ErrorSegment s => _mono(
        t,
        s.message,
        t.dangerSoft,
        t.textErrorPrimary,
      ),
      final ViolationSegment s => _mono(
        t,
        s.target == null ? s.message : '${s.message}: ${s.target}',
        t.warnSoft,
        t.textWarningPrimary,
      ),
      final TextSegment s => _answer(t, s),
    };
  }

  /// Answer markdown stays in its chronological position in the transcript.
  Widget? _answer(DesignSystemTokens t, TextSegment s) {
    if (s.text.trim().isEmpty) {
      return null;
    }
    return PhoneMarkdown(data: s.text);
  }

  /// The row of the tool call [s], the segment at [index]; [calls] are the
  /// calls it made as a script, each with its own index.
  Widget _tool(
    DesignSystemTokens t,
    ToolSegment s,
    int index, {
    List<(int, ToolSegment)> calls = const [],
  }) {
    final key = '$index';
    final open = _expanded.contains(key);
    final callSegments = [for (final (_, call) in calls) call];
    final script = isReplTool(s.toolName);
    // Keep per-call summaries as the primary label; protocol names belong in
    // expanded diagnostics, not the row header.
    final description = s.inputs?['description'];
    final l10n = AppLocalizations.of(context);
    final label = description is String && description.trim().isNotEmpty
        ? description.trim().split('\n').first
        : resolveToolDisplayName(
            s.toolName,
            todos: l10n.transcriptToolTodos,
            searchMemory: l10n.transcriptToolSearchMemory,
            renderMedia: l10n.transcriptToolRenderMedia,
          );
    final showIdentifier = s.toolName.isNotEmpty && s.toolName != label;
    final (icon, color) = switch (nestedCallStateOf(s)) {
      NestedCallState.running => (AppIcons.loader, t.fgTertiary),
      NestedCallState.ok => (AppIcons.check, t.fgSuccessPrimary),
      NestedCallState.failed => (AppIcons.x, t.textErrorPrimary),
      // Refused before it ran: not a tool that failed.
      NestedCallState.denied => (AppIcons.circleSlash, t.fgWarningPrimary),
      NestedCallState.cancelled => (AppIcons.minus, t.fgTertiary),
    };
    return CcTappable(
      onPressed: () => _toggle(key),
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: t.bgSecondary,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 13, color: color),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CcFonts.code(
                        textStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: t.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (calls.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      _callSummary(l10n, NestedCallTally.of(callSegments)),
                      style: TextStyle(fontSize: 11, color: t.textTertiary),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (showIdentifier ||
                      calls.isNotEmpty ||
                      s.outputs.isNotEmpty ||
                      s.inputs != null) ...[
                    Icon(
                      open ? AppIcons.chevronDown : AppIcons.chevronRight,
                      size: 12,
                      color: t.fgTertiary,
                    ),
                  ],
                ],
              ),
              if (open && script) ..._scriptDetail(t, s, index, calls),
              if (open && !script) ...[
                if (showIdentifier)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: SelectableRegion(
                        selectionControls: emptyTextSelectionControls,
                        child: Text(
                          s.toolName,
                          style: CcFonts.code(
                            textStyle: TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: t.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (s.inputs != null)
                  _detail(
                    t,
                    AppLocalizations.of(context).input,
                    _pretty(s.inputs),
                  ),
                if (s.outputs.isNotEmpty)
                  _detail(t, AppLocalizations.of(context).output, s.outputs),
                if (calls.isNotEmpty) ..._nestedCalls(t, calls),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
