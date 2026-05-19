import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/server_build_provider.dart';
import 'package:flutter_test/flutter_test.dart';

ServerBuild _server(String version) => ServerBuild(version: version);

void main() {
  test('a server on the same version is not stale', () {
    expect(serverOlderThanClient(_server(BuildInfo.buildVersion)), isFalse);
  });

  test('a server that advertises nothing is "cannot tell", never a warning', () {
    expect(serverOlderThanClient(null), isNull);
    expect(serverOlderThanClient(const ServerBuild()), isNull);
    expect(serverOlderThanClient(_server('')), isNull);
  });

  test('orders dotted versions component-wise', () {
    // The comparison is always against this client's own BuildInfo, so the
    // cases are chosen around it rather than as free pairs.
    expect(serverOlderThanClient(_server('0.0.0')), isTrue);
    expect(serverOlderThanClient(_server('999.0.0')), isFalse);
    // A later component never outranks an earlier one.
    expect(serverOlderThanClient(_server('0.1.0')), isFalse);
    expect(serverOlderThanClient(_server('1.0.0')), isFalse);
  });

  test('a pre-release server is older than the matching release', () {
    // This is the case the numeric-only compare got wrong: every component of
    // "0.0.1-beta" parsed to a number except the last, which fell back to 0,
    // making the pre-release compare EQUAL to the release and hiding a real
    // "your server is behind" warning.
    const preRelease = '${BuildInfo.buildVersion}-beta';
    expect(serverOlderThanClient(_server(preRelease)), isTrue);
  });

  test('build metadata does not affect precedence', () {
    expect(
      serverOlderThanClient(_server('${BuildInfo.buildVersion}+abc123')),
      isFalse,
    );
  });
}
