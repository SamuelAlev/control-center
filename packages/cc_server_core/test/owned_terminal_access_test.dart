import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/owned_terminal_access.dart';
import 'package:test/test.dart';

/// An environment's setup or process runs on the host, so typing into it,
/// resizing or closing it takes what starting setup in its space takes, not
/// bare membership; anyone else is answered as if it did not exist.
void main() {
  late _Members members;
  late List<String> exposed;
  late Set<String> ownedSpaces;
  late List<String> forgeChecked;

  setUp(() {
    members = _Members();
    exposed = ['repo-a', 'repo-b'];
    ownedSpaces = {'space-1'};
    forgeChecked = [];
  });

  Future<bool> drive(
    String userId, {
    ({String? spaceId})? owned = (spaceId: 'space-1'),
    bool forgeReads = true,
    bool withMembers = true,
  }) => mayDriveTerminal(
    RepoOpContext(
      args: const {'session_id': 'tty-1'},
      workspaceId: 'ws-1',
      deviceId: 'device-1',
      userId: userId,
    ),
    sessionId: 'tty-1',
    terminals: _Terminals(owned),
    members: withMembers ? members : null,
    reposExposedBySpace: (ctx) async {
      expect(ctx.args['space_id'], 'space-1');
      return exposed;
    },
    requireRepoForgeRead:
        ({required workspaceId, required userId, required repoId}) async {
          forgeChecked.add(repoId);
          if (!forgeReads) {
            throw const AuthException('no forge read');
          }
        },
    assertSpaceOwned: (workspaceId, spaceId, userId) async {
      if (!ownedSpaces.contains(spaceId)) {
        throw const NotFoundException('no such space');
      }
    },
  );

  test("a person's own terminal is left to the port", () async {
    expect(await drive('eve', owned: null, withMembers: false), isTrue);
  });

  test('a member with write on every exposed repo may', () async {
    members.add('eve', WorkspaceRole.member, {
      'repo-a': RepoGrantLevel.write,
      'repo-b': RepoGrantLevel.write,
    });
    expect(await drive('eve'), isTrue);
    expect(forgeChecked, ['repo-a', 'repo-b']);
  });

  test('an admin may without per-repo grants', () async {
    members.add('ada', WorkspaceRole.admin, const {});
    expect(await drive('ada'), isTrue);
  });

  test('read or review on one exposed repo is not enough', () async {
    members.add('eve', WorkspaceRole.member, {
      'repo-a': RepoGrantLevel.write,
      'repo-b': RepoGrantLevel.review,
    });
    expect(await drive('eve'), isFalse);
  });

  test('bare membership is not enough', () async {
    members.add('eve', WorkspaceRole.member, const {});
    expect(await drive('eve'), isFalse);
  });

  test('a non-member may not', () async {
    expect(await drive('mallory'), isFalse);
  });

  test("a space that is not the caller's refuses", () async {
    members.add('ada', WorkspaceRole.admin, const {});
    ownedSpaces.clear();
    expect(await drive('ada'), isFalse);
  });

  test('every exposed repo must be readable through the forge', () async {
    members.add('ada', WorkspaceRole.admin, const {});
    expect(await drive('ada', forgeReads: false), isFalse);
  });

  test('an owned session with no space refuses', () async {
    members.add('ada', WorkspaceRole.admin, const {});
    expect(await drive('ada', owned: (spaceId: null)), isFalse);
  });

  test('a server with no membership wiring refuses', () async {
    expect(await drive('ada', withMembers: false), isFalse);
  });
}

class _Terminals with _Unused implements TerminalSessionPort {
  _Terminals(this._owned);

  final ({String? spaceId})? _owned;

  @override
  ({String? spaceId})? ownedSessionOf(String sessionId) => _owned;
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
