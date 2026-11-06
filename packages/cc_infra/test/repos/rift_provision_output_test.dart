import 'dart:io';

import 'package:cc_domain/core/domain/ports/git_command_port.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/git/process_git_command_adapter.dart';
import 'package:cc_infra/src/repos/rift_repo_isolation_adapter.dart';
import 'package:cc_infra/src/repos/space_provisioning_log.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// What a provision reports while it works. rift has nothing to forward, so the
/// adapter narrates the copy; the fetch and the checkout are git's own output.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('cc_rift_output'));
  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  RiftRepoIsolationAdapter adapter(GitCommandPort git, RiftClient rift) =>
      RiftRepoIsolationAdapter(
        rift: rift,
        git: git,
        missingRiftIsExpected: false,
      );

  test('reports each stage in order, with git output in place', () async {
    final git = _ScriptedGit(fetchProgress: ['Receiving objects: 100%']);
    final lines = <String>[];

    await adapter(git, _DirectoryRift()).provision(
      sourcePath: '/src/shop-ui',
      destParentDir: root.path,
      name: 'shop-ui',
      branch: 'space/one',
      baseRef: 'main',
      authUrl: 'https://github.com/acme/shop-ui.git',
      onOutput: lines.add,
    );

    expect(lines, [
      'Copying /src/shop-ui (copy-on-write)',
      'Copied in 0s',
      'Fetching main',
      'Receiving objects: 100%',
      'Checking out space/one',
    ]);
    expect(git.commandsOf('fetch').single, contains('--progress'));
    expect(git.commandsOf('checkout').single, contains('--progress'));
  });

  test('says so when the fetch fails and the copy is used as is', () async {
    final git = _ScriptedGit(failFetch: true);
    final lines = <String>[];

    await adapter(git, _DirectoryRift()).provision(
      sourcePath: '/src/shop-ui',
      destParentDir: root.path,
      name: 'shop-ui',
      branch: 'space/one',
      baseRef: 'main',
      authUrl: 'https://github.com/acme/shop-ui.git',
      onOutput: lines.add,
    );

    expect(lines, contains(startsWith('Could not fetch main')));
  });

  test('asks git for no progress when nobody is reading it', () async {
    final git = _ScriptedGit();

    await adapter(git, _DirectoryRift()).provision(
      sourcePath: '/src/shop-ui',
      destParentDir: root.path,
      name: 'shop-ui',
      branch: 'space/one',
      baseRef: 'main',
      authUrl: 'https://github.com/acme/shop-ui.git',
    );

    expect(git.commandsOf('fetch').single, isNot(contains('--progress')));
    expect(git.commandsOf('checkout').single, isNot(contains('--progress')));
  });

  test('a real fetch through a pipe reaches the log as progress', () async {
    // The feature rests on this: git withholds progress from a pipe unless
    // asked, and writes it with `\r` for the log to collapse.
    final home = File(p.join(root.path, 'gitconfig'))
      ..writeAsStringSync('[user]\n\tname = T\n\temail = t@example.com\n');
    final env = {'GIT_CONFIG_GLOBAL': home.path};
    Future<void> git(String workdir, List<String> args) async {
      final result = await Process.run(
        'git',
        args,
        workingDirectory: workdir,
        environment: env,
      );
      expect(result.exitCode, 0, reason: '${result.stderr}');
    }

    final origin = Directory(p.join(root.path, 'origin'))..createSync();
    await git(origin.path, ['init', '-b', 'main']);
    for (var i = 0; i < 40; i++) {
      File(p.join(origin.path, 'file$i.txt')).writeAsStringSync('content $i\n');
    }
    await git(origin.path, ['add', '.']);
    await git(origin.path, ['commit', '-m', 'seed']);

    final log = InMemorySpaceProvisioningLog();
    final lines = <String>[];
    final subscription = log
        .follow('ws', 'space')
        .listen((line) => lines.add(line.text));
    addTearDown(subscription.cancel);

    await adapter(
      const ProcessGitCommandAdapter(),
      _EmptyRepoRift(git),
    ).provision(
      sourcePath: origin.path,
      destParentDir: p.join(root.path, 'dest'),
      name: 'copy',
      branch: 'space/one',
      baseRef: 'main',
      authUrl: 'file://${origin.path}',
      onOutput: (line) => log.write('ws', 'space', line),
    );
    await pumpEventQueue();

    final held = <String>[];
    final reader = log
        .follow('ws', 'space')
        .listen((line) => held.add(line.text));
    await pumpEventQueue();
    await reader.cancel();

    expect(lines, anyElement(contains('objects:')));
    final bars = [
      for (final line in held)
        if (RegExp(r'^(.+?):\s+\d{1,3}%').firstMatch(line) case final match?)
          match.group(1),
    ];
    expect(bars, isNotEmpty);
    expect(
      bars.toSet(),
      hasLength(bars.length),
      reason: 'each progress bar is one line, however often it moved: $held',
    );
  });
}

/// A rift that makes the destination directory and nothing more.
class _DirectoryRift implements RiftClient {
  @override
  bool get isAvailable => true;

  @override
  Future<void> init({required String at}) async {}

  @override
  Future<String> create({
    required String from,
    required String into,
    String? name,
    bool copyAll = true,
    bool hooks = false,
  }) async {
    final path = p.join(into, name ?? 'copy');
    Directory(path).createSync(recursive: true);
    return path;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A rift whose copy is a fresh repository, so a fetch has work to do.
class _EmptyRepoRift extends _DirectoryRift {
  _EmptyRepoRift(this._git);

  final Future<void> Function(String workdir, List<String> args) _git;

  @override
  Future<String> create({
    required String from,
    required String into,
    String? name,
    bool copyAll = true,
    bool hooks = false,
  }) async {
    final path = await super.create(from: from, into: into, name: name);
    await _git(path, ['init', '-b', 'scratch']);
    return path;
  }
}

class _ScriptedGit implements GitCommandPort {
  _ScriptedGit({this.fetchProgress = const [], this.failFetch = false});

  final List<String> fetchProgress;
  final bool failFetch;
  final List<List<String>> commands = [];

  /// Every git command whose verb is [verb].
  List<List<String>> commandsOf(String verb) =>
      commands.where((args) => args.contains(verb)).toList();

  @override
  Future<GitResult> run(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
    void Function(String line)? onProgress,
    CancellationToken? cancel,
  }) async {
    commands.add(args);
    if (args.contains('--show-toplevel')) {
      return GitResult(exitCode: 0, stdout: '$workdir\n', stderr: '');
    }
    if (args.contains('fetch')) {
      fetchProgress.forEach(onProgress ?? (_) {});
      if (failFetch) {
        return const GitResult(exitCode: 1, stdout: '', stderr: 'no network');
      }
    }
    return const GitResult(exitCode: 0, stdout: '', stderr: '');
  }

  @override
  Stream<String> runStreaming(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
  }) => const Stream.empty();
}
