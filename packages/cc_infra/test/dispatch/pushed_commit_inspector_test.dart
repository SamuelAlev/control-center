import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_infra/src/dispatch/pushed_commit_inspector.dart';
import 'package:test/test.dart';

void main() {
  group('PushedCommitInspector.inspect', () {
    late Directory scratch;
    late Map<String, String> gitEnv;

    Future<String> git(List<String> args, {Map<String, String>? env}) async {
      final r = await Process.run(
        'git',
        args,
        workingDirectory: '${scratch.path}/repo',
        environment: {...gitEnv, ...?env},
      );
      expect(r.exitCode, 0, reason: '${args.join(' ')}: ${r.stderr}');
      return (r.stdout as String).trim();
    }

    setUp(() async {
      scratch = await Directory.systemTemp.createTemp('cc-inspect-test-');
      // A scratch global config: the host's may sign (and hang) every commit.
      final global = File('${scratch.path}/gitconfig')..writeAsStringSync('');
      gitEnv = {
        'GIT_CONFIG_GLOBAL': global.path,
        'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_AUTHOR_NAME': 'Ada',
        'GIT_AUTHOR_EMAIL': 'ada@example.com',
        'GIT_COMMITTER_NAME': 'Ada',
        'GIT_COMMITTER_EMAIL': 'ada@example.com',
      };
      Directory('${scratch.path}/repo').createSync();
      await git(['init', '--quiet', '-b', 'main']);
    });

    tearDown(() => scratch.delete(recursive: true));

    test('reads every commit and tag in a real pack', () async {
      File('${scratch.path}/repo/a.txt').writeAsStringSync('a');
      await git(['add', 'a.txt']);
      await git(['commit', '--quiet', '-m', 'first']);
      File('${scratch.path}/repo/b.txt').writeAsStringSync('b');
      await git(['add', 'b.txt']);
      await git(
        ['commit', '--quiet', '-m', 'second\n\nSigned-off-by: Ada <a@x>'],
        env: {
          'GIT_AUTHOR_EMAIL': '1+ada@users.noreply.github.com',
          'GIT_COMMITTER_NAME': 'Control Center',
          'GIT_COMMITTER_EMAIL': 'hi@usectrl.dev',
        },
      );
      await git(['tag', '-a', 'v1', '-m', 'release']);

      final packFile = File('${scratch.path}/pushed.pack');
      final pack = await Process.start(
        'git',
        ['pack-objects', '--stdout', '--revs'],
        workingDirectory: '${scratch.path}/repo',
        environment: gitEnv,
      );
      pack.stdin.writeln('refs/tags/v1');
      await pack.stdin.close();
      await pack.stdout.pipe(packFile.openWrite());
      expect(await pack.exitCode, 0);

      final objects = await PushedCommitInspector.inspect(packFile);
      final commits = objects.where((o) => o.kind == 'commit').toList();
      final tags = objects.where((o) => o.kind == 'tag').toList();
      expect(commits, hasLength(2));
      expect(tags, hasLength(1));

      final first = commits.singleWhere((c) => !c.signedOff);
      expect(first.authorEmail, 'ada@example.com');
      expect(first.committerEmail, 'ada@example.com');
      expect(first.signed, isFalse);

      final second = commits.singleWhere((c) => c.signedOff);
      expect(second.authorEmail, '1+ada@users.noreply.github.com');
      expect(second.committerEmail, 'hi@usectrl.dev');

      expect(tags.single.committerEmail, 'ada@example.com');
      expect(tags.single.authorEmail, isNull);
    });

    test('bytes that are not a pack are refused', () async {
      final bogus = File('${scratch.path}/bogus.pack')
        ..writeAsStringSync('PACK-bytes');
      expect(
        () => PushedCommitInspector.inspect(bogus),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PushedCommitInspector.parse', () {
    test('a gpgsig header marks the commit signed', () {
      final o = PushedCommitInspector.parse(
        'commit',
        'c1',
        'tree 1\n'
            'author Ada <ada@example.com> 1700000000 +0000\n'
            'committer Ada <ada@example.com> 1700000000 +0000\n'
            'gpgsig -----BEGIN SSH SIGNATURE-----\n'
            ' AAAA\n'
            ' -----END SSH SIGNATURE-----\n'
            '\n'
            'message\n',
      );
      expect(o.signed, isTrue);
      expect(o.signedOff, isFalse);
    });

    test('a signed tag is marked signed', () {
      final o = PushedCommitInspector.parse(
        'tag',
        't1',
        'object 1\ntype commit\ntag v1\n'
            'tagger Ada <ada@example.com> 1700000000 +0000\n'
            '\n'
            'release\n'
            '-----BEGIN PGP SIGNATURE-----\n'
            'AAAA\n'
            '-----END PGP SIGNATURE-----\n',
      );
      expect(o.signed, isTrue);
      expect(o.committerEmail, 'ada@example.com');
    });

    test('a commit without an author is malformed', () {
      expect(
        () => PushedCommitInspector.parse(
          'commit',
          'c1',
          'tree 1\ncommitter Ada <a@x> 1 +0000\n\nm\n',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('a repeated author or committer header is malformed (git shows '
        'the first, so the checked one could differ)', () {
      const twoAuthors =
          'tree 1\nauthor Eve <eve@x> 1 +0000\nauthor Ada <a@x> 1 +0000\n'
          'committer Ada <a@x> 1 +0000\n\nm\n';
      const twoCommitters =
          'tree 1\nauthor Ada <a@x> 1 +0000\ncommitter Eve <eve@x> 1 +0000\n'
          'committer Ada <a@x> 1 +0000\n\nm\n';
      for (final raw in [twoAuthors, twoCommitters]) {
        expect(
          () => PushedCommitInspector.parse('commit', 'c1', raw),
          throwsA(isA<FormatException>()),
        );
      }
    });
  });

  group('PushedCommitInspector.violation', () {
    PushedGitObject commit({
      String author = 'ada@example.com',
      String committer = 'ada@example.com',
      bool signed = false,
      bool signedOff = false,
    }) => PushedGitObject(
      kind: 'commit',
      oid: '0123456789abcdef',
      authorEmail: author,
      committerEmail: committer,
      signed: signed,
      signedOff: signedOff,
    );

    final owner = AgentCommitIdentity.owner(
      name: 'Ada',
      email: 'Ada@Example.com',
    );
    final member = AgentCommitIdentity.member(
      name: 'Bo',
      email: '7+bo@users.noreply.github.com',
    );

    test('the owner may push signed commits as themselves', () {
      expect(
        PushedCommitInspector.violation([commit(signed: true)], owner),
        isNull,
      );
    });

    test('a member run pushes unsigned, authored by them, committed by '
        'Control Center', () {
      final ok = commit(
        author: '7+bo@users.noreply.github.com',
        committer: AgentCommitIdentity.controlCenterEmail,
      );
      expect(PushedCommitInspector.violation([ok], member), isNull);
      expect(
        PushedCommitInspector.violation([
          commit(
            author: '7+bo@users.noreply.github.com',
            committer: AgentCommitIdentity.controlCenterEmail,
            signed: true,
          ),
        ], member),
        contains('unsigned'),
      );
      expect(
        PushedCommitInspector.violation([
          commit(author: '7+bo@users.noreply.github.com'),
        ], member),
        contains('committed by ada@example.com'),
      );
      expect(
        PushedCommitInspector.violation([
          commit(committer: AgentCommitIdentity.controlCenterEmail),
        ], member),
        contains('authored by ada@example.com'),
      );
    });

    test('Signed-off-by is refused even for the owner', () {
      expect(
        PushedCommitInspector.violation([commit(signedOff: true)], owner),
        contains('Signed-off-by'),
      );
    });

    test('an unrequested run is Control Center throughout', () {
      final identity = AgentCommitIdentity.unrequested();
      expect(
        PushedCommitInspector.violation([
          commit(
            author: AgentCommitIdentity.controlCenterEmail,
            committer: AgentCommitIdentity.controlCenterEmail,
          ),
        ], identity),
        isNull,
      );
      expect(PushedCommitInspector.violation([commit()], identity), isNotNull);
    });
  });
}
