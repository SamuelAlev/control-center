import 'dart:io';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_server_core/src/space_stack_push.dart';
import 'package:test/test.dart';

/// A stack push is the agent's work pushed from the server, outside the push
/// gateway: every commit it sends is inspected first, and nothing the agent
/// controls in the checkout (its refs, its remote, its config) decides what
/// is sent, where, or what counts as already published.
void main() {
  late Directory scratch;
  late String work;
  late String origin;
  late Map<String, String> env;
  late StackLayerPusher pusher;

  // Ada asked for the run, attribution on: its commits are hers, crediting
  // Control Center.
  const ada = (name: 'Ada', email: '7+ada@users.noreply.github.com');
  final requester = AgentCommitIdentity.person(ada, creditAgent: true);
  final repo = Repo(
    id: 'repo-1',
    name: 'app',
    path: '/src/app',
    forge: ForgeHost.github,
    remoteOwner: 'acme',
    remoteName: 'app',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  /// Every `git fetch` the pusher ran, with how many objects the scratch
  /// repository held right after it.
  late List<({List<String> args, int objects})> fetches;

  Future<({int exitCode, String stdout, String stderr})> plain(
    String cwd,
    List<String> args, {
    Map<String, String>? environment,
    String? stdin,
  }) async {
    final process = await Process.start(
      'git',
      args,
      workingDirectory: cwd,
      environment: {...env, ...?environment},
    );
    final out = process.stdout.transform(systemEncoding.decoder).join();
    final err = process.stderr.transform(systemEncoding.decoder).join();
    if (stdin != null) {
      process.stdin.write(stdin);
    }
    await process.stdin.close();
    return (
      exitCode: await process.exitCode,
      stdout: await out,
      stderr: await err,
    );
  }

  /// The pusher's git, as the server runs it: server-run git never lists an
  /// alternate's refs (`IsolatedGit` empties `core.alternateRefsCommand`).
  Future<({int exitCode, String stdout, String stderr})> run(
    String cwd,
    List<String> args, {
    Map<String, String>? environment,
    String? stdin,
  }) async {
    final r = await plain(
      cwd,
      ['-c', 'core.alternateRefsCommand=', ...args],
      environment: environment,
      stdin: stdin,
    );
    if (args.first == 'fetch') {
      final counted = await plain(cwd, ['count-objects', '-v']);
      var objects = 0;
      for (final line in counted.stdout.split('\n')) {
        if (line.split(': ') case [
          final key,
          final value,
        ] when key == 'count' || key == 'in-pack') {
          objects += int.parse(value);
        }
      }
      fetches.add((args: args, objects: objects));
    }
    return r;
  }

  Future<String> git(String cwd, List<String> args) async {
    final r = await run(cwd, args);
    expect(r.exitCode, 0, reason: '${args.join(' ')}: ${r.stderr}');
    return r.stdout.trim();
  }

  /// Commits a new file on the checkout's current branch as [author] (and
  /// [committer], [author] by default) with [message].
  Future<String> commit(
    GitPerson author,
    String message, {
    GitPerson? committer,
  }) async {
    final name = 'f${DateTime.now().microsecondsSinceEpoch}.txt';
    File('$work/$name').writeAsStringSync(message);
    await git(work, ['add', name]);
    final by = committer ?? author;
    final r = await run(
      work,
      ['commit', '--quiet', '--no-gpg-sign', '-m', message],
      environment: {
        'GIT_AUTHOR_NAME': author.name,
        'GIT_AUTHOR_EMAIL': author.email,
        'GIT_COMMITTER_NAME': by.name,
        'GIT_COMMITTER_EMAIL': by.email,
      },
    );
    expect(r.exitCode, 0, reason: r.stderr);
    return git(work, ['rev-parse', 'HEAD']);
  }

  Future<String?> remoteTip(String bare, String branch) async {
    final r = await run(bare, ['rev-parse', '--verify', '--quiet', branch]);
    return r.exitCode == 0 ? r.stdout.trim() : null;
  }

  Future<StackPushSession> open() async {
    final (:session, :error) = await pusher.open(
      root: work,
      repo: repo,
      auth: const {},
    );
    expect(error, isNull);
    return session!;
  }

  /// Pushes [branch] in a session of its own.
  Future<String?> push({
    StackPushRule? rule,
    String branch = 'feature',
    bool force = false,
  }) async {
    final session = await open();
    try {
      return await session.push(
        branch: branch,
        force: force,
        rule: rule ?? AgentRunStackPush([requester]),
      );
    } finally {
      await session.close();
    }
  }

  const agent = AgentCommitIdentity.controlCenter;
  const human = (name: 'Stack', email: 'stack@example.com');
  const cto = (name: 'The CTO', email: 'cto@corp.com');
  final trailer = '\n\n${requester.coAuthorTrailers.single}';

  setUp(() async {
    fetches = [];
    scratch = await Directory.systemTemp.createTemp('cc-stack-push-test-');
    final global = File('${scratch.path}/gitconfig')..writeAsStringSync('');
    env = {'GIT_CONFIG_GLOBAL': global.path, 'GIT_CONFIG_NOSYSTEM': '1'};
    work = '${scratch.path}/work';
    origin = '${scratch.path}/origin.git';
    Directory(work).createSync();
    await git(scratch.path, [
      'init',
      '--quiet',
      '--bare',
      '-b',
      'main',
      origin,
    ]);
    await git(work, ['init', '--quiet', '-b', 'main']);
    await git(work, ['remote', 'add', 'origin', origin]);
    await commit(human, 'base');
    await git(work, ['push', '--quiet', 'origin', 'main']);
    await git(work, ['switch', '--quiet', '-c', 'feature']);
    pusher = StackLayerPusher(git: run, remoteUrl: (_) => origin);
  });

  tearDown(() => scratch.delete(recursive: true));

  test('an agent run pushes its requester\'s well-formed commits; what the '
      'remote already has is not inspected again', () async {
    final tip = await commit(ada, 'agent work$trailer');

    expect(await push(), isNull);
    expect(await remoteTip(origin, 'feature'), tip);
    // What `push -u origin` would have recorded in the checkout.
    expect(await git(work, ['rev-parse', 'origin/feature']), tip);
  });

  test('an agent run cannot push a commit naming someone else', () async {
    await commit(cto, 'forged$trailer', committer: ada);

    final refused = await push();

    expect(refused, contains('did not push feature'));
    expect(refused, contains('authored by The CTO <cto@corp.com>'));
    expect(await remoteTip(origin, 'feature'), isNull);
  });

  test('a sign-off, a borrowed co-author or a dropped credit is '
      'refused', () async {
    for (final (message, reason) in [
      ('signed$trailer\nSigned-off-by: Legal <legal@corp.com>', 'Signed-off'),
      ('borrowed$trailer\nCo-authored-by: Eve <eve@x.dev>', 'Eve'),
      ('no credit', 'does not carry'),
    ]) {
      await git(work, ['reset', '--quiet', '--hard', 'main']);
      await commit(ada, message);
      expect(await push(), contains(reason), reason: message);
    }
    expect(await remoteTip(origin, 'feature'), isNull);
  });

  test('a forged remote-tracking ref in the checkout hides nothing', () async {
    final forged = await commit(cto, 'forged$trailer', committer: ada);
    // The agent claims the remote already has it.
    await git(work, ['update-ref', 'refs/remotes/origin/feature', forged]);
    await git(work, ['update-ref', 'refs/remotes/origin/main', forged]);

    expect(await push(), contains('authored by The CTO'));
    expect(await remoteTip(origin, 'feature'), isNull);
  });

  test(
    'the checkout\'s remote and config never pick the destination',
    () async {
      final decoy = '${scratch.path}/decoy.git';
      await git(scratch.path, ['init', '--quiet', '--bare', decoy]);
      await git(work, ['remote', 'set-url', 'origin', decoy]);
      await git(work, ['config', 'remote.origin.pushurl', decoy]);
      await git(work, ['config', 'url.$decoy.insteadOf', origin]);
      final tip = await commit(ada, 'agent work$trailer');

      expect(await push(), isNull);
      expect(await remoteTip(origin, 'feature'), tip);
      expect(await remoteTip(decoy, 'feature'), isNull);
    },
  );

  test('a branch that points at a tag object is refused', () async {
    await commit(ada, 'agent work$trailer');
    await git(work, [
      '-c',
      'user.name=Agent',
      '-c',
      'user.email=a@x.dev',
      'tag',
      '-a',
      'v1',
      '-m',
      'tag',
    ]);
    final tag = await git(work, ['rev-parse', 'v1']);
    // git refuses this through update-ref; an agent just writes the file.
    File('$work/.git/refs/heads/tagged').writeAsStringSync('$tag\n');

    expect(
      await push(branch: 'tagged'),
      contains('does not point at a commit'),
    );
    expect(await remoteTip(origin, 'tagged'), isNull);
  });

  test('a person publishes their own commits; only commits authored as the '
      'agent are held to the agent rule', () async {
    const rule = PersonStackPush([agent]);
    // Their own commit, signed off or not, is theirs.
    await commit(human, 'mine\n\nSigned-off-by: Stack <stack@example.com>');
    // An automation's commit: the agent's, crediting whoever armed it.
    final tip = await commit(
      agent,
      'agent work\n\nCo-Authored-By: Stack <stack@example.com>',
    );

    expect(await push(rule: rule), isNull);
    expect(await remoteTip(origin, 'feature'), tip);

    await commit(agent, 'agent signs off\n\nSigned-off-by: Legal <l@corp.com>');
    expect(await push(rule: rule), contains('Signed-off-by'));
    expect(await remoteTip(origin, 'feature'), tip);
  });
  test('the fetch tells the remote what the checkout already has, so it '
      'sends only what is new', () async {
    for (var i = 0; i < 30; i++) {
      await commit(human, 'history $i');
    }
    await git(work, ['push', '--quiet', 'origin', 'feature:main']);
    // A colleague's branch the checkout has never seen: one new commit.
    final colleague = '${scratch.path}/colleague';
    await git(scratch.path, ['clone', '--quiet', origin, colleague]);
    File('$colleague/theirs.txt').writeAsStringSync('theirs');
    await git(colleague, ['add', 'theirs.txt']);
    final r = await run(
      colleague,
      ['commit', '--quiet', '--no-gpg-sign', '-m', 'theirs'],
      environment: {
        'GIT_AUTHOR_NAME': cto.name,
        'GIT_AUTHOR_EMAIL': cto.email,
        'GIT_COMMITTER_NAME': cto.name,
        'GIT_COMMITTER_EMAIL': cto.email,
      },
    );
    expect(r.exitCode, 0, reason: r.stderr);
    await git(colleague, ['push', '--quiet', 'origin', 'HEAD:colleague']);
    await commit(ada, 'agent work$trailer');

    expect(await push(), isNull);

    // The colleague's commit, its tree and its file; not the 31 commits of
    // history (93 objects) the checkout already holds.
    expect(fetches.single.objects, lessThanOrEqualTo(3));
  });

  test('every layer of a publish shares one read of the remote; a lower '
      'layer just pushed is not inspected again', () async {
    final lower = await commit(ada, 'lower$trailer');
    await git(work, ['switch', '--quiet', '-c', 'upper']);
    final upper = await commit(ada, 'upper$trailer');
    final session = await open();
    try {
      final rule = AgentRunStackPush([requester]);
      expect(
        await session.push(branch: 'feature', force: false, rule: rule),
        isNull,
      );
      expect(
        await session.push(branch: 'upper', force: false, rule: rule),
        isNull,
      );
    } finally {
      await session.close();
    }
    expect(fetches, hasLength(1));
    expect(await remoteTip(origin, 'feature'), lower);
    expect(await remoteTip(origin, 'upper'), upper);
  });

  test('a checkout ref whose object is missing does not stop the '
      'push', () async {
    final tip = await commit(ada, 'agent work$trailer');
    File('$work/.git/refs/heads/broken').writeAsStringSync('${'0' * 39}1\n');

    expect(await push(), isNull);
    expect(await remoteTip(origin, 'feature'), tip);
  });

  test('a stalled transfer is given up on, not waited on forever', () async {
    final seen = <Map<String, String>?>[];
    pusher = StackLayerPusher(
      git: (cwd, args, {environment, stdin}) {
        if (args.first == 'fetch' || args.first == 'push') {
          seen.add(environment);
        }
        return run(cwd, args, environment: environment, stdin: stdin);
      },
      remoteUrl: (_) => origin,
    );
    await commit(ada, 'agent work$trailer');

    expect(await push(), isNull);
    expect(seen, hasLength(2));
    for (final environment in seen) {
      expect(environment, containsPair('GIT_HTTP_LOW_SPEED_LIMIT', '1'));
      expect(environment, containsPair('GIT_HTTP_LOW_SPEED_TIME', '120'));
    }
  });
}
