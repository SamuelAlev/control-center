import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/user_profile_ops.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/scim_service.dart';
import 'package:cc_server_core/src/identity/sso_provisioner.dart';
import 'package:cc_server_core/src/identity/workspace_invite_service.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// An email address identifies a person to SSO and SCIM only when the
/// identity provider or the server owner put it there. These run the real
/// user store, memberships, invite service, SSO provisioner, SCIM service and
/// the `users.*` ops, so a squatter is stopped where it would really act.
void main() {
  const workspaceId = 'ws-1';
  const ownerId = 'u-owner';
  const victimAddress = 'victim@corp.test';
  const idp = 'https://idp.test';

  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoUserRepository users;
  late DaoWorkspaceMembershipRepository members;
  late SsoProvisioner provisioner;
  late RepoOpDispatcher dispatcher;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, workspaceId);
    users = DaoUserRepository(global.userDao);
    members = DaoWorkspaceMembershipRepository(dbs);
    provisioner = SsoProvisioner(
      users: users,
      members: members,
      workspaces: DaoWorkspaceRepository(global.workspaceRegistryDao, dbs),
    );
    dispatcher = RepoOpDispatcher(
      registry: RepoOpRegistry(buildEmailVouchOps(users: users)),
      mapException: mapAppExceptionToRpc,
      resolveServerOwner: (userId) async => userId == ownerId,
    );
    for (final (id, handle) in [(ownerId, 'owner'), ('u-sq', 'squatter')]) {
      await users.upsert(
        User(
          id: id,
          handle: handle,
          displayName: handle,
          createdAt: DateTime.utc(2026),
        ),
      );
    }
    await members.upsert(
      WorkspaceMember(
        id: 'm-sq',
        workspaceId: workspaceId,
        userId: 'u-sq',
        role: WorkspaceRole.member,
        joinedAt: DateTime.utc(2026),
      ),
    );
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  RepoOpContext ctx(String userId, Map<String, dynamic> args) => RepoOpContext(
    args: args,
    workspaceId: null,
    deviceId: 'dev-$userId',
    userId: userId,
  );

  /// `users.updateProfile` exactly as the RPC op runs it.
  Future<void> setOwnEmail(String userId, String email) => updateOwnProfile(
    ctx(userId, {'email': email}),
    users: users,
    serverOwnerUserId: ownerId,
  );

  SsoProvisioningPolicy policy({required bool jit}) => SsoProvisioningPolicy(
    defaultRole: WorkspaceRole.member,
    groupRoleMap: const {'admins': WorkspaceRole.admin},
    autoMemberMode: SsoAutoMemberMode.all,
    allowJit: jit,
  );

  /// A first SSO login for [subject] asserting a verified [email] and the
  /// `admins` group, through matching and membership grants.
  Future<User> login(String subject, String email, {bool jit = true}) async {
    final claims = SsoClaims(
      email: email,
      ssoSubject: subject,
      ssoIssuer: idp,
      groups: const ['admins'],
    );
    final user = await provisioner.provisionUser(
      claims,
      policy: policy(jit: jit),
    );
    await provisioner.ensureMemberships(user, claims, policy(jit: jit));
    return user;
  }

  Future<Map<String, dynamic>> vouch(String callerId, String userId) =>
      dispatcher.call(
        id: 1,
        params: {
          'op': 'users.vouchEmail',
          'args': {'user_id': userId},
        },
        deviceId: 'dev-$callerId',
        userId: callerId,
        sessionCapability: SessionCapability.fullClient,
      );

  Future<void> expectSquatterUntouched() async {
    final squatter = (await users.getById('u-sq'))!;
    expect(squatter.ssoSubject, isNull, reason: 'no subject pinned');
    expect(
      (await members.getMember(workspaceId, 'u-sq'))!.role,
      WorkspaceRole.member,
      reason: 'no group-derived role',
    );
  }

  group('a member who sets their email to someone else\'s address', () {
    test('does not receive that person\'s first SSO login (JIT on); the '
        'vouched identity takes the address', () async {
      await setOwnEmail('u-sq', victimAddress);
      expect((await users.getById('u-sq'))!.emailVerified, isFalse);

      final victim = await login('sub-victim', victimAddress);

      expect(victim.id, isNot('u-sq'));
      expect(victim.email, victimAddress);
      expect(victim.emailVerified, isTrue);
      expect(
        (await members.getMember(workspaceId, victim.id))!.role,
        WorkspaceRole.admin,
      );
      await expectSquatterUntouched();
      // The unvouched holder loses the address to the vouched identity.
      expect((await users.getById('u-sq'))!.email, isNull);
      expect((await users.getAllByEmail(victimAddress)).map((u) => u.id), [
        victim.id,
      ]);
    });

    test('does not receive it with JIT off, and the refusal does not say '
        'whether the address exists', () async {
      await setOwnEmail('u-sq', victimAddress);

      Future<String> refusal(String email) async {
        try {
          await login('sub-${email.hashCode}', email, jit: false);
        } on AuthException catch (e) {
          return e.message;
        }
        fail('login with JIT off should be refused');
      }

      expect(await refusal(victimAddress), await refusal('nobody@corp.test'));
      await expectSquatterUntouched();
      expect((await users.getById('u-sq'))!.email, victimAddress);
    });

    test('is not adopted by a SCIM push for that address', () async {
      // An SSO-managed account is in SCIM's scope; its self-set address
      // still identifies nobody.
      final squatter = (await users.getById('u-sq'))!;
      await users.upsert(
        squatter.copyWith(ssoIssuer: idp, ssoSubject: 'sub-squatter'),
      );
      await setOwnEmail('u-sq', victimAddress);
      final dir = await Directory.systemTemp.createTemp('email_provenance');
      addTearDown(() => dir.delete(recursive: true));
      final scim = ScimService(
        verifyScimToken: (_) async => true,
        users: users,
        members: members,
        devices: global.pairedDeviceDao,
        secrets: FileSecretsStore(dataDir: dir.path),
      );

      final pushed = await scim.handle(
        method: 'POST',
        segments: ['scim', 'v2', 'Users'],
        query: const {},
        body: '{"userName":"$victimAddress","externalId":"ext-victim"}',
      );

      expect(pushed.status, 201);
      expect(pushed.body['id'], isNot('u-sq'));
      final created = (await users.getById(pushed.body['id']! as String))!;
      expect(created.email, victimAddress);
      expect(created.emailVerified, isTrue);
      final after = (await users.getById('u-sq'))!;
      expect(after.ssoSubject, 'sub-squatter');
      expect(after.email, isNull);
      expect(after.deactivatedAt, isNull);
    });
  });

  test('an address typed at invite redemption never matches', () async {
    final invites = WorkspaceInviteService(
      invites: DaoWorkspaceInviteRepository(dbs, global.workspaceRouteDao),
      members: members,
      users: users,
    );
    final created = await invites.create(
      workspaceId: workspaceId,
      createdBy: ownerId,
      role: WorkspaceRole.member,
    );
    final redeemed = await invites.redeem(
      code: created.code,
      handle: 'guest',
      email: victimAddress,
    );
    expect(redeemed.user.emailVerified, isFalse);

    final victim = await login('sub-victim', victimAddress);

    expect(victim.id, isNot(redeemed.user.id));
    expect((await users.getById(redeemed.user.id))!.ssoSubject, isNull);
  });

  test('a vouched address matches and pins once', () async {
    await setOwnEmail('u-sq', 'sam@corp.test');
    final vouched = await vouch(ownerId, 'u-sq');
    expect(vouched['error'], isNull);
    final data = (vouched['result'] as Map)['data'] as Map;
    expect((data['user'] as Map)['email_verified'], true);

    final first = await login('sub-sam', 'sam@corp.test');
    expect(first.id, 'u-sq');
    expect((await users.getById('u-sq'))!.ssoSubject, 'sub-sam');
    expect((await login('sub-sam', 'sam@corp.test')).id, 'u-sq');
    // Another subject asserting the same address does not take the account.
    await expectLater(
      login('sub-other', 'sam@corp.test'),
      throwsA(isA<AuthException>()),
    );
    expect((await users.getById('u-sq'))!.ssoSubject, 'sub-sam');
  });

  test('an SSO login asserting another case of a vouched address signs in '
      'to that account, not a second one', () async {
    await setOwnEmail('u-sq', 'sam@corp.test');
    await vouch(ownerId, 'u-sq');
    final before = (await users.getAll()).length;

    expect((await login('sub-sam', ' Sam@CORP.test')).id, 'u-sq');
    expect((await users.getAll()).length, before);
  });

  test("the server owner's own self-set address matches", () async {
    await setOwnEmail(ownerId, 'owner@corp.test');
    expect((await users.getById(ownerId))!.emailVerified, isTrue);

    expect((await login('sub-owner', 'owner@corp.test')).id, ownerId);
  });

  test(
    'the owner cannot take an address another account holds vouched',
    () async {
      await setOwnEmail('u-sq', 'sam@corp.test');
      await vouch(ownerId, 'u-sq');

      await expectLater(
        setOwnEmail(ownerId, 'sam@corp.test'),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test('changing a vouched address un-vouches it', () async {
    await setOwnEmail('u-sq', 'sam@corp.test');
    await vouch(ownerId, 'u-sq');
    await setOwnEmail('u-sq', victimAddress);

    final after = (await users.getById('u-sq'))!;
    expect(after.email, victimAddress);
    expect(after.emailVerified, isFalse);
    expect((await login('sub-victim', victimAddress)).id, isNot('u-sq'));
  });

  group('users.vouchEmail', () {
    test('is refused for anyone but the server owner, by name', () async {
      await setOwnEmail('u-sq', 'sam@corp.test');

      final refused = await vouch('u-sq', 'u-sq');

      final error = refused['error'] as Map;
      expect(error['code'], RpcErrorCodes.unauthorized);
      expect((error['data'] as Map)['kind'], 'server_owner_required');
      expect((await users.getById('u-sq'))!.emailVerified, isFalse);
    });

    test('refuses a case variant of an address another account holds '
        'vouched', () async {
      await setOwnEmail('u-sq', 'sam@corp.test');
      expect((await vouch(ownerId, 'u-sq'))['error'], isNull);
      await users.upsert(
        User(
          id: 'u-3',
          handle: 'third',
          displayName: 'third',
          createdAt: DateTime.utc(2026),
        ),
      );
      // A row from before addresses were normalized.
      await global.customStatement(
        "UPDATE users SET email = 'Sam@Corp.TEST' WHERE id = 'u-3'",
      );

      final refused = await vouch(ownerId, 'u-3');

      expect((refused['error'] as Map)['code'], RpcErrorCodes.validation);
      expect((await users.getById('u-3'))!.emailVerified, isFalse);
    });

    test('refuses an account with no address or a deactivated one', () async {
      final none = await vouch(ownerId, 'u-sq');
      expect((none['error'] as Map)['code'], RpcErrorCodes.validation);

      await setOwnEmail('u-sq', 'sam@corp.test');
      final squatter = (await users.getById('u-sq'))!;
      await users.upsert(squatter.copyWith(deactivatedAt: DateTime.utc(2026)));
      final gone = await vouch(ownerId, 'u-sq');
      expect((gone['error'] as Map)['code'], RpcErrorCodes.validation);
      expect((await users.getById('u-sq'))!.emailVerified, isFalse);
    });
  });
}
