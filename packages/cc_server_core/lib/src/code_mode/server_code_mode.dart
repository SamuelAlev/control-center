import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show NotFoundException;
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        BundledCodeRunner,
        CcInfraLog,
        ChildProcess,
        CodeRunnerNotFoundException,
        CodeSandboxProcess,
        runnerWorkingDirectory;
// ignore: implementation_imports
import 'package:cc_infra/src/code_mode/code_runner_live_availability.dart'
    show oneLogLine;
// ignore: implementation_imports
import 'package:cc_infra/src/code_mode/host_path_scrub.dart';
import 'package:cc_server_core/src/server_boot_refusal.dart' show printableText;
import 'package:cc_server_core/src/workspaces/live_workspaces.dart';
import 'package:path/path.dart' as p;

/// The code mode runner (`cc_codemode`) this server found in its bundle, and
/// what its boot self-test said about this host.
///
/// Built once at boot. A server whose bundle has no runner refuses to start
/// (the native preflight names it), so a host only exists for a runner that
/// was found; whether that runner can confine itself here is a separate
/// question, answered by [start]. A runner that cannot is never a reason to
/// stop the server: code mode is unavailable on this host, no run gets
/// `repl`, and `codeMode.status` says why. There is no mode in which a
/// script runs with less isolation.
class CodeRunnerHost {
  /// Uses [sandbox], which runs [executable].
  CodeRunnerHost({
    required this.executable,
    required this.sandbox,
    required this.appSupportRoot,
  });

  /// Finds the runner the way [BundledCodeRunner.locate] does and wraps it in
  /// a [CodeSandboxProcess], or returns null when there is none. Null is not
  /// a degraded mode: the boot preflight refuses to start without the runner,
  /// and this is only how boot gets past the construction that precedes it.
  ///
  /// Where the runner may be is read from [processEnvironment] (the real
  /// process environment unless a test gives one), never from a `.env`
  /// file.
  static CodeRunnerHost? locate({
    required String appSupportRoot,
    Map<String, String>? processEnvironment,
  }) {
    final BundledCodeRunner runner;
    try {
      runner = BundledCodeRunner.locate(
        appSupportRoot: appSupportRoot,
        processEnvironment: processEnvironment,
      );
    } on CodeRunnerNotFoundException {
      return null;
    }
    return CodeRunnerHost(
      executable: runner.executable,
      sandbox: CodeSandboxProcess(executable: runner.executable),
      appSupportRoot: appSupportRoot,
    );
  }

  /// The absolute path of the runner. Never sent to a client.
  final String executable;

  /// The sandbox every script on this server runs in.
  final CodeSandboxProcess sandbox;

  /// The server's data directory. Never sent to a client.
  final String appSupportRoot;

  String? _version;

  /// The runner's `--version` line (`cc_codemode 0.1.0 quickjs-ng 0.16.2
  /// protocol 1`) as [versionLabel] makes it safe, or null when it did not
  /// answer or did not pass its self-test: what a binary that cannot prove
  /// itself prints is not reported.
  String? get version => availability is CodeRunnerAvailable ? _version : null;

  /// The most characters of a runner's version kept.
  static const int maxVersionChars = 80;

  /// [line] as one line of printable ASCII, at most [maxVersionChars]
  /// characters, for the startup line, the status and the log.
  static String versionLabel(String line) {
    final printable = line.replaceAll(RegExp(r'[^\x20-\x7e]'), ' ');
    final collapsed = printable.replaceAll(RegExp(' +'), ' ').trim();
    return collapsed.length <= maxVersionChars
        ? collapsed
        : '${collapsed.substring(0, maxVersionChars - 3)}...';
  }

  /// Whether this host runs scripts, live: what the boot self-test found,
  /// turned off by a launch failure and a failed re-run of the self-test,
  /// and on again by a later re-run that passes
  /// ([CodeSandboxProcess.availability]).
  CodeRunnerAvailability get availability => sandbox.availability;

  /// Runs the self-test and reads the version, both once, both in parallel.
  ///
  /// Until this completes [availability] is unavailable ("has not run yet"),
  /// so boot awaits it before the server accepts a run.
  Future<void> start() async {
    await Future.wait([sandbox.selfTest(), _readVersion()]);
  }

  Future<void> _readVersion() async {
    try {
      final result = await ChildProcess.run(
        executable,
        const ['--version'],
        workingDirectory: runnerWorkingDirectory(executable),
        inheritBase: false,
        inherit: [if (Platform.isWindows) 'SYSTEMROOT'],
        environment: const {'PATH': ''},
      ).timeout(const Duration(seconds: 10));
      final line = versionLabel('${result.stdout}'.trim().split('\n').first);
      _version = result.exitCode == 0 && line.isNotEmpty ? line : null;
    } on Object {
      _version = null;
    }
  }

  /// [availability]'s reason with every host path taken out, for the wire.
  ///
  /// The self-test's reasons can carry the runner's path (a start failure
  /// quotes the `ProcessException`) or anything the runner wrote to stderr.
  /// The operator reads the full text in the startup line; a client reads
  /// this: every path the self-test or a launch can name that the server
  /// knows ([knownHostPaths]) replaced whole, the rest by pattern, then
  /// redacted and made printable as a refusal quotes text.
  String? get publicReason => switch (availability) {
    CodeRunnerUnavailable(:final reason) => _printable(
      scrubHostPaths(reason, knownPaths: knownHostPaths),
    ),
    CodeRunnerAvailable() => null,
  };

  /// The host paths a self-test or launch reason can hold that this server
  /// can name: the runner, its directory and working directory, the
  /// directories a runner is installed in, the data directory and the
  /// temporary directory (as given and resolved). The user's home is added
  /// by [scrubHostPaths].
  List<String> get knownHostPaths {
    final temp = Directory.systemTemp;
    String? resolved;
    try {
      resolved = temp.resolveSymbolicLinksSync();
    } on FileSystemException {
      resolved = null;
    }
    return [
      executable,
      p.dirname(executable),
      runnerWorkingDirectory(executable),
      ...BundledCodeRunner.installDirectories(),
      appSupportRoot,
      temp.path,
      ?resolved,
    ];
  }

  /// The one startup line about code mode, for the operator: what is
  /// really bounded on this server, or why it runs no script.
  String startupLine({
    required int maxProcesses,
    required int maxParked,
    required int workspaceShare,
    required int maxHeapBytes,
  }) => startupLineFor(
    availability,
    version: _version,
    maxProcesses: maxProcesses,
    maxParked: maxParked,
    workspaceShare: workspaceShare,
    maxHeapBytes: maxHeapBytes,
  );

  /// Logs each change of availability after boot, once, as [lineFor] says
  /// it: the loss and the return both as warnings, so both show at the
  /// server's default log level (`warning`), as the startup line does (it
  /// goes out on the lifecycle lane, shown unless `--log-level error`).
  static StreamSubscription<CodeRunnerAvailability> logChanges(
    Stream<CodeRunnerAvailability> changes, {
    required String Function(CodeRunnerAvailability availability) lineFor,
  }) => changes.listen(
    (availability) => CcInfraLog.warning(lineFor(availability)),
  );

  /// The startup line for [availability] (see [startupLine]): one line,
  /// its reason redacted and made printable ([_printable]).
  static String startupLineFor(
    CodeRunnerAvailability availability, {
    required String? version,
    required int maxProcesses,
    required int maxParked,
    required int workspaceShare,
    required int maxHeapBytes,
  }) {
    final line = switch (availability) {
      CodeRunnerAvailable() =>
        'cc_server: code_mode=available (${version ?? 'cc_codemode'}; '
            '$maxProcesses ${maxProcesses == 1 ? 'script' : 'scripts'} at '
            'once, at most $workspaceShare per workspace; up to $maxParked '
            'more ${maxParked == 1 ? 'runner' : 'runners'} kept for scripts '
            'waiting on a person; heap at most '
            '${maxHeapBytes ~/ (1024 * 1024)} MiB per script)',
      CodeRunnerUnavailable(:final reason) =>
        'cc_server: code_mode=unavailable '
            '(${_printable(reason)}) — runs on '
            'this host get no repl tool; scripts never run without full '
            'lockdown',
    };
    return line;
  }

  /// [text] on one line ([oneLogLine]: redacted, every control and
  /// separator a blank), then made printable as a refusal quotes text
  /// ([printableText]: redacted again, anything else that does not print
  /// escaped), whole.
  static String _printable(String text) {
    final line = oneLogLine(text);
    return printableText(line, max: line.length + 1);
  }
}

/// Whether this server runs scripts, and the limits a workspace's scripts
/// run under.
///
/// There is no setting that turns code mode on or off: a run has `repl`
/// exactly when [availability] is available. Every limits read takes its
/// workspace explicitly and checks that it is registered and not deleted
/// before its database is opened: opening an unknown workspace's database
/// would create it. Stored limits are read leniently: a missing or malformed
/// row is the defaults, never an error, so a hand-edited row cannot break a
/// run.
class CodeModeSettings {
  /// Creates the settings.
  CodeModeSettings({
    required this._availability,
    required this._workspaces,
    required this._settings,
  });

  final CodeRunnerAvailability Function() _availability;
  final WorkspaceRepository _workspaces;
  final WorkspaceSettingsRepository _settings;

  /// Whether this server runs scripts, now: what the runner's self-test
  /// found, or unavailable on a public demo.
  CodeRunnerAvailability get availability => _availability();

  /// The limits [workspaceId]'s scripts run under: its stored overrides over
  /// [CodeModeLimits.defaults], or the defaults when nothing is stored or the
  /// stored value is malformed or out of bounds. Throws [NotFoundException]
  /// for a workspace that is not registered.
  Future<CodeModeLimits> limitsFor(String workspaceId) async {
    if (!await isLiveWorkspace(_workspaces, workspaceId)) {
      throw NotFoundException(
        'Workspace $workspaceId is not registered.',
        code: 'workspace_not_found',
      );
    }
    final raw = await _settings.get(workspaceId, kCodeModeLimitsSettingKey);
    if (raw == null || raw.isEmpty) {
      return CodeModeLimits.defaults;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return CodeModeLimits.defaults.withOverridesJson(decoded);
      }
    } on Object {
      // A malformed or out-of-bounds row reads as no overrides.
    }
    return CodeModeLimits.defaults;
  }
}
