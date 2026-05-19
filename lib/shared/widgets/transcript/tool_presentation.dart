import 'package:cc_domain/core/domain/services/transcript_status.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Coarse category of a tool call, used to color its transcript-row accent so
/// a fleet of tool calls stays scannable at a glance. Color is an *additional*
/// cue — every row also carries an icon and a verb label (DESIGN.md: never
/// color-as-only-signal). The palette is resolved from design tokens at the
/// call site, so it stays within the warm/status system (no cool hues).
enum ToolCategory {
  /// Read-only inspection: read, grep, glob, list.
  explore,

  /// Mutating file edits: edit, write.
  edit,

  /// Shell execution: bash.
  run,

  /// Spawning another agent / sub-task: task, agent.
  delegate,

  /// External data fetch: web search / web fetch.
  fetch,

  /// Anything else (MCP tools, todos, unknown).
  other,
}
/// Collapsed-header presentation for a tool segment: icon, verb, an optional
/// target subtitle (shortened file path / command / query), and its category.
class ToolPresentation {
  /// Creates a [ToolPresentation].
  const ToolPresentation({
    required this.icon,
    required this.verb,
    required this.category,
    this.subtitle,
  });

  /// Leading icon.
  final IconData icon;

  /// Verb label ("Read", "Edit", "Bash", or a humanized MCP name).
  final String verb;

  /// Coarse category, for the row's accent color.
  final ToolCategory category;

  /// Target subtitle, or null.
  final String? subtitle;
}

/// Resolves the [ToolPresentation] for [seg] from its (normalized) tool name
/// and parsed inputs.
ToolPresentation resolveToolPresentation(ToolSegment seg) {
  final name = normalizeToolName(seg.toolName);
  final inputs = seg.inputs;

  String? str(String key) {
    final v = inputs?[key];
    return v is String && v.isNotEmpty ? v : null;
  }

  switch (name) {
    case 'read':
      return ToolPresentation(
        icon: AppIcons.eye,
        verb: 'Read',
        category: ToolCategory.explore,
        subtitle: _withOffset(shortenPath(str('file_path')), inputs),
      );
    case 'edit':
    case 'multiedit':
      return ToolPresentation(
        icon: AppIcons.pencil,
        verb: 'Edit',
        category: ToolCategory.edit,
        subtitle: shortenPath(str('file_path')),
      );
    case 'write':
      return ToolPresentation(
        icon: AppIcons.fileCode,
        verb: 'Write',
        category: ToolCategory.edit,
        subtitle: shortenPath(str('file_path')),
      );
    case 'bash':
      return ToolPresentation(
        icon: AppIcons.terminal,
        verb: 'Bash',
        category: ToolCategory.run,
        subtitle: _firstLine(str('description') ?? str('command')),
      );
    case 'grep':
      return ToolPresentation(
        icon: AppIcons.search,
        verb: 'Grep',
        category: ToolCategory.explore,
        subtitle: str('pattern'),
      );
    case 'glob':
      return ToolPresentation(
        icon: AppIcons.search,
        verb: 'Glob',
        category: ToolCategory.explore,
        subtitle: str('pattern'),
      );
    case 'ls':
    case 'list':
      return ToolPresentation(
        icon: AppIcons.folderOpen,
        verb: 'List',
        category: ToolCategory.explore,
        subtitle: shortenPath(str('path')),
      );
    case 'webfetch':
    case 'web_search':
    case 'websearch':
      return ToolPresentation(
        icon: AppIcons.globe,
        verb: 'Fetch',
        category: ToolCategory.fetch,
        subtitle: str('url') ?? str('query'),
      );
    case 'task':
    case 'agent':
      return ToolPresentation(
        icon: AppIcons.zap,
        verb: 'Agent',
        category: ToolCategory.delegate,
        subtitle: str('description'),
      );
    case 'todowrite':
      return const ToolPresentation(
        icon: AppIcons.squareCheck,
        verb: 'Todos',
        category: ToolCategory.other,
      );
    default:
      return ToolPresentation(
        icon: _mcpIcon(name),
        verb: humanizeToolName(seg.toolName),
        category: ToolCategory.other,
        subtitle: _inputsPreview(inputs),
      );
  }
}

IconData _mcpIcon(String name) {
  if (name.contains('ticket')) {
    return AppIcons.ticket;
  }
  if (name.contains('search') || name.contains('find')) {
    return AppIcons.search;
  }
  if (name.contains('memory') || name.contains('fact')) {
    return AppIcons.brain;
  }
  if (name.contains('create') || name.contains('add') || name.contains('write')) {
    return AppIcons.plus;
  }
  return AppIcons.wrench;
}

/// Humanizes a tool name for display: strips any `mcp__server__` prefix, splits
/// snake_case, and sentence-cases the result ("create_ticket" → "Create ticket").
String humanizeToolName(String toolName) {
  final name = normalizeToolName(toolName);
  if (name.isEmpty) {
    return 'Tool';
  }
  final words = name.split(RegExp(r'[_\s]+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) {
    return 'Tool';
  }
  final first = words.first;
  final head = first[0].toUpperCase() + first.substring(1);
  return [head, ...words.skip(1)].join(' ');
}

/// Shortens a file path to its last two segments for compact display.
String? shortenPath(String? path) {
  if (path == null || path.isEmpty) {
    return null;
  }
  final parts = path.split('/').where((p) => p.isNotEmpty).toList();
  if (parts.length <= 2) {
    return path;
  }
  return '…/${parts.sublist(parts.length - 2).join('/')}';
}

String? _withOffset(String? path, Map<String, dynamic>? inputs) {
  if (path == null) {
    return null;
  }
  final offset = inputs?['offset'];
  return offset is num ? '$path:${offset.toInt()}' : path;
}

String? _firstLine(String? text) {
  if (text == null || text.isEmpty) {
    return null;
  }
  final i = text.indexOf('\n');
  final line = (i == -1 ? text : text.substring(0, i)).trim();
  return line.isEmpty ? null : line;
}

String? _inputsPreview(Map<String, dynamic>? inputs) {
  if (inputs == null || inputs.isEmpty) {
    return null;
  }
  final keys = inputs.keys.take(2).toList();
  return keys.map((k) {
    final v = inputs[k];
    final s = v is String ? v : v.toString();
    final preview = s.length > 40 ? '${s.substring(0, 40)}…' : s;
    return '$k: $preview';
  }).join(', ');
}
