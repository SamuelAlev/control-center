import 'dart:io';

import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_domain/features/sandboxing/domain/network_baseline.dart';
import 'package:cc_infra/src/rigs/rig_exec_defaults.dart';
import 'package:test/test.dart';

void main() {
  group('execRigEgressAllowlist', () {
    test('is never empty — an exec rig must be able to fetch and install', () {
      // The regression this pins: exec rigs were opened with an EMPTY
      // allowlist. The per-rig proxies enforce it (deny-by-default), and the
      // credential broker's allowed-hosts set is derived from it, so an empty
      // list meant no apt, no git fetch and a broker that refused every mint
      // while the capability flags said `git push` should work.
      final list = execRigEgressAllowlist();
      expect(list, isNotEmpty);
      expect(list, containsAll(kBaselineAllowedDomains));
      expect(list, containsAll(kExecRigAptMirrors));
    });

    test("admits the worktree's forge git host", () {
      final remote = parseForgeRemote('git@bitbucket.org:team/repo.git');
      final list = execRigEgressAllowlist(forge: remote);
      expect(list, contains('bitbucket.org'));
    });
  });

  group('detectWorktreeForge', () {
    test('a non-git directory resolves to null, never throws', () async {
      final dir = await Directory.systemTemp.createTemp('cc-rig-forge-');
      try {
        expect(await detectWorktreeForge(dir.path), isNull);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('a missing path resolves to null', () async {
      expect(await detectWorktreeForge('/nonexistent/path/xyz'), isNull);
      expect(await detectWorktreeForge(''), isNull);
    });

    test('reads the origin remote of a real checkout', () async {
      final dir = await Directory.systemTemp.createTemp('cc-rig-forge-');
      try {
        await Process.run('git', ['-C', dir.path, 'init', '-q']);
        await Process.run('git', [
          '-C',
          dir.path,
          'remote',
          'add',
          'origin',
          'https://github.com/acme/widget.git',
        ]);
        final forge = await detectWorktreeForge(dir.path);
        expect(forge, isNotNull);
        expect(forge!.owner, 'acme');
        expect(forge.name, 'widget');
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
