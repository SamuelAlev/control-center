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
      const secondMessage =
          'second\n\nSigned-off-by: Ada <a@x>\n'
          'co-authored-by: Bo <bo@x>\nCo-Authored-By: Cy <cy@x>';
      await git(
        ['commit', '--quiet', '-m', secondMessage],
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
      expect(first.coAuthors, isEmpty);
      expect(first.authorEmail, 'ada@example.com');
      expect(first.committerEmail, 'ada@example.com');
      expect(first.signed, isFalse);

      final second = commits.singleWhere((c) => c.signedOff);
      expect(second.authorEmail, '1+ada@users.noreply.github.com');
      expect(second.committerEmail, 'hi@usectrl.dev');
      expect(second.committerName, 'Control Center');
      expect(second.authorName, 'Ada');
      expect(second.coAuthors, [
        'co-authored-by: Bo <bo@x>',
        'Co-Authored-By: Cy <cy@x>',
      ]);

      expect(tags.single.committerEmail, 'ada@example.com');
      expect(tags.single.authorEmail, isNull);
    });

    test('reads named commits out of a repository, and refuses a missing '
        'object or one that is not a commit', () async {
      File('${scratch.path}/repo/a.txt').writeAsStringSync('a');
      await git(['add', 'a.txt']);
      await git(['commit', '--quiet', '-m', 'first']);
      final sha = await git(['rev-parse', 'HEAD']);
      final tree = await git(['rev-parse', 'HEAD^{tree}']);
      final gitDir = '${scratch.path}/repo/.git';

      final objects = await PushedCommitInspector.inspectCommits(gitDir, [sha]);
      expect(objects.single.oid, sha);
      expect(objects.single.authorName, 'Ada');
      expect(
        () => PushedCommitInspector.inspectCommits(gitDir, ['0' * 40]),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PushedCommitInspector.inspectCommits(gitDir, [tree]),
        throwsA(isA<FormatException>()),
      );
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
        'object ${'a' * 40}\ntype commit\ntag v1\n'
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

    test('the encoding header and identity names are read', () {
      final o = PushedCommitInspector.parse(
        'commit',
        'c1',
        'tree 1\n'
            'author Ada Lovelace <ada@example.com> 1700000000 +0000\n'
            'committer Control Center <x@y> 1700000000 +0000\n'
            'encoding UTF-16LE\n'
            '\n'
            'message\n',
      );
      expect(o.encoding, 'UTF-16LE');
      expect(o.authorName, 'Ada Lovelace');
      expect(o.committerName, 'Control Center');
    });

    test('names are kept as written, and both dates are read', () {
      final o = PushedCommitInspector.parse(
        'commit',
        'c1',
        'tree 1\n'
            'author Ada\u00a0 <ada@example.com> 1700000000 +0100\n'
            'committer  Ada <ada@example.com> 1700000360 -0800\n'
            '\n'
            'message\n',
      );
      expect(o.authorName, 'Ada\u00a0');
      expect(o.committerName, ' Ada');
      expect(o.authorTime, 1700000000);
      expect(o.committerTime, 1700000360);
    });

    test('an identity without a date is malformed', () {
      for (final raw in [
        'tree 1\nauthor Ada <a@x>\ncommitter Ada <a@x> 1 +0000\n\nm\n',
        'tree 1\nauthor Ada <a@x> 1 +0000\ncommitter Ada <a@x>\n\nm\n',
        'tree 1\nauthor Ada <a@x> 1 +0000\ncommitter Ada <a@x> soon +0000\n\nm\n',
        'tree 1\nauthor Ada <a@x> 1 +0000\ncommitter Ada <a@x> <b@x> 1 +0000\n\nm\n',
      ]) {
        expect(
          () => PushedCommitInspector.parse('commit', 'c1', raw),
          throwsA(isA<FormatException>()),
          reason: raw,
        );
      }
    });

    test('a tag is signed by any armor git reads, whatever follows on its '
        'line', () {
      for (final armor in [
        '-----BEGIN PGP SIGNATURE-----',
        '-----BEGIN PGP MESSAGE-----',
        '-----BEGIN SSH SIGNATURE-----',
        '-----BEGIN SIGNED MESSAGE-----',
        '-----BEGIN SSH SIGNATURE----- trailing',
      ]) {
        final o = PushedCommitInspector.parse(
          'tag',
          't1',
          'object ${'a' * 40}\ntype commit\ntag v1\n'
              'tagger Ada <ada@example.com> 1700000000 +0000\n'
              '\n'
              'release\n'
              '$armor\nAAAA\n',
        );
        expect(o.signed, isTrue, reason: armor);
      }
      final plain = PushedCommitInspector.parse(
        'tag',
        't1',
        'object ${'a' * 40}\ntype commit\ntag v1\n'
            'tagger Ada <ada@example.com> 1700000000 +0000\n'
            '\n'
            'release, not -----BEGIN PGP SIGNATURE----- at a line start\n',
      );
      expect(plain.signed, isFalse);
    });

    group('co-author trailers', () {
      const cc = 'Co-Authored-By: Control Center <hi@usectrl.dev>';
      PushedGitObject of(String message) => PushedCommitInspector.parse(
        'commit',
        'c1',
        'tree 1\n'
            'author Ada <ada@example.com> 1700000000 +0000\n'
            'committer Ada <ada@example.com> 1700000000 +0000\n'
            '\n'
            '$message',
      );

      test('the last paragraph of trailer lines credits its co-authors', () {
        for (final message in [
          'change\n\n$cc\n',
          'change\n\nbody text\n\n$cc\n',
          'change\n\nRefs: #12\n$cc\nReviewed-by: Bo <bo@x>\n',
          'change\n\n$cc\n\n \t\n',
          'change\r\n\r\n$cc\r\n',
        ]) {
          final o = of(message);
          expect(o.creditedCoAuthors, [cc], reason: message);
          expect(o.coAuthors, [cc], reason: message);
        }
      });

      test('a co-author line anywhere else is seen and credits nobody', () {
        for (final message in [
          // The subject is not a trailer block.
          '$cc\n',
          // Prose in the last paragraph.
          'change\n\n$cc\nand thanks\n',
          'change\n\nthanks to\n$cc\n',
          // Not the last paragraph.
          'change\n\n$cc\n\nMore text.\n',
          // Indented: git reads it as the line above continuing.
          'change\n\nRefs: #12\n $cc\n',
          // A paragraph break git does not see as one is still text here.
          'change\n\u00a0\n$cc\n',
        ]) {
          final o = of(message);
          expect(o.creditedCoAuthors, isEmpty, reason: message);
          expect(o.coAuthors, hasLength(1), reason: message);
        }
      });

      test('a message without a co-author line has neither', () {
        final o = of('change\n\nbody\n');
        expect(o.coAuthors, isEmpty);
        expect(o.creditedCoAuthors, isEmpty);
      });
    });

    test('what an object stands on is read: a commit\'s parents, a tag\'s '
        'target', () {
      final a = 'a' * 40;
      final b = 'b' * 40;
      final merge = PushedCommitInspector.parse(
        'commit',
        'c1',
        'tree ${'c' * 40}\nparent $a\nparent $b\n'
            'author Ada <a@x> 1 +0000\ncommitter Ada <a@x> 1 +0000\n\nm\n',
      );
      expect(merge.buildsOn, [a, b]);
      final root = PushedCommitInspector.parse(
        'commit',
        'c1',
        'tree ${'c' * 40}\n'
            'author Ada <a@x> 1 +0000\ncommitter Ada <a@x> 1 +0000\n\n'
            'parent $a\n',
      );
      expect(root.buildsOn, isEmpty, reason: 'a message line is not a header');
      final tag = PushedCommitInspector.parse(
        'tag',
        't1',
        'object $a\ntype commit\ntag v1\n'
            'tagger Ada <a@x> 1 +0000\n\nrelease\n',
      );
      expect(tag.buildsOn, [a]);
    });

    test('a parent or target that is not an object id is malformed', () {
      for (final (kind, raw) in [
        (
          'commit',
          'tree 1\nparent HEAD\n'
              'author Ada <a@x> 1 +0000\ncommitter Ada <a@x> 1 +0000\n\nm\n',
        ),
        (
          'tag',
          'object v1\ntype commit\ntag v1\n'
              'tagger Ada <a@x> 1 +0000\n\nrelease\n',
        ),
        ('tag', 'type commit\ntag v1\ntagger Ada <a@x> 1 +0000\n\nrelease\n'),
      ]) {
        expect(
          () => PushedCommitInspector.parse(kind, 'x', raw),
          throwsA(isA<FormatException>()),
          reason: raw,
        );
      }
    });

    test('a repeated encoding header is malformed', () {
      expect(
        () => PushedCommitInspector.parse(
          'commit',
          'c1',
          'tree 1\nauthor A <a@x> 1 +0000\ncommitter A <a@x> 1 +0000\n'
              'encoding UTF-8\nencoding UTF-16\n\nm\n',
        ),
        throwsA(isA<FormatException>()),
      );
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
    const bo = (name: 'Bo', email: '7+bo@users.noreply.github.com');
    const cc = AgentCommitIdentity.controlCenterEmail;
    const ccName = AgentCommitIdentity.controlCenterName;
    const ccTrailer = 'Co-Authored-By: Control Center <hi@usectrl.dev>';
    const key =
        'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeyOfBoKeyOfBoKeyOfBoKeyOfBoKeyOfBoKeyOfBoKey';
    const otherKey =
        'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtherKeyOtherKeyOtherKeyOtherKeyOtherKeyOthe';
    // A person asked, attribution on: their commits, crediting Control Center.
    final person = AgentCommitIdentity.person(bo, creditAgent: true);
    // Nobody asked: the agent's commits.
    final automation = AgentCommitIdentity.automation();

    PushedGitObject commit({
      String author = '7+bo@users.noreply.github.com',
      String committer = '7+bo@users.noreply.github.com',
      String authorName = 'Bo',
      String committerName = 'Bo',
      String? encoding,
      bool signed = false,
      String? signedBy,
      bool signedOff = false,
      List<String> coAuthors = const [ccTrailer],
      List<String>? credited,
    }) => PushedGitObject(
      kind: 'commit',
      oid: '0123456789abcdef',
      authorName: authorName,
      authorEmail: author,
      committerName: committerName,
      committerEmail: committer,
      encoding: encoding,
      signed: signed,
      signedBy: signedBy,
      signedOff: signedOff,
      coAuthors: coAuthors,
      // Unless a test says otherwise, every co-author line is a trailer.
      creditedCoAuthors: credited ?? coAuthors,
    );

    PushedGitObject agentCommit({
      String author = cc,
      String committer = cc,
      String authorName = ccName,
      String committerName = ccName,
      bool signed = false,
      bool signedOff = false,
      List<String> coAuthors = const [],
    }) => commit(
      author: author,
      committer: committer,
      authorName: authorName,
      committerName: committerName,
      signed: signed,
      signedOff: signedOff,
      coAuthors: coAuthors,
    );

    test('a run a person asked for pushes commits that are theirs: author '
        'and committer, crediting Control Center', () {
      expect(PushedCommitInspector.violation([commit()], person), isNull);
      expect(
        PushedCommitInspector.violation([
          commit(committer: 'ada@example.com'),
        ], person),
        contains('<ada@example.com>; this run commits as Bo'),
      );
      // Authored as the agent (or anyone else) is not their commit.
      expect(
        PushedCommitInspector.violation([
          commit(author: cc, authorName: ccName),
        ], person),
        contains('authored by $ccName <$cc>; this run authors as Bo'),
      );
    });

    test('the name is checked as well as the email', () {
      expect(
        PushedCommitInspector.violation([
          commit(authorName: 'The CTO'),
        ], person),
        contains('authored by The CTO <7+bo@users.noreply.github.com>'),
      );
      expect(
        PushedCommitInspector.violation([
          commit(committerName: 'The CTO'),
        ], person),
        contains('committed by The CTO <7+bo@users.noreply.github.com>'),
      );
    });

    test('a name is compared exactly as git wrote it', () {
      // A forge shows what surrounds the name too; only the run's own name,
      // byte for byte, is the run's.
      for (final name in ['Bo\u00a0', '\u00a0Bo', 'Bo \u200b', 'bo']) {
        expect(
          PushedCommitInspector.violation([commit(authorName: name)], person),
          contains('this run authors as Bo'),
          reason: name.codeUnits.toString(),
        );
        expect(
          PushedCommitInspector.violation([
            commit(committerName: name),
          ], person),
          contains('this run commits as Bo'),
          reason: name.codeUnits.toString(),
        );
      }
    });

    test('a refused identity says the commit is somebody else\'s to '
        'publish', () {
      expect(
        PushedCommitInspector.violation([
          commit(author: 'ada@example.com', authorName: 'Ada'),
        ], person),
        allOf(
          contains('A run pushes only its own commits'),
          contains('do not re-create it under another name'),
        ),
      );
    });

    test('without a signing key every signed commit is refused', () {
      for (final identity in [person, automation]) {
        final object = identity.isPerson
            ? commit(signed: true, signedBy: key)
            : agentCommit(signed: true);
        expect(
          PushedCommitInspector.violation([object], identity),
          allOf(contains('is signed'), contains('are not signed')),
        );
      }
    });

    test('with a signing key every commit carries a valid signature by '
        'exactly that key', () {
      final signing = AgentCommitIdentity.person(
        bo,
        creditAgent: true,
        signingKey: key,
      );
      expect(
        PushedCommitInspector.violation([
          commit(signed: true, signedBy: key),
        ], signing),
        isNull,
      );
      expect(
        PushedCommitInspector.violation([commit()], signing),
        contains('is not signed; this run signs its commits'),
      );
      // Another key, or a signature that does not verify (signedBy null).
      for (final by in [otherKey, null]) {
        expect(
          PushedCommitInspector.violation([
            commit(signed: true, signedBy: by),
          ], signing),
          contains('is not signed with the key of the person who asked'),
          reason: '$by',
        );
      }
    });

    test('a commit without the run\'s co-author line is refused', () {
      expect(
        PushedCommitInspector.violation([commit(coAuthors: const [])], person),
        allOf(contains('does not carry'), contains(ccTrailer)),
      );
    });

    test('a co-author line counts only where git reads trailers', () {
      // In the body, or in a last paragraph that is not all trailers, the
      // line credits nobody on a forge: the run's credit is missing.
      expect(
        PushedCommitInspector.violation([commit(credited: const [])], person),
        allOf(
          contains('where git reads it'),
          contains('blank line followed by exactly "$ccTrailer"'),
        ),
      );
      // Twice as a trailer is still only the run's own credit...
      expect(
        PushedCommitInspector.violation([
          commit(coAuthors: const [ccTrailer, ccTrailer]),
        ], person),
        isNull,
      );
      // ...but a trailer does not excuse a copy that is not one.
      expect(
        PushedCommitInspector.violation([
          commit(
            coAuthors: const [ccTrailer, ccTrailer],
            credited: const [ccTrailer],
          ),
        ], person),
        contains('where git reads it'),
      );
    });

    test('with attribution off a person\'s commits credit nobody', () {
      final uncredited = AgentCommitIdentity.person(bo);
      expect(
        PushedCommitInspector.violation([
          commit(coAuthors: const []),
        ], uncredited),
        isNull,
      );
      expect(
        PushedCommitInspector.violation([commit()], uncredited),
        contains('this run credits no co-author'),
      );
    });

    test('the co-author line matches case-insensitively, whitespace '
        'collapsed', () {
      expect(
        PushedCommitInspector.violation([
          commit(
            coAuthors: const [
              'co-authored-by:   Control  Center <HI@usectrl.dev>',
            ],
          ),
        ], person),
        isNull,
      );
    });

    test('any other co-author line is refused, in any case', () {
      for (final foreign in const [
        'co-authored-by: Eve <eve@example.com>',
        'CO-AUTHORED-BY: Eve <eve@example.com>',
        'Co-Authored-By: Claude <noreply@anthropic.com>',
      ]) {
        expect(
          PushedCommitInspector.violation([
            commit(coAuthors: [ccTrailer, foreign]),
          ], person),
          allOf(contains('credits "$foreign"'), contains(ccTrailer)),
          reason: foreign,
        );
      }
    });

    test('Signed-off-by is refused', () {
      expect(
        PushedCommitInspector.violation([commit(signedOff: true)], person),
        contains('Signed-off-by'),
      );
    });

    test('a run nobody asked for is the agent throughout and credits '
        'exactly the people accountable for it', () {
      expect(
        PushedCommitInspector.violation([agentCommit()], automation),
        isNull,
      );
      expect(
        PushedCommitInspector.violation([
          agentCommit(author: 'ada@example.com'),
        ], automation),
        isNotNull,
      );
      expect(
        PushedCommitInspector.violation([
          agentCommit(
            coAuthors: const [
              'Co-Authored-By: Bo <${'7+bo@users.noreply.github.com'}>',
            ],
          ),
        ], automation),
        contains('this run credits no co-author'),
      );

      const cy = (name: 'Cy', email: '8+cy@users.noreply.github.com');
      final armed = AgentCommitIdentity.automation(accountable: [bo, cy]);
      final trailers = armed.coAuthorTrailers;
      expect(
        PushedCommitInspector.violation([
          agentCommit(coAuthors: trailers.reversed.toList()),
        ], armed),
        isNull,
        reason: 'order does not matter',
      );
      expect(
        PushedCommitInspector.violation([
          agentCommit(coAuthors: [trailers.first]),
        ], armed),
        allOf(contains('does not carry'), contains(trailers.last)),
      );
    });

    test('a commit that declares another encoding is refused', () {
      expect(
        PushedCommitInspector.violation([commit(encoding: 'UTF-16LE')], person),
        contains('declares the encoding "UTF-16LE"'),
      );
      for (final utf8 in ['UTF-8', 'utf8']) {
        expect(
          PushedCommitInspector.violation([commit(encoding: utf8)], person),
          isNull,
        );
      }
    });

    test('a push for several runs needs every commit to keep one of their '
        'rules, and with none no commit passes', () {
      final uncredited = AgentCommitIdentity.person(bo);
      expect(
        PushedCommitInspector.violationOfAny(
          [commit(), commit(coAuthors: const [])],
          [person, uncredited],
        ),
        isNull,
      );
      expect(
        PushedCommitInspector.violationOfAny([agentCommit()], [person]),
        contains('this run commits as'),
      );
      expect(
        PushedCommitInspector.violationOfAny([commit()], const []),
        contains('no commit identity'),
      );
      expect(PushedCommitInspector.violationOfAny(const [], const []), isNull);
    });

    test('a person\'s push holds only agent-authored commits to the agent '
        'rule', () {
      const agents = [AgentCommitIdentity.controlCenter];
      // The person's own commit, signed or not, whoever it credits.
      expect(
        PushedCommitInspector.agentObjectViolation([
          commit(signed: true, signedBy: key, signedOff: true),
        ], agents),
        isNull,
      );
      // A well-formed agent commit, whoever it credits.
      expect(
        PushedCommitInspector.agentObjectViolation([
          agentCommit(coAuthors: const ['Co-Authored-By: Bo <bo@x>']),
        ], agents),
        isNull,
      );
      // Claiming the agent by name alone still makes it agent work.
      expect(
        PushedCommitInspector.agentObjectViolation([
          agentCommit(author: 'cto@corp.com'),
        ], agents),
        contains('authored by $ccName <cto@corp.com>'),
      );
      expect(
        PushedCommitInspector.agentObjectViolation([
          agentCommit(signedOff: true),
        ], agents),
        contains('Signed-off-by'),
      );
      expect(
        PushedCommitInspector.agentObjectViolation([
          agentCommit(signed: true),
        ], agents),
        contains('is signed'),
      );
      expect(
        PushedCommitInspector.agentObjectViolation([
          agentCommit(committer: 'cto@corp.com', committerName: 'CTO'),
        ], agents),
        contains('committed by CTO <cto@corp.com>'),
      );
    });

    test('a tag names the run as tagger, needs no co-author line and is '
        'never signed', () {
      const tag = PushedGitObject(
        kind: 'tag',
        oid: 't1',
        committerName: 'Bo',
        committerEmail: '7+bo@users.noreply.github.com',
        signed: false,
        signedOff: false,
      );
      expect(PushedCommitInspector.violation([tag], person), isNull);
      const signedTag = PushedGitObject(
        kind: 'tag',
        oid: 't2',
        committerName: 'Bo',
        committerEmail: '7+bo@users.noreply.github.com',
        signed: true,
        signedOff: false,
      );
      for (final identity in [
        person,
        AgentCommitIdentity.person(bo, creditAgent: true, signingKey: key),
      ]) {
        expect(
          PushedCommitInspector.violation([signedTag], identity),
          contains('tags here are never signed'),
        );
      }
    });
  });
}
