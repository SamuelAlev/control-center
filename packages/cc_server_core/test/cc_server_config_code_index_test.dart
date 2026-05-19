import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:test/test.dart';

/// `--code-index` is the field kill switch for background code-graph
/// indexing (a host where indexing misbehaves boots clean without a rebuild);
/// `--code-index-defer` holds the first arm/index sweep past the ready
/// banner so it never competes with the desktop's initial RPC burst.
void main() {
  test('indexing defaults to on with a 15s defer', () {
    final config = CcServerConfig.resolve(const []);
    expect(config.codeIndexEnabled, isTrue);
    expect(config.codeIndexDeferSeconds, 15);
  });

  test('--code-index off disables; anything else stays on', () {
    expect(
      CcServerConfig.resolve(const ['--code-index', 'off']).codeIndexEnabled,
      isFalse,
    );
    expect(
      CcServerConfig.resolve(const ['--code-index=off']).codeIndexEnabled,
      isFalse,
    );
    expect(
      CcServerConfig.resolve(const ['--code-index', 'on']).codeIndexEnabled,
      isTrue,
    );
    // A bare flag arrives as 'true' → not 'off' → on.
    expect(
      CcServerConfig.resolve(const ['--code-index']).codeIndexEnabled,
      isTrue,
    );
  });

  test('--code-index-defer parses and clamps to 0..300', () {
    expect(
      CcServerConfig.resolve(const [
        '--code-index-defer',
        '0',
      ]).codeIndexDeferSeconds,
      0,
    );
    expect(
      CcServerConfig.resolve(const [
        '--code-index-defer=45',
      ]).codeIndexDeferSeconds,
      45,
    );
    expect(
      CcServerConfig.resolve(const [
        '--code-index-defer',
        '9999',
      ]).codeIndexDeferSeconds,
      300,
    );
    expect(
      CcServerConfig.resolve(const [
        '--code-index-defer',
        '-5',
      ]).codeIndexDeferSeconds,
      0,
    );
    expect(
      CcServerConfig.resolve(const [
        '--code-index-defer',
        'nonsense',
      ]).codeIndexDeferSeconds,
      15,
      reason: 'unparseable → the default',
    );
  });
}
