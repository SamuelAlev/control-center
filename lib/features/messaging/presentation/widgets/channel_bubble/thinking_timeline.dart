import 'dart:async';
import 'dart:convert';

import 'package:control_center/core/domain/value_objects/thinking_event.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart' as sm;
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A collapsible event-timeline view of an agent's structured thinking.
///
/// Renders the events emitted by `MessagingService.dispatchAgent` — reasoning
/// spans, tool calls (paired with their results), errors, and sandbox
/// violations — as discrete rows so MCP work is legible at a glance.
class ThinkingTimeline extends StatefulWidget {
  /// Creates a [ThinkingTimeline].
  const ThinkingTimeline({
    super.key,
    required this.events,
    this.eventStream,
    this.isLive = false,
  });

  /// Events already persisted to the thinking message.
  final List<ThinkingEvent> events;

  /// Live event feed from `ActiveStreamRegistry.eventStreamFor`. When set,
  /// new events arriving on the stream are appended to the visible log.
  final Stream<ThinkingEvent>? eventStream;

  /// Whether the agent is still emitting events.
  final bool isLive;

  @override
  State<ThinkingTimeline> createState() => _ThinkingTimelineState();
}

class _ThinkingTimelineState extends State<ThinkingTimeline> {
  bool _expanded = false;
  final List<ThinkingEvent> _liveEvents = [];
  StreamSubscription<ThinkingEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant ThinkingTimeline old) {
    super.didUpdateWidget(old);
    if (old.eventStream != widget.eventStream) {
      _sub?.cancel();
      _liveEvents.clear();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _subscribe() {
    final stream = widget.eventStream;
    if (stream == null) {
      return;
    }
    _sub = stream.listen((event) {
      if (!mounted) {
        return;
      }
      setState(() => _liveEvents.add(event));
    });
  }

  /// Returns the union of persisted and live events. Live events that
  /// duplicate already-persisted ones (same timestamp + kind) are dropped.
  List<ThinkingEvent> _allEvents() {
    if (_liveEvents.isEmpty) {
      return widget.events;
    }
    if (widget.events.isEmpty) {
      return _liveEvents;
    }
    final persistedKeys = {
      for (final e in widget.events) '${e.timestamp.microsecondsSinceEpoch}|${e.kind}',
    };
    final extra = _liveEvents.where(
      (e) => !persistedKeys.contains('${e.timestamp.microsecondsSinceEpoch}|${e.kind}'),
    );
    return [...widget.events, ...extra];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final theme = Theme.of(context);
    final all = _allEvents();
    final rows = groupThinkingEvents(all);

    if (rows.isEmpty && !widget.isLive) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            isLive: widget.isLive,
            rows: rows,
            expanded: _expanded,
            onToggle: () => setState(() => _expanded = !_expanded),
            tokens: tokens,
            theme: theme,
          ),
          if (_expanded || (widget.isLive && rows.isNotEmpty))
            _TimelineBody(rows: rows, isLive: widget.isLive),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isLive,
    required this.rows,
    required this.expanded,
    required this.onToggle,
    required this.tokens,
    required this.theme,
  });

  final bool isLive;
  final List<ThinkingEventRow> rows;
  final bool expanded;
  final VoidCallback onToggle;
  final DesignSystemTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final toolCalls = rows.where((r) => r.primary.kind == ThinkingEventKind.toolCall).length;
    final totalMs = rows.fold<int>(
      0,
      (acc, r) => acc + (r.primary.duration?.inMilliseconds ?? 0),
    );
    final durationLabel = _formatDuration(Duration(milliseconds: totalMs));
    final summary = _buildSummary(rows, isLive, durationLabel, toolCalls);

    return FTappable(
      onPress: onToggle,
      focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            if (isLive)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: FCircularProgress(
                    style: FCircularProgressStyleDelta.delta(
                      iconStyle: IconThemeDataDelta.delta(size: 12),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                  size: 14,
                  color: tokens.fgTertiary,
                ),
              ),
            Expanded(
              child: Text(
                summary,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tokens.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _buildSummary(
    List<ThinkingEventRow> rows,
    bool isLive,
    String duration,
    int toolCalls,
  ) {
    if (rows.isEmpty) {
      return isLive ? 'Thinking…' : '';
    }
    if (isLive) {
      final last = rows.last.primary;
      return switch (last.kind) {
        ThinkingEventKind.toolCall => 'Running ${last.toolName ?? 'tool'}…',
        ThinkingEventKind.toolResult => 'Reading result…',
        ThinkingEventKind.reasoning => 'Thinking…',
        ThinkingEventKind.error => 'Recovering from error…',
        ThinkingEventKind.sandboxViolation => 'Sandbox blocked an action…',
      };
    }
    final base = 'Thought for $duration';
    if (toolCalls > 0) {
      return '$base · $toolCalls tool call${toolCalls == 1 ? '' : 's'}';
    }
    return base;
  }
}

class _TimelineBody extends StatelessWidget {
  const _TimelineBody({required this.rows, required this.isLive});

  final List<ThinkingEventRow> rows;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Container(
        padding: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: tokens.borderSecondary, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++)
              _TimelineRow(
                row: rows[i],
                isLast: i == rows.length - 1,
                pending: isLive && i == rows.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatefulWidget {
  const _TimelineRow({
    required this.row,
    required this.isLast,
    required this.pending,
  });

  final ThinkingEventRow row;
  final bool isLast;
  final bool pending;

  @override
  State<_TimelineRow> createState() => _TimelineRowState();
}

class _TimelineRowState extends State<_TimelineRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final theme = Theme.of(context);
    final primary = widget.row.primary;
    final decor = _decorate(primary, tokens);
    final canExpand = _hasExpandable(widget.row);

    final summaryRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(decor.icon, size: 14, color: decor.color),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            _summaryText(primary, tokens, theme),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (primary.duration != null)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              _formatDuration(primary.duration!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.textQuaternary,
                fontSize: 10,
              ),
            ),
          ),
        const SizedBox(width: 4),
        _StatusDot(row: widget.row, pending: widget.pending, tokens: tokens),
      ],
    );

    final header = canExpand
        ? FTappable(
            onPress: () => setState(() => _open = !_open),
            focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: summaryRow,
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: summaryRow,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (_open) _ExpandedDetail(row: widget.row),
      ],
    );
  }

  TextSpan _summaryText(
    ThinkingEvent ev,
    DesignSystemTokens tokens,
    ThemeData theme,
  ) {
    final base = theme.textTheme.labelSmall?.copyWith(
      color: tokens.textTertiary,
    );
    final mono = AppFonts.codeDynamic(
      theme.textTheme.bodySmall?.fontFamily ?? 'JetBrains Mono',
      textStyle: theme.textTheme.labelSmall?.copyWith(
        color: tokens.textPrimary,
      ),
    );
    switch (ev.kind) {
      case ThinkingEventKind.toolCall:
        return TextSpan(children: [
          TextSpan(text: ev.toolName ?? 'tool', style: mono),
          TextSpan(text: '(${_inputsPreview(ev.inputs)})', style: mono),
        ]);
      case ThinkingEventKind.reasoning:
        return TextSpan(text: _firstLine(ev.content) ?? 'Thinking…', style: base);
      case ThinkingEventKind.error:
        return TextSpan(
          text: _firstLine(ev.content) ?? 'Error',
          style: base?.copyWith(color: tokens.fgErrorPrimary),
        );
      case ThinkingEventKind.sandboxViolation:
        return TextSpan(
          text: _firstLine(ev.content) ?? 'Sandbox blocked an action',
          style: base?.copyWith(color: tokens.fgWarningPrimary),
        );
      case ThinkingEventKind.toolResult:
        return TextSpan(text: _firstLine(ev.content) ?? 'result', style: mono);
    }
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.row,
    required this.pending,
    required this.tokens,
  });

  final ThinkingEventRow row;
  final bool pending;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final primary = row.primary;
    Color color;
    IconData? icon;
    if (pending) {
      color = tokens.fgBrandPrimary;
      icon = LucideIcons.loaderCircle;
    } else if (primary.kind == ThinkingEventKind.toolCall) {
      if (row.result == null) {
        color = tokens.textQuaternary;
        icon = LucideIcons.minus;
      } else {
        color = tokens.fgSuccessPrimary;
        icon = LucideIcons.check;
      }
    } else if (primary.kind == ThinkingEventKind.error) {
      color = tokens.fgErrorPrimary;
      icon = LucideIcons.circleX;
    } else if (primary.kind == ThinkingEventKind.sandboxViolation) {
      color = tokens.fgWarningPrimary;
      icon = LucideIcons.shield;
    } else {
      return const SizedBox(width: 12, height: 12);
    }
    return Icon(icon, size: 12, color: color);
  }
}

class _ExpandedDetail extends StatelessWidget {
  const _ExpandedDetail({required this.row});

  final ThinkingEventRow row;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final theme = Theme.of(context);
    final primary = row.primary;
    final result = row.result;

    final monoStyle = AppFonts.codeDynamic(
      theme.textTheme.bodySmall?.fontFamily ?? 'JetBrains Mono',
      textStyle: theme.textTheme.bodySmall?.copyWith(
        color: tokens.textTertiary,
        height: 1.4,
      ),
    );

    Widget block(String label, String? body) {
      if (body == null || body.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.textQuaternary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens.bgPrimary,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: tokens.borderSecondary),
              ),
              child: SelectableText(body, style: monoStyle),
            ),
          ],
        ),
      );
    }

    if (primary.kind == ThinkingEventKind.toolCall) {
      final inputs = primary.inputs;
      final inputBody = inputs == null || inputs.isEmpty
          ? null
          : const JsonEncoder.withIndent('  ').convert(inputs);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            block('Inputs', inputBody ?? primary.content),
            block('Outputs', result?.outputs ?? result?.content),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: sm.SmoothMarkdown(
        data: primary.content,
        selectable: true,
        styleSheet: _thinkingMdStyle(tokens, theme),
        plugins: chatPlugins,
        builderRegistry: chatBuilders,
      ),
    );
  }
}

class _RowDecor {
  const _RowDecor(this.icon, this.color);
  final IconData icon;
  final Color color;
}

_RowDecor _decorate(ThinkingEvent ev, DesignSystemTokens tokens) {
  switch (ev.kind) {
    case ThinkingEventKind.reasoning:
      return _RowDecor(LucideIcons.brain, tokens.textTertiary);
    case ThinkingEventKind.toolCall:
      return _RowDecor(_toolIcon(ev.toolName), tokens.textPrimary);
    case ThinkingEventKind.toolResult:
      return _RowDecor(LucideIcons.cornerDownRight, tokens.textQuaternary);
    case ThinkingEventKind.error:
      return _RowDecor(LucideIcons.triangleAlert, tokens.fgErrorPrimary);
    case ThinkingEventKind.sandboxViolation:
      return _RowDecor(LucideIcons.shield, tokens.fgWarningPrimary);
  }
}

IconData _toolIcon(String? name) {
  if (name == null) {
    return LucideIcons.wrench;
  }
  final n = name.toLowerCase();
  if (n.contains('read') || n.contains('file')) {
    return LucideIcons.fileText;
  }
  if (n.contains('write') || n.contains('edit')) {
    return LucideIcons.pencil;
  }
  if (n.contains('grep') || n.contains('search') || n.contains('find')) {
    return LucideIcons.search;
  }
  if (n.contains('bash') || n.contains('shell') || n.contains('exec')) {
    return LucideIcons.terminal;
  }
  if (n.contains('http') || n.contains('curl') || n.contains('fetch') || n.contains('web')) {
    return LucideIcons.globe;
  }
  return LucideIcons.wrench;
}

String _inputsPreview(Map<String, dynamic>? inputs) {
  if (inputs == null || inputs.isEmpty) {
    return '';
  }
  final keys = inputs.keys.take(2).toList();
  return keys
      .map((k) {
        final v = inputs[k];
        final s = v is String ? v : v.toString();
        final preview = s.length > 24 ? '${s.substring(0, 24)}…' : s;
        return '$k: $preview';
      })
      .join(', ');
}

bool _hasExpandable(ThinkingEventRow row) {
  final primary = row.primary;
  if (primary.kind == ThinkingEventKind.toolCall) {
    return (primary.inputs != null && primary.inputs!.isNotEmpty) ||
        (row.result?.content.isNotEmpty ?? false) ||
        primary.content.isNotEmpty;
  }
  return primary.content.length > 80;
}

String? _firstLine(String content) {
  if (content.isEmpty) {
    return null;
  }
  final i = content.indexOf('\n');
  final line = (i == -1 ? content : content.substring(0, i)).trim();
  return line.isEmpty ? null : line;
}

String _formatDuration(Duration d) {
  if (d.inMilliseconds < 1000) {
    return '<1s';
  }
  if (d.inSeconds < 60) {
    return '${d.inSeconds}s';
  }
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return s == 0 ? '${m}m' : '${m}m ${s}s';
}

sm.MarkdownStyleSheet _thinkingMdStyle(
  DesignSystemTokens tokens,
  ThemeData theme,
) {
  final bodyStyle = theme.textTheme.bodySmall?.copyWith(
    color: tokens.textQuaternary,
    height: bodyLineHeight,
  );
  return sm.MarkdownStyleSheet.fromTheme(theme).copyWith(
    textStyle: bodyStyle,
    codeBlockStyle: AppFonts.codeDynamic(
      theme.textTheme.bodySmall?.fontFamily ?? 'JetBrains Mono',
      textStyle: theme.textTheme.bodySmall?.copyWith(
        color: tokens.textQuaternary,
        height: bodyLineHeight,
      ),
    ),
    inlineCodeStyle: AppFonts.codeDynamic(
      theme.textTheme.bodySmall?.fontFamily ?? 'JetBrains Mono',
      textStyle: theme.textTheme.bodySmall?.copyWith(
        color: tokens.textQuaternary,
        backgroundColor: tokens.bgPrimary,
        height: bodyLineHeight,
      ),
    ),
    linkStyle: theme.textTheme.bodySmall?.copyWith(
      color: tokens.textBrandTertiary,
      decoration: TextDecoration.underline,
      height: bodyLineHeight,
    ),
  );
}
