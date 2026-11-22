import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart'
    show AdapterTransport;
import 'package:cc_harness/tools.dart';

/// What a read-only run (`readOnly: true`, a goal's review run, an
/// improvement review) may call, whatever its conversation's mode says.
///
/// A read-only run changes nothing: not the worktree, the checklist, notes,
/// memory, artifacts, messages, tickets, pull requests, processes, wakes or
/// goals, and it does not ask a person. It reads and answers through
/// [outputVerbs]. Every surface a run's tool call passes asks [admits]: the
/// built-in harness's tool surface (and so its scripts' nested calls), the
/// MCP dispatcher's gate for Claude Code and ACP (from the attested call
/// scope's run, never from an argument) and Claude Code's own tool hook.
///
/// A tool is decided by its curated action classes where it has one that
/// changes state ([deniedClasses]); a tool whose classes say nothing about a
/// local write (most of the MCP surface writes only this server's database)
/// is decided by [readTools] or [stateTools]. Anything in neither set is
/// refused, so a new tool is refused to read-only runs until someone
/// decides it (`action_class_coverage_test.dart` fails on an undecided one).
// ignore: avoid_classes_with_only_static_members
abstract final class ReadOnlyRunProfile {
  /// The conversation mode a read-only run is started in: its prompt, its
  /// sandbox (read-only worktree mounts) and Claude Code's permission mode
  /// come from it. Its tool surface does not: [admits] narrows it.
  static const Mode mode = Mode.review;

  /// Effect classes a read-only run is refused: every class but network
  /// reads and secret reads, the same set every read-only mode refuses.
  static Set<ActionClass> get deniedClasses => profileFor(mode).deniedClasses;

  /// The only way a read-only run answers.
  static const Set<String> outputVerbs = {'submit_output'};

  /// Tools that change nothing and carry no denied class.
  static const Set<String> readTools = {
    // Files and code.
    'read', 'search', 'search_files', 'find', 'read_output',
    'search_code', 'code_symbol', 'code_callers', 'code_callees',
    'code_impact', 'list_repos', 'stack_status', 'render_media',
    // The conversation, its checklist and its goal.
    'get_messages', 'get_space_notes', 'todo_read', 'goal_status',
    'agent_activity', 'list_agent_presence', 'list_agents', 'list_spaces',
    'get_org_chart', 'list_wakes', 'list_goals', 'list_approvals',
    // Tickets and work products.
    'list_tickets', 'get_ticket', 'list_ticket_relations',
    'list_work_products', 'get_work_product',
    // Memory, artifacts and skills.
    'search_memory', 'get_my_notes', 'list_memory_domains',
    'list_memory_conflicts', 'list_policies', 'list_artifacts',
    'get_artifact', 'list_skills', 'list_skill_updates', 'verify_skills',
    // Environments, machines, runtimes and the server.
    'environment_status', 'environment_logs', 'rig_list',
    'list_runtime_health', 'list_runtime_profiles', 'list_workspaces',
    'preview_trigger',
    // Feeds, read only.
    'list_feeds', 'list_articles', 'get_article',
    // The run's own mechanics: the tool catalogue, its context, and `repl`,
    // whose every nested call is admitted here under its own name.
    'search_tools', 'list_my_tools', 'search_tool_bm25', 'compact',
    'bash_output', 'repl',
  };

  /// Tools without a denied class that still change something (a row of
  /// this server, a person's attention, another run): refused.
  static const Set<String> stateTools = {
    // Subagents and workers.
    'task', 'vibe_spawn', 'vibe_send', 'vibe_wait', 'vibe_kill', 'vibe_list',
    // The worktree's checkpoints.
    'checkpoint', 'rewind',
    // Network fetches: not needed to judge, and a way out for injected text.
    'web_fetch', 'web_search',
    // Asking a person, approvals.
    'ask_user', 'create_approval', 'decide_approval', 'comment_approval',
    // The checklist, notes, memory and artifacts.
    'todo_write', 'update_my_notes', 'update_space_notes', 'remember',
    'propose_fact', 'propose_policy', 'supersede_fact', 'supersede_policy',
    'record_observation', 'consolidate_memory', 'harmonize_memory',
    'publish_artifact', 'revise_artifact',
    // Messages, peers and team state.
    'send_message', 'request_peer_review', 'record_team_activity',
    'agent_heartbeat', 'set_cohort_summary',
    // Reviews, plans and verdicts other than the run's own output.
    'add_review_node', 'add_review_diagram', 'confirm_review_node',
    'dismiss_review_node', 'resolve_review_node', 'finalize_review',
    'submit_plan', 'submit_reviewer_verdict', 'exit_plan_mode',
    // Tickets, work products, playbooks, runtimes and feeds.
    'add_ticket_collaborator', 'ticket_pr_link', 'create_work_product',
    'save_work_product_revision', 'create_playbook',
    'create_runtime_profile', 'set_article_read', 'set_article_saved',
    'refresh_feeds',
    // Branches of the stack.
    'stack_checkout', 'stack_cut',
    // Wakes and goals.
    'wake_me', 'cancel_wake', 'complete_goal', 'create_goal',
    'update_goal_progress',
  };

  /// The script's own functions (code mode's `ScriptGlobals`) that only read
  /// or compute: a read-only run's scripts keep them. `load` and
  /// `storedKeys` read what earlier runs stored, `history`, `outputs` and
  /// `loadOutput` read the run's past.
  static const Set<String> scriptGlobalReads = {
    'text', 'image', 'load', 'storedKeys', 'sleep', 'setTimeout',
    'clearTimeout', 'limits', 'exit', 'models.embed', 'models.rank',
    'models.classify', 'history', 'outputs', 'loadOutput',
  };

  /// The script's own functions that keep something past the script: a
  /// read-only run's scripts are refused them (`store()` throws, `keep()`
  /// rejects, and the result says why), so nothing the run computed reaches
  /// a later run through them.
  static const Set<String> scriptGlobalWrites = {'store', 'keep'};

  /// Whether a read-only run may call the tool [name] whose curated action
  /// classes are [classes].
  static bool admits(String name, Set<ActionClass> classes) {
    if (outputVerbs.contains(name)) {
      return true;
    }
    final denied = deniedClasses;
    if (classes.any(denied.contains)) {
      return false;
    }
    return readTools.contains(name);
  }

  /// Claude Code's own tools that only read. Its MCP tools (`mcp__…`) are
  /// admitted by the MCP dispatcher, which asks [admits].
  static const Set<String> claudeCodeReadTools = {
    'Read',
    'Glob',
    'Grep',
    'LS',
    'NotebookRead',
  };

  /// Whether a read-only Claude Code run may call its tool [name].
  static bool admitsClaudeTool(String name) =>
      name.startsWith('mcp__') || claudeCodeReadTools.contains(name);

  /// Whether [name] with [classes] has been decided for a read-only run:
  /// admitted, refused by a class, or listed as a state change.
  static bool decides(String name, Set<ActionClass> classes) =>
      outputVerbs.contains(name) ||
      readTools.contains(name) ||
      stateTools.contains(name) ||
      classes.any(deniedClasses.contains);

  /// The tool surface of a read-only run over [tools]: only what [admits]
  /// passes, with the output verbs pinned.
  static ToolSurfaceSpec toolSurfaceOver(Iterable<HarnessTool> tools) =>
      ToolSurfaceSpec(
        denyNames: {
          for (final tool in tools)
            if (!admits(tool.name, tool.actionClasses)) tool.name,
        },
        pinnedNames: outputVerbs,
        deniedActionClasses: deniedClasses,
      );

  /// Whether a run on [transport] is held to reading. The built-in harness
  /// is (its tool surface, [toolSurfaceOver]), and so is Claude Code (its
  /// tool hook's allow-list, [admitsClaudeTool], and the MCP gate). ACP is
  /// not: it negotiates no permissions, so the agent's own tools (a shell,
  /// edits, fetches) would run unchecked; a read-only run is refused there
  /// before its run row (`ReadOnlyRunUnavailableException.backend`).
  static bool enforcedOn(AdapterTransport transport) => switch (transport) {
    AdapterTransport.harness || AdapterTransport.claudeCli => true,
    AdapterTransport.acp => false,
  };

  /// What a refused call of [name] reads (model-facing).
  static String refusal(String name) =>
      '$name is not available in a read-only run: this run reads and answers '
      'with submit_output, and changes nothing.';
}
