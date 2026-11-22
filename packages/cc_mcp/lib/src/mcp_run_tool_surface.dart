import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/code_mode/domain/services/repl_tool_description.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_catalog.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/dispatch/domain/modes/read_only_run_profile.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/services/mode_tool_guard.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:cc_mcp/src/mcp_script_surface.dart';
import 'package:cc_mcp/src/mcp_server_instructions.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:cc_mcp/src/tools/repl_tool.dart' show ReplMcpTool;

/// What a run of the MCP surface sees and may call from a script: its
/// `tools/list`, whether it has the script surface at all ([hasRepl]), the
/// tools it calls directly and the tools its scripts may call. The
/// dispatcher ([McpToolDispatcher]) asks it on every listing, every call
/// and every nested call of a script, so the decision is made in one place.
final class McpRunToolSurface {
  /// Creates the surface over [registry], gated by [modeGuard].
  McpRunToolSurface({required this.registry, this.modeGuard});

  /// The tools.
  final McpToolRegistry registry;

  /// Resolves a run's conversation mode; null applies no mode.
  final ModeToolGuard? modeGuard;

  /// What `tools/list` advertises to [scope]'s caller.
  ///
  /// A caller that is not an attested run, and every caller of a server
  /// without a usable `repl`, sees every tool [view] admits except `repl`.
  /// An attested run on a server with `repl` sees `repl`, the direct tools
  /// ([directNames]: [ModeToolPolicy.directNamesFor], the mode's pinned
  /// verbs and the interaction verbs) and every tool no script of the run
  /// can reach, and calls everything else from a script. The `repl`
  /// description is built for this run's callable set and is the same bytes
  /// for the same surface, because it sits in the client's cached prefix.
  /// A read-only run ([McpCallScope.readOnly]) is listed only the tools
  /// `ReadOnlyRunProfile.admits`, so it does not try the others.
  ///
  /// The client may defer what is listed (Claude Code keeps every MCP tool
  /// behind its tool search by default). For an attested run, with `repl` or
  /// without, `repl` and the direct tools carry [upfrontMeta], which asks
  /// the client to load them upfront; everything else listed, a tool no
  /// script can reach included, is left to load on first use, and nothing
  /// external or listed to another caller is ever marked.
  Future<List<ToolDef>> listed(McpCallScope? scope, McpToolView view) async {
    final all = [
      for (final d in registry.listDefinitions(view: view))
        if (admitsFor(scope, d.name, view)) d,
    ];
    if (!hasRepl(scope, view)) {
      final upfront = scope != null && scope.attested
          ? directNames(await runMode(scope))
          : const <String>{};
      return [
        for (final d in all)
          if (d.name != ReplToolDescription.toolName)
            upfront.contains(d.name) && !registry.isExternal(d.name, view: view)
                ? _upfront(d)
                : d,
      ];
    }
    final run = scope!;
    final mode = await runMode(run);
    final callable = scriptCallable(run, view, mode);
    final direct = {
      ...directNames(mode),
      // A tool no script of this run can reach stays direct, as on the
      // harness: one that says it is not for scripts, and one the script
      // lane leaves out (a tool not confined to a workspace, say). Nothing
      // else could reach it. A tool the mode refuses is not listed, and the
      // discovery tools are not offered: the script catalog replaces them.
      for (final d in all)
        if (!_discoveryTools.contains(d.name) &&
            !callable.containsKey(d.name) &&
            (mode == null || ModeToolPolicy.isAllowed(d.name, mode)))
          d.name,
    };
    final catalog = ScriptCatalog([
      for (final tool in callable.values) descriptorOf(tool, run, view),
    ]);
    final description = ReplToolDescription.build(
      catalog,
      directToolNames: direct,
    );
    final upfront = directNames(mode);
    return [
      for (final d in all)
        if (d.name == ReplToolDescription.toolName)
          ToolDef(
            name: d.name,
            description: description,
            inputSchema: d.inputSchema,
            meta: upfrontMeta,
          )
        else if (direct.contains(d.name))
          upfront.contains(d.name) && !registry.isExternal(d.name, view: view)
              ? _upfront(d)
              : d,
    ];
  }

  /// The `_meta` key that asks Claude Code to load a listed tool upfront
  /// instead of keeping it behind its tool search. A client that does not
  /// know it ignores it.
  static const String alwaysLoadKey = 'anthropic/alwaysLoad';

  /// The `_meta` of a tool a run is asked to have loaded from the start.
  static const Map<String, Object> upfrontMeta = {alwaysLoadKey: true};

  static ToolDef _upfront(ToolDef d) => ToolDef(
    name: d.name,
    description: d.description,
    inputSchema: d.inputSchema,
    meta: upfrontMeta,
  );

  /// The MCP `initialize` instructions for [scope]'s caller.
  ///
  /// An attested run with `repl` ([hasRepl]) is told how its script-only
  /// tools are reached, with an index of the first-party ones, from the same
  /// sets [listed] uses: what a script may call ([scriptCallable]) less the
  /// direct tools ([directNames]). Every other caller gets the generic text
  /// ([McpServerInstructions.generic]), with no claim about `repl`.
  Future<String> instructions(McpCallScope? scope, McpToolView view) async {
    if (!hasRepl(scope, view)) {
      return McpServerInstructions.generic;
    }
    final run = scope!;
    final mode = await runMode(run);
    final direct = directNames(mode);
    return McpServerInstructions.forScripts([
      for (final name in scriptCallable(run, view, mode).keys)
        if (!direct.contains(name) && !registry.isExternal(name, view: view))
          name,
    ]);
  }

  /// Whether [scope]'s caller gets the script surface: an attested run with
  /// a run-log id (a script's audit row hangs off it, so `repl` refuses a
  /// run without one), on a server whose `repl` is registered in [view] and
  /// whose runner passes its self-test now (read on every call, so a runner
  /// turned off stops the redirect at once), and whose scripts the server
  /// has not refused for a reason no other script would have escaped
  /// ([ReplMcpTool.withdrawn]): such a run calls every tool directly for
  /// the rest of its life.
  bool hasRepl(McpCallScope? scope, McpToolView view) {
    final runLogId = scope?.runLogId;
    if (scope == null ||
        !scope.attested ||
        runLogId == null ||
        runLogId.isEmpty) {
      return false;
    }
    final repl = registry.lookup(ReplToolDescription.toolName, view: view);
    return repl != null &&
        (repl is! ReplMcpTool ||
            (repl.executions.availability.isAvailable &&
                !repl.withdrawn.contains(runLogId)));
  }

  /// The tools a caller may be pointed at by name: every tool [view] admits
  /// but `repl` for a caller without the script surface, and every tool but
  /// the catalogue searches for a run with it ([scripts], from [hasRepl];
  /// its script-only tools are named for its scripts).
  Iterable<String> nameable(McpToolView view, {required bool scripts}) => [
    for (final name in registry.toolNames(view: view))
      if (scripts
          ? !_discoveryTools.contains(name)
          : name != ReplToolDescription.toolName)
        name,
  ];

  /// The run's conversation mode, resolved from its own scope (never from a
  /// call's arguments), or null when there is no conversation to scope to.
  Future<Mode?> runMode(McpCallScope scope) async {
    final guard = modeGuard;
    final workspaceId = scope.workspaceId;
    if (guard == null || workspaceId == null || workspaceId.isEmpty) {
      return null;
    }
    return guard.resolveMode(
      workspaceId: workspaceId,
      spaceId: scope.spaceId,
      agentId: scope.agentId,
    );
  }

  /// The catalogue search's tool name (`SearchToolBm25.toolName`).
  static const String searchToolName = 'search_tool_bm25';

  /// The sentence a run with scripts reads with its search hits.
  static const String scriptHitsNote =
      'A hit with `"script_only": true` is not in your tool list: call it '
      'from a `repl` script as `await tools["<name>"](args)`, not directly. '
      'The other hits are called directly by their `name`.';

  /// [result], a `search_tool_bm25` answer, as true for a run of [scope]
  /// with scripts ([hasRepl]): each hit says whether the run reaches it only
  /// from a script (`script_only`, the field the harness `search_tools`
  /// uses for the same fact), the note says how to call such a hit, and the
  /// catalogue searches, which the run is not listed, are not hits. Any
  /// answer of another shape is returned unchanged.
  Future<CallResult> searchForScripts(
    CallResult result,
    McpCallScope scope,
    McpToolView view,
  ) async {
    if (result.isError || result.content.length != 1) {
      return result;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(result.content.single.text);
    } on FormatException {
      return result;
    }
    if (decoded is! Map<String, dynamic> || decoded['tools'] is! List) {
      return result;
    }
    final mode = await runMode(scope);
    final reached = scriptCallable(scope, view, mode);
    final direct = directNames(mode);
    final hits = [
      for (final hit in decoded['tools'] as List)
        if (hit is Map<String, dynamic> &&
            !_discoveryTools.contains(hit['name']))
          {
            ...hit,
            'script_only':
                reached.containsKey(hit['name']) &&
                !direct.contains(hit['name']),
          },
    ];
    final note = decoded['note'];
    return CallResult.success(
      jsonEncode({
        ...decoded,
        'matches': [for (final hit in hits) hit['name']],
        'tools': hits,
        // A mode's own sentence (restricted hits) stays after it.
        'note': decoded['conversation_mode'] != null && note is String
            ? '$scriptHitsNote $note'
            : scriptHitsNote,
      }),
    );
  }

  /// The catalogue searches. Not listed to a run with `repl`: a script has
  /// `searchTools()` and `ALL_TOOLS`, and the `repl` description indexes
  /// what a script can call.
  static const Set<String> _discoveryTools = {searchToolName, 'list_my_tools'};

  /// The tools a run with `repl` in [mode] calls directly: the direct set
  /// with the mode's own loop, the mode's pinned verbs (its output verbs and
  /// its exit verb) and the interaction verbs, so a run never has to write a
  /// script to deliver its deliverable or to ask a person something.
  static Set<String> directNames(Mode? mode) => {
    ...ModeToolPolicy.directNamesFor(mode ?? Mode.chat),
    ...profileFor(mode ?? Mode.chat).pinnedVerbs,
    ...ModeCapabilityProfile.interactionVerbs,
  };

  /// Whether [scope]'s caller may call [name] at all: every tool, except
  /// for a read-only run, which may call only what changes nothing.
  bool admitsFor(McpCallScope? scope, String name, McpToolView view) {
    if (!(scope?.readOnly ?? false)) {
      return true;
    }
    final tool = registry.lookup(name, view: view);
    return tool != null &&
        ReadOnlyRunProfile.admits(tool.name, tool.actionClasses);
  }

  /// What a script running for [scope] may call, by name: [view]'s tools
  /// that the mode guard admits in [mode], without the tools that say they
  /// are not for scripts ([McpTool.scriptCallable]),
  /// and without any tool the run could not call directly either (one that
  /// is not confined to a workspace, or needs an identity the run lacks).
  Map<String, McpTool> scriptCallable(
    McpCallScope scope,
    McpToolView view,
    Mode? mode,
  ) {
    final callable = <String, McpTool>{};
    for (final name in registry.toolNames(view: view)) {
      if ((mode != null && !ModeToolPolicy.isAllowed(name, mode)) ||
          !admitsFor(scope, name, view)) {
        continue;
      }
      final tool = registry.lookup(name, view: view);
      if (tool == null ||
          !tool.scriptCallable ||
          !(McpToolDispatcher.declaresWorkspace(tool) ||
              registry.isExternal(name, view: view)) ||
          (tool.requiresRunGrant && !scope.attested) ||
          scope.firstMissing(tool.requiredScopeKeys) != null) {
        continue;
      }
      callable[name] = tool;
    }
    return callable;
  }

  /// How a script sees [tool]: under its server's namespace when it is
  /// external, under `control-center` when it is ours.
  ScriptToolDescriptor descriptorOf(
    McpTool tool,
    McpCallScope scope,
    McpToolView view,
  ) => scriptToolDescriptor(
    tool,
    scope: scope,
    namespace: registry.isExternal(tool.name, view: view)
        ? ScriptToolNamespace.external(tool.serverName ?? tool.name)
        : ScriptToolNamespace.controlCenter,
  );
}
