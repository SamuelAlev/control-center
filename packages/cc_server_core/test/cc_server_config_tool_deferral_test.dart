import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:test/test.dart';

/// `--tool-deferral` is the field kill switch for the two-tier tool surface.
///
/// It is an opt-OUT: a harness run sends a small resident set plus a name index
/// of the rest by default. Off makes every admitted tool resident again, which
/// is byte-for-byte the requests the server made before deferral existed — so a
/// model that handles the two-tier surface badly is a flag away from the old
/// behaviour rather than a release away.
void main() {
  test('tool deferral defaults to on', () {
    expect(CcServerConfig.resolve(const []).toolDeferralEnabled, isTrue);
  });

  test('--tool-deferral off disables; anything else stays on', () {
    expect(
      CcServerConfig.resolve(
        const ['--tool-deferral', 'off'],
      ).toolDeferralEnabled,
      isFalse,
    );
    expect(
      CcServerConfig.resolve(const ['--tool-deferral=off']).toolDeferralEnabled,
      isFalse,
    );
    expect(
      CcServerConfig.resolve(
        const ['--tool-deferral', 'OFF'],
      ).toolDeferralEnabled,
      isFalse,
      reason: 'the value is matched case-insensitively',
    );
    expect(
      CcServerConfig.resolve(
        const ['--tool-deferral', 'on'],
      ).toolDeferralEnabled,
      isTrue,
    );
    // A bare flag arrives as 'true' → not 'off' → on.
    expect(
      CcServerConfig.resolve(const ['--tool-deferral']).toolDeferralEnabled,
      isTrue,
    );
  });

  test('the environment variable works where a flag is not available', () {
    // Containers and systemd units configure by environment, not argv.
    expect(
      CcServerConfig.resolve(
        const [],
        environment: const {'CC_SERVER_TOOL_DEFERRAL': 'off'},
      ).toolDeferralEnabled,
      isFalse,
    );
  });
}
