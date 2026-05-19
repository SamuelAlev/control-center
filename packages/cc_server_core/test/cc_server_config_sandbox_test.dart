import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:test/test.dart';

/// `--sandbox` is the field kill switch for wrapping agent runs in the host's
/// OS-native sandbox. It is an opt-OUT: the default is on and a host with no
/// backend (Windows, or Linux without `bwrap`/`socat`) still falls back on its
/// own. The switch exists for the case the probe cannot see — a host where the
/// sandbox profile itself misbehaves — so it boots clean without a rebuild.
void main() {
  test('the sandbox defaults to on', () {
    expect(CcServerConfig.resolve(const []).sandboxEnabled, isTrue);
  });

  test('--sandbox off disables; anything else stays on', () {
    expect(
      CcServerConfig.resolve(const ['--sandbox', 'off']).sandboxEnabled,
      isFalse,
    );
    expect(
      CcServerConfig.resolve(const ['--sandbox=off']).sandboxEnabled,
      isFalse,
    );
    expect(
      CcServerConfig.resolve(const ['--sandbox', 'OFF']).sandboxEnabled,
      isFalse,
      reason: 'the value is matched case-insensitively',
    );
    expect(
      CcServerConfig.resolve(const ['--sandbox', 'on']).sandboxEnabled,
      isTrue,
    );
    // A bare flag arrives as 'true' → not 'off' → on.
    expect(CcServerConfig.resolve(const ['--sandbox']).sandboxEnabled, isTrue);
  });
}
