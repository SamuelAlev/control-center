import 'dart:io';

import 'package:test/test.dart';

/// Every `McpTool` on disk must be WIRED, or explicitly listed as not wired.
///
/// The tool surface is a hand-maintained list split across two files
/// (`server_mcp_registry.dart`'s constructor list and the post-construction
/// `..register(...)` cascade in `cc_server_runtime.dart`), and nothing tied
/// "a tool class exists" to "the tool is registered". A tool could therefore be
/// written, reviewed, tested and merged, and still never appear in
/// `tools/list` — with no failing test anywhere, because its unit tests
/// construct it directly.
///
/// That is not hypothetical. When this ratchet was written it found
/// **19 of 123 tool classes** — 15% of the agent-facing API — that no
/// production file ever constructs. Some of that is probably deliberate
/// (`create_workspace`, `hire_agent`, `fire_agent` and `kill_agent` are
/// powerful, and holding them back is a defensible product call); some of it
/// looks like drift. Which is which is a decision for a human, so they are
/// baselined below rather than guessed at.
///
/// Shrinking allowlist, the house pattern: a NEW unregistered tool fails, and
/// an entry that no longer belongs (because the tool got wired, or deleted)
/// ALSO fails. The list therefore cannot quietly stop describing reality.
void main() {
  // Tool classes that exist but are deliberately-or-not left unwired.
  //
  // To remove an entry: register the tool. To add one: say why here.
  //
  // The set is currently EMPTY: the previously-unwired tool classes (agent
  // lifecycle hire/fire/kill/propose/update, create_workspace, the Projects
  // CRUD set, checkout/release task, ask_user_question, request_confirmation,
  // list_pull_requests, get_agent_run_logs, doctor) were deleted outright —
  // every tool class that exists is now registered.
  const unwired = <String>{};

  late final Directory root;
  late final Map<String, String> toolClasses;
  late final String wiring;

  setUpAll(() {
    root = _repoRoot();
    toolClasses = _toolClasses(root);
    wiring = [
      'packages/cc_server_core/lib/src/server_mcp_registry.dart',
      'packages/cc_server_core/lib/src/cc_server_runtime.dart',
    ].map((rel) => File('${root.path}/$rel').readAsStringSync()).join('\n');
  });

  test('the scan finds the real tool surface', () {
    // Non-vacuity: a moved directory or a changed base-class name would
    // otherwise turn every assertion below into a tautology.
    expect(
      toolClasses.length,
      greaterThan(100),
      reason:
          'found only ${toolClasses.length} tool classes — the detector has '
          'probably stopped matching',
    );
    expect(toolClasses.keys, contains('ListSkillsTool'));

    // A tool does not have to extend `McpTool` DIRECTLY. The rig tools share an
    // abstract `RigUseTool` base, and a name-shaped regex silently skipped all
    // three — so three agent-facing tools sat outside the ratchet entirely.
    // Pinned by name because the hole reopens the moment someone factors a
    // second family onto a shared base.
    expect(
      toolClasses.keys,
      containsAll(['ComputerUseTool', 'BrowserUseTool', 'MobileUseTool']),
      reason:
          'the detector is not following indirect subclasses — a tool on a '
          'shared base (RigUseTool) is invisible to this ratchet again',
    );

    // The abstract bases are not tools; registering one is impossible.
    expect(toolClasses.keys, isNot(contains('RigUseTool')));
  });

  test('every tool is registered, or listed as deliberately not', () {
    final missing = <String>[];
    for (final entry in toolClasses.entries) {
      if (unwired.contains(entry.key)) {
        continue;
      }
      if (!RegExp('(?<![A-Za-z0-9_])${entry.key}\\(').hasMatch(wiring)) {
        missing.add('${entry.key} (${entry.value})');
      }
    }
    expect(
      missing.toList()..sort(),
      isEmpty,
      reason:
          'These McpTool classes exist on disk but are constructed by neither '
          'server_mcp_registry.dart nor cc_server_runtime.dart, so they never '
          'appear in `tools/list` — an agent cannot call them and nothing '
          'else fails. Register them, or add them to `unwired` above with a '
          'reason:\n  ${missing.join('\n  ')}',
    );
  });

  test('the unwired list has no stale entries', () {
    final stale = <String>[];
    for (final name in unwired) {
      if (!toolClasses.containsKey(name)) {
        stale.add('$name (no such tool class)');
      } else if (RegExp('(?<![A-Za-z0-9_])$name\\(').hasMatch(wiring)) {
        stale.add('$name (now registered)');
      }
    }
    expect(
      stale.toList()..sort(),
      isEmpty,
      reason:
          'The `unwired` list has drifted from reality. Remove these '
          'entries:\n  ${stale.join('\n  ')}',
    );
  });
}

/// Every concrete `McpTool` subclass under cc_mcp's tools directory, mapped to
/// its filename.
///
/// Subclassing is resolved TRANSITIVELY. Matching only classes whose supertype
/// is spelled `…McpTool` looks equivalent and is not: the rig tools
/// (`computer_use` / `browser_use` / `mobile_use`) extend an abstract
/// `RigUseTool`, so a name-shaped regex dropped three agent-facing tools out of
/// the ratchet without failing anything. Any shared base added later would have
/// gone the same way.
///
/// Abstract classes are excluded — a base cannot be registered, so demanding it
/// appear in the wiring would fail on the one class that legitimately does not.
Map<String, String> _toolClasses(Directory root) {
  final dir = Directory('${root.path}/packages/cc_mcp/lib/src/tools');
  expect(dir.existsSync(), isTrue, reason: 'cc_mcp tools directory not found');
  final pattern = RegExp(
    r'\n(abstract\s+)?class\s+(\w+)\s+(?:extends|implements)\s+(\w+)',
  );

  // (subclass, supertype, isAbstract, file), in declaration order.
  final declarations =
      <({String name, String base, bool isAbstract, String file})>[];
  for (final file in dir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.dart')) {
      continue;
    }
    final fileName = file.uri.pathSegments.last;
    for (final m in pattern.allMatches(file.readAsStringSync())) {
      declarations.add((
        name: m.group(2)!,
        base: m.group(3)!,
        isAbstract: m.group(1) != null,
        file: fileName,
      ));
    }
  }

  // Fixpoint: a class is a tool if its base is `McpTool` (however spelled) or
  // is itself a tool. Iterating to a fixpoint rather than once handles a base
  // declared in a file the walker reaches later.
  bool isRootBase(String base) => RegExp(r'^\w*McpTool\w*$').hasMatch(base);
  final toolTypes = <String>{};
  var changed = true;
  while (changed) {
    changed = false;
    for (final d in declarations) {
      if (toolTypes.contains(d.name)) {
        continue;
      }
      if (isRootBase(d.base) || toolTypes.contains(d.base)) {
        toolTypes.add(d.name);
        changed = true;
      }
    }
  }

  return {
    for (final d in declarations)
      if (toolTypes.contains(d.name) && !d.isAbstract) d.name: d.file,
  };
}

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
