import 'dart:io';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:test/test.dart';

/// One phrasing for "you did not give me a required argument".
///
/// Agents pattern-match error text to self-correct, so N spellings of one
/// failure is N things a model has to have learned — and the drift is
/// invisible to every other test, because each tool's own suite asserts its
/// own string. `workspace_id` alone had four:
///
///   'Missing or invalid argument: workspace_id'          (83)
///   'Missing or invalid argument: workspace_id'                               (15)
///   'Missing or invalid argument: workspace_id'  (11)
///   'Missing or invalid argument: workspace_id'                              (3)
///
/// All 113 now read the same. `McpTool.missingArgument` composes the phrasing
/// and `McpTool.requireString` is the two-line reader that uses it.
void main() {
  test('workspace_id failures all read the same', () {
    final drifted = <String>[];
    final canonical = McpTool.missingArgument('workspace_id');
    // Any single-quoted literal on ONE line that talks about a missing
    // workspace_id. Line-bounded on purpose: an unbounded `[^']*` runs past
    // the closing quote and swallows whole doc comments, because prose is full
    // of apostrophes.
    final message = RegExp("'[^'\n]*[Mm]issing[^'\n]*workspace_id[^'\n]*'");
    for (final file in _toolSources()) {
      for (final m in message.allMatches(file.readAsStringSync())) {
        final literal = m.group(0)!;
        final text = literal.substring(1, literal.length - 1);
        // The canonical string, optionally continuing into extra remediation
        // (one tool explains that dispatch injects the id for you).
        if (text == canonical || text.startsWith('$canonical.')) {
          continue;
        }
        drifted.add('${_short(file)}: $literal');
      }
    }
    expect(
      drifted.toList()..sort(),
      isEmpty,
      reason:
          'These spell the missing-workspace_id failure differently. Use '
          '`McpTool.requireString(args, \'workspace_id\')`, or compose the '
          'message with `McpTool.missingArgument`:\n  ${drifted.join('\n  ')}',
    );
  });

  test('the scan is looking at the real tool surface', () {
    // Non-vacuity: a moved directory would make the check above pass by
    // reading nothing.
    final sources = _toolSources().toList();
    expect(sources.length, greaterThan(60));
    final hits = sources
        .where((f) => f.readAsStringSync().contains('workspace_id'))
        .length;
    expect(
      hits,
      greaterThan(40),
      reason: 'only $hits tool files mention workspace_id — scan is wrong',
    );
  });

  group('McpTool.requireString', () {
    test('returns the value when present', () {
      final (value, error) = McpTool.requireString({
        'workspace_id': 'ws-1',
      }, 'workspace_id');
      expect(value, 'ws-1');
      expect(error, isNull);
    });

    test('rejects a missing, wrong-typed or EMPTY argument', () {
      for (final args in <Map<String, dynamic>>[
        {},
        {'workspace_id': 42},
        {'workspace_id': null},
        // Empty counts as missing: these arguments are ids and names, and ''
        // is never a valid one — accepting it moves the failure somewhere
        // less legible.
        {'workspace_id': ''},
      ]) {
        final (value, error) = McpTool.requireString(args, 'workspace_id');
        expect(value, isNull, reason: '$args');
        expect(error, isNotNull, reason: '$args');
        expect(error!.isError, isTrue);
        expect(
          error.content.map((c) => c.text).join(),
          contains('Missing or invalid argument: workspace_id'),
        );
      }
    });
  });
}

Iterable<File> _toolSources() {
  final dir = Directory('${_repoRoot().path}/packages/cc_mcp/lib/src/tools');
  expect(dir.existsSync(), isTrue, reason: 'cc_mcp tools directory not found');
  return dir.listSync().whereType<File>().where(
    (f) => f.path.endsWith('.dart'),
  );
}

String _short(File f) => f.uri.pathSegments.last;

Directory _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (Directory('${dir.path}/packages/cc_mcp/lib/src/tools').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('Could not locate the repo root from ${Directory.current.path}');
    }
    dir = parent;
  }
}
