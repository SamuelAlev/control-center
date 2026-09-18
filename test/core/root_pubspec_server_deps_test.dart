import 'dart:io';

import 'package:test/test.dart';

/// Root `pubspec.yaml` must not *depend* on server packages the app must not
/// import (QUALITY.md R6). Tests may still reach them via `dev_dependencies`.
void main() {
  const banned = ['cc_host', 'cc_persistence', 'cc_server_core', 'cc_mcp'];

  test('root dependencies do not include server packages', () {
    final file = File('${_repoRoot()}/pubspec.yaml');
    expect(file.existsSync(), isTrue);
    final keys = _childKeysOf(file.readAsLinesSync(), 'dependencies');
    final hits = keys.where(banned.contains).toList();
    expect(
      hits,
      isEmpty,
      reason:
          'Root pubspec.yaml dependencies still list ${hits.join(", ")}. '
          'Move them to dev_dependencies — lib/ must not import the server.',
    );
  });
}

List<String> _childKeysOf(List<String> lines, String block) {
  final keys = <String>[];
  final depLine = RegExp(r'^\s{2}([A-Za-z0-9_]+)\s*:');
  var inBlock = false;
  for (final line in lines) {
    if (line.startsWith('$block:')) {
      inBlock = true;
      continue;
    }
    if (inBlock && line.isNotEmpty && !line.startsWith(' ')) {
      break;
    }
    if (!inBlock) {
      continue;
    }
    final m = depLine.firstMatch(line);
    if (m != null) {
      keys.add(m.group(1)!);
    }
  }
  return keys;
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync() &&
        Directory('${dir.path}/lib').existsSync() &&
        Directory('${dir.path}/packages').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
}
