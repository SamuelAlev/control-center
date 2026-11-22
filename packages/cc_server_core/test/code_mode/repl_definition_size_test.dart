import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/repl_tool_description.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import '../helpers/server_mcp_registry_fixture.dart';
import '../helpers/test_database.dart';

/// The `repl` definition a standard chat run sends, pinned at
/// [ReplToolDescription.maxDefinitionBytes], and what the whole tool block
/// weighs with `repl` and without.
///
/// The surface is the one a chat run gets: the production registry builder
/// over the server's MCP registry (the fixture holds the tools that need no
/// live services), materialized as a run materializes it, with `repl` bound
/// as a run binds it. Each definition is measured as the provider receives
/// it: `{name, description, input_schema}` JSON-encoded, in UTF-8.
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

  List<HarnessTool> chatTools({required bool withRepl}) {
    final profile = profileFor(Mode.chat);
    final registry = buildHarnessToolRegistry(
      mode: Mode.chat,
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
      replSlot: withRepl,
    )..register(TaskTool(_NeverSpawns()));
    final surface = materializeHarnessToolSurface(
      registry: registry,
      surface: profile.toToolSurfaceSpec(),
      residency: profile.toToolResidencySpec(enabled: true),
    );
    return surface.hasRepl
        ? bindReplTool(
            resident: surface.resident,
            scriptOnly: surface.scriptOnly,
            binding: ReplBinding(
              executions: _NoScripts(),
              run: ReplRunIdentity(
        workspaceId: 'ws-1',
        runId: 'run-1',
        readOnly: false,
        past: null,
      ),
              limits: CodeModeLimits.defaults,
            ),
          )
        : surface.resident;
  }

  int bytesOf(HarnessTool tool) => utf8
      .encode(
        jsonEncode({
          'name': tool.name,
          'description': tool.description,
          'input_schema': tool.inputSchema,
        }),
      )
      .length;

  test('the repl definition fits its cap on the standard chat surface', () {
    final repl = chatTools(
      withRepl: true,
    ).singleWhere((t) => t.name == ReplToolDescription.toolName);
    final bytes = bytesOf(repl);
    expect(bytes, ReplToolDescription.definitionBytes(repl.description));
    // ignore: avoid_print
    print(
      'repl definition: $bytes B, '
      '${ReplToolDescription.maxDefinitionBytes - bytes} B free of '
      '${ReplToolDescription.maxDefinitionBytes}',
    );
    expect(bytes, lessThanOrEqualTo(ReplToolDescription.maxDefinitionBytes));
  });

  test('the same surface gives the same repl bytes', () {
    String description() => chatTools(
      withRepl: true,
    ).singleWhere((t) => t.name == ReplToolDescription.toolName).description;
    expect(description(), description());
  });

  test('measure: the chat tool block with repl and without', () {
    for (final withRepl in [false, true]) {
      final tools = chatTools(withRepl: withRepl);
      final rows = [for (final t in tools) '${t.name} ${bytesOf(t)}'];
      final total = utf8
          .encode(
            jsonEncode([
              for (final t in tools)
                {
                  'name': t.name,
                  'description': t.description,
                  'input_schema': t.inputSchema,
                },
            ]),
          )
          .length;
      // ignore: avoid_print
      print(
        '${withRepl ? 'with' : 'without'} repl: ${tools.length} tools, '
        '$total B\n  ${rows.join('\n  ')}',
      );
      expect(tools, isNotEmpty);
    }
  });
}

class _NoScripts implements CodeExecutionPort {
  @override
  CodeRunnerAvailability get availability =>
      const CodeRunnerAvailability.available();

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) => throw StateError('no scripts in this test');
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
