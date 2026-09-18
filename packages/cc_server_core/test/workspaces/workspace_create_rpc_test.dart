import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/workspaces/workspace_create_rpc.dart';
import 'package:test/test.dart';

void main() {
  late _FakeWorkspaces workspaces;
  late _FakeMembers members;
  late RepoOp create;

  setUp(() {
    workspaces = _FakeWorkspaces();
    members = _FakeMembers();
    create = buildWorkspaceCreateOps(
      workspaceRepository: workspaces,
      identityMembers: members,
      eventBus: DomainEventBus(),
    ).singleWhere((o) => o.name == 'workspace.create');
  });

  test('mints a workspace and records the caller as owner', () async {
    final data = await create.handler(
      const RepoOpContext(
        args: {'name': '  Alpha  '},
        workspaceId: null,
        deviceId: 'dev-1',
        userId: 'user-1',
      ),
    );
    final wire = data['workspace'] as Map;
    expect(wire['name'], 'Alpha');
    expect(wire['id'], isNotEmpty);
    expect(workspaces.store, hasLength(1));
    final stored = workspaces.store.values.single;
    expect(stored.ownerUserId, 'user-1');
    expect(members.rows, hasLength(1));
    expect(members.rows.single.userId, 'user-1');
    expect(members.rows.single.role, WorkspaceRole.owner);
  });
}

class _FakeWorkspaces implements WorkspaceRepository {
  final Map<String, Workspace> store = {};

  @override
  Future<String> upsert(Workspace workspace) async {
    store[workspace.id] = workspace;
    return workspace.id;
  }

  @override
  Future<Workspace?> getById(String id) async => store[id];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMembers implements WorkspaceMembershipRepository {
  final List<WorkspaceMember> rows = [];

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async {
    for (final m in rows) {
      if (m.workspaceId == workspaceId && m.userId == userId) {
        return m;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(WorkspaceMember member) async {
    rows.add(member);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
