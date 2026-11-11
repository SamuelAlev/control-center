import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/ports/commit_signing_port.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
// ignore: implementation_imports
import 'package:cc_infra/src/dispatch/pushed_commit_inspector.dart';
// ignore: implementation_imports
import 'package:cc_infra/src/git/ssh_commit_signature.dart';
import 'package:cc_server_core/src/commit_resigner.dart';
import 'package:test/test.dart';

class _Signing implements CommitSigningPort {
  _Signing(this.keys, {this.failAt});

  final Map<String, SshSigningKey> keys;
  int signatures = 0;

  /// The signature (1-based) that throws, as a key deleted mid-range would.
  final int? failAt;

  @override
  Future<String?> publicKeyOf(String userId) async => keys[userId]?.publicKey;

  @override
  Future<String> sign(String userId, String publicKey, List<int> commit) async {
    final key = keys[userId];
    if (key == null || key.publicKey != publicKey || signatures + 1 == failAt) {
      throw const CommitSigningUnavailable('no key.');
    }
    signatures++;
    return key.sign(commit);
  }
}

final bool _hasSshKeygen = () {
  try {
    return Process.runSync('ssh-keygen', ['-Y', 'sign']).exitCode != 127;
  } on ProcessException {
    return false;
  }
}();

void main() {
  const ada = (name: 'Ada', email: '7+ada@users.noreply.github.com');
  const bot = AgentCommitIdentity.controlCenter;
  late Directory scratch;
  late String repo;
  late Map<String, String> env;
  late SshSigningKey key;
  late _Signing signing;
  late CommitResigner resigner;
  late AgentCommitIdentity identity;

  Future<String> git(
    List<String> args, {
    GitPerson? as,
    GitPerson? committer,
  }) async {
    final author = as ?? ada;
    final by = committer ?? author;
    final r = await Process.run(
      'git',
      args,
      workingDirectory: repo,
      environment: {
        ...env,
        'GIT_AUTHOR_NAME': author.name,
        'GIT_AUTHOR_EMAIL': author.email,
        'GIT_COMMITTER_NAME': by.name,
        'GIT_COMMITTER_EMAIL': by.email,
      },
      includeParentEnvironment: false,
    );
    expect(r.exitCode, 0, reason: '${args.join(' ')}: ${r.stderr}');
    return '${r.stdout}'.trim();
  }

  Future<String> commit(
    String message, {
    GitPerson? as,
    GitPerson? committer,
  }) async {
    final name = 'f${DateTime.now().microsecondsSinceEpoch}.txt';
    File('$repo/$name').writeAsStringSync(message);
    await git(['add', name]);
    await git(
      ['commit', '--quiet', '-m', message],
      as: as,
      committer: committer,
    );
    return git(['rev-parse', 'HEAD']);
  }

  Future<PushedGitObject> read(String rev) async {
    final r = await Process.run(
      'git',
      ['cat-file', 'commit', rev],
      workingDirectory: repo,
      environment: env,
      includeParentEnvironment: false,
      stdoutEncoding: null,
    );
    expect(r.exitCode, 0);
    return PushedCommitInspector.read('commit', rev, r.stdout as List<int>);
  }

  setUp(() async {
    scratch = await Directory.systemTemp.createTemp('cc-resign-test-');
    repo = '${scratch.path}/repo';
    Directory(repo).createSync();
    env = {
      'PATH': Platform.environment['PATH'] ?? '/usr/bin:/bin',
      'HOME': scratch.path,
      'GIT_CONFIG_GLOBAL': (File(
        '${scratch.path}/gitconfig',
      )..writeAsStringSync('')).path,
      'GIT_CONFIG_NOSYSTEM': '1',
    };
    await git(['init', '--quiet', '-b', 'main']);
    key = await SshSigningKey.generate();
    signing = _Signing({'u-ada': key});
    resigner = CommitResigner(signing);
    identity = AgentCommitIdentity.person(ada, signingKey: key.publicKey);
  });

  tearDown(() => scratch.delete(recursive: true));

  test('HEAD is re-created signed: same tree, author, committer and message, '
      'and git still finds the repository sound', () async {
    await commit('base');
    final unsigned = await commit(
      'change\n\nCo-Authored-By: Control Center <hi@usectrl.dev>',
    );
    // The credit is this person's to carry when their attribution is on.
    identity = AgentCommitIdentity.person(
      ada,
      creditAgent: true,
      signingKey: key.publicKey,
    );
    final before = await git([
      'log',
      '-1',
      '--format=%T %an <%ae> %cn <%ce> %at %ct%n%B',
    ]);

    final signed = await resigner.sign(
      root: repo,
      userId: 'u-ada',
      identity: identity,
    );

    expect(signed, isNot(unsigned));
    expect(await git(['rev-parse', 'HEAD']), signed);
    expect(
      await git(['rev-parse', 'main']),
      signed,
      reason: 'the branch moved',
    );
    expect(
      await git(['log', '-1', '--format=%T %an <%ae> %cn <%ce> %at %ct%n%B']),
      before,
    );
    expect((await read('HEAD')).signedBy, key.publicKey);
    expect((await read('HEAD~1')).signed, isFalse, reason: 'only HEAD');
    await git(['fsck', '--strict', '--no-dangling']);
    expect(await git(['status', '--porcelain']), isEmpty);
  });

  test('git itself verifies the signature', () async {
    await commit('change');
    await resigner.sign(root: repo, userId: 'u-ada', identity: identity);
    final allowed = File('${scratch.path}/allowed')
      ..writeAsStringSync('${ada.email} namespaces="git" ${key.publicKey}\n');
    final verified = await Process.run(
      'git',
      [
        '-c',
        'gpg.format=ssh',
        '-c',
        'gpg.ssh.allowedSignersFile=${allowed.path}',
        'verify-commit',
        'HEAD',
      ],
      workingDirectory: repo,
      environment: env,
      includeParentEnvironment: false,
    );
    expect(verified.exitCode, 0, reason: '${verified.stderr}');
    expect('${verified.stderr}', contains('Good "git" signature'));
  }, skip: _hasSshKeygen ? false : 'ssh-keygen is not installed');

  test('a range is signed oldest first, commits above a re-created one are '
      're-parented, and only the person\'s own are signed', () async {
    final base = await commit('base');
    await commit('mine 1');
    await commit('the agent\'s', as: bot);
    await commit('theirs, I committed it', as: bot, committer: ada);
    await commit('mine 2');

    final head = await resigner.sign(
      root: repo,
      userId: 'u-ada',
      identity: identity,
      revisions: ['$base..HEAD'],
    );

    expect(await git(['rev-list', '--count', '$base..HEAD']), '4');
    expect(await git(['rev-parse', 'HEAD']), head);
    expect(
      await git(['log', '--format=%s', '$base..HEAD']),
      'mine 2\ntheirs, I committed it\nthe agent\'s\nmine 1',
    );
    expect((await read('HEAD')).signedBy, key.publicKey);
    // Committing someone's work (a rebase does) does not make it yours.
    expect((await read('HEAD~1')).signed, isFalse, reason: 'authored by bot');
    expect((await read('HEAD~2')).signed, isFalse, reason: "the agent's");
    expect((await read('HEAD~3')).signedBy, key.publicKey);
    expect(await git(['rev-parse', 'HEAD~4']), base, reason: 'base untouched');
    expect(signing.signatures, 2);
    expect(
      await resigner.unsignedOwn(
        root: repo,
        identity: identity,
        revisions: ['$base..HEAD'],
      ),
      isEmpty,
    );
    await git(['fsck', '--strict', '--no-dangling']);
  });

  test('a commit the push rule refuses for the person is left as it is: '
      'borrowed credit, a sign-off, or someone else\'s authorship', () async {
    const mallory = (name: 'Mallory', email: 'm@example.com');
    for (final (message, author) in [
      ('borrowed\n\nCo-authored-by: Linus <l@example.com>', ada),
      ('signed off\n\nSigned-off-by: Ada <a@example.com>', ada),
      ('hers', mallory),
    ]) {
      final before = await commit(message, as: author, committer: ada);
      expect(
        await resigner.sign(root: repo, userId: 'u-ada', identity: identity),
        before,
        reason: message,
      );
      expect((await read('HEAD')).signed, isFalse, reason: message);
    }
    expect(signing.signatures, 0);
  });

  test('a replace ref or a graft cannot change what is signed', () async {
    final base = await commit('base');
    final real = await commit('real');
    // A replacement for HEAD: someone else's commit, which git would show
    // in its place.
    await git(['checkout', '--quiet', '--detach', base]);
    final fake = await commit('fake', as: (name: 'M', email: 'm@example.com'));
    await git(['checkout', '--quiet', 'main']);
    await git(['replace', real, fake]);
    // A graft that hides the base from the range.
    final middle = await commit('middle');
    final top = await commit('top');
    File('$repo/.git/info/grafts')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('$top\n');

    await resigner.sign(
      root: repo,
      userId: 'u-ada',
      identity: identity,
      revisions: ['$base..HEAD'],
    );

    // Read the way the remote will: no replace refs, no grafts.
    final real0 = {
      ...env,
      'GIT_NO_REPLACE_OBJECTS': '1',
      'GIT_GRAFT_FILE': '/dev/null',
    };
    Future<ProcessResult> plain(List<String> args) => Process.run(
      'git',
      args,
      workingDirectory: repo,
      environment: real0,
      includeParentEnvironment: false,
      stdoutEncoding: null,
    );
    final log = await plain(['log', '--format=%H %s', '$base..HEAD']);
    final lines = const LineSplitter().convert(
      utf8.decode(log.stdout as List<int>),
    );
    expect(lines.map((l) => l.split(' ').last), ['top', 'middle', 'real']);
    for (final line in lines) {
      final oid = line.split(' ').first;
      final raw = await plain(['cat-file', 'commit', oid]);
      final object = await PushedCommitInspector.read(
        'commit',
        oid,
        raw.stdout as List<int>,
      );
      expect(object.authorName, 'Ada', reason: line);
      expect(object.signedBy, key.publicKey, reason: line);
    }
    expect(middle, isNot(fake));
  });

  test('a commit someone else signed keeps its signature, and so does every '
      'commit of the range below it', () async {
    final base = await commit('base');
    await commit('mine below');
    // Eve's commit, signed with her own key.
    const eve = (name: 'Eve', email: 'eve@example.com');
    final eveKey = await SshSigningKey.generate();
    await commit('hers', as: eve);
    await CommitResigner(_Signing({'u-eve': eveKey})).sign(
      root: repo,
      userId: 'u-eve',
      identity: AgentCommitIdentity.person(eve, signingKey: eveKey.publicKey),
    );
    final hers = await git(['rev-parse', 'HEAD']);
    await commit('mine above');

    await resigner.sign(
      root: repo,
      userId: 'u-ada',
      identity: identity,
      revisions: ['$base..HEAD'],
    );

    expect(await git(['rev-parse', 'HEAD~1']), hers, reason: 'untouched');
    expect((await read('HEAD~1')).signedBy, eveKey.publicKey);
    expect((await read('HEAD')).signedBy, key.publicKey);
    expect((await read('HEAD~2')).signed, isFalse, reason: 'below hers');
    expect(
      await resigner.unsignedOwn(
        root: repo,
        identity: identity,
        revisions: ['$base..HEAD'],
      ),
      [
        await git(['rev-parse', 'HEAD~2']),
      ],
    );
  });

  test('a signing failure half-way leaves HEAD where it was', () async {
    final base = await commit('base');
    await commit('one');
    final head = await commit('two');
    await expectLater(
      CommitResigner(_Signing({'u-ada': key}, failAt: 2)).sign(
        root: repo,
        userId: 'u-ada',
        identity: identity,
        revisions: ['$base..HEAD'],
      ),
      throwsA(isA<CommitSigningUnavailable>()),
    );
    expect(await git(['rev-parse', 'HEAD']), head);
  });

  test('signing again changes nothing', () async {
    final base = await commit('base');
    await commit('mine');
    final once = await resigner.sign(
      root: repo,
      userId: 'u-ada',
      identity: identity,
      revisions: ['$base..HEAD'],
    );
    final signatures = signing.signatures;
    final twice = await resigner.sign(
      root: repo,
      userId: 'u-ada',
      identity: identity,
      revisions: ['$base..HEAD'],
    );
    expect(twice, once);
    expect(signing.signatures, signatures);
  });

  test(
    'a key that changed or is gone signs nothing and moves nothing',
    () async {
      final head = await commit('mine');
      signing.keys['u-ada'] = await SshSigningKey.generate();
      await expectLater(
        resigner.sign(root: repo, userId: 'u-ada', identity: identity),
        throwsA(isA<CommitSigningUnavailable>()),
      );
      signing.keys.remove('u-ada');
      await expectLater(
        resigner.sign(root: repo, userId: 'u-ada', identity: identity),
        throwsA(isA<CommitSigningUnavailable>()),
      );
      expect(await git(['rev-parse', 'HEAD']), head);
    },
  );

  test('a commit message with unusual bytes survives byte for byte', () async {
    const message = 'ünïcödé ✓\n\nline with trailing spaces   \n\ttab\n';
    File('$repo/x.txt').writeAsStringSync('x');
    await git(['add', 'x.txt']);
    await git(['commit', '--quiet', '--cleanup=verbatim', '-m', message]);
    final before = await git(['log', '-1', '--format=%B']);

    await resigner.sign(root: repo, userId: 'u-ada', identity: identity);

    expect(await git(['log', '-1', '--format=%B']), before);
    expect(utf8.encode(before), isNotEmpty);
    expect((await read('HEAD')).signedBy, key.publicKey);
  });
}
