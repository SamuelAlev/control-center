import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:test/test.dart';

/// Third-party credentials come from the environment only: no build carries
/// one, and no CLI flag sets one (`ps` can read argv).
void main() {
  test('nothing configured leaves the Klipy key empty', () {
    // An explicit empty environment: `resolve` otherwise layers the working
    // directory's `.env` under the real one.
    final config = CcServerConfig.resolve(const [], environment: const {});

    expect(config.klipyAppKey, isEmpty);
  });

  test('a credential flag is not read', () {
    // Passing one is not an error — the parser ignores unknown flags — but it
    // configures nothing, so a deployment that tried it fails visibly rather
    // than half-working.
    final config = CcServerConfig.resolve(const [
      '--klipy-app-key=flag-key',
    ], environment: const {});

    expect(config.klipyAppKey, isEmpty);
  });

  test('the environment supplies the Klipy key, trimmed', () {
    final config = CcServerConfig.resolve(
      const [],
      environment: const {'KLIPY_APP_KEY': '  env-key  '},
    );

    expect(config.klipyAppKey, 'env-key');
  });
}
