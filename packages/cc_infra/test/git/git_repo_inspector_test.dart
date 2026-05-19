import 'dart:io';

import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/src/git/git_repo_inspector.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises [GitRepoInspector] against real (temp) git repos: the happy
/// path (parses origin → owner/repo + current branch) and the three failure
/// modes (not a work tree, no origin, an unsupported forge) plus the
/// GitLab and Bitbucket origins it now accepts.
void main() {
  const inspector = GitRepoInspector();

  Future<int> git(List<String> args, String cwd) async =>
      (await Process.run('git', args, workingDirectory: cwd)).exitCode;

  group('GitRepoInspector.inspect — happy path', () {
    test('parses a github HTTPS origin + current branch', () async {
      final repo = Directory.systemTemp.createTempSync('cc_inspector_');
      addTearDown(() => repo.deleteSync(recursive: true));
      await git(['init', '-q', '-b', 'main'], repo.path);
      await git([
        'remote',
        'add',
        'origin',
        'https://github.com/acme/widget.git',
      ], repo.path);
      await git(['config', 'user.email', 't@e.com'], repo.path);
      await git(['config', 'user.name', 'T'], repo.path);
      File(p.join(repo.path, 'f.txt')).writeAsStringSync('x');
      await git(['add', '-A'], repo.path);
      await git(['commit', '-q', '-m', 'init'], repo.path);

      final info = await inspector.inspect(repo.path);
      expect(info.owner, 'acme');
      expect(info.repoName, 'widget');
      expect(info.branch, 'main');
      expect(info.path, repo.path);
    });

    test('parses a github SSH origin', () async {
      final repo = Directory.systemTemp.createTempSync('cc_inspector_ssh_');
      addTearDown(() => repo.deleteSync(recursive: true));
      await git(['init', '-q', '-b', 'dev'], repo.path);
      await git([
        'remote',
        'add',
        'origin',
        'git@github.com:foo/bar.git',
      ], repo.path);
      await git(['config', 'user.email', 't@e.com'], repo.path);
      await git(['config', 'user.name', 'T'], repo.path);
      File(p.join(repo.path, 'f.txt')).writeAsStringSync('x');
      await git(['add', '-A'], repo.path);
      await git(['commit', '-q', '-m', 'init'], repo.path);

      final info = await inspector.inspect(repo.path);
      expect(info.owner, 'foo');
      expect(info.repoName, 'bar');
      expect(info.branch, 'dev');
    });
  });

  group('GitRepoInspector.inspect — failures', () {
    test('throws when the path is not a git work tree', () async {
      final plain = Directory.systemTemp.createTempSync('cc_inspector_not_');
      addTearDown(() => plain.deleteSync(recursive: true));
      expect(
        () => inspector.inspect(plain.path),
        throwsA(
          isA<GitRepoInspectionException>().having(
            (e) => e.message,
            'message',
            contains('not inside'),
          ),
        ),
      );
    });

    test('throws when there is no origin remote', () async {
      final repo = Directory.systemTemp.createTempSync(
        'cc_inspector_noorigin_',
      );
      addTearDown(() => repo.deleteSync(recursive: true));
      await git(['init', '-q'], repo.path);
      expect(
        () => inspector.inspect(repo.path),
        throwsA(
          isA<GitRepoInspectionException>().having(
            (e) => e.message,
            'message',
            contains('origin'),
          ),
        ),
      );
    });

    test('accepts a gitlab origin and reports the gitlab forge', () async {
      final repo = Directory.systemTemp.createTempSync('cc_inspector_gl_');
      addTearDown(() => repo.deleteSync(recursive: true));
      await git(['init', '-q'], repo.path);
      await git([
        'remote',
        'add',
        'origin',
        'https://gitlab.com/acme/widget.git',
      ], repo.path);

      final info = await inspector.inspect(repo.path);
      expect(info.forge, ForgeHost.gitlab);
      expect(info.owner, 'acme');
      expect(info.repoName, 'widget');
    });

    test('keeps a nested gitlab namespace intact', () async {
      final repo = Directory.systemTemp.createTempSync('cc_inspector_glns_');
      addTearDown(() => repo.deleteSync(recursive: true));
      await git(['init', '-q'], repo.path);
      await git([
        'remote',
        'add',
        'origin',
        'https://gitlab.com/acme/team/widget.git',
      ], repo.path);

      final info = await inspector.inspect(repo.path);
      expect(info.owner, 'acme/team');
      expect(info.repoName, 'widget');
    });

    test('accepts a bitbucket origin', () async {
      final repo = Directory.systemTemp.createTempSync('cc_inspector_bb_');
      addTearDown(() => repo.deleteSync(recursive: true));
      await git(['init', '-q'], repo.path);
      await git([
        'remote',
        'add',
        'origin',
        'git@bitbucket.org:acme/widget.git',
      ], repo.path);

      final info = await inspector.inspect(repo.path);
      expect(info.forge, ForgeHost.bitbucket);
      expect(info.owner, 'acme');
      expect(info.repoName, 'widget');
    });

    test('throws when origin is on no supported forge', () async {
      final repo = Directory.systemTemp.createTempSync('cc_inspector_other_');
      addTearDown(() => repo.deleteSync(recursive: true));
      await git(['init', '-q'], repo.path);
      await git([
        'remote',
        'add',
        'origin',
        'https://git.example.com/acme/widget.git',
      ], repo.path);
      expect(
        () => inspector.inspect(repo.path),
        throwsA(
          isA<GitRepoInspectionException>().having(
            (e) => e.message,
            'message',
            allOf(contains('supported forge'), contains('github.com')),
          ),
        ),
      );
    });
  });
}
