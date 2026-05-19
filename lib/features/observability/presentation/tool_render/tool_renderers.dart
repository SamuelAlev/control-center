import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/run_activity_providers.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/tool_render/run_activity_opener_scope.dart';
import 'package:control_center/features/observability/presentation/tool_render/tool_render_parts.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A per-tool renderer: a one-line [summary] always shown in the card header and
/// an optional expandable [body] with the full detail.
///
/// Renderers turn an opaque [ToolSegment] (tool name + JSON args + raw output)
/// into a readable, auditable card — a bash command/output split, an edit's
/// diff, a subagent task's outcome — instead of dumped JSON. Look one up with
/// [resolveToolRenderer]; render with [ToolCallCard].
abstract class ToolRenderer {
  /// Const base constructor.
  const ToolRenderer();

  /// The always-visible one-line summary (right of the tool name).
  Widget summary(BuildContext context, ToolSegment s);

  /// The expandable detail body, or null when the summary says it all.
  Widget? body(BuildContext context, ToolSegment s) => null;
}

/// Normalizes a wire tool name for registry lookup: strips a leading
/// `mcp__<server>__` prefix and lowercases (`mcp__cc__create_ticket` →
/// `create_ticket`, `Read` → `read`).
String normalizeToolName(String raw) {
  var name = raw.trim();
  final mcp = RegExp(r'^mcp__[^_]+(?:_[^_]+)*__(.+)$').firstMatch(name);
  if (mcp != null) {
    name = mcp.group(1)!;
  } else if (name.startsWith('mcp__')) {
    name = name.substring(name.lastIndexOf('__') + 2);
  }
  return name.toLowerCase();
}

const _bash = BashRenderer();
const _edit = EditRenderer();
const _read = ReadRenderer();
const _search = SearchRenderer();
const _task = TaskRenderer();
const _github = GithubRenderer();
const _lsp = LspRenderer();
const _memory = MemoryRenderer();
const _browser = BrowserRenderer();
const _job = JobRenderer();
const _todo = TodoRenderer();
const _generic = GenericToolRenderer();

const Map<String, ToolRenderer> _registry = {
  'bash': _bash,
  'shell': _bash,
  'run_command': _bash,
  'terminal': _bash,
  'edit': _edit,
  'apply_patch': _edit,
  'str_replace': _edit,
  'str_replace_editor': _edit,
  'write': _edit,
  'create_file': _edit,
  'read': _read,
  'view': _read,
  'cat': _read,
  'search': _search,
  'grep': _search,
  'glob': _search,
  'find': _search,
  'ripgrep': _search,
  'task': _task,
  'hire_agent': _task,
  'dispatch_reviewers': _task,
  'consult_agent': _task,
  'agent': _task,
  'github': _github,
  'gh': _github,
  'create_pr': _github,
  'pr': _github,
  'lsp': _lsp,
  'diagnostics': _lsp,
  'references': _lsp,
  'rename': _lsp,
  'memory': _memory,
  'recall': _memory,
  'recall_facts': _memory,
  'manage_memory': _memory,
  'retain': _memory,
  'reflect': _memory,
  'remember': _memory,
  'browser': _browser,
  'puppeteer': _browser,
  'navigate': _browser,
  'fetch': _browser,
  'web_search': _browser,
  'job': _job,
  'poll': _job,
  'cancel_job': _job,
  'await': _job,
  'todo': _todo,
  'todowrite': _todo,
  // Our own MCP checklist tools. `normalizeToolName` strips the
  // `mcp__<server>__` prefix but not underscores, so `todo_write` never matched
  // the `todowrite` alias and every checklist call fell through to the generic
  // card — the transitions the agent is asked to make were invisible.
  'todo_write': _todo,
  'todo_read': _todo,
  'update_plan': _todo,
};

/// Resolves the renderer for [toolName] (aliases included), or a generic
/// fallback that shows the args + output for any unknown tool.
ToolRenderer resolveToolRenderer(String toolName) =>
    _registry[normalizeToolName(toolName)] ?? _generic;

String _str(Map<String, dynamic>? inputs, List<String> keys) {
  if (inputs == null) {
    return '';
  }
  for (final key in keys) {
    final value = inputs[key];
    if (value != null && '$value'.isNotEmpty) {
      return compactArg(value);
    }
  }
  return '';
}

Map<String, String> _argMap(Map<String, dynamic>? inputs) {
  if (inputs == null) {
    return const {};
  }
  return {
    for (final entry in inputs.entries)
      if (entry.value != null)
        entry.key: entry.value is String
            ? entry.value as String
            : jsonEncode(entry.value),
  };
}

ObsTone _statusTone(ToolSegmentStatus status) => switch (status) {
  ToolSegmentStatus.running => ObsTone.brand,
  ToolSegmentStatus.ok => ObsTone.success,
  ToolSegmentStatus.error => ObsTone.danger,
  ToolSegmentStatus.interrupted => ObsTone.warning,
};

Widget _summaryText(BuildContext context, String text, {bool error = false}) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Text(
    text.isEmpty ? '—' : text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: CcTypography.monoNum.copyWith(
      fontSize: 12,
      color: error ? t.textErrorPrimary : t.textSecondary,
    ),
  );
}

/// Fallback renderer: a compact arg preview + the full args grid and output.
class GenericToolRenderer extends ToolRenderer {
  /// Creates a [GenericToolRenderer].
  const GenericToolRenderer();

  @override
  Widget summary(BuildContext context, ToolSegment s) {
    final first = s.inputs == null || s.inputs!.isEmpty
        ? ''
        : compactArg(s.inputs!.values.first);
    return _summaryText(context, ellipsize(first, 80), error: s.isError);
  }

  @override
  Widget? body(BuildContext context, ToolSegment s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ToolKvGrid(entries: _argMap(s.inputs)),
      if (s.outputs.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        OutputBlock(text: s.outputs, error: s.isError),
      ],
    ],
  );
}

/// `bash` — command + output split into sections.
class BashRenderer extends ToolRenderer {
  /// Creates a [BashRenderer].
  const BashRenderer();

  @override
  Widget summary(BuildContext context, ToolSegment s) => _summaryText(
    context,
    ellipsize(_str(s.inputs, ['command', 'cmd', 'script']), 88),
    error: s.isError,
  );

  @override
  Widget? body(BuildContext context, ToolSegment s) {
    final command = _str(s.inputs, ['command', 'cmd', 'script']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (command.isNotEmpty)
          OutputBlock(text: '\$ $command', maxLines: 6, title: 'command'),
        if (s.outputs.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          OutputBlock(text: s.outputs, error: s.isError, title: 'output'),
        ],
      ],
    );
  }
}

/// `edit` — file path + a minimal old/new diff.
class EditRenderer extends ToolRenderer {
  /// Creates an [EditRenderer].
  const EditRenderer();

  @override
  Widget summary(BuildContext context, ToolSegment s) {
    final path = _str(s.inputs, ['file_path', 'path', 'filename']);
    final base = path.isEmpty ? path : path.split('/').last;
    return _summaryText(context, base, error: s.isError);
  }

  @override
  Widget? body(BuildContext context, ToolSegment s) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final path = _str(s.inputs, ['file_path', 'path', 'filename']);
    final oldStr = _str(s.inputs, ['old_string', 'old_str', 'old']);
    final newStr = _str(s.inputs, ['new_string', 'new_str', 'new', 'content']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (path.isNotEmpty)
          Text(
            path,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
        if (oldStr.isNotEmpty || newStr.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          if (oldStr.isNotEmpty)
            OutputBlock(
              text: _prefixLines(oldStr, '- '),
              error: true,
              maxLines: 8,
            ),
          if (newStr.isNotEmpty)
            OutputBlock(text: _prefixLines(newStr, '+ '), maxLines: 8),
        ] else if (s.outputs.isNotEmpty)
          OutputBlock(text: s.outputs, error: s.isError),
      ],
    );
  }

  String _prefixLines(String text, String prefix) =>
      text.split('\n').map((l) => '$prefix$l').join('\n');
}

/// `read` — path with optional range.
class ReadRenderer extends ToolRenderer {
  /// Creates a [ReadRenderer].
  const ReadRenderer();

  @override
  Widget summary(BuildContext context, ToolSegment s) {
    final path = _str(s.inputs, ['file_path', 'path', 'filename']);
    final offset = _str(s.inputs, ['offset', 'line']);
    final limit = _str(s.inputs, ['limit']);
    final suffix = offset.isEmpty
        ? ''
        : ':$offset${limit.isEmpty ? '' : '-$limit'}';
    return _summaryText(context, '$path$suffix', error: s.isError);
  }

  @override
  Widget? body(BuildContext context, ToolSegment s) =>
      s.outputs.isEmpty ? null : OutputBlock(text: s.outputs, error: s.isError);
}

/// `search` / `grep` — pattern + paths.
class SearchRenderer extends ToolRenderer {
  /// Creates a [SearchRenderer].
  const SearchRenderer();

  @override
  Widget summary(BuildContext context, ToolSegment s) {
    final pattern = _str(s.inputs, ['pattern', 'query', 'q', 'regex']);
    final path = _str(s.inputs, ['path', 'glob', 'include']);
    final label = pattern.isEmpty ? '' : '/$pattern/';
    return _summaryText(
      context,
      path.isEmpty ? label : '$label  $path',
      error: s.isError,
    );
  }

  @override
  Widget? body(BuildContext context, ToolSegment s) =>
      s.outputs.isEmpty ? null : OutputBlock(text: s.outputs, error: s.isError);
}

/// `task` / subagent spawn — assignment + outcome chip (the structured
/// subagent-task result card).
class TaskRenderer extends ToolRenderer {
  /// Creates a [TaskRenderer].
  const TaskRenderer();

  @override
  Widget summary(BuildContext context, ToolSegment s) {
    final assignment = _str(s.inputs, [
      'description',
      'assignment',
      'prompt',
      'task',
      'objective',
    ]);
    return Row(
      children: [
        _SubagentChip(segment: s, label: assignment),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _summaryText(
            context,
            ellipsize(assignment, 72),
            error: s.isError,
          ),
        ),
      ],
    );
  }

  @override
  Widget? body(BuildContext context, ToolSegment s) {
    final outcome = switch (s.status) {
      ToolSegmentStatus.ok => 'done',
      ToolSegmentStatus.error => 'failed',
      ToolSegmentStatus.interrupted => 'aborted',
      ToolSegmentStatus.running => 'running',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ToolChip(label: outcome, tone: _statusTone(s.status)),
            if (s.durationMs != null) ...[
              const SizedBox(width: AppSpacing.sm),
              ToolChip(label: fmtDuration(s.durationMs!)),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ToolKvGrid(entries: _argMap(s.inputs)),
        if (s.outputs.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          OutputBlock(text: s.outputs, error: s.isError, title: 'result'),
        ],
      ],
    );
  }
}

/// `github` — operation + salient context.
class GithubRenderer extends ToolRenderer {
  /// Creates a [GithubRenderer].
  const GithubRenderer();

  @override
  Widget summary(BuildContext context, ToolSegment s) {
    final op = _str(s.inputs, ['op', 'action', 'command']);
    final ctx = _str(s.inputs, ['query', 'pr', 'pr_number', 'branch', 'repo']);
    return Row(
      children: [
        if (op.isNotEmpty) ...[
          ToolChip(label: op, tone: ObsTone.brand),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: _summaryText(context, ellipsize(ctx, 72), error: s.isError),
        ),
      ],
    );
  }

  @override
  Widget? body(BuildContext context, ToolSegment s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ToolKvGrid(entries: _argMap(s.inputs)),
      if (s.outputs.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        OutputBlock(text: s.outputs, error: s.isError),
      ],
    ],
  );
}

/// `lsp` — action + file:line + symbol.
class LspRenderer extends ToolRenderer {
  /// Creates an [LspRenderer].
  const LspRenderer();

  @override
  Widget summary(BuildContext context, ToolSegment s) {
    final action = _str(s.inputs, ['action', 'op']);
    final file = _str(s.inputs, ['file', 'file_path', 'path']);
    final symbol = _str(s.inputs, ['symbol', 'name', 'query']);
    final parts = [
      if (action.isNotEmpty) action,
      if (file.isNotEmpty) file.split('/').last,
      if (symbol.isNotEmpty) symbol,
    ];
    return _summaryText(context, parts.join(' · '), error: s.isError);
  }

  @override
  Widget? body(BuildContext context, ToolSegment s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ToolKvGrid(entries: _argMap(s.inputs)),
      if (s.outputs.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        OutputBlock(text: s.outputs, error: s.isError),
      ],
    ],
  );
}

/// `memory` — query/topic + a memory chip.
class MemoryRenderer extends ToolRenderer {
  /// Creates a [MemoryRenderer].
  const MemoryRenderer();

  @override
  Widget summary(BuildContext context, ToolSegment s) {
    final query = _str(s.inputs, ['query', 'topic', 'content', 'fact', 'q']);
    return Row(
      children: [
        const ToolChip(label: 'memory'),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _summaryText(context, ellipsize(query, 72), error: s.isError),
        ),
      ],
    );
  }

  @override
  Widget? body(BuildContext context, ToolSegment s) =>
      s.outputs.isEmpty ? null : OutputBlock(text: s.outputs, error: s.isError);
}

/// `browser` / `fetch` — action + URL.
class BrowserRenderer extends ToolRenderer {
  /// Creates a [BrowserRenderer].
  const BrowserRenderer();

  @override
  Widget summary(BuildContext context, ToolSegment s) {
    final action = _str(s.inputs, ['action', 'op']);
    final url = _str(s.inputs, ['url', 'href', 'target', 'query']);
    return _summaryText(
      context,
      [if (action.isNotEmpty) action, url].where((e) => e.isNotEmpty).join(' '),
      error: s.isError,
    );
  }

  @override
  Widget? body(BuildContext context, ToolSegment s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ToolKvGrid(entries: _argMap(s.inputs)),
      if (s.outputs.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        OutputBlock(text: s.outputs, error: s.isError),
      ],
    ],
  );
}

/// `job` — poll/cancel/list rendered as the job's status text.
class JobRenderer extends ToolRenderer {
  /// Creates a [JobRenderer].
  const JobRenderer();

  @override
  Widget summary(BuildContext context, ToolSegment s) {
    final ids = _str(s.inputs, ['id', 'ids', 'job_id', 'jobs']);
    final op = s.inputs?.containsKey('cancel') ?? false
        ? 'cancel'
        : s.inputs?.containsKey('list') ?? false
        ? 'list'
        : 'poll';
    return _summaryText(context, '$op ${ellipsize(ids, 60)}'.trim());
  }

  @override
  Widget? body(BuildContext context, ToolSegment s) =>
      s.outputs.isEmpty ? null : OutputBlock(text: s.outputs, error: s.isError);
}

/// `todo` — item count.
class TodoRenderer extends ToolRenderer {
  /// Creates a [TodoRenderer].
  const TodoRenderer();

  @override
  Widget summary(BuildContext context, ToolSegment s) {
    final todos = s.inputs?['todos'] ?? s.inputs?['items'] ?? s.inputs?['plan'];
    final count = todos is List ? todos.length : null;
    return _summaryText(context, count == null ? 'plan' : '$count items');
  }

  @override
  Widget? body(BuildContext context, ToolSegment s) =>
      s.outputs.isEmpty ? null : OutputBlock(text: s.outputs);
}

/// An expandable card rendering one [ToolSegment] via its resolved renderer:
/// always-visible status + name + one-line summary, with a tappable body when
/// the renderer provides detail.
class ToolCallCard extends StatefulWidget {
  /// Creates a [ToolCallCard].
  const ToolCallCard({
    super.key,
    required this.segment,
    this.initiallyExpanded = false,
  });

  /// The tool call to render.
  final ToolSegment segment;

  /// Whether the body starts expanded.
  final bool initiallyExpanded;

  @override
  State<ToolCallCard> createState() => _ToolCallCardState();
}

class _ToolCallCardState extends State<ToolCallCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final segment = widget.segment;
    final renderer = resolveToolRenderer(segment.toolName);
    final body = renderer.body(context, segment);
    final hasBody = body != null && !segment.isPruned;
    final duration = toolDurationLabel(segment.durationMs);

    final header = Row(
      children: [
        toolStatusIcon(context, segment.status),
        const SizedBox(width: AppSpacing.sm),
        Text(
          normalizeToolName(segment.toolName),
          style: CcTypography.label.copyWith(
            color: t.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: renderer.summary(context, segment)),
        if (segment.isPruned) ...[
          const SizedBox(width: AppSpacing.xs),
          const ToolChip(label: 'pruned', tone: ObsTone.warning),
        ],
        if (duration.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            duration,
            style: CcTypography.caption.copyWith(color: t.textQuaternary),
          ),
        ],
        if (hasBody)
          Icon(
            _expanded ? AppIcons.chevronDown : AppIcons.chevronRight,
            size: 14,
            color: t.fgTertiary,
          ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: t.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBody)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: AppRadii.brLg,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: header,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: header,
            ),
          if (hasBody && _expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: body,
            ),
        ],
      ),
    );
  }
}

/// Renders an ordered list of tool calls as a column of [ToolCallCard]s.
class TranscriptToolList extends StatelessWidget {
  /// Creates a [TranscriptToolList].
  const TranscriptToolList({super.key, required this.segments});

  /// The tool segments, in transcript order.
  final List<ToolSegment> segments;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    if (segments.isEmpty) {
      return Text(
        'No tool calls yet.',
        style: CcTypography.caption.copyWith(color: t.textTertiary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final s in segments) ToolCallCard(segment: s)],
    );
  }
}

/// The `subagent` chip on a `task` cell — a button into the spawned run's own
/// activity when that run is resolvable and the plain chip otherwise.
///
/// Resolution goes through the child run's recorded `spawnToolCallId`, so a
/// parent that fired several `task` calls in one turn still links each cell to
/// the right child. A transcript recorded before spawn correlation existed (or
/// whose child row has since been pruned) resolves to null and stays inert.
class _SubagentChip extends ConsumerWidget {
  const _SubagentChip({required this.segment, required this.label});

  final ToolSegment segment;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const chip = ToolChip(label: 'subagent', tone: ObsTone.brand);
    final scope = RunActivityOpenerScope.maybeOf(context);
    if (scope == null || segment.toolCallId.isEmpty) {
      return chip;
    }
    final runId = ref.watch(
      runIdForSpawnToolCallProvider((
        workspaceId: scope.workspaceId,
        channelId: scope.channelId,
        runId: segment.toolCallId,
      )),
    );
    if (runId == null) {
      return chip;
    }
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.openAgentActivity,
      child: CcTooltip(
        message: l10n.openAgentActivity,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => scope.openRun(
              runId: runId,
              label: label.trim().isEmpty ? l10n.ideAgentActivity : label,
            ),
            child: chip,
          ),
        ),
      ),
    );
  }
}
