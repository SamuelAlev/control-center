import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

/// `--log-level` / `CC_SERVER_LOG_LEVEL` sets the minimum server log severity.
/// The default is `warning`; `debug` includes HTTP request/response traces and
/// no-op code-graph index sweeps.
void main() {
  test('defaults to warning', () {
    expect(
      CcServerConfig.resolve(const []).logLevel,
      CcServerLogLevel.warning,
    );
  });

  test('accepts a bare flag value and the = form', () {
    expect(
      CcServerConfig.resolve(const ['--log-level', 'debug']).logLevel,
      CcServerLogLevel.debug,
    );
    expect(
      CcServerConfig.resolve(const ['--log-level=warning']).logLevel,
      CcServerLogLevel.warning,
    );
  });

  test('is case-insensitive and accepts the warn alias', () {
    expect(
      CcServerConfig.resolve(const ['--log-level', 'DEBUG']).logLevel,
      CcServerLogLevel.debug,
    );
    expect(
      CcServerConfig.resolve(const ['--log-level', 'Warn']).logLevel,
      CcServerLogLevel.warning,
    );
    expect(
      CcServerConfig.resolve(const ['--log-level', 'ERROR']).logLevel,
      CcServerLogLevel.error,
    );
  });

  test('an unrecognised value falls back to warning', () {
    expect(
      CcServerConfig.resolve(const ['--log-level', 'chatty']).logLevel,
      CcServerLogLevel.warning,
    );
  });

  test('info is still selectable', () {
    expect(
      CcServerConfig.resolve(const ['--log-level', 'info']).logLevel,
      CcServerLogLevel.info,
    );
  });

  test('does not disturb the flag that follows it', () {
    final config = CcServerConfig.resolve(const [
      '--log-level',
      'debug',
      '--port',
      '9999',
    ]);
    expect(config.logLevel, CcServerLogLevel.debug);
    expect(config.port, 9999);
  });
}
