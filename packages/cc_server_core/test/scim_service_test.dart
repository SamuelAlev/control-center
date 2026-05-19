import 'dart:io';

import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/scim_service.dart';
import 'package:test/test.dart';

void main() {
  late _Fakes fakes;
  late FileSecretsStore secrets;
  late ScimService service;

  setUp(() async {
    fakes = _Fakes();
    final dir = await Directory.systemTemp.createTemp('scim_test');
    secrets = FileSecretsStore(dataDir: dir.path);
    service = ScimService(
      verifyScimToken: (token) async => token == 'valid-token',
      users: fakes.users,
      members: fakes.members,
      devices: fakes.devices,
      secrets: secrets,
    );
  });

  test('authorize: bearer token, constant verdicts', () async {
    expect(await service.authorize(null), isFalse);
    expect(await service.authorize('Bearer wrong'), isFalse);
    expect(await service.authorize('Bearer valid-token'), isTrue);
  });

  test('create provisions + pins the SCIM externalId', () async {
    final result = await service.handle(
      method: 'POST',
      segments: ['scim', 'v2', 'Users'],
      query: const {},
      body:
          '{"userName":"dana@example.com","name":{"formatted":"Dana Doe"},'
          '"externalId":"ext-42","active":true}',
    );
    expect(result.status, 201);
    expect(result.body['userName'], 'dana@example.com');
    final user = fakes.users.byEmail['dana@example.com']!;
    expect(user.ssoIssuer, ScimService.scimIssuer);
    expect(user.ssoSubject, 'ext-42');
    expect(user.deactivatedAt, isNull);
  });

  test('create with a known email reuses the account', () async {
    await service.handle(
      method: 'POST',
      segments: ['scim', 'v2', 'Users'],
      query: const {},
      body: '{"userName":"dana@example.com","externalId":"ext-42"}',
    );
    final second = await service.handle(
      method: 'POST',
      segments: ['scim', 'v2', 'Users'],
      query: const {},
      body: '{"userName":"dana@example.com","externalId":"ext-42"}',
    );
    expect(second.status, 200); // matched, not created
    expect(fakes.users.byEmail.length, 1);
  });

  test('patch active:false deprovisions: devices, memberships, stamp',
      () async {
    final created = await service.handle(
      method: 'POST',
      segments: ['scim', 'v2', 'Users'],
      query: const {},
      body: '{"userName":"eva@example.com","externalId":"ext-e"}',
    );
    final id = created.body['id'] as String;
    fakes.members.seed(id);
    fakes.devices.seed(id, 'device-1');
    await secrets.writePsk('device-1', 'psk-1');

    final patched = await service.handle(
      method: 'PATCH',
      segments: ['scim', 'v2', 'Users', id],
      query: const {},
      body:
          '{"Operations":[{"op":"replace","path":"active","value":false}]}',
    );
    expect(patched.status, 200);
    expect(patched.body['active'], isFalse);
    // Deprovision: device row + PSK gone, membership gone.
    expect(fakes.devices.byId.containsKey('device-1'), isFalse);
    expect(await secrets.readPsk('device-1'), isNull);
    expect(
      fakes.members.all.where((m) => m.userId == id).toList(),
      isEmpty,
    );
    expect(fakes.users.byId[id]!.deactivatedAt, isNotNull);
  });

  test('DELETE deactivates without removing the row', () async {
    final created = await service.handle(
      method: 'POST',
      segments: ['scim', 'v2', 'Users'],
      query: const {},
      body: '{"userName":"felix@example.com"}',
    );
    final id = created.body['id'] as String;
    final deleted = await service.handle(
      method: 'DELETE',
      segments: ['scim', 'v2', 'Users', id],
      query: const {},
      body: null,
    );
    expect(deleted.status, 204);
    expect(fakes.users.byId.containsKey(id), isTrue); // attribution stays
    expect(fakes.users.byId[id]!.deactivatedAt, isNotNull);
  });

  test('re-creating a deactivated user with active:true reactivates, '
      'without re-granting memberships', () async {
    final created = await service.handle(
      method: 'POST',
      segments: ['scim', 'v2', 'Users'],
      query: const {},
      body: '{"userName":"gina@example.com","externalId":"ext-g"}',
    );
    final id = created.body['id'] as String;
    fakes.members.seed(id);
    await service.handle(
      method: 'PATCH',
      segments: ['scim', 'v2', 'Users', id],
      query: const {},
      body: '{"Operations":[{"op":"replace","value":{"active":false}}]}',
    );
    expect(fakes.members.all.where((m) => m.userId == id), isEmpty);

    final recreated = await service.handle(
      method: 'POST',
      segments: ['scim', 'v2', 'Users'],
      query: const {},
      body: '{"userName":"gina@example.com","externalId":"ext-g",'
          '"active":true}',
    );
    expect(recreated.status, 200);
    expect(recreated.body['active'], isTrue);
    expect(fakes.members.all.where((m) => m.userId == id), isEmpty);
  });

  test('list with userName filter', () async {
    await service.handle(
      method: 'POST',
      segments: ['scim', 'v2', 'Users'],
      query: const {},
      body: '{"userName":"hana@example.com"}',
    );
    final hit = await service.handle(
      method: 'GET',
      segments: ['scim', 'v2', 'Users'],
      query: const {'filter': 'userName eq "hana@example.com"'},
      body: null,
    );
    expect(hit.status, 200);
    expect(hit.body['totalResults'], 1);

    final miss = await service.handle(
      method: 'GET',
      segments: ['scim', 'v2', 'Users'],
      query: const {'filter': 'userName eq "nobody@example.com"'},
      body: null,
    );
    expect(miss.body['totalResults'], 0);
  });

  test('a local (non-SSO) account is invisible to the SCIM surface', () async {
    // A manually-provisioned account (no ssoIssuer) the IdP never created.
    fakes.users.byId['local-1'] = User(
      id: 'local-1',
      handle: 'owner',
      displayName: 'Owner',
      email: 'owner@example.com',
      createdAt: DateTime(2026, 1, 1),
    );
    fakes.users.byEmail['owner@example.com'] = fakes.users.byId['local-1']!;

    // Not returned by GET-by-id...
    final get = await service.handle(
      method: 'GET',
      segments: ['scim', 'v2', 'Users', 'local-1'],
      query: const {},
      body: null,
    );
    expect(get.status, 404);

    // ...nor by list/filter...
    final list = await service.handle(
      method: 'GET',
      segments: ['scim', 'v2', 'Users'],
      query: const {'filter': 'userName eq "owner@example.com"'},
      body: null,
    );
    expect(list.body['totalResults'], 0);

    // ...nor deactivatable by id.
    final del = await service.handle(
      method: 'DELETE',
      segments: ['scim', 'v2', 'Users', 'local-1'],
      query: const {},
      body: null,
    );
    expect(del.status, 404);
    expect(fakes.users.byId['local-1']!.deactivatedAt, isNull);
  });

  test('a create colliding on a local account email does not adopt it',
      () async {
    fakes.users.byId['local-1'] = User(
      id: 'local-1',
      handle: 'owner',
      displayName: 'Owner',
      email: 'owner@example.com',
      createdAt: DateTime(2026, 1, 1),
    );
    fakes.users.byEmail['owner@example.com'] = fakes.users.byId['local-1']!;

    final created = await service.handle(
      method: 'POST',
      segments: ['scim', 'v2', 'Users'],
      query: const {},
      body: '{"userName":"owner@example.com","active":false}',
    );
    // A distinct, SCIM-managed record — the local account is untouched.
    expect(created.body['id'], isNot('local-1'));
    expect(fakes.users.byId['local-1']!.deactivatedAt, isNull);
  });

  test('refuses to deactivate a workspace owner', () async {
    final created = await service.handle(
      method: 'POST',
      segments: ['scim', 'v2', 'Users'],
      query: const {},
      body: '{"userName":"boss@example.com","externalId":"ext-boss"}',
    );
    final id = created.body['id'] as String;
    fakes.members.all.add(
      WorkspaceMember(
        id: 'm-owner',
        workspaceId: 'ws-1',
        userId: id,
        role: WorkspaceRole.owner,
        joinedAt: DateTime(2026, 1, 1),
      ),
    );
    fakes.devices.seed(id, 'device-boss');
    await secrets.writePsk('device-boss', 'psk-boss');

    final patched = await service.handle(
      method: 'PATCH',
      segments: ['scim', 'v2', 'Users', id],
      query: const {},
      body: '{"Operations":[{"op":"replace","path":"active","value":false}]}',
    );
    // Denied — nothing revoked, membership intact, account still active.
    expect(patched.status, greaterThanOrEqualTo(400));
    expect(fakes.users.byId[id]!.deactivatedAt, isNull);
    expect(fakes.devices.byId.containsKey('device-boss'), isTrue);
    expect(
      fakes.members.all.any((m) => m.userId == id && m.role == WorkspaceRole.owner),
      isTrue,
    );
  });

  test('Groups push is a documented 501, reads are empty', () async {
    final read = await service.handle(
      method: 'GET',
      segments: ['scim', 'v2', 'Groups'],
      query: const {},
      body: null,
    );
    expect(read.status, 200);
    expect(read.body['totalResults'], 0);
    final push = await service.handle(
      method: 'POST',
      segments: ['scim', 'v2', 'Groups'],
      query: const {},
      body: '{"displayName":"admins"}',
    );
    expect(push.status, 501);
  });
}

class _Fakes {
  final users = _FakeUserRepository();
  final members = _FakeMembershipRepository();
  final devices = _FakeDeviceDao();
}

class _FakeUserRepository implements UserRepository {
  final byId = <String, User>{};
  final byHandle = <String, User>{};
  final byEmail = <String, User>{};

  @override
  Future<User?> getById(String id) async => byId[id];

  @override
  Future<User?> getByHandle(String handle) async => byHandle[handle];

  @override
  Future<User?> getByEmail(String email) async => byEmail[email];

  @override
  Future<User?> getBySsoSubject(String issuer, String subject) async {
    for (final user in byId.values) {
      if (user.ssoIssuer == issuer && user.ssoSubject == subject) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(User user) async {
    byId[user.id] = user;
    byHandle[user.handle] = user;
    if (user.email != null) {
      byEmail[user.email!] = user;
    }
  }

  @override
  Future<List<User>> getAll() async => byId.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<int> count() async => byId.length;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeMembershipRepository implements WorkspaceMembershipRepository {
  final all = <WorkspaceMember>[];

  void seed(String userId) {
    all.add(
      WorkspaceMember(
        id: 'm-$userId',
        workspaceId: 'ws-1',
        userId: userId,
        role: WorkspaceRole.member,
        joinedAt: DateTime(2026, 1, 1),
      ),
    );
  }

  @override
  Future<List<WorkspaceMember>> getForUser(String userId) async =>
      all.where((m) => m.userId == userId).toList();

  @override
  Future<void> remove(String workspaceId, String userId) async {
    all.removeWhere(
      (m) => m.workspaceId == workspaceId && m.userId == userId,
    );
  }

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async {
    for (final m in all) {
      if (m.workspaceId == workspaceId && m.userId == userId) {
        return m;
      }
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeDeviceDao implements PairedDeviceDao {
  final byId = <String, PairedDevicesTableData>{};

  void seed(String userId, String deviceId) {
    byId[deviceId] = PairedDevicesTableData(
      id: deviceId,
      userId: userId,
      workspaceId: null,
      label: 'test',
      platform: 'web',
      pskRef: 'file',
      status: PairedDeviceStatus.active,
      pairedAt: DateTime(2026, 1, 1),
      lastSeenAt: null,
      expiresAt: null,
      remoteFingerprint: null,
    );
  }

  @override
  Future<List<PairedDevicesTableData>> getForUser(String userId) async =>
      byId.values.where((d) => d.userId == userId).toList();

  @override
  Future<int> remove(String id) async {
    byId.remove(id);
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
