import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/environment_ops.dart';
import 'package:cc_server_core/src/catalog/owned_terminal_access.dart';
import 'package:cc_server_core/src/catalog/terminal_watch_queries.dart';
import 'package:test/test.dart';

/// A reader of an environment learns, from the stream they already open,
/// whether they may operate it: `can_drive` first on `terminal.output` for its
/// start or process terminal, `can_operate` on every `environment.watch`
/// frame. Both come from the right `terminal.write` and
/// `environment.ensure` enforce, so a control the client enables is one
/// the server accepts.
void main() {
  late _Members members;
  late _Terminals terminals;

  setUp(() {
    members = _Members()
      ..add('reader', WorkspaceRole.member, {
        'repo-a': RepoGrantLevel.read,
        'repo-b': RepoGrantLevel.read,
      })
      ..add('writer', WorkspaceRole.member, {
        'repo-a': RepoGrantLevel.write,
        'repo-b': RepoGrantLevel.write,
      })
      ..add('admin', WorkspaceRole.admin, const {});
    terminals = _Terminals();
    addTearDown(terminals.close);
  });

  Future<List<String>> exposed(RepoOpContext ctx) async {
    expect(ctx.args['space_id'], 'space-1');
    return const ['repo-a', 'repo-b'];
  }

  Future<void> forgeReads({
    required String workspaceId,
    required String userId,
    required String repoId,
  }) async {}

  Future<void> spaceOwned(
    String workspaceId,
    String spaceId,
    String userId,
  ) async {
    if (workspaceId != 'ws-1') {
      throw const WorkspaceMismatchException('Not this workspace');
    }
    if (userId == 'stranger') {
      throw const AuthException(
        'This space exposes a repository you cannot read.',
      );
    }
  }

  WatchQueryContext watchCtx(String userId, Map<String, dynamic> args) =>
      WatchQueryContext(
        args: args,
        workspaceId: 'ws-1',
        deviceId: 'device-1',
        userId: userId,
      );

  group('terminal.output', () {
    late WatchQuery output;

    setUp(() {
      output = buildTerminalWatchQueries(
        terminals,
        mayDrive: (ctx) => mayDriveTerminal(
          ctx,
          sessionId: ctx.args['session_id'] as String,
          terminals: terminals,
          members: members,
          reposExposedBySpace: exposed,
          requireRepoForgeRead: forgeReads,
          assertSpaceOwned: spaceOwned,
        ),
        requireView: (ctx) => requireTerminalView(
          ctx,
          terminals: terminals,
          assertSpaceOwned: spaceOwned,
        ),
      ).singleWhere((query) => query.name == 'terminal.output');
    });

    Future<Map<String, dynamic>> firstFrame(String userId) =>
        output.handler(watchCtx(userId, const {'session_id': 'setup-1'})).first;

    test('a member with read-only grants may not drive it', () async {
      expect(await firstFrame('reader'), {'can_drive': false});
    });

    test('a writer and an admin may', () async {
      expect(await firstFrame('writer'), {'can_drive': true});
      expect(await firstFrame('admin'), {'can_drive': true});
    });

    test('a member who may not read its space sees none of it', () async {
      await expectLater(firstFrame('stranger'), throwsA(isA<AuthException>()));
      expect(terminals.opened, isEmpty);
    });

    test("a person's own terminal is theirs to drive", () async {
      terminals.owned = null;
      expect(await firstFrame('reader'), {'can_drive': true});
    });

    test('bytes printed while the right is asked arrive after it', () async {
      final gate = Completer<void>();
      final frames = <Map<String, dynamic>>[];
      final done = Completer<void>();
      final query = buildTerminalWatchQueries(
        terminals,
        mayDrive: (ctx) async {
          await gate.future;
          return false;
        },
        requireView: (ctx) => requireTerminalView(
          ctx,
          terminals: terminals,
          assertSpaceOwned: spaceOwned,
        ),
      ).singleWhere((query) => query.name == 'terminal.output');
      final subscription = query
          .handler(watchCtx('reader', const {'session_id': 'setup-1'}))
          .listen(frames.add, onDone: done.complete);
      await Future<void>.delayed(Duration.zero);
      terminals.bytes.add(utf8.encode('npm install'));
      gate.complete();
      await Future<void>.delayed(Duration.zero);
      await terminals.close();
      await done.future;
      await subscription.cancel();
      expect(frames, [
        {'can_drive': false},
        {'chunk': base64Encode(utf8.encode('npm install'))},
      ]);
    });
  });

  group('environment.watch', () {
    late WatchQuery watch;

    setUp(() {
      watch = buildEnvironmentWatchQueries(
        environments: _Environments(),
        reposExposedBySpace: exposed,
        requireRepoReadGrant: forgeReads,
        assertSpaceOwned: spaceOwned,
        mayOperate: (ctx, spaceId) => mayOperateEnvironment(
          ctx,
          spaceId: spaceId,
          members: members,
          reposExposedBySpace: exposed,
          requireRepoForgeRead: forgeReads,
          assertSpaceOwned: spaceOwned,
        ),
      ).singleWhere((query) => query.name == 'environment.watch');
    });

    Future<Object?> canOperate(String userId) async => (await watch
        .handler(watchCtx(userId, const {'space_id': 'space-1'}))
        .first)['can_operate'];

    test('a member with read-only grants may not operate it', () async {
      expect(await canOperate('reader'), isFalse);
    });

    test('a writer and an admin may', () async {
      expect(await canOperate('writer'), isTrue);
      expect(await canOperate('admin'), isTrue);
    });
  });
}

class _Terminals with _Unused implements TerminalSessionPort {
  ({String? spaceId})? owned = (spaceId: 'space-1');
  final bytes = StreamController<List<int>>.broadcast();
  final opened = <String>[];

  Future<void> close() => bytes.close();

  @override
  ({String? spaceId})? ownedSessionOf(String sessionId) => owned;

  @override
  Stream<List<int>> output({
    required String workspaceId,
    required String userId,
    required String sessionId,
  }) {
    opened.add(userId);
    return bytes.stream;
  }
}

class _Environments with _Unused implements EnvironmentPort {
  @override
  Stream<List<SpaceEnvironment>> watch(String workspaceId, String spaceId) =>
      Stream.value(const []);
}

class _Members with _Unused implements WorkspaceMembershipRepository {
  final _roles = <String, WorkspaceRole>{};
  final _grants = <String, Map<String, RepoGrantLevel>>{};

  void add(String userId, WorkspaceRole role, Map<String, RepoGrantLevel> g) {
    _roles[userId] = role;
    _grants[userId] = g;
  }

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async {
    final role = _roles[userId];
    return role == null
        ? null
        : WorkspaceMember(
            id: 'm-$userId',
            workspaceId: workspaceId,
            userId: userId,
            role: role,
            joinedAt: DateTime(2026),
          );
  }

  @override
  Future<Map<String, RepoGrantLevel>> getRepoGrants(
    String workspaceId,
    String userId,
  ) async => _grants[userId] ?? const {};
}

mixin _Unused {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
