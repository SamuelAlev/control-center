import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:test/test.dart';

/// `--credential-gate` bounds how long a run whose credential cannot serve it
/// waits for a human before failing with the message it would have failed with
/// anyway.
///
/// The ceiling is the whole reason the gate is safe to have on by default: an
/// unattended run — a pipeline step, a cron trigger, a webhook — must not turn
/// into a hang because nobody was awake to paste a key. `0` is the kill switch
/// and restores the pre-gate behaviour exactly.
void main() {
  test('the gate is on by default, bounded at fifteen minutes', () {
    expect(CcServerConfig.resolve(const []).credentialGateSeconds, 900);
  });

  test('0 turns it off entirely', () {
    expect(
      CcServerConfig.resolve(const [
        '--credential-gate=0',
      ]).credentialGateSeconds,
      0,
    );
    expect(
      CcServerConfig.resolve(const [
        '--credential-gate',
        '0',
      ]).credentialGateSeconds,
      0,
    );
  });

  test('a custom deadline is honoured, clamped to an hour', () {
    expect(
      CcServerConfig.resolve(const [
        '--credential-gate',
        '120',
      ]).credentialGateSeconds,
      120,
    );
    // A run parked longer than an hour is holding a worktree lease and a
    // dispatch slot for a person who is plainly not coming back.
    expect(
      CcServerConfig.resolve(const [
        '--credential-gate',
        '99999',
      ]).credentialGateSeconds,
      3600,
    );
    expect(
      CcServerConfig.resolve(const [
        '--credential-gate',
        '-5',
      ]).credentialGateSeconds,
      0,
    );
  });

  test('unparseable input falls back to the default, never to zero', () {
    // Silently disabling the feature on a typo would be indistinguishable from
    // it never having worked.
    expect(
      CcServerConfig.resolve(const [
        '--credential-gate',
        'soon',
      ]).credentialGateSeconds,
      900,
    );
  });

  test('the environment variable works where a flag is not available', () {
    expect(
      CcServerConfig.resolve(
        const [],
        environment: const {'CC_SERVER_CREDENTIAL_GATE': '60'},
      ).credentialGateSeconds,
      60,
    );
  });
}
