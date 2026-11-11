import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/sign_in_ops.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:test/test.dart';

/// The `oauth.*` surface: every call validates the workspace it names
/// (registered, not deleted) before membership, refuses a non-member, keeps
/// the person from the session, and answers an attempt the server does not
/// know as failed with `attempt_unknown` instead of an error.
void main() {
  late Directory dir;
  late RepoOpDispatcher dispatcher;
  late _Members members;
  late ProviderSignInService service;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_sign_in_ops_');
    final settings = ConnectSettings(
      secrets: FileSecretsStore(dataDir: dir.path),
    );
    service =
        ProviderSignInService(
            connect: ConnectClient(
              settings: settings,
              trustedRootKeys: const [],
            ),
          )
          ..register(_Lane())
          ..register(_Lane(ConnectOAuthLane.linearApp, _ownApp));
    final workspaces = _Workspaces({
      'ws': _workspace('ws'),
      'gone': _workspace('gone', deletedAt: DateTime.utc(2026, 2)),
    });
    members = _Members(
      {
        'ws': {'ada'},
        'gone': {'ada'},
      },
      admins: {'ada'},
    );
    dispatcher = RepoOpDispatcher(
      registry: RepoOpRegistry(
        buildSignInOps(
          signIn: service,
          workspaces: workspaces,
          members: members,
          pairingServerUrl: 'https://cc.example',
        ),
      ),
      mapException: mapAppExceptionToRpc,
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<Map<String, dynamic>> call(
    String op,
    String user,
    Map<String, dynamic> args,
  ) => dispatcher.call(
    id: 1,
    params: {'op': op, 'args': args},
    deviceId: 'dev-$user',
    userId: user,
    sessionCapability: SessionCapability.fullClient,
  );

  int? code(Map<String, dynamic> res) =>
      (res['error'] as Map?)?['code'] as int?;

  Map<String, Object?> data(Map<String, dynamic> res) {
    expect(res['error'], isNull, reason: '$res');
    return ((res['result'] as Map)['data'] as Map).cast<String, Object?>();
  }

  const loginId = 'AAAAAAAAAAAAAAAAAAAAAA';

  Map<String, dynamic> argsFor(String op, String workspaceId) => {
    'workspace_id': workspaceId,
    if (op != 'oauth.lanes' && op != 'oauth.connections') 'lane': 'github',
    if (op == 'oauth.status' || op == 'oauth.complete') 'login_id': loginId,
    if (op == 'oauth.complete') 'code': 'ABCD2345',
  };

  const ops = [
    'oauth.lanes',
    'oauth.begin',
    'oauth.status',
    'oauth.complete',
    'oauth.connections',
    'oauth.disconnect',
  ];

  test(
    'an unknown or deleted workspace is refused before membership',
    () async {
      for (final op in ops) {
        for (final workspace in ['nope', 'gone']) {
          members.asked.clear();
          final res = await call(op, 'ada', argsFor(op, workspace));
          expect(code(res), RpcErrorCodes.notFound, reason: '$op $workspace');
          expect(members.asked, isEmpty, reason: '$op $workspace');
        }
      }
    },
  );

  test('a non-member is refused on every oauth op', () async {
    for (final op in ops) {
      final res = await call(op, 'eve', argsFor(op, 'ws'));
      expect(code(res), RpcErrorCodes.unauthorized, reason: op);
    }
  });

  test('a member reads the lanes with their unavailable reason', () async {
    final lanes =
        (data(await call('oauth.lanes', 'ada', {'workspace_id': 'ws'}))['lanes']
                as List)
            .cast<Map<String, Object?>>();
    final github = lanes.singleWhere((l) => l['lane'] == 'github');
    expect(github['mode'], 'unavailable');
    expect(github['unavailable_reason'], 'not_configured');
  });

  test(
    'an attempt the server does not know reads as attempt_unknown',
    () async {
      final attempt = data(
        await call('oauth.status', 'ada', {
          'workspace_id': 'ws',
          'login_id': loginId,
          'lane': 'github',
        }),
      );
      expect(attempt['status'], 'failed');
      expect(attempt['error'], 'attempt_unknown');
      expect(attempt['lane'], 'github');
      expect(attempt['login_id'], loginId);
    },
  );

  test('a member sees the connection with the status wire', () async {
    final connections =
        (data(
                  await call('oauth.connections', 'ada', {
                    'workspace_id': 'ws',
                  }),
                )['connections']
                as List)
            .cast<Map<String, Object?>>();
    final github = connections.singleWhere((c) => c['lane'] == 'github');
    expect(github['status'], 'not_connected');
    expect(github.containsKey('connected'), isFalse);
    expect(github.containsKey('needs_sign_in'), isFalse);
  });

  test('an admin demoted mid sign-in cannot finish a workspace lane', () async {
    final begun = data(
      await call('oauth.begin', 'ada', {
        'workspace_id': 'ws',
        'lane': 'linear_app',
      }),
    );
    final url = Uri.parse(begun['url']! as String);
    final page = service.handleCallback(
      Uri.parse(
        'https://cc.example/oauth/linear_app/callback'
        '?state=${url.queryParameters['state']}&code=provider-code',
      ),
    );
    members.admins.clear();

    final res = await call('oauth.complete', 'ada', {
      'workspace_id': 'ws',
      'login_id': begun['login_id'],
      'code': page.confirmCode,
    });
    expect(code(res), RpcErrorCodes.unauthorized);
    final status = data(
      await call('oauth.status', 'ada', {
        'workspace_id': 'ws',
        'login_id': begun['login_id'],
        'lane': 'linear_app',
      }),
    );
    expect(status['status'], 'pending');
  });

  test('NeedsSignInException maps to unauthorized with its lane', () {
    final mapped = mapAppExceptionToRpc(const NeedsSignInException('gitlab'));
    expect(mapped?.code, RpcErrorCodes.unauthorized);
    expect(mapped?.data, {'kind': 'needs_sign_in', 'lane': 'gitlab'});
  });
}

final _ownApp = OwnOAuthApp(
  authorize: Uri.https('linear.app', '/oauth/authorize'),
  // Never reached: the exchange is refused before it.
  token: Uri.https('api.linear.app', '/oauth/token'),
  clientId: 'own-client',
  clientSecret: 'own-secret',
  scopes: const ['read'],
);

final class _Lane implements SignInLaneBinding {
  _Lane([this.lane = ConnectOAuthLane.github, this.own]);

  @override
  final ConnectOAuthLane lane;

  final OwnOAuthApp? own;

  @override
  Future<OwnOAuthApp?> ownApp(String? workspaceId) async => own;

  @override
  Future<bool> allowsConnect(String? workspaceId) async => true;

  @override
  Future<String?> slotFor(String? workspaceId) async => null;

  @override
  Future<Set<String>> accountHolders(String accountId) async => const {};

  @override
  Future<void> revokeOwnGrant(ProviderToken token, String? slot) async {}

  @override
  Future<SignInIdentity> identify(String accessToken) =>
      throw UnimplementedError();

  @override
  Future<void> store(SignInResult result) async {}

  @override
  Future<LaneConnection?> connection(
    String userId,
    String? workspaceId,
  ) async => null;

  @override
  Future<void> disconnect(String userId, String? workspaceId) async {}

  @override
  Future<int> offboard({String? userId, String? workspaceId}) async => 0;

  @override
  Future<List<SealRequest>> connectSeals(
    String connectOrigin,
    List<String> workspaceIds,
  ) async => const [];
}

Workspace _workspace(String id, {DateTime? deletedAt}) => Workspace(
  id: id,
  name: id,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  deletedAt: deletedAt,
);

final class _Workspaces implements WorkspaceRepository {
  _Workspaces(this.byId);

  final Map<String, Workspace> byId;

  @override
  Future<Workspace?> getById(String id) async => byId[id];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Members implements WorkspaceMembershipRepository {
  _Members(this.byWorkspace, {required this.admins});

  final Map<String, Set<String>> byWorkspace;

  /// Users with the admin role wherever they are members.
  final Set<String> admins;
  final List<String> asked = [];

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async {
    asked.add(workspaceId);
    if (!(byWorkspace[workspaceId]?.contains(userId) ?? false)) {
      return null;
    }
    return WorkspaceMember(
      id: '$workspaceId-$userId',
      workspaceId: workspaceId,
      userId: userId,
      role: admins.contains(userId)
          ? WorkspaceRole.admin
          : WorkspaceRole.member,
      joinedAt: DateTime.utc(2026),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
