import 'package:cc_domain/cc_domain.dart';
import 'package:control_center/core/update/deployed_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses the manifest shape the deploys write', () {
    final v = DeployedVersion.parse(
      '{"version": "1.2.0", "gitSha": "abc1234", "builtAt": "2026-08-14"}',
    );
    expect(v, isNotNull);
    expect(v!.version, '1.2.0');
    expect(v.gitSha, 'abc1234');
    expect(v.builtAt, '2026-08-14');
  });

  test('a malformed manifest is ignored, never an update', () {
    expect(DeployedVersion.parse('not json'), isNull);
    expect(DeployedVersion.parse('{}'), isNull);
    expect(DeployedVersion.parse('{"version": "", "gitSha": ""}'), isNull);
    expect(DeployedVersion.parse('["array"]'), isNull);
  });

  test('differsFromRunningBuild keys on the sha, not the version string', () {
    // A CI deploy has a different sha than the running (unstamped) build —
    // banner-worthy even when the version string is unchanged.
    const v = DeployedVersion(
      version: BuildInfo.buildVersion,
      gitSha: 'c0ffee1',
    );
    expect(v.differsFromRunningBuild(), isTrue);

    // The same sha (a manifest echoing this build) is NOT an update.
    expect(
      const DeployedVersion(
        version: '9.9.9',
        gitSha: BuildInfo.buildGitSha,
      ).differsFromRunningBuild(),
      isFalse,
    );
  });
}
