import 'package:cc_domain/core/domain/services/transcript_status.dart';

/// A readable transcript label, never the identifier used to invoke the tool.
///
/// Known Control Center MCP actions can use the caller's localized labels;
/// everything else follows the desktop transcript's existing sentence-case
/// convention. Do not use this function for matching or dispatch.
String resolveToolDisplayName(
  String toolName, {
  String? todos,
  String? searchMemory,
  String? renderMedia,
}) {
  final identifier = toolName.trim().toLowerCase();
  final name = normalizeToolName(toolName);
  final isControlCenterTool =
      identifier.startsWith('mcp__control-center__') ||
      identifier.startsWith('mcp__control_center__');
  if (isControlCenterTool) {
    if ((name == 'todo_read' || name == 'todo_write') && todos != null) {
      return todos;
    }
    if (name == 'search_memory' && searchMemory != null) {
      return searchMemory;
    }
    if (name == 'render_media' && renderMedia != null) {
      return renderMedia;
    }
  }
  if (name.isEmpty) {
    return 'Tool';
  }
  final words = name.split(RegExp(r'[_\s]+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) {
    return 'Tool';
  }
  final first = words.first;
  return [
    first[0].toUpperCase() + first.substring(1),
    ...words.skip(1),
  ].join(' ');
}
