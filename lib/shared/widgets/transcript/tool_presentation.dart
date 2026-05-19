import 'package:control_center/core/domain/services/transcript_status.dart';
import 'package:control_center/core/domain/value_objects/transcript_segment.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Collapsed-header presentation for a tool segment: icon, verb, and an
/// optional target subtitle (shortened file path / command / query).
class ToolPresentation {
  /// Creates a [ToolPresentation].
  const ToolPresentation({required this.icon, required this.verb, this.subtitle});

  /// Leading icon.
  final IconData icon;

  /// Verb label ("Read", "Edit", "Bash", or a humanized MCP name).
  final String verb;

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
        icon: LucideIcons.eye,
        verb: 'Read',
        subtitle: _withOffset(shortenPath(str('file_path')), inputs),
      );
    case 'edit':
    case 'multiedit':
      return ToolPresentation(
        icon: LucideIcons.pencil,
        verb: 'Edit',
        subtitle: shortenPath(str('file_path')),
      );
    case 'write':
      return ToolPresentation(
        icon: LucideIcons.fileCode,
        verb: 'Write',
        subtitle: shortenPath(str('file_path')),
      );
    case 'bash':
      return ToolPresentation(
        icon: LucideIcons.terminal,
        verb: 'Bash',
        subtitle: _firstLine(str('description') ?? str('command')),
      );
    case 'grep':
      return ToolPresentation(
        icon: LucideIcons.search,
        verb: 'Grep',
        subtitle: str('pattern'),
      );
    case 'glob':
      return ToolPresentation(
        icon: LucideIcons.search,
        verb: 'Glob',
        subtitle: str('pattern'),
      );
    case 'ls':
    case 'list':
      return ToolPresentation(
        icon: LucideIcons.folderOpen,
        verb: 'List',
        subtitle: shortenPath(str('path')),
      );
    case 'webfetch':
    case 'web_search':
    case 'websearch':
      return ToolPresentation(
        icon: LucideIcons.globe,
        verb: 'Fetch',
        subtitle: str('url') ?? str('query'),
      );
    case 'task':
    case 'agent':
      return ToolPresentation(
        icon: LucideIcons.zap,
        verb: 'Agent',
        subtitle: str('description'),
      );
    case 'todowrite':
      return const ToolPresentation(
        icon: LucideIcons.squareCheck,
        verb: 'Todos',
      );
    default:
      return ToolPresentation(
        icon: _mcpIcon(name),
        verb: humanizeToolName(seg.toolName),
        subtitle: _inputsPreview(inputs),
      );
  }
}

IconData _mcpIcon(String name) {
  if (name.contains('ticket')) {
    return LucideIcons.ticket;
  }
  if (name.contains('search') || name.contains('find')) {
    return LucideIcons.search;
  }
  if (name.contains('memory') || name.contains('fact')) {
    return LucideIcons.brain;
  }
  if (name.contains('create') || name.contains('add') || name.contains('write')) {
    return LucideIcons.plus;
  }
  return LucideIcons.wrench;
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
