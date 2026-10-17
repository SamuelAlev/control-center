import 'dart:convert';

import 'package:cc_domain/core/domain/services/tool_display_name.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/phone_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

part 'agent_transcript_details.dart';

/// Renders an agent turn's transcript as one **continuous, inline flow** —
/// reasoning, tool calls (with inputs/outputs), errors, sandbox violations and
/// the answer text, all in the chronological order they were emitted, rather
/// than collapsing the process and printing the answer separately at the end.
/// Updates live from the turn relay, not from the list row.
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
  /// Tool call ids the user has expanded to inspect inputs/outputs.
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final segments = widget.segments;
    if (segments.isEmpty && !widget.isLive) {
      return const SizedBox.shrink();
    }
    final children = <Widget>[];
    for (final seg in segments) {
      final row = _row(t, seg);
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

  Widget? _row(DesignSystemTokens t, TranscriptSegment seg) {
    return switch (seg) {
      final ToolSegment s => _tool(t, s),
      final ReasoningSegment s => _reasoning(t, s),
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

  Widget? _reasoning(DesignSystemTokens t, ReasoningSegment s) {
    if (s.text.trim().isEmpty) {
      return null;
    }
    // A faint leading rail sets the agent's thinking apart from its answer now
    // that both interleave in one column (the answer is upright primary text).
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: t.borderSecondary, width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 8),
        child: Text(
          s.text,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            fontStyle: FontStyle.italic,
            color: t.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _mono(DesignSystemTokens t, String text, Color bg, Color fg) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        // RTL carve-out: error/violation payloads are log output — LTR in
        // every locale.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            text,
            style: CcFonts.code(
              textStyle: TextStyle(fontSize: 12, height: 1.4, color: fg),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tool(DesignSystemTokens t, ToolSegment s) {
    final open = _expanded.contains(s.toolCallId);
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
    final (icon, color) = switch (s.status) {
      ToolSegmentStatus.running => (AppIcons.loader, t.fgTertiary),
      ToolSegmentStatus.ok => (AppIcons.check, t.fgSuccessPrimary),
      ToolSegmentStatus.error => (AppIcons.x, t.textErrorPrimary),
      ToolSegmentStatus.interrupted => (AppIcons.minus, t.fgTertiary),
    };
    return CcTappable(
      onPressed: () => setState(() {
        if (s.toolCallId.isEmpty) {
          return;
        }
        if (open) {
          _expanded.remove(s.toolCallId);
        } else {
          _expanded.add(s.toolCallId);
        }
      }),
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
                  if (showIdentifier ||
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
              if (open) ...[
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
