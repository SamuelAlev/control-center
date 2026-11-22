import 'dart:io';

import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_infra/src/dispatch/worktree_fingerprints.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  late String repo;
  late WorktreeFingerprints fingerprints;

  void git(List<String> args, {String? dir}) {
    final result = Process.runSync('git', [
      '-c',
      'user.name=Test',
      '-c',
      'user.email=test@example.invalid',
      '-c',
      'commit.gpgsign=false',
      ...args,
    ], workingDirectory: dir ?? repo);
    if (result.exitCode != 0) {
      fail('git ${args.join(' ')}: ${result.stderr}');
    }
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('worktree-fingerprint-');
    repo = p.join(root.path, 'spaces', 'space-1', 'repos', 'app');
    Directory(repo).createSync(recursive: true);
    git(['init', '-q']);
    File(p.join(repo, 'a.txt')).writeAsStringSync('one\n');
    git(['add', '.']);
    git(['commit', '-q', '-m', 'first']);
    fingerprints = WorktreeFingerprints(
      conversations: _Conversations(),
      filesystem: _Filesystem(root.path),
    );
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<String?> current({String workspaceId = 'ws-1'}) => fingerprints
      .fingerprint(workspaceId: workspaceId, conversationId: 'conv-1');

  test('equal while nothing changed', () async {
    final first = await current();
    expect(first, isNotNull);
    expect(await current(), first);
  });

  test('different after an edit', () async {
    final before = await current();
    File(p.join(repo, 'a.txt')).writeAsStringSync('two\n');
    final edited = await current();
    expect(edited, isNot(before));
    // A second edit to an already-dirty file still moves it.
    File(p.join(repo, 'a.txt')).writeAsStringSync('three, longer\n');
    expect(await current(), isNot(edited));
  });

  test('different after a commit', () async {
    File(p.join(repo, 'a.txt')).writeAsStringSync('two\n');
    final dirty = await current();
    git(['commit', '-q', '-am', 'second']);
    final committed = await current();
    expect(committed, isNot(dirty));
    git(['commit', '-q', '--allow-empty', '-m', 'third']);
    expect(await current(), isNot(committed));
  });

  test('different after an untracked file, also in a new directory', () async {
    final before = await current();
    Directory(p.join(repo, 'new')).createSync();
    File(p.join(repo, 'new', 'b.txt')).writeAsStringSync('b');
    final untracked = await current();
    expect(untracked, isNot(before));
    File(p.join(repo, 'new', 'c.txt')).writeAsStringSync('c');
    expect(await current(), isNot(untracked));
  });

  test(
    'several worktrees fold into one; a change in either moves it',
    () async {
      final second = p.join(p.dirname(repo), 'lib');
      Directory(second).createSync();
      git(['init', '-q'], dir: second);
      final both = await current();
      expect(both, isNotNull);
      expect(await current(), both);
      File(p.join(second, 'x.txt')).writeAsStringSync('x');
      expect(await current(), isNot(both));
    },
  );

  test('null: no worktree, not a git tree, or a foreign workspace', () async {
    expect(await current(workspaceId: 'ws-other'), isNull);
    Directory(p.join(p.dirname(repo), 'plain')).createSync();
    expect(await current(), isNull, reason: 'one checkout is not a git tree');
    Directory(p.dirname(repo)).deleteSync(recursive: true);
    expect(await current(), isNull);
  });
}

class _Conversations implements ConversationRepository {
  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async => workspaceId == 'ws-1' && conversationId == 'conv-1'
      ? Conversation(
          id: 'conv-1',
          workspaceId: 'ws-1',
          spaceId: 'space-1',
          title: 'c',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        )
      : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Filesystem implements WorkspaceFilesystemPort {
  _Filesystem(this.root);

  final String root;

  @override
  Future<String> spaceDir(String workspaceId, String spaceId) async =>
      p.join(root, 'spaces', spaceId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
