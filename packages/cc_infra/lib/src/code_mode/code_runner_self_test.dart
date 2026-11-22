import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_infra/src/code_mode/runner_frames.dart';

/// Runs the runner's `--self-test` in the process [spawn] starts and reads
/// what it proves: the runner is available only when it is a release build
/// (`"build":"release"`), locked itself down fully, every check it attempted
/// was denied, every test session under the lockdown passed and it exited 0.
/// Otherwise the answer says what failed, with each control's own detail cut
/// to [detailChars]. A debug build has debug assertions and no path
/// scrubbing, and is never what a bundle ships, so it runs no script.
///
/// A self-test that does not finish within [timeout] is killed; its output
/// is read for at most [exitGrace] after it exits.
///
/// [protocolProblem] is what [checkCodeRunnerProtocol] found, when the
/// runner does not speak this server's protocol. A runner that passed
/// everything but says it is not a release build is told that, whatever
/// its protocol (the more useful reason: the fix is a release build, not
/// another of the same); any other outcome gives [protocolProblem] first.
Future<CodeRunnerAvailability> runCodeRunnerSelfTest(
  Future<Process> Function() spawn, {
  required Duration timeout,
  required Duration exitGrace,
  required int detailChars,
  CodeRunnerAvailability? protocolProblem,
}) async {
  final Process process;
  try {
    process = await spawn();
  } on Object catch (e) {
    return protocolProblem ??
        CodeRunnerAvailability.unavailable(
          'The code mode runner could not be started: $e',
        );
  }
  unawaited(process.stdin.close().catchError((Object _) {}));
  final stdout = BoundedCapture(64 * 1024);
  final stderr = BoundedCapture(8 * 1024);
  final reading = Future.wait([
    process.stdout.forEach(stdout.add),
    process.stderr.forEach(stderr.add),
  ]);
  int exitCode;
  try {
    exitCode = await process.exitCode.timeout(timeout);
    await reading.timeout(exitGrace, onTimeout: () => const []);
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
    await process.exitCode;
    return protocolProblem ??
        CodeRunnerAvailability.unavailable(
          'The code mode runner self-test did not finish within '
          '${timeout.inSeconds} s.',
        );
  }
  final text = utf8.decode(stdout.bytes(), allowMalformed: true).trim();
  Map<String, dynamic>? report;
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map && decoded['selftest'] is Map) {
      report = (decoded['selftest'] as Map).cast<String, dynamic>();
    }
  } on FormatException {
    report = null;
  }
  if (report == null) {
    final err = oneLineLabel(
      utf8.decode(stderr.bytes(), allowMalformed: true),
      detailChars,
    );
    return protocolProblem ??
        CodeRunnerAvailability.unavailable(
          'The code mode runner self-test exited with code $exitCode and no '
          'report${err.isEmpty ? '' : ': $err'}.',
        );
  }
  final lockdown = report['lockdown'];
  final level = lockdown is Map ? lockdown['level'] : null;
  // What the runner says about each control it could not apply (on
  // Windows, the command that grants the runner its access entry). The
  // operator needs it; a client reads the public reason, with host paths
  // scrubbed.
  final controlDetails = <String, String>{
    if (lockdown is Map && lockdown['controls'] is List)
      for (final c in lockdown['controls'] as List)
        if (c is Map && c['name'] is String && c['detail'] is String)
          c['name'] as String: oneLineLabel(c['detail'] as String, detailChars),
  };
  final failedControls = [
    if (lockdown is Map && lockdown['failed'] is List)
      for (final f in lockdown['failed'] as List)
        switch (controlDetails['$f']) {
          final String detail when detail.isNotEmpty =>
            '${oneLineLabel('$f', 64)} ($detail)',
          _ => oneLineLabel('$f', 64),
        },
  ];
  final allowed = [
    if (report['checks'] is List)
      for (final c in report['checks'] as List)
        if (c is Map && c['denied'] != true) '${c['name']}',
  ];
  // The runner also runs real sessions under its lockdown; a lockdown that
  // denies everything but kills scripts is no use either.
  final session = report['session'];
  final sessionPassed = session is Map && session['passed'] == true;
  final build = report['build'];
  final buildProblem = switch (build) {
    'release' => null,
    'debug' => 'is a debug build',
    final String other => 'reports its build as "${oneLineLabel(other, 32)}"',
    _ => 'does not report its build',
  };
  if (exitCode == 0 &&
      report['ok'] == true &&
      level == CodeRunnerLockdown.fullLevel &&
      failedControls.isEmpty &&
      allowed.isEmpty &&
      sessionPassed) {
    if (buildProblem == null) {
      return protocolProblem ?? const CodeRunnerAvailability.available();
    }
    return CodeRunnerAvailability.unavailable(
      'The code mode runner $buildProblem, not a release build, so it runs '
      'no script on this host. Install a release build (built by '
      'scripts/natives/build_codemode.sh and staged with '
      'scripts/build_server.sh).',
    );
  }
  final lockdownReasons = <String>[
    if (level != CodeRunnerLockdown.fullLevel) 'lockdown level is $level',
    if (failedControls.isNotEmpty)
      'controls not applied: ${failedControls.join(', ')}',
    if (allowed.isNotEmpty) 'not denied: ${allowed.join(', ')}',
  ];
  final sessionDetail = session is Map && session['detail'] is String
      ? session['detail'] as String
      : 'no session result was reported';
  final reasons = <String>[
    ...lockdownReasons,
    if (!sessionPassed)
      'a test script could not run under the lockdown: $sessionDetail',
    if (exitCode != 0) 'exit code $exitCode',
    if (buildProblem != null) 'it $buildProblem',
  ];
  final problem = lockdownReasons.isEmpty
      ? 'cannot run scripts'
      : 'cannot lock itself down';
  return protocolProblem ??
      CodeRunnerAvailability.unavailable(
        'The code mode runner $problem on this host '
        '(${reasons.isEmpty ? 'the self-test failed' : reasons.join('; ')}).',
      );
}

/// Runs the runner's `--version` in the process [spawn] starts and checks
/// the protocol it names (`cc_codemode <runner> <engine> protocol <n>`)
/// against [expected]: null when they match, otherwise the reason it runs
/// no script. The self-test proves the lockdown, not the protocol, so a
/// runner older or newer than this server would pass it and then fail
/// every script; this refuses it before any is sent.
Future<CodeRunnerAvailability?> checkCodeRunnerProtocol(
  Future<Process> Function() spawn, {
  required int expected,
  required Duration timeout,
}) async {
  final Process process;
  try {
    process = await spawn();
  } on Object catch (e) {
    return CodeRunnerAvailability.unavailable(
      'The code mode runner could not be started: $e',
    );
  }
  unawaited(process.stdin.close().catchError((Object _) {}));
  final stdout = BoundedCapture(4 * 1024);
  final reading = Future.wait([
    process.stdout.forEach(stdout.add),
    process.stderr.drain<void>(),
  ]);
  try {
    await process.exitCode.timeout(timeout);
    await reading.timeout(timeout, onTimeout: () => const []);
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
    await process.exitCode;
    return CodeRunnerAvailability.unavailable(
      'The code mode runner did not report its version within '
      '${timeout.inSeconds} s.',
    );
  }
  final text = utf8.decode(stdout.bytes(), allowMalformed: true).trim();
  final protocol = RegExp(r' protocol (\d+)$').firstMatch(text)?.group(1);
  if (protocol == '$expected') {
    return null;
  }
  return CodeRunnerAvailability.unavailable(
    protocol == null
        ? 'The code mode runner does not report its protocol; this server '
              'speaks $expected. Reinstall the application or server bundle.'
        : 'The code mode runner speaks protocol $protocol; this server '
              'speaks $expected. Reinstall the application or server bundle.',
  );
}
