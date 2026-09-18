import 'dart:io';

import 'package:test/test.dart';

/// Source-level contract: each forge PR client implements [ForgePrClient]
/// (QUALITY.md R13). Behavioral HTTP coverage lives next to each client.
void main() {
  test('github, gitlab and bitbucket forge clients implement ForgePrClient', () {
    final root = _repoRoot();
    const files = [
      'packages/cc_infra/lib/src/network/github/github_forge_pr_client.dart',
      'packages/cc_infra/lib/src/network/gitlab/gitlab_forge_pr_client.dart',
      'packages/cc_infra/lib/src/network/bitbucket/bitbucket_forge_pr_client.dart',
    ];
    for (final rel in files) {
      final src = File('$root/$rel').readAsStringSync();
      expect(
        src.contains('implements ForgePrClient'),
        isTrue,
        reason: '$rel must implement ForgePrClient',
      );
    }
  });
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File(
      '${dir.path}/packages/cc_infra/lib/src/network/github/github_forge_pr_client.dart',
    ).existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
}
