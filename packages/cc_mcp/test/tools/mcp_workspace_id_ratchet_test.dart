import 'dart:io';

import 'package:test/test.dart';

/// Every workspace-scoped MCP tool must list `workspace_id` in its top-level
/// `required` array (QUALITY.md R7). Genuine globals stay on an explicit
/// allowlist so a new tool cannot silently omit the isolation argument.
void main() {
  const allowlist = {
    'list_workspaces_tool.dart',
    'newsfeed_tools.dart',
  };

  test('workspace-scoped MCP tools require workspace_id', () {
    final dir = Directory(_toolsDir());
    expect(dir.existsSync(), isTrue);
    final offenders = <String>[];
    var schemas = 0;
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.dart')) {
        continue;
      }
      final name = file.uri.pathSegments.last;
      if (allowlist.contains(name)) {
        continue;
      }
      final src = file.readAsStringSync();
      for (final schema in _inputSchemas(src)) {
        schemas++;
        final required = _topLevelRequired(schema);
        if (required == null || !required.contains('workspace_id')) {
          offenders.add('$name (required: ${required ?? "<none>"})');
        }
      }
    }
    expect(schemas, greaterThan(0));
    expect(
      offenders,
      isEmpty,
      reason:
          'MCP tools missing top-level required workspace_id. Add the arg, or '
          'put a genuine global on the allowlist in this test:\n'
          '${offenders.join('\n')}',
    );
  });
}

String _toolsDir() {
  var dir = Directory.current;
  while (true) {
    final candidate = Directory('${dir.path}/packages/cc_mcp/lib/src/tools');
    if (candidate.existsSync()) {
      return candidate.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return '${Directory.current.path}/lib/src/tools';
    }
    dir = parent;
  }
}

Iterable<String> _inputSchemas(String src) sync* {
  final re = RegExp(r'get inputSchema\s*=>');
  for (final m in re.allMatches(src)) {
    final start = src.indexOf('{', m.end);
    if (start < 0) {
      continue;
    }
    var depth = 0;
    for (var i = start; i < src.length; i++) {
      final c = src[i];
      if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0) {
          yield src.substring(start, i + 1);
          break;
        }
      }
    }
  }
}

List<String>? _topLevelRequired(String schema) {
  final re = RegExp(r"""^([ \t]*)'required'\s*:\s*\[([^\]]*)\]""", multiLine: true);
  Match? best;
  var bestIndent = 1 << 30;
  for (final m in re.allMatches(schema)) {
    final indent = m.group(1)!.length;
    if (indent < bestIndent) {
      bestIndent = indent;
      best = m;
    }
  }
  if (best == null) {
    return null;
  }
  return RegExp(r"""['"]([^'"]+)['"]""")
      .allMatches(best.group(2)!)
      .map((m) => m.group(1)!)
      .toList();
}
