import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import '../helpers/server_mcp_registry_fixture.dart';
import '../helpers/test_database.dart';
import 'script_callable_pin_test.dart'
    show harnessScriptCallable, mcpScriptCallable;

/// Every direct tool a script may also call states what a script receives
/// from it (`HarnessTool.resultNote`, `McpTool.resultNote`): `repl`'s
/// description shows that note instead of the tool's declaration, so a
/// direct tool without one would leave a script author guessing the shape.
///
/// The direct set is the one each mode really has: its direct tools, its
/// pinned verbs and the interaction verbs, over the production registry
/// builder and the server's own MCP registry. A tool joins the direct set or
/// becomes script-callable, and this fails until it has a note.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  setUp(() {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
  });
  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Set<String> directFor(Mode mode) => {
    ...ModeToolPolicy.directNamesFor(mode),
    ...profileFor(mode).pinnedVerbs,
    ...ModeCapabilityProfile.interactionVerbs,
  };

  test('every direct harness tool a script may call has a result note', () {
    final checked = <String>{};
    for (final mode in Mode.values) {
      final registry = buildHarnessToolRegistry(
        mode: mode,
        networkEnabled: true,
        env: const {},
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        conversationId: 'conv-1',
        spaceId: 'space-1',
        fileSearch: _NoFileSearch(),
        mcpRegistry: buildTestServerMcpRegistry(global: global, dbs: dbs),
        // A run has an output store, so `read_output` is direct.
        toolOutputStore: InMemoryToolOutputStore(),
        replSlot: true,
      )..register(TaskTool(_NeverSpawns()));
      final direct = directFor(mode);
      for (final tool in registry.toolsFor(
        profileFor(mode).toToolSurfaceSpec(),
      )) {
        if (!direct.contains(tool.name) || !tool.scriptCallable) {
          continue;
        }
        checked.add(tool.name);
        expect(
          tool.resultNote?.trim(),
          isNotEmpty,
          reason: '${mode.name}: ${tool.name} is direct and script-callable',
        );
      }
    }
    // Non-vacuity: the built-ins and the bridged ones are both checked.
    expect(
      checked,
      containsAll([
        'read',
        'write',
        'edit',
        'search',
        'find',
        'bash',
        'read_output',
        'ask_user',
        'todo_write',
        'search_memory',
      ]),
    );
  });

  test('every direct MCP tool a script may call has a result note', () {
    final registry = buildTestServerMcpRegistry(global: global, dbs: dbs);
    final checked = <String>{};
    for (final mode in Mode.values) {
      for (final name in directFor(mode)) {
        final tool = registry.lookup(name, view: McpToolView.shared);
        if (tool == null || !tool.scriptCallable) {
          continue;
        }
        checked.add(name);
        expect(
          tool.resultNote?.trim(),
          isNotEmpty,
          reason: '${mode.name}: $name is direct and script-callable',
        );
      }
    }
    expect(checked, containsAll(['ask_user', 'todo_write', 'search_memory']));
  });

  // The registries above hold the tools that need no live services, so
  // `read_output` and the review tools are not built there. Their sources
  // are read instead: every class that declares a direct tool a script may
  // call states its note.
  test('every class of a direct tool a script may call states a note', () {
    final direct = {for (final mode in Mode.values) ...directFor(mode)};
    final scriptable = {
      for (final name in direct)
        if (harnessScriptCallable[name] ?? mcpScriptCallable[name] ?? false)
          name,
    };
    final sources = [
      for (final root in const [
        '../cc_harness/lib',
        '../cc_harness_runtime/lib',
        '../cc_infra/lib',
        '../cc_mcp/lib',
        '../cc_server_core/lib',
      ])
        for (final f in Directory(root).listSync(recursive: true))
          if (f is File && f.path.endsWith('.dart')) f,
    ];
    final declaring = <String, List<String>>{};
    for (final file in sources) {
      final text = file.readAsStringSync();
      for (final name in scriptable) {
        if (text.contains("String get name => '$name';")) {
          (declaring[name] ??= []).add(file.path);
          expect(
            text,
            contains('String get resultNote =>'),
            reason: '${file.path} declares $name',
          );
        }
      }
    }
    expect(declaring.keys.toSet(), scriptable);
    expect(
      scriptable,
      containsAll([
        'read_output',
        'add_review_node',
        'confirm_review_node',
        'dismiss_review_node',
        'resolve_review_node',
      ]),
    );
  });

  test('a note is one line of at most 240 characters', () {
    final registry = buildTestServerMcpRegistry(global: global, dbs: dbs);
    final notes = <String, String>{
      for (final name in registry.toolNames(view: McpToolView.shared))
        name: ?registry.lookup(name, view: McpToolView.shared)!.resultNote,
    };
    expect(notes, isNotEmpty);
    for (final MapEntry(key: name, value: note) in notes.entries) {
      expect(note, isNot(contains('\n')), reason: name);
      expect(note.length, lessThanOrEqualTo(240), reason: name);
    }
  });
}

class _NeverSpawns implements SubagentSpawner {
  @override
  Future<SubagentResult> spawn(SubagentSpawnRequest request) =>
      throw StateError('not spawned in this test');
}

class _NoFileSearch implements FileSearchPort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('no file search in this test');
}
