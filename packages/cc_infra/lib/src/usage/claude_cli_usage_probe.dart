import 'dart:async';
import 'dart:io';

import 'package:cc_infra/src/detection/claude_code_model_probe.dart';
import 'package:cc_infra/src/detection/claude_control_session.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';
import 'package:cc_infra/src/sandboxing/macos_sandbox.dart';

/// What `claude` reported about one account's plan.
class ClaudeCliUsage {
  /// Creates a [ClaudeCliUsage].
  const ClaudeCliUsage({
    required this.available,
    required this.signedOut,
    this.rateLimits = const {},
  });

  /// Reads the answers to `initialize` and `get_usage`.
  factory ClaudeCliUsage.fromControl({
    required Map<String, dynamic> init,
    required Map<String, dynamic> usage,
  }) {
    final account = init['account'];
    final limits = usage['rate_limits'];
    return ClaudeCliUsage(
      available: usage['rate_limits_available'] == true && limits is Map,
      signedOut: account is Map && account['tokenSource'] == 'none',
      rateLimits: limits is Map ? Map<String, dynamic>.from(limits) : const {},
    );
  }

  /// Whether this login has plan limits to report at all. False for an API
  /// key or a third-party provider, and for an account that is signed out.
  final bool available;

  /// Whether the CLI found no credential for this account.
  final bool signedOut;

  /// The plan's usage body: `five_hour`, `seven_day`, `spend` and the rest.
  final Map<String, dynamic> rateLimits;
}

/// Reads one account's plan usage. Returns null when Claude Code is not
/// installed; [configDir] is the account's `CLAUDE_CONFIG_DIR`, or null for
/// the operator's own login.
typedef ClaudeUsageReader =
    Future<ClaudeCliUsage?> Function({String? configDir});

/// Asks the Claude Code CLI for an account's plan usage, without spending a
/// token.
///
/// Control Center never handles a Claude credential for this. `get_usage` on
/// the stream-json control protocol is the CLI's own read of its own login, so
/// the token stays inside the binary that owns it and the CLI renews it when
/// it needs to. Anthropic's terms do not let a third-party product collect or
/// use those tokens; see `SECURITY.md`.
///
/// Isolated the same way as [ClaudeCodeModelProbe]: an empty temporary working
/// directory, no MCP servers, hooks off, no session persisted, and no message
/// sent, so nothing reaches a model.
///
/// Managed accounts on macOS run with the sandbox's keychain stand-in first on
/// `PATH`. A sandboxed run keeps its rotating login in `.credentials.json`, so
/// the Keychain's copy can be older than the file. Refresh tokens rotate and a
/// spent one can revoke the login, so a host process must read and renew from
/// the same file a run does, never the older copy.
class ClaudeCliUsageProbe {
  /// Creates a [ClaudeCliUsageProbe].
  ClaudeCliUsageProbe({
    ClaudeProbeProcessStarter? start,
    Future<String?> Function(String binary)? resolveBinary,
    Map<String, String>? environment,
    String? Function()? keychainStandInDir,
    this.timeout = const Duration(seconds: 30),
    this.requestTimeout = const Duration(seconds: 20),
  }) : _start = start ?? _defaultStart,
       _resolveBinary = resolveBinary ?? resolveBinaryPath,
       _env = environment ?? Platform.environment,
       _standInDir = keychainStandInDir ?? _defaultStandInDir;

  final ClaudeProbeProcessStarter _start;
  final Future<String?> Function(String binary) _resolveBinary;
  final Map<String, String> _env;
  final String? Function() _standInDir;

  /// The bound on one whole read.
  final Duration timeout;

  /// The bound on one control request.
  final Duration requestTimeout;

  /// Credential variables that would make the CLI report a metered login
  /// instead of the plan this reading is about.
  static const List<String> _meteredCredentials = [
    'ANTHROPIC_API_KEY',
    'ANTHROPIC_AUTH_TOKEN',
  ];

  static Future<Process> _defaultStart(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    required Map<String, String> environment,
  }) => Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: false,
    runInShell: false,
  );

  static String? _defaultStandInDir() {
    if (!Platform.isMacOS) {
      return null;
    }
    return MacosSandbox.installKeychainStandIn(
      Directory('${Directory.systemTemp.path}/cc-claude-usage'),
    );
  }

  /// The environment one read runs with. Visible for tests.
  Map<String, String> environmentFor(String? configDir) {
    final env = {..._env};
    _meteredCredentials.forEach(env.remove);
    if (configDir == null || configDir.isEmpty) {
      return env;
    }
    env['CLAUDE_CONFIG_DIR'] = configDir;
    final standIn = _standInDir();
    if (standIn != null) {
      final path = env['PATH'];
      env['PATH'] = path == null || path.isEmpty ? standIn : '$standIn:$path';
    }
    return env;
  }

  /// Reads the plan usage of the account in [configDir]. Returns null when
  /// `claude` is not installed. Throws when the CLI cannot be driven.
  Future<ClaudeCliUsage?> read({String? configDir}) async {
    final binary = await _resolveBinary('claude');
    if (binary == null) {
      return null;
    }
    final cwd = await Directory.systemTemp.createTemp('cc-claude-usage-');
    Process? process;
    try {
      process = await _start(
        binary,
        ClaudeCodeModelProbe.args,
        workingDirectory: cwd.path,
        environment: environmentFor(configDir),
      );
      final session = ClaudeControlSession(process, requestTimeout);
      return await _read(session).timeout(timeout);
    } finally {
      process?.kill();
      try {
        await cwd.delete(recursive: true);
      } on Object {
        // A leftover empty temp dir is harmless.
      }
    }
  }

  Future<ClaudeCliUsage> _read(ClaudeControlSession session) async {
    final init = await session.request({'subtype': 'initialize'});
    // Without `skip_behaviors` the CLI scans every transcript from the last
    // seven days for a section this reading never uses.
    final usage = await session.request({
      'subtype': 'get_usage',
      'skip_behaviors': true,
    });
    return ClaudeCliUsage.fromControl(init: init, usage: usage);
  }
}
