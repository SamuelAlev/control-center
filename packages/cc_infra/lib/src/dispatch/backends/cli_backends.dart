import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/agent_commit_attribution.dart';
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

  /// Native checklists are private to Claude Code, not the conversation's
  /// persisted Control Center list. Do not disable Agent, Task, TaskOutput or
  /// TaskStop: those run and manage subagents, not checklist items.
  static const nativeChecklistTools =
      'TodoWrite,TaskCreate,TaskUpdate,TaskGet,TaskList';

  // Keep this shell-policy-safe for the same reason as the Bash instruction.
  static const _controlCenterSystemPrompt =
      '$bashDescriptionInstruction '
      'For still images including SVG, HEIC and WebP, video or GIF/APNG frames, '
      'and PDF or PDF-compatible AI pages, use tool search to load '
      'mcp__control-center__render_media. It returns images using bundled '
      'renderers. Do not ask the user to install FFmpeg or invoke system '
      'media tools. '
      'For multi-step work or a user-provided task list, you MUST use the '
      'Control Center checklist. Use your tool search to load '
      'mcp__control-center__todo_read and mcp__control-center__todo_write '
      'before starting substantive work. Claude Code native task tools are '
      'disabled because their lists are not shown in Control Center. '
      'Call todo_read before creating or resuming a checklist and after '
      'context compaction so you preserve existing items. Call todo_write '
      'with the FULL list, marking exactly one item in_progress before you '
      'start it and completed immediately when it is done. Update the list '
      'as you work, not only at the end. Keep existing item ids and content '
      'stable and retain unfinished items. Reconcile statuses before your '
      'final reply. A plan written in chat is not a substitute for the '
      'checklist. Skip checklists for single-step replies. '
      'When the task calls for publishing changes, invoke git push and '
      'gh pr create as needed. Control Center requests approval when the '
      'guarded action runs. Printing commands in chat does not request '
      'approval. Do not hand the commands back to the user merely because '
      'approval may be required. Respect a denial and report the blocker. '
      'A network denial is also a boundary. Do not clear proxy variables, '
      'change proxy settings or disable sandboxing to evade it. Report the '
      'blocked destination instead.';

  /// The same appended prompt is used by launch and native-resume scoping.
  /// Without the MCP connection, leave Claude's own checklist available.
  static String appendedSystemPrompt({required bool hasControlCenterMcp}) =>
      hasControlCenterMcp
      ? '$_controlCenterSystemPrompt $agentCommitAttributionInstruction'
      : '$bashDescriptionInstruction $agentCommitAttributionInstruction';

  /// Builds the `claude -p` flag list (everything after the binary path,
  /// excluding the positional `-p` itself and the prompt). [modelId] selects
  /// the model; [permissionMode] maps to `--permission-mode`; [mcpConfigPath]
  /// points Claude at the Control Center MCP server; [settingsJson] is passed
  /// as `--settings` (the action-policy hooks); [skipPermissions] adds
  /// `--dangerously-skip-permissions` for non-interactive automation.
  /// [appendedSystemPrompt] rides as `--append-system-prompt`. With an MCP
  /// config, native checklist tools are disabled in favor of Control Center.
  /// [effortLevel] is the agent's configured reasoning effort, forwarded only
  /// when [capabilities] says the binary accepts `--effort` and the level maps
  /// to one of its supported values. [resumeSessionId] resumes that exact
  /// native session — never `--continue`, which would silently pick "the latest
  /// session in this directory".
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
    String? effortLevel,
    String? resumeSessionId,
    ClaudeCliCapabilities capabilities = ClaudeCliCapabilities.baseline,
  }) {
    final hasControlCenterMcp =
        mcpConfigPath != null && mcpConfigPath.isNotEmpty;
    final args = <String>[
      '-p',
      '--input-format',
      'stream-json',
      '--output-format',
      'stream-json',
      '--verbose',
      '--include-partial-messages',
      '--append-system-prompt',
      appendedSystemPrompt(hasControlCenterMcp: hasControlCenterMcp),
      if (capabilities.supportsSubagentSystemPrompt) ...[
        '--append-subagent-system-prompt',
        agentCommitAttributionInstruction,
      ],
    ];
    if (modelId != null && modelId.isNotEmpty) {
      args.addAll(['--model', modelId]);
    }
    final effort = claudeEffortValue(effortLevel, capabilities);
    if (effort != null) {
      args.addAll(['--effort', effort]);
    }
    if (permissionMode != null && permissionMode.isNotEmpty) {
      args.addAll(['--permission-mode', permissionMode]);
    }
    if (hasControlCenterMcp) {
      // Load the Control Center MCP server explicitly. A project-scoped
      // `.mcp.json` is NOT auto-loaded: Claude Code gates project MCP servers
      // behind a separate approval prompt that non-interactive `claude -p`
      // never answers. Without this the agent sees zero `mcp__*` tools and
      // cannot call `complete_ticket`. `--strict-mcp-config` makes Claude use
      // ONLY this config, avoiding a duplicate of the same server picked up
      // from project discovery.
      args.addAll([
        '--mcp-config',
        mcpConfigPath,
        '--strict-mcp-config',
        '--disallowedTools',
        nativeChecklistTools,
      ]);
    }
    // Command-line settings also cover non-pooled accounts and beat project
    // settings. Preserve policy hooks, but never emit Claude's own bylines.
    final settings = <String, dynamic>{
      if (settingsJson != null && settingsJson.isNotEmpty)
        ...jsonDecode(settingsJson) as Map<String, dynamic>,
      'attribution': const {'commit': '', 'pr': ''},
    };
    args.addAll(['--settings', jsonEncode(settings)]);
    if (resumeSessionId != null &&
        resumeSessionId.isNotEmpty &&
        capabilities.supportsResume) {
      // An EXPLICIT session id, never `--continue` ("the most recent
      // conversation in the current directory"), which is unsafe the moment
      // two conversations share a directory. The caller has already checked
      // that this id belongs to the run's scope.
      args.addAll(['--resume', resumeSessionId]);
    }
    if (skipPermissions) {
      args.add('--dangerously-skip-permissions');
    }
    return args;
  }

  /// Maps the platform's reasoning-effort id ([effortLevel]) onto a value
  /// `claude --effort` accepts, or null when nothing should be passed.
  ///
  /// Null is the honest answer for two cases that must not fail a launch:
  /// an unrecognized id, and a level the resolved binary does not advertise.
  /// `minimal` maps UP to `low` because `low` is the CLI's floor — passing
  /// nothing would let the model's own (higher) default win, which is the
  /// opposite of what an explicit `minimal` asked for.
  ///
  /// Never a default: a run with no configured effort passes no `--effort`, so
  /// nobody is silently dropped to low effort.
  static String? claudeEffortValue(
    String? effortLevel, [
    ClaudeCliCapabilities capabilities = ClaudeCliCapabilities.baseline,
  ]) {
    if (effortLevel == null) {
      return null;
    }
    if (!capabilities.supportsEffort) {
      return null;
    }
    final mapped = switch (effortLevel.trim().toLowerCase()) {
      'minimal' || 'none' || 'off' => 'low',
      'low' => 'low',
      'medium' || 'mid' => 'medium',
      'high' => 'high',
      'xhigh' || 'extra-high' => 'xhigh',
      'max' => 'max',
      _ => null,
    };
    if (mapped == null || !capabilities.supportsEffortValue(mapped)) {
      return null;
    }
    return mapped;
  }

  @override
  List<String> buildArgs({String? modelId, String? effortLevel}) {
    // Reasoning effort for Claude is conveyed through the model id / the
    // stream itself; the session assembles the real argv via
    // [buildClaudeArgs]. Kept to satisfy the backend contract, and mapped
    // through the same value rules so the two never disagree.
    final args = <String>[];
    if (modelId != null && modelId.isNotEmpty) {
      args.addAll(['--model', modelId]);
    }
    final effort = claudeEffortValue(effortLevel);
    if (effort != null) {
      args.addAll(['--effort', effort]);
    }
    return args;
  }

  @override
  Map<String, String> defaultEnv() => const {};

  /// Which optional `claude` flags the resolved binary actually accepts, and
  /// whether it restores a session's saved cost totals.
  ///
  /// Flags come from the binary's OWN `--help`; the accounting capability comes
  /// from a separate `--version`, because `--help` need not carry a version at
  /// all and guessing "modern" from its absence is exactly the optimism that
  /// swallows spend. Both are cached per binary IDENTITY (path + size + mtime),
  /// so upgrading the CLI in place re-probes instead of retaining stale flags.
  static final Map<String, ({String identity, ClaudeCliCapabilities caps})>
  _probeCache = {};

  /// Seeds the cache for [binaryPath] (tests, or a host that already knows).
  static void cacheFor(String binaryPath, ClaudeCliCapabilities capabilities) {
    _probeCache[binaryPath] = (
      identity: _identityOf(binaryPath),
      caps: capabilities,
    );
  }

  /// Forgets every cached probe (a host that upgraded the CLI mid-process).
  static void clearCapabilityCache() => _probeCache.clear();

  /// A cheap binary identity: size + mtime, or empty when unreadable. An
  /// upgrade at the same path changes it, which invalidates the cache.
  static String _identityOf(String binaryPath) {
    try {
      final stat = FileStat.statSync(binaryPath);
      return '${stat.size}:${stat.modified.millisecondsSinceEpoch}';
    } on Object {
      return '';
    }
  }

  /// Resolves the binary's capabilities, memoized per identity.
  ///
  /// Flag capabilities fall back to the documented baseline when `--help` is
  /// missing/unrecognizable/failed (so `--effort`/`--resume` keep working on a
  /// CLI the adapter is pinned to). The ACCOUNTING capability does NOT: it
  /// requires a successfully parsed `--version`, because the alternative is
  /// crediting an unknown build with durability it may not have.
  static Future<ClaudeCliCapabilities> detectCapabilities(
    String binaryPath,
  ) async {
    if (binaryPath.isEmpty) {
      return ClaudeCliCapabilities.conservative;
    }
    final identity = _identityOf(binaryPath);
    final cached = _probeCache[binaryPath];
    if (cached != null && cached.identity == identity) {
      return cached.caps;
    }
    if (identity.isEmpty) {
      // An unreadable/absent binary: probing would only throw, and the CLI's
      // own capabilities are UNKNOWN. Conservative, never optimistic.
      const result = ClaudeCliCapabilities.conservative;
      _probeCache[binaryPath] = (identity: identity, caps: result);
      return result;
    }

    String? helpText;
    String? versionText;
    try {
      final probe = await Process.run(binaryPath, const ['--help']);
      helpText = '${probe.stdout}${probe.stderr}';
    } on Object {
      helpText = null;
    }
    try {
      final probe = await Process.run(binaryPath, const ['--version']);
      versionText = '${probe.stdout}${probe.stderr}';
    } on Object {
      versionText = null;
    }

    // A help text that could not be read or is not recognizably Claude Code's
    // means the flags are UNKNOWN — not "assume the pinned set".
    final flags = helpText == null
        ? ClaudeCliCapabilities.conservative
        : (ClaudeCliCapabilities.fromHelp(helpText) ??
              ClaudeCliCapabilities.conservative);
    final version = ClaudeCliCapabilities.versionOf(versionText);
    final result = ClaudeCliCapabilities(
      supportsEffort: flags.supportsEffort,
      supportsResume: flags.supportsResume,
      supportsSessionId: flags.supportsSessionId,
      effortValues: flags.effortValues,
      supportsSubagentSystemPrompt:
          flags.supportsSubagentSystemPrompt ||
          ClaudeCliCapabilities._versionAtLeast(version, 205),
      restoresSessionTotals:
          ClaudeCliCapabilities.restoresSessionTotalsForVersion(version),
      version: version,
    );
    _probeCache[binaryPath] = (identity: identity, caps: result);
    return result;
  }
}

/// The optional `claude` flags a given binary accepts, derived from its own
/// `--help`.
///
/// [baseline] is the documented capability set of the CLI line this adapter is
/// pinned to (2.1.293): `--effort`, `--resume` and `--session-id` are all
/// present. A probe that runs and is recognizably Claude Code help wins over
/// it; a probe that cannot run falls back to it.
class ClaudeCliCapabilities {
  /// Creates a [ClaudeCliCapabilities].
  const ClaudeCliCapabilities({
    required this.supportsEffort,
    required this.supportsResume,
    required this.supportsSessionId,
    this.supportsSubagentSystemPrompt = false,
    this.effortValues = const {'low', 'medium', 'high', 'xhigh', 'max'},
    this.restoresSessionTotals = false,
    this.version,
  });

  /// Documented flag set for the pinned CLI line (2.1.293).
  ///
  /// Flags ONLY: [restoresSessionTotals] stays false here, because claiming
  /// durability requires the binary's own version, and this value is what a
  /// failed or unrecognizable probe falls back to.
  static const baseline = ClaudeCliCapabilities(
    supportsEffort: true,
    supportsResume: true,
    supportsSessionId: true,
    supportsSubagentSystemPrompt: true,
  );

  /// A binary whose help was READABLE but advertises none of these flags.
  static const minimal = ClaudeCliCapabilities(
    supportsEffort: false,
    supportsResume: false,
    supportsSessionId: false,
    effortValues: {},
  );

  /// Nothing could be probed — no readable binary, no help, or help that is
  /// not recognizably Claude Code's.
  ///
  /// EVERY flag is false: an unknown build must not be handed `--effort`,
  /// `--resume` or `--session-id` on the hope that it accepts them, because the
  /// CLI rejects an unknown option by exiting before it emits anything — which
  /// kills the turn. [baseline] is the documented PINNED set and stays the
  /// builder's default for hosts that know what they are running.
  static const conservative = ClaudeCliCapabilities(
    supportsEffort: false,
    supportsResume: false,
    supportsSessionId: false,
    effortValues: {},
  );

  /// Whether `--effort <level>` is accepted.
  final bool supportsEffort;

  /// Whether `--resume <session-id>` is accepted.
  final bool supportsResume;

  /// Whether `--session-id <uuid>` is accepted.
  final bool supportsSessionId;

  /// Whether non-fork native subagents accept an appended system prompt.
  /// The headless flag is absent from interactive help, so the version probe
  /// also enables it starting with Claude Code 2.1.205.
  final bool supportsSubagentSystemPrompt;

  /// The effort levels advertised by `--effort`, when it is present.
  final Set<String> effortValues;

  /// Whether this CLI makes a session's cost totals durable across a normal
  /// exit AND restores them into a resumed call.
  ///
  /// Claude Code changed this in 2.1.277: before it, a resumed `claude -p`
  /// started its totals at zero, so the previous spend could not be part of the
  /// running total. Whether the persisted baseline may be seeded back into the
  /// ledger depends on this — deltaing new figures against a baseline the CLI
  /// never restored silently swallows spend.
  final bool restoresSessionTotals;

  /// The version string the binary reported (`2.1.293`), or null when it could
  /// not be determined — in which case [restoresSessionTotals] is false and the
  /// session reports that it could not establish the accounting capability.
  final String? version;

  /// Whether [value] is one of the advertised effort levels.
  bool supportsEffortValue(String value) => effortValues.contains(value);

  static final RegExp _versionPattern = RegExp(r'(\d+)\.(\d+)\.(\d+)');

  /// Extracts a `x.y.z` version from `--version` output (which reads
  /// `2.1.293 (Claude Code)`), or null when there is none.
  static String? versionOf(String? versionOutput) {
    if (versionOutput == null) {
      return null;
    }
    final match = _versionPattern.firstMatch(versionOutput);
    return match?.group(0);
  }

  /// Whether a CLI of [version] makes a session's cost totals durable across a
  /// normal exit AND restores them into a resumed call.
  ///
  /// Claude Code changed this in 2.1.277. An unknown or unparseable version is
  /// NOT credited with it: silently treating new figures as deltas against a
  /// baseline the CLI never restored is how spend disappears.
  static bool restoresSessionTotalsForVersion(String? version) =>
      _versionAtLeast(version, 277);

  static bool _versionAtLeast(String? version, int minimumPatch) {
    if (version == null) {
      return false;
    }
    final match = _versionPattern.firstMatch(version);
    if (match == null) {
      return false;
    }
    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    final patch = int.parse(match.group(3)!);
    if (major != 2) {
      return major > 2;
    }
    if (minor != 1) {
      return minor > 1;
    }
    return patch >= minimumPatch;
  }

  /// Parses a `--help` dump. Returns null when the text is not recognizably
  /// Claude Code's help (so the caller falls back to [baseline] rather than
  /// concluding "no flags" from unrelated output).
  static ClaudeCliCapabilities? fromHelp(String helpText) {
    // A recognizable Claude Code help lists at least one of the long flags the
    // adapter already depends on. Without that, the output may be a wrapper
    // script, a shell builtin, or a probe that failed — all of which must NOT
    // be read as "this CLI supports nothing".
    final looksLikeClaudeHelp =
        helpText.contains('--output-format') ||
        helpText.contains('--permission-mode') ||
        helpText.contains('Claude Code');
    if (!looksLikeClaudeHelp) {
      return null;
    }
    final effort = helpText.contains('--effort');
    return ClaudeCliCapabilities(
      supportsEffort: effort,
      supportsResume: helpText.contains('--resume') || helpText.contains('-r,'),
      supportsSessionId: helpText.contains('--session-id'),
      supportsSubagentSystemPrompt: helpText.contains(
        '--append-subagent-system-prompt',
      ),
      effortValues: effort ? _parseEffortValues(helpText) : const {},
      // Never from `--help`: it need not carry a version, and guessing
      // "modern" from its absence is what swallowed spend. The accounting
      // capability comes from a separate `--version` probe.
    );
  }

  /// Reads the `(low, medium, high, xhigh, max)` list off the `--effort`
  /// option's help PARAGRAPH.
  ///
  /// The choices wrap onto the following indented line in the real help, so the
  /// search runs to the next option line rather than to the end of the first
  /// line — otherwise the advertised list is never found and every baseline
  /// value is substituted, which is exactly how an unsupported `xhigh`/`max`
  /// reaches a narrow CLI. Falls back to the documented set when the option
  /// carries no parenthesized list at all.
  static Set<String> _parseEffortValues(String helpText) {
    final at = helpText.indexOf('--effort');
    if (at < 0) {
      return const {'low', 'medium', 'high', 'xhigh', 'max'};
    }
    final rest = helpText.substring(at);
    // Stop at the next option line: a line whose first non-space character is
    // a dash that starts a new `--flag`.
    final next = RegExp(r'\n\s*--[a-zA-Z]').firstMatch(rest);
    final paragraph = next == null ? rest : rest.substring(0, next.start);
    final match = _choices.firstMatch(paragraph);
    if (match == null) {
      return const {'low', 'medium', 'high', 'xhigh', 'max'};
    }
    final parsed = {
      for (final part in match.group(1)!.split(','))
        if (part.trim().isNotEmpty) part.trim().toLowerCase(),
    };
    return parsed.isEmpty
        ? const {'low', 'medium', 'high', 'xhigh', 'max'}
        : parsed;
  }

  static final RegExp _choices = RegExp(r'\(([^)]*)\)');
}
