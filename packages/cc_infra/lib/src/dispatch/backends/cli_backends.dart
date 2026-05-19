import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';

/// Backend for the structured NDJSON CLI mode (`--mode json`). Driven
/// by the dispatch session's sandbox-exec path; this class only builds the
/// argv + declares its (empty) default env.
class StructuredCliBackend implements AgentBackend {
  /// Creates a [StructuredCliBackend].
  const StructuredCliBackend({
    required this.cliName,
    this.jsonModeConstraint = _defaultJsonConstraint,
  });

  @override
  final String cliName;

  @override
  AdapterTransport get transport => AdapterTransport.structuredCli;

  @override
  String? get acpArgs => null;

  /// The system-prompt constraint that makes Pi emit one JSON object per line.
  final String jsonModeConstraint;

  static const String _defaultJsonConstraint =
      'Output structured JSON events. Each line must be a valid JSON object.';

  @override
  List<String> buildArgs({String? modelId, String? effortLevel}) {
    final args = <String>['--mode', 'json'];
    if (modelId != null && modelId.isNotEmpty) {
      args.addAll(['--model', modelId]);
    }
    // Pi exposes reasoning via `--thinking <level>`.
    if (effortLevel != null && effortLevel.isNotEmpty) {
      args.addAll(['--thinking', effortLevel]);
    }
    args.addAll(['--append-system-prompt', jsonModeConstraint]);
    return args;
  }

  @override
  Map<String, String> defaultEnv() => const {};
}

/// Backend for Claude Code driven directly as a structured CLI: `claude -p`
/// is spawned inside the OS sandbox (like Pi) and emits `stream-json` NDJSON
/// that the dispatch session parses. This class declares the transport + the
/// argv flags the session passes after the binary; the full flag set
/// (including `--permission-mode` / `--mcp-config`) is assembled by
/// [buildClaudeArgs], which has access to the conversation mode + MCP config
/// that the [AgentBackend.buildArgs] contract does not.
class ClaudeCliBackend implements AgentBackend {
  /// Creates a [ClaudeCliBackend].
  const ClaudeCliBackend({this.cliName = 'claude'});

  @override
  final String cliName;

  @override
  AdapterTransport get transport => AdapterTransport.claudeCli;

  @override
  String? get acpArgs => null;

  /// Builds the `claude -p` flag list (everything after the binary path,
  /// excluding the positional `-p` itself and the prompt). [modelId] selects
  /// the model; [permissionMode] maps to `--permission-mode`; [mcpConfigPath]
  /// points Claude at the Control Center MCP server; [skipPermissions] adds
  /// `--dangerously-skip-permissions` for non-interactive automation.
  static List<String> buildClaudeArgs({
    String? modelId,
    String? permissionMode,
    String? mcpConfigPath,
    bool skipPermissions = true,
  }) {
    final args = <String>[
      '-p',
      '--output-format',
      'stream-json',
      '--verbose',
      '--include-partial-messages',
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
