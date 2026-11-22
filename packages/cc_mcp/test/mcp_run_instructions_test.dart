// ignore_for_file: avoid_dynamic_calls

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/services/mode_tool_guard.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_mcp/src/mcp_run_tool_surface.dart';
import 'package:cc_mcp/src/mcp_server_instructions.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:cc_mcp/src/tools/repl_tool.dart';
import 'package:test/test.dart';

import 'code_mode_fakes.dart';

/// What a Claude Code run is told about its tools: which listed entries it
/// is asked to load upfront (`_meta["anthropic/alwaysLoad"]`), and the
/// `initialize` instructions that say how its script-only tools are reached.
void main() {
  late FixedModeResolver modes;
  late McpToolRegistry registry;
  late McpToolDispatcher dispatcher;

  List<McpTool> tools({bool withRepl = true, bool runnerUp = true}) => [
    ProbeTool('read_thing'),
    ProbeTool('search_memory'),
    ProbeTool('write_thing', actionClasses: {ActionClass.workspaceMutation}),
    ProbeTool('create_ticket'),
    ProbeTool('todo_write'),
    ProbeTool('todo_read'),
    ProbeTool('ask_user'),
    ProbeTool('submit_plan', scriptCallable: false),
    ProbeTool('exit_plan_mode', scriptCallable: false),
    ProbeTool('consult_agent', scriptCallable: false),
    ProbeTool('search_tool_bm25', scriptCallable: false),
    ProbeTool('list_my_tools', scriptCallable: false),
    if (withRepl)
      ReplMcpTool(
        executions: FakeExecutions(
          availability: runnerUp
              ? const CodeRunnerAvailability.available()
              : const CodeRunnerAvailability.unavailable('no seccomp'),
        ),
        limitsFor: (_) async => CodeModeLimits.defaults,
        records: FakeRecords(),
        past: null,
      ),
  ];

  void build(List<McpTool> list) {
    registry = McpToolRegistry(list);
    dispatcher = McpToolDispatcher(
      registry: registry,
      modeGuard: ModeToolGuard(modes),
    );
  }

  setUp(() {
    modes = FixedModeResolver(Mode.chat);
    build(tools());
  });

  Future<List<Map<String, dynamic>>> list(McpCallScope? scope) async {
    final response = await dispatcher.handleScopedRequest(
      JsonRpcRequest(method: 'tools/list', params: {}, id: 1),
      scope: scope,
    );
    return (response['result']['tools'] as List).cast<Map<String, dynamic>>();
  }

  /// The listed names that carry the upfront mark, sorted.
  Future<List<String>> marked(McpCallScope? scope) async => [
    for (final t in await list(scope))
      if (t['_meta'] != null) t['name'] as String,
  ]..sort();

  Future<String> instructions(McpCallScope? scope) async {
    final response = await dispatcher.handleScopedRequest(
      JsonRpcRequest(
        method: 'initialize',
        params: {
          'clientInfo': {'name': 'claude-code'},
        },
        id: 0,
      ),
      scope: scope,
    );
    return response['result']['instructions'] as String;
  }

  /// The tools of the external server `acme`, one of them named like a
  /// direct tool of ours.
  void connectExternal() => registry.setWorkspaceTools('ws-own', [
    _External('acme', 'mcp__acme__make'),
    _External('acme', 'search_memory'),
  ]);

  group('upfront tools', () {
    test('a run with repl: repl and its direct tools, nothing else', () async {
      final listed = await list(runScope());
      expect(await marked(runScope()), [
        'ask_user',
        'repl',
        'search_memory',
        'todo_write',
      ]);
      for (final t in listed) {
        if (t['_meta'] != null) {
          expect(t['_meta'], {McpRunToolSurface.alwaysLoadKey: true});
          expect(McpRunToolSurface.alwaysLoadKey, 'anthropic/alwaysLoad');
        }
      }
      // A tool no script can reach stays listed, behind the client's search.
      expect([for (final t in listed) t['name']], contains('consult_agent'));

      modes.mode = Mode.plan;
      expect(await marked(runScope()), [
        'ask_user',
        'exit_plan_mode',
        'repl',
        'search_memory',
        'submit_plan',
        'todo_write',
      ]);
    });

    test('a run without repl: its direct tools only', () async {
      for (final list in [tools(withRepl: false), tools(runnerUp: false)]) {
        build(list);
        expect(await marked(runScope()), [
          'ask_user',
          'search_memory',
          'todo_write',
        ]);
      }
      // A run with no run-log id has no script surface, and is still a run.
      build(tools());
      expect(await marked(runScope(runLogId: null)), [
        'ask_user',
        'search_memory',
        'todo_write',
      ]);
    });

    test('a caller that is not a run gets no mark', () async {
      for (final scope in [null, const McpCallScope(workspaceId: 'ws-own')]) {
        final listed = await list(scope);
        expect(listed, isNotEmpty);
        for (final t in listed) {
          expect(t.containsKey('_meta'), isFalse, reason: '${t['name']}');
        }
      }
    });

    test('an external tool is never marked, with repl or without', () async {
      connectExternal();
      expect(await marked(runScope()), isNot(contains('search_memory')));
      expect(await marked(runScope()), isNot(contains('mcp__acme__make')));
      build(tools(withRepl: false));
      connectExternal();
      final listed = await list(runScope());
      expect([
        for (final t in listed) t['name'],
      ], containsAll(['mcp__acme__make', 'search_memory']));
      expect(await marked(runScope()), ['ask_user', 'todo_write']);
    });
  });

  group('instructions', () {
    test('a run with repl is told how its script-only tools are reached, '
        'with an index of its own first-party ones', () async {
      connectExternal();
      final text = await instructions(runScope());
      expect(
        text,
        startsWith(
          'Control Center tools for this run.\n\n`repl` is loaded. It runs a '
          'JavaScript script',
        ),
      );
      expect(text, contains('`await tools.<name>({...})`'));
      expect(text, contains('never report it as missing'));
      expect(text, contains('4 tools are callable only that way'));
      final index = text.split('Callable only from a `repl` script:\n').last;
      expect(
        index,
        '- Tickets and projects: `create_ticket`, `todo_read`\n'
        '- Other: `read_thing`, `write_thing`',
      );
      expect(text, isNot(contains('acme')));
      expect(text, isNot(contains('mcp__')));
      for (final name in [
        'search_memory',
        'todo_write',
        'ask_user',
        'consult_agent',
        'search_tool_bm25',
        'list_my_tools',
        'search_tools',
      ]) {
        expect(text, isNot(contains(name)), reason: name);
      }
      expect(text.length, lessThanOrEqualTo(McpServerInstructions.maxChars));
    });

    test('the index follows the mode', () async {
      modes.mode = Mode.plan;
      final text = await instructions(runScope());
      // Plan mode refuses the write tool.
      expect(text, isNot(contains('write_thing')));
      expect(text, isNot(contains('submit_plan')));
    });

    test('everyone else gets the generic text', () async {
      final runWithout = runScope(runLogId: null);
      for (final scope in [
        null,
        const McpCallScope(workspaceId: 'ws-own'),
        runWithout,
      ]) {
        expect(await instructions(scope), McpServerInstructions.generic);
      }
      build(tools(runnerUp: false));
      expect(await instructions(runScope()), McpServerInstructions.generic);
      for (final word in [
        'repl',
        'search_tools',
        'list_my_tools',
        'search_tool_bm25',
      ]) {
        expect(McpServerInstructions.generic, isNot(contains(word)));
      }
    });

    test('the same names in another order give the same bytes', () {
      final names = [
        'create_ticket',
        'record_observation',
        'code_callers',
        'open_pull_request',
        'render_media',
        'todo_read',
        'list_repos',
      ];
      final text = McpServerInstructions.forScripts(names);
      expect(McpServerInstructions.forScripts(names.reversed), text);
      expect(
        McpServerInstructions.forScripts([...names.skip(3), ...names.take(3)]),
        text,
      );
    });

    test('an index too large for the limit lists whole categories in order '
        'and counts the rest', () {
      final names = [
        for (var i = 0; i < 40; i++) 'ticket_number_$i',
        for (var i = 0; i < 40; i++) 'memory_number_$i',
        for (var i = 0; i < 400; i++) 'misc_tool_number_$i',
      ];
      final text = McpServerInstructions.forScripts(names);
      expect(text.length, lessThanOrEqualTo(McpServerInstructions.maxChars));
      expect(text, contains('480 tools are callable only that way'));
      expect(text, contains('- Tickets and projects: `ticket_number_0`'));
      expect(text, contains('- Memory and knowledge: `memory_number_0`'));
      expect(text, isNot(contains('misc_tool_number')));
      expect(text, endsWith('\n- And 400 more, found with `searchTools`.'));

      // Everything that fits is listed whole, with no count line.
      final small = McpServerInstructions.forScripts(names.take(80));
      expect(small, isNot(contains('more, found with')));
      expect(small, endsWith('`memory_number_9`'));
    });
  });
}

/// A tool of the external server [server], named [name].
class _External extends ProbeTool {
  _External(this.server, String name) : super(name);

  final String server;

  @override
  String? get serverName => server;
}
