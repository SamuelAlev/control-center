import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';

/// Backend for Claude Code driven directly as a structured CLI: `claude -p`
/// is spawned inside the OS sandbox and emits `stream-json` NDJSON that the
/// dispatch session parses. This class declares the transport + the argv flags
/// the session passes after the binary; the full flag set (including
/// `--permission-mode` / `--mcp-config`) is assembled by [buildClaudeArgs],
/// which has access to the conversation mode + MCP config that the
/// [AgentBackend.buildArgs] contract does not.
class ClaudeCliBackend implements AgentBackend {
  /// Creates a [ClaudeCliBackend].
  const ClaudeCliBackend({this.cliName = 'claude'});

  @override
  final String cliName;

  @override
  AdapterTransport get transport => AdapterTransport.claudeCli;

  @override
  String? get acpArgs => null;

  /// Appended to Claude Code's system prompt on every run.
  ///
  /// `Bash.description` is optional in Claude Code's schema, and a session
  /// that skips it on its first call skips it on every call after — leaving
  /// the transcript a column of raw commands. The harness makes the same
  /// argument required (`withRequiredCallDescription`); this is the Claude
  /// Code side, with the PreToolUse hook as the backstop.
  ///
  /// Plain prose on purpose: the argv is joined and run through the command
  /// policy as a shell line, so no `;`, `|`, `&`, backticks or parentheses.
  static const bashDescriptionInstruction =
      'Always set the description argument on every Bash call to a clear, '
      'concise 5-10 word summary of what the command does. The user reads '
      'that description in place of the raw command.';

  /// Builds the `claude -p` flag list (everything after the binary path,
  /// excluding the positional `-p` itself and the prompt). [modelId] selects
  /// the model; [permissionMode] maps to `--permission-mode`; [mcpConfigPath]
  /// points Claude at the Control Center MCP server; [settingsJson] is passed
  /// as `--settings` (the action-policy hooks); [skipPermissions] adds
  /// `--dangerously-skip-permissions` for non-interactive automation.
  /// [bashDescriptionInstruction] always rides as `--append-system-prompt`.
  ///
  /// Input is always `--input-format stream-json`: the prompt is the first
  /// NDJSON user message on stdin, and stdin stays open for the run so queued
  /// steering reaches the turn in flight (Claude Code injects a mid-turn user
  /// message at its next tool boundary). The session closes stdin at the
  /// turn's `result`, which is what lets the process exit.
  static List<String> buildClaudeArgs({
    String? modelId,
    String? permissionMode,
    String? mcpConfigPath,
    String? settingsJson,
    bool skipPermissions = true,
  }) {
    final args = <String>[
      '-p',
      '--input-format',
      'stream-json',
      '--output-format',
      'stream-json',
      '--verbose',
      '--include-partial-messages',
      '--append-system-prompt',
      bashDescriptionInstruction,
    ];
    if (modelId != null && modelId.isNotEmpty) {
      args.addAll(['--model', modelId]);
    }
    if (permissionMode != null && permissionMode.isNotEmpty) {
      args.addAll(['--permission-mode', permissionMode]);
    }
    if (mcpConfigPath != null && mcpConfigPath.isNotEmpty) {
      // Load the Control Center MCP server explicitly. A project-scoped
      // `.mcp.json` is NOT auto-loaded: Claude Code gates project MCP servers
      // behind a separate approval prompt that non-interactive `claude -p`
      // never answers. Without this the agent sees zero `mcp__*` tools and
      // cannot call `complete_ticket`. `--strict-mcp-config` makes Claude use
      // ONLY this config, avoiding a duplicate of the same server picked up
      // from project discovery.
      args.addAll(['--mcp-config', mcpConfigPath, '--strict-mcp-config']);
    }
    if (settingsJson != null && settingsJson.isNotEmpty) {
      args.addAll(['--settings', settingsJson]);
    }
    if (skipPermissions) {
      args.add('--dangerously-skip-permissions');
    }
    return args;
  }

  @override
  List<String> buildArgs({String? modelId, String? effortLevel}) {
    // Reasoning effort for Claude is conveyed through the model id / the
    // stream itself; the session assembles the real argv via
    // [buildClaudeArgs]. Kept to satisfy the backend contract.
    final args = <String>[];
    if (modelId != null && modelId.isNotEmpty) {
      args.addAll(['--model', modelId]);
    }
    if (effortLevel != null && effortLevel.isNotEmpty) {
      args.addAll(['--effort', effortLevel]);
    }
    return args;
  }

  @override
  Map<String, String> defaultEnv() => const {};
}
