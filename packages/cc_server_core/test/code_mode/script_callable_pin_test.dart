import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show JsonRpcRequest;
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/services/repl_tool_description.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/cc_infra.dart';
// ignore: implementation_imports
import 'package:cc_infra/src/evaluation/goal_verification_session.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart'
    show BridgedMcpTool, McpRemoteTool;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import '../helpers/server_mcp_registry_fixture.dart';
import '../helpers/test_database.dart';

/// Every tool's decision whether a code mode script may call it, pinned both
/// ways on both surfaces: a tool nobody decided about fails here, not in a
/// run. Every class of a tool (one that extends, mixes in or implements
/// `HarnessTool` or `McpTool`) in the server's packages is read off its
/// source and must appear below with the decision its source states
/// (`scriptCallable`, `true` unless overridden); a declaration the scan
/// cannot read fails it; every entry must still name a tool; and every tool
/// the harness registry and the test server's MCP registry build says the
/// same at run time.
///
/// Reasons for `false`. Harness: `repl` would nest interpreters; `task` and
/// the vibe verbs start model loops of their own, outside the script's
/// deadline and the run's view of what it is doing; `checkpoint`, `rewind`
/// and `compact` rewrite the conversation the script is part of; `search_tools` answers a
/// question the script catalog already answers. MCP: `repl` and the catalogue
/// searches likewise; the rest start, message or assign another agent run,
/// create, decide or comment on an approval (what a comment says is read by
/// the person deciding it), propose or change policy, install or change
/// skills, create a runtime profile, leave plan mode, or end the run
/// (`submit_output`). `complete_goal` is a claim the server verifies, so a
/// script that checks each item and then claims may call it.
///
/// A tool may also refuse a script particular arguments
/// (`scriptArgumentRefusal`): `create_ticket` refuses `assignee`, and `bash`
/// refuses `run_in_background` (a background command must not outlive the
/// script that started it).
///
/// Tools with no source of their own are decided by rule: a tool of an
/// external or workspace MCP server (`BridgedMcpTool`) is callable by a
/// script under the gate every call of it gets: an `exec` tool that requires
/// approval, since nothing gives `BridgedMcpTool` a tier resolver; a wrapper
/// (`McpToolBridge`, `DiagnosticsOnWriteTool`, the controlled evaluation
/// tools) answers what the tool it wraps answers.
const harnessScriptCallable = <String, bool>{
  'apply_patch': true,
  'ask_user': true,
  'ast_edit': true,
  'ast_grep': true,
  'bash': true,
  'bash_kill': true,
  'bash_output': true,
  'checkpoint': false,
  'compact': false,
  // Evaluation-only copies of two MCP tools (cc_infra
  // `goal_verification_session.dart`), decided as the product's are: the
  // goal attempt's `complete_goal` is callable, and the review run's
  // `submit_output` is not. Both are built in `pinnedTools()`.
  'complete_goal': true,
  'debug': true,
  'edit': true,
  'eval': false,
  'find': true,
  'lsp': true,
  'lsp_rename': true,
  'read': true,
  'read_output': true,
  'repl': false,
  'resolve': true,
  'rewind': false,
  'search': true,
  'search_files': true,
  'search_tools': false,
  'submit_output': false,
  'task': false,
  'vibe_kill': false,
  'vibe_list': false,
  'vibe_send': false,
  'vibe_spawn': false,
  'vibe_wait': false,
  'web_fetch': true,
  'web_search': true,
  'write': true,
};

/// See [harnessScriptCallable].
const mcpScriptCallable = <String, bool>{
  'add_review_diagram': true,
  'add_review_node': true,
  'add_ticket_collaborator': true,
  'agent_activity': true,
  'agent_heartbeat': true,
  'app_use': true,
  'ask_agent': false,
  'ask_user': true,
  'assign_ticket': false,
  'browser_use': true,
  'cancel_wake': true,
  'close_ticket': true,
  'code_callees': true,
  'code_callers': true,
  'code_impact': true,
  'code_symbol': true,
  'comment_approval': false,
  'comment_on_pull_request': true,
  'comment_on_ticket': false,
  'complete_goal': true,
  'computer_use': true,
  'confirm_review_node': true,
  'consolidate_memory': true,
  'consult_agent': false,
  'create_approval': false,
  'create_goal': true,
  'create_playbook': true,
  'create_runtime_profile': false,
  'create_skill': false,
  'create_ticket': true,
  'create_work_product': true,
  'decide_approval': false,
  'delegate_task': false,
  'delegate_ticket': false,
  'dismiss_review_node': true,
  'dispatch_reviewers': false,
  'environment_destroy': true,
  'environment_down': true,
  'environment_exec': true,
  'environment_launch_app': true,
  'environment_logs': true,
  'environment_reset': true,
  'environment_restart': true,
  'environment_run_task': true,
  'environment_status': true,
  'environment_stop_app': true,
  'environment_up': true,
  'exit_plan_mode': false,
  'fail_ticket': true,
  'finalize_review': true,
  'get_article': true,
  'get_artifact': true,
  'get_messages': true,
  'get_my_notes': true,
  'get_org_chart': true,
  'get_space_notes': true,
  'get_ticket': true,
  'get_work_product': true,
  'goal_status': true,
  'harmonize_memory': true,
  'install_skill': false,
  'ios_use': true,
  'list_agent_presence': true,
  'list_agents': true,
  'list_approvals': true,
  'list_articles': true,
  'list_artifacts': true,
  'list_feeds': true,
  'list_goals': true,
  'list_memory_conflicts': true,
  'list_memory_domains': true,
  'list_my_tools': false,
  'list_policies': true,
  'list_repos': true,
  'list_runtime_health': true,
  'list_runtime_profiles': true,
  'list_skill_updates': true,
  'list_skills': true,
  'list_spaces': true,
  'list_ticket_relations': true,
  'list_tickets': true,
  'list_wakes': true,
  'list_work_products': true,
  'list_workspaces': true,
  'mobile_use': true,
  'open_pull_request': true,
  'pin_skill': false,
  'preview_trigger': true,
  'propose_fact': true,
  'propose_orchestration': false,
  'propose_policy': false,
  'publish_artifact': true,
  'publish_review_to_github': true,
  'reassign_ticket': false,
  'record_observation': true,
  'record_team_activity': true,
  'refresh_feeds': true,
  'remember': true,
  'render_media': true,
  'repl': false,
  'request_peer_review': false,
  'resolve_review_node': true,
  'revise_artifact': true,
  'rig_close': true,
  'rig_list': true,
  'run_playbook': false,
  'save_work_product_revision': true,
  'search_code': true,
  'search_memory': true,
  'search_tool_bm25': false,
  'send_message': false,
  'send_to_agent': false,
  'set_article_read': true,
  'set_article_saved': true,
  'set_cohort_summary': true,
  'stack_checkout': true,
  'stack_cut': true,
  'stack_publish': true,
  'stack_status': true,
  'start_ai_review': false,
  'submit_output': false,
  'submit_plan': false,
  'submit_reviewer_verdict': true,
  'supersede_fact': true,
  'supersede_policy': false,
  'ticket_pr_link': true,
  'ticket_relation': true,
  'todo_read': true,
  'todo_write': true,
  'update_goal_progress': true,
  'update_my_notes': true,
  'update_pull_request': true,
  'update_skill': false,
  'update_space_notes': true,
  'update_ticket': true,
  'verify_skills': true,
  'wake_me': true,
};

/// Tool classes whose name is not in their source, each decided by a rule
/// (see [harnessScriptCallable]): wrappers answer for what they wrap.
const harnessWrappers = {
  'McpToolBridge',
  'DiagnosticsOnWriteTool',
  'ControlledEvaluationBashTool',
  '_ControlledFileTool',
};

/// See [harnessWrappers]: an external or workspace server's tool.
const mcpWrappers = {'BridgedMcpTool'};

void main() {
  final neverScripted = {
    for (final e in harnessScriptCallable.entries)
      if (!e.value) e.key,
  };
  final mcpNeverScripted = {
    for (final e in mcpScriptCallable.entries)
      if (!e.value) e.key,
  };

  List<HarnessTool> pinnedTools() {
    final registry = buildHarnessToolRegistry(
      mode: Mode.chat,
      networkEnabled: true,
      env: const {},
      workspaceId: 'ws-1',
      agentId: 'agent-1',
      conversationId: 'conv-1',
      fileSearch: _NoFileSearch(),
      mcpRegistry: McpToolRegistry(const []),
      replSlot: true,
      // `eval` is built only with a kernel factory and a launcher; neither
      // runs here, the pin only reads what the tool says.
      evalKernelFor: (_) => throw StateError('no kernel in this test'),
      toolProcesses: const HostToolProcessLauncher(),
    )..register(TaskTool(_NeverSpawns()));
    return [
      ...registry.tools,
      ...buildVibeTools(roster: VibeRoster(), runner: _NeverRuns()),
      HarnessToolSearchTool(
        catalog: registry.tools,
        residency: const ToolResidencySpec(),
      ),
      ReplTool(
        executor: _NoScripts(),
        run: ReplRunIdentity(
        workspaceId: 'ws-1',
        runId: 'run-1',
        readOnly: false,
        past: null,
      ),
        callableTools: registry.tools,
        limits: CodeModeLimits.defaults,
      ),
      // Evaluation-only tools: built here so each says what its pin says.
      EvaluationCompleteGoalTool((_) => throw StateError('no claim here')),
      EvaluationSubmitOutputTool(),
    ];
  }

  test('every harness tool class is pinned with the decision its source '
      'states, and every pin names a tool', () {
    final scan = _scanTools(const [
      '../cc_harness/lib',
      '../cc_harness_runtime/lib',
      '../cc_infra/lib',
      '../cc_server_core/lib',
    ], base: 'HarnessTool');
    expect(scan.decided, harnessScriptCallable);
    expect(scan.wrappers.keys.toSet(), harnessWrappers);
    // A wrapper answers what it wraps, never a value of its own.
    for (final MapEntry(key: cls, value: answer) in scan.wrappers.entries) {
      expect(answer, endsWith('.scriptCallable'), reason: cls);
    }
  });

  test('every tool the harness registry builds says what its pin says', () {
    final tools = pinnedTools();
    final built = {for (final t in tools) t.name: t.scriptCallable};
    for (final MapEntry(key: name, value: callable) in built.entries) {
      expect(harnessScriptCallable[name], callable, reason: name);
    }
    expect(
      built.keys,
      containsAll(neverScripted),
      reason: 'a tool a script may not call was renamed or is not built',
    );
    // Non-vacuity: ordinary tools stay callable.
    for (final name in ['read', 'search_files', 'bash']) {
      expect(built[name], isTrue, reason: name);
    }
  });

  test('an MCP tool the harness bridges answers for itself, with its '
      'argument rule', () {
    for (final MapEntry(key: name, value: callable)
        in mcpScriptCallable.entries) {
      expect(
        McpToolBridge(_Named(name, scriptCallable: callable)).scriptCallable,
        callable,
        reason: name,
      );
    }
  });

  test('the surface with repl never puts them in the script list', () {
    for (final mode in Mode.values) {
      final profile = profileFor(mode);
      final registry = HarnessToolRegistry.of(pinnedTools());
      final surface = materializeHarnessToolSurface(
        registry: registry,
        surface: profile.toToolSurfaceSpec(),
        residency: profile.toToolResidencySpec(),
      );
      expect(surface.hasRepl, isTrue, reason: mode.name);
      final scripted = {for (final t in surface.scriptOnly) t.name};
      expect(scripted.intersection(neverScripted), isEmpty, reason: mode.name);
      // ...and leaves them where a direct call reaches them: among the
      // direct tools when the direct set names them, deferred otherwise.
      final admitted = {
        for (final t in registry.toolsFor(profile.toToolSurfaceSpec())) t.name,
      };
      final resident = {for (final t in surface.resident) t.name};
      final deferred = {for (final t in surface.deferred) t.name};
      final unscripted = admitted.intersection(neverScripted).difference({
        ...ModeToolPolicy.residentDiscovery,
        'repl',
      });
      expect(
        {...resident, ...deferred},
        containsAll(unscripted),
        reason: mode.name,
      );
      expect(deferred.intersection(resident), isEmpty, reason: mode.name);
      expect(
        resident.intersection(unscripted).difference({
          ...ModeToolPolicy.directNamesFor(mode),
          ...profile.pinnedVerbs,
          ...ModeCapabilityProfile.interactionVerbs,
        }),
        isEmpty,
        reason: mode.name,
      );
      // `search_tools` is resident exactly when something is deferred (a
      // script never needs it, a deferred tool does), and `list_my_tools`
      // never is: the script catalog replaces it.
      expect(resident, isNot(contains('list_my_tools')), reason: mode.name);
      expect(
        resident.contains('search_tools'),
        surface.hasDeferred,
        reason: mode.name,
      );
    }
  });

  group('the scan', () {
    test('sees a tool that mixes in or implements a tool, and what it '
        'inherits from a mixin', () {
      final scan = _scanSources([
        '''
abstract class Base {}
mixin Held on Base {
  bool get scriptCallable => false;
}
class Mixed extends Base with Held {
  String get name => 'mixed';
}
class OnlyImplements implements Base {
  String get name => 'implements';
  bool get scriptCallable => false;
}
class Plain extends Base {
  String get name => 'plain';
}
mixin class HeldToo implements Base {
  bool get scriptCallable => false;
  String get name => 'held_too';
}
class MixedClass extends Base with HeldToo {
  String get name => 'mixed_class';
}
''',
      ], base: 'Base');
      expect(scan.decided, {
        'mixed': false,
        'implements': false,
        'plain': true,
        'held_too': false,
        'mixed_class': false,
      });
    });

    for (final (form, body) in [
      ('a block-bodied getter', 'bool get scriptCallable { return false; }'),
      ('a field', 'final bool scriptCallable = false;'),
      ('a late final', 'late final bool scriptCallable = false;'),
    ]) {
      test('fails on $form instead of reading it as inherited', () {
        expect(
          () => _scanSources([
            '''
abstract class Base {}
class Hidden extends Base {
  String get name => 'hidden';
  $body
}
''',
          ], base: 'Base'),
          throwsA(isA<TestFailure>()),
        );
      });
    }

    test('fails on a class that only implements a tool and states nothing', () {
      expect(
        () => _scanSources([
          '''
abstract class Base {}
class Bare implements Base {
  String get name => 'bare';
}
''',
        ], base: 'Base'),
        throwsA(isA<TestFailure>()),
      );
    });
  });

  group('the MCP lane', () {
    test('every MCP tool class is pinned with the decision its source '
        'states, and every pin names a tool', () {
      final scan = _scanTools(const [
        '../cc_mcp/lib',
        '../cc_mcp_client/lib',
        '../cc_infra/lib',
        '../cc_server_core/lib',
      ], base: 'McpTool');
      expect(scan.decided, mcpScriptCallable);
      // An external or workspace server's tool states nothing: callable by
      // rule, under the gate its `exec` tier and approval give every call.
      expect(scan.wrappers, {'BridgedMcpTool': null});
    });

    test('an external or workspace server\'s tool is callable by a script '
        'and asks like any call of it', () {
      final tool = BridgedMcpTool(
        serverName: 'tracker',
        remoteTool: const McpRemoteTool(
          name: 'create_issue',
          description: 'Creates an issue.',
          inputSchema: {'type': 'object'},
        ),
        invoker: (_, _, _) async => const {},
      );
      expect(tool.scriptCallable, isTrue);
      expect(tool.scriptArgumentRefusal(const {'assignee': 'a'}), isNull);
      expect(tool.requiresApproval, isTrue);
      expect(tool.toolApproval(const {}).tier, CapabilityTier.exec);
      expect(McpToolBridge(tool).scriptCallable, isTrue);
    });

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

    test('the tools that are not for scripts are exactly the pinned ones, '
        'and none is offered to a script', () async {
      final repl = ReplMcpTool(
        executions: _NoScripts(),
        limitsFor: (_) async => CodeModeLimits.defaults,
        records: _NoRecords(),
        past: null,
      );
      final registry = buildTestServerMcpRegistry(
        global: global,
        dbs: dbs,
        repl: repl,
      );
      final dispatcher = McpToolDispatcher(registry: registry);
      repl.bind(dispatcher);
      final notScripted = <String>{
        for (final name in registry.toolNames(view: McpToolView.shared))
          if (registry.lookup(name, view: McpToolView.shared) case final tool?
              when !tool.scriptCallable)
            name,
      };

      // This registry holds the tools that need no live services; each of
      // them that is not for scripts is pinned, and so is every other.
      final registered = registry.toolNames(view: McpToolView.shared).toSet();
      expect(notScripted, mcpNeverScripted.intersection(registered));
      expect(notScripted, isNotEmpty);
      // Every tool it builds is pinned, with the decision it gives at run
      // time.
      for (final name in registered) {
        expect(
          mcpScriptCallable[name],
          registry.lookup(name, view: McpToolView.shared)!.scriptCallable,
          reason: name,
        );
      }

      const scope = McpCallScope(
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        conversationId: 'conv-1',
        spaceId: 'space-1',
        attested: true,
        runId: 'dispatch-1',
        runLogId: 'log-1',
      );
      final scriptable = {
        for (final d in await dispatcher.scriptToolsFor(scope)) d.name,
      };
      expect(scriptable, isNotEmpty);
      expect(scriptable.intersection(mcpNeverScripted), isEmpty);
      // Non-vacuity: the borderline tools that stay callable.
      expect(scriptable, containsAll(['todo_write', 'list_agents']));

      final listed = await dispatcher.handleScopedRequest(
        JsonRpcRequest(method: 'tools/list', params: const {}, id: 1),
        scope: scope,
      );
      final description =
          ((listed['result'] as Map<String, dynamic>)['tools'] as List)
                  .cast<Map<String, dynamic>>()
                  .singleWhere((t) => t['name'] == 'repl')['description']
              as String;
      expect(description, contains(ReplToolDescription.namespacesHeading));
      // A direct tool a script may also call is listed with its result note.
      expect(
        description,
        contains(
          '- todo_write: '
          '${registry.lookup('todo_write', view: McpToolView.shared)!.resultNote}',
        ),
      );
      // An attested run still has every tool a script may not call, but the
      // catalogue searches (the script catalog replaces them).
      final listedNames = {
        for (final t
            in (listed['result'] as Map<String, dynamic>)['tools'] as List)
          (t as Map<String, dynamic>)['name'] as String,
      };
      expect(
        listedNames,
        containsAll(
          notScripted.difference({'search_tool_bm25', 'list_my_tools'}),
        ),
      );
      expect(listedNames, isNot(contains('search_tool_bm25')));
      for (final name in mcpNeverScripted) {
        expect(
          description,
          isNot(contains('{ $name(args')),
          reason: 'repl offers $name',
        );
      }
    });
  });
}

/// What a tool class's source states: `decided` maps each tool name to its
/// `scriptCallable` (inherited from a mixin or a base class when not its own,
/// `true` when nobody overrides it); `wrappers` maps each class whose name is
/// not in its source to the expression its `scriptCallable` returns (null
/// when it states none).
///
/// A class is a tool of [base] when it extends, mixes in or implements
/// [base] or another tool. A declaration of `scriptCallable` this scan cannot
/// read (anything but `bool get scriptCallable => <expression>;`: a block
/// body, a field, a late final) fails it rather than being read as
/// inherited, and so does a class that only implements a tool and states
/// nothing, since it inherits no answer.
({Map<String, bool> decided, Map<String, String?> wrappers}) _scanTools(
  List<String> roots, {
  required String base,
}) {
  final sources = <String>[
    for (final root in roots)
      for (final file in Directory(
        root,
      ).listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'))
          file.readAsStringSync(),
  ];
  return _scanSources(sources, base: base);
}

({Map<String, bool> decided, Map<String, String?> wrappers}) _scanSources(
  List<String> sources, {
  required String base,
}) {
  final declaration = RegExp(
    r'^((?:abstract |final |base |sealed |interface |mixin (?=class ))*)'
    r'(class|mixin) (\w+)'
    r'(?:<[^>{]*>)?([^{]*)\{',
    multiLine: true,
  );
  final topLevel = RegExp(
    r'^(?:abstract |final |base |sealed |interface |mixin )*'
    r'(?:class|mixin|enum|extension|typedef) ',
    multiLine: true,
  );
  List<String> named(String header, String keyword) {
    final m = RegExp(
      '\\b$keyword\\s+([\\w<>, ]+?)(?=\\s+(?:with|implements|on)\\b|\$)',
    ).firstMatch(header.trim());
    return m == null
        ? const []
        : [
            for (final t in m.group(1)!.split(','))
              t.trim().replaceAll(RegExp('<.*'), ''),
          ];
  }

  // Class names repeat across packages (`AskUserTool` is a harness tool and
  // an MCP tool), so every declaration is kept and a parent is found by name
  // among those that are tools of [base].
  final classes =
      <
        ({
          String name,
          String? parent,
          List<String> mixins,
          List<String> interfaces,
          bool isAbstract,
          String body,
        })
      >[];
  for (final source in sources) {
    final starts = [for (final m in topLevel.allMatches(source)) m.start];
    for (final m in declaration.allMatches(source)) {
      final next = starts.firstWhere(
        (s) => s > m.start,
        orElse: () => source.length,
      );
      final isMixin = m.group(2) == 'mixin';
      final header = m.group(4)!;
      classes.add((
        name: m.group(3)!,
        parent: isMixin ? null : named(header, 'extends').firstOrNull,
        mixins: named(header, 'with'),
        interfaces: [
          ...named(header, 'implements'),
          if (isMixin) ...named(header, 'on'),
        ],
        isAbstract:
            isMixin ||
            m.group(1)!.contains('abstract') ||
            m.group(1)!.contains('interface'),
        body: source.substring(m.start, next),
      ));
    }
  }
  String keyOf(({String name, String body}) c) =>
      '${c.name}@${c.body.hashCode}';
  final byKey = {
    for (final c in classes) keyOf((name: c.name, body: c.body)): c,
  };
  String? toolKey(String name, Set<String> tools) =>
      tools.where((k) => k.startsWith('$name@')).firstOrNull;
  final tools = <String>{};
  // Grows from [base] down: a class that extends, mixes in or implements a
  // tool is one.
  for (var grew = true; grew;) {
    grew = false;
    for (final MapEntry(key: key, value: c) in byKey.entries) {
      if (tools.contains(key)) {
        continue;
      }
      final supers = [?c.parent, ...c.mixins, ...c.interfaces];
      if (supers.any((t) => t == base || toolKey(t, tools) != null)) {
        tools.add(key);
        grew = true;
      }
    }
  }
  final readable = RegExp(r'bool get scriptCallable =>\s*([^;]+);');
  final declared = RegExp(
    r'^\s*(?:late\s+)?(?:final\s+)?(?:bool\??|var)\s+(?:get\s+)?'
    r'scriptCallable\b|\bget\s+scriptCallable\b',
    multiLine: true,
  );
  String? stated(String name, String body) {
    final declarations = declared.allMatches(body).toList();
    if (declarations.isEmpty) {
      return null;
    }
    final read = readable.firstMatch(body);
    if (declarations.length != 1 ||
        read == null ||
        !body
            .substring(declarations.single.start)
            .trimLeft()
            .startsWith('bool get scriptCallable =>')) {
      fail(
        '$name declares scriptCallable in a form this scan cannot read; '
        'write `bool get scriptCallable => <expression>;`',
      );
    }
    return read.group(1)!.trim();
  }

  String? inherited(String key) {
    final c = byKey[key]!;
    final own = stated(c.name, c.body);
    if (own != null) {
      return own;
    }
    // The last mixin wins, then the superclass; an interface lends nothing.
    for (final mixin in c.mixins.reversed) {
      final k = toolKey(mixin, tools);
      if (k != null) {
        final answer = inherited(k);
        if (answer != null) {
          return answer;
        }
      }
    }
    final parent = c.parent;
    if (parent != null && parent != base) {
      final k = toolKey(parent, tools);
      if (k != null) {
        return inherited(k);
      }
    }
    if (parent == null && c.mixins.isEmpty && !c.isAbstract) {
      fail(
        '${c.name} only implements a tool and states no scriptCallable, so '
        'it inherits no answer',
      );
    }
    return null;
  }

  final decided = <String, bool>{};
  final wrappers = <String, String?>{};
  for (final key in tools) {
    final c = byKey[key]!;
    if (c.isAbstract) {
      continue;
    }
    final name =
        RegExp(
          r"String get name => '([a-z0-9_]+)';",
        ).firstMatch(c.body)?.group(1) ??
        RegExp(
          r"static const String toolName = '([a-z0-9_]+)';",
        ).firstMatch(c.body)?.group(1) ??
        (c.body.contains('get name => ReplToolDescription.toolName')
            ? ReplToolDescription.toolName
            : null);
    final answer = inherited(key);
    if (name == null) {
      wrappers[c.name] = answer;
      continue;
    }
    final callable = switch (answer) {
      null || 'true' => true,
      'false' => false,
      _ => fail('${c.name} ($name) answers scriptCallable with "$answer"'),
    };
    final earlier = decided[name];
    expect(
      earlier == null || earlier == callable,
      isTrue,
      reason: 'two classes named $name disagree',
    );
    decided[name] = callable;
  }
  return (decided: decided, wrappers: wrappers);
}

/// An MCP tool that says only its name and decision.
class _Named extends McpTool {
  _Named(this.name, {required this.scriptCallable});

  @override
  final String name;
  @override
  final bool scriptCallable;
  @override
  String get description => name;
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success('ok');
}

class _NeverSpawns implements SubagentSpawner {
  @override
  Future<SubagentResult> spawn(SubagentSpawnRequest request) =>
      throw StateError('not spawned in this test');
}

class _NeverRuns implements VibeWorkerRunner {
  @override
  Future<SubagentResult> run({
    required VibeWorker worker,
    required String brief,
    required HarnessToolContext context,
    required SubagentType type,
    String? modelOverride,
  }) => throw StateError('not run in this test');
}

/// Reports a runner that passed, so the surfaces offer `repl`; it never runs
/// a script.
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

class _NoFileSearch implements FileSearchPort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('no file search in this test');
}

class _NoRecords implements CodeExecutionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('no scripts in this test');
}
