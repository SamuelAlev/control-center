import 'dart:async';

import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/util/command_redaction.dart';

/// Whether the code mode runner can run scripts on this host, live.
///
/// It is the boot self-test's answer until a runner fails to launch for a
/// reason that is not its script's ([launchFailed]) and a re-run of the
/// self-test then fails: scripts are off. The causes such a failure can
/// have are often passing (a runner killed before its `ready` frame,
/// processes exhausted for a moment), so while scripts are off for that
/// reason, reading [current] is the demand that re-runs the self-test, and
/// one that passes turns them back on. Re-runs, from either trigger, start
/// at most once per retest interval and never two at once; a failing one
/// changes nothing. A boot self-test that never passed keeps scripts off
/// until a restart. Scripts are on only after a self-test that passed:
/// [current] becomes available from nothing else.
class CodeRunnerLiveAvailability {
  /// Creates the availability of one runner host; `selfTest` runs the
  /// runner's `--self-test` once and answers.
  CodeRunnerLiveAvailability({
    required this._selfTest,
    required this._retestInterval,
  });

  final Future<CodeRunnerAvailability> Function() _selfTest;
  final Duration _retestInterval;

  CodeRunnerAvailability _current = const CodeRunnerAvailability.unavailable(
    'The code mode runner self-test has not run yet.',
  );
  bool _closed = false;
  bool _lost = false;
  Future<void>? _retest;
  Stopwatch? _sinceRetest;
  int _retests = 0;
  final StreamController<CodeRunnerAvailability> _changes =
      StreamController.broadcast(sync: true);

  /// The current answer. While a failed re-test keeps scripts off, a read
  /// re-runs the self-test when one is due.
  CodeRunnerAvailability get current {
    if (_lost) {
      _retestIfDue();
    }
    return _current;
  }

  /// Fires once per change after boot, with the new answer: unavailable
  /// when a re-test failed, available when a later one passed.
  Stream<CodeRunnerAvailability> get changes => _changes.stream;

  /// Self-tests re-run after boot so far.
  int get retests => _retests;

  /// Waits for a self-test re-run in flight, if any. For tests.
  Future<void> get retestDone => _retest ?? Future.value();

  /// The boot self-test. Once a failed re-test has turned scripts off, it
  /// returns that answer without running: only a re-run turns them back on.
  Future<CodeRunnerAvailability> boot() async {
    if (_lost) {
      return _current;
    }
    final result = _oneLine(await _selfTest());
    if (!_lost) {
      _current = result;
    }
    return _current;
  }

  /// A runner did not launch for a reason that is not its script's: it
  /// could not be spawned, it exited before its `ready` frame, the frame was
  /// malformed or of another protocol, or it reported less than full
  /// lockdown. The script has not been sent by then (`init` follows a valid
  /// `ready`), so neither its text nor its arguments, timeout or heap can
  /// cause one; a handshake that only times out does not count, since an
  /// isolate busy with other work can delay it. Re-runs the self-test when
  /// one is due, and turns [current] off when it fails.
  ///
  /// [why] (which can name the runner's path) is said once, in one line,
  /// for the operator: inside the reason scripts are off for when the
  /// re-test fails, in a line of its own when it passes; a failure that
  /// starts no re-test (one is in flight, or ran within the interval) is a
  /// debug line.
  void launchFailed(String why) {
    if (_current is! CodeRunnerAvailable || !_retestIfDue(why: why)) {
      CcInfraLog.debug(
        'code mode: a script runner failed to launch: '
        '${oneLogLine(why)}',
      );
    }
  }

  /// Starts a re-test when one is due; whether it did.
  bool _retestIfDue({String? why}) {
    if (_closed || _retest != null) {
      return false;
    }
    final since = _sinceRetest;
    if (since != null && since.elapsed < _retestInterval) {
      return false;
    }
    _sinceRetest = Stopwatch()..start();
    _retests++;
    _retest = _rerunSelfTest(why).whenComplete(() => _retest = null);
    return true;
  }

  Future<void> _rerunSelfTest(String? why) async {
    final CodeRunnerAvailability result;
    try {
      result = await _selfTest();
    } on Object catch (e, st) {
      CcInfraLog.error('code mode: re-running the self-test failed', e, st);
      return;
    }
    if (_closed) {
      return;
    }
    final lost = result is CodeRunnerUnavailable;
    if (lost == _lost) {
      if (!lost && why != null) {
        CcInfraLog.warning(
          'code mode: a script runner failed to launch (${oneLogLine(why)}); '
          'the self-test passed again, so scripts stay on',
        );
      }
      return;
    }
    _lost = lost;
    _current = _oneLine(switch (result) {
      CodeRunnerUnavailable(:final reason) when why != null =>
        CodeRunnerAvailability.unavailable(
          '$reason (re-run after a script runner failed to launch: $why)',
        ),
      _ => result,
    });
    _changes.add(_current);
  }

  /// [availability] with its reason on one line: it is logged, and shown.
  static CodeRunnerAvailability _oneLine(CodeRunnerAvailability availability) =>
      switch (availability) {
        CodeRunnerUnavailable(:final reason) =>
          CodeRunnerAvailability.unavailable(oneLogLine(reason)),
        final CodeRunnerAvailable available => available,
      };

  /// Stops re-running the self-test and closes [changes]; the host shut
  /// down.
  void close() {
    _closed = true;
    unawaited(_changes.close());
  }
}

/// [text] as a code mode reason or log line holds it: the characters that
/// hide inside a word dropped ([_hidden]), so a token split by one is
/// found whole; secrets redacted ([redactSecrets]); then on one line
/// ([oneLineLabel]: every control character, C0 and C1, every line or
/// paragraph separator and every bidirectional control becomes a blank),
/// never cut.
String oneLogLine(String text) {
  final redacted = redactSecrets(text.replaceAll(_hidden, ''));
  return oneLineLabel(redacted, redacted.length + 1);
}

/// What hides inside a word: the soft hyphen, the Mongolian vowel
/// separator, the zero-width spaces, joiners and marks (U+200B to U+200F),
/// the invisible operators (U+2060 to U+2064), the byte order mark, the
/// variation selectors and lone surrogates.
final RegExp _hidden = RegExp(
  r'[\u00AD\u180E\u200B-\u200F\u2060-\u2064\uFEFF\uFE00-\uFE0F'
  r'\u{E0100}-\u{E01EF}\uD800-\uDFFF]',
  unicode: true,
);
