import 'dart:io';

import 'package:test/test.dart';

/// Each MCP tool file must have a dedicated unit test, an aggregator test,
/// or an explicit gap entry (QUALITY.md R11). Adding a tool without a test
/// (or a named gap) fails.
void main() {
  const helpers = {
    'tools.dart',
    'memory_repo_scope_arg.dart',
    'peer_agent_messaging.dart',
  };

  /// Multi-tool files covered by a named aggregator rather than 1:1.
  const aggregators = {
    'artifact_tools.dart': 'artifact_tools_test.dart',
    'code_graph_tools.dart': 'code_graph_tools_test.dart',
    'goal_supervision_tools.dart': 'goal_supervision_tools_test.dart',
  };

  /// Tools that still lack a dedicated behavioral test. Shrink only.
  const gaps = <String>{};

  test('every MCP tool file has a test or a named gap', () {
    final toolsDir = Directory(_toolsDir());
    final testsDir = Directory(_testsDir());
    expect(toolsDir.existsSync(), isTrue);
    expect(testsDir.existsSync(), isTrue);

    final tests = testsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('_test.dart'))
        .map((f) => f.uri.pathSegments.last)
        .toSet();

    final uncovered = <String>[];
    final staleGaps = <String>{...gaps};
    for (final file in toolsDir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.dart')) {
        continue;
      }
      final name = file.uri.pathSegments.last;
      if (helpers.contains(name)) {
        continue;
      }
      staleGaps.remove(name);
      final dedicated = '${name.replaceFirst('.dart', '')}_test.dart';
      if (tests.contains(dedicated)) {
        continue;
      }
      final aggregator = aggregators[name];
      if (aggregator != null && tests.contains(aggregator)) {
        continue;
      }
      if (gaps.contains(name)) {
        continue;
      }
      uncovered.add(name);
    }

    expect(
      uncovered..sort(),
      isEmpty,
      reason:
          'MCP tool files with no dedicated test, aggregator, or gap entry. '
          'Add packages/cc_mcp/test/tools/<name>_test.dart or name the gap in '
          'mcp_tool_test_presence_ratchet_test.dart:\n${uncovered.join('\n')}',
    );
    expect(
      staleGaps.toList()..sort(),
      isEmpty,
      reason:
          'Stale MCP test-gap entries (file gone or now tested) — prune them:\n'
          '${(staleGaps.toList()..sort()).join('\n')}',
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

String _testsDir() {
  final tools = Directory(_toolsDir());
  return '${tools.parent.parent.parent.path}/test/tools';
}
