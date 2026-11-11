import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/environment_ops.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:test/test.dart';

/// Saving or approving an environment definition that runs anything on the
/// server host is the server owner's; a workspace admin may still save one
/// that runs entirely in a rig. The op hands the service who the caller is
/// from the session, never from an argument, and the service's refusal
/// reaches the wire as the dispatcher's own `server_owner_required`.
void main() {
  const owner = 'olga';
  const admin = 'ada';

  late _Environments environments;
  late List<String> activity;

  setUp(() {
    environments = _Environments();
    activity = [];
  });

  RepoOpDispatcher dispatcher({String? serverOwnerUserId = owner}) =>
      RepoOpDispatcher(
        registry: RepoOpRegistry(
          buildEnvironmentOps(
            environments: environments,
            reposExposedBySpace: (_) async => const [],
            assertSpaceOwned: (_, _, _) async {},
            serverOwnerUserId: serverOwnerUserId,
          ),
        ),
        mapException: mapAppExceptionToRpc,
        // Both are admins of the workspace; only one owns the server.
        resolveRole: (_, _) async => WorkspaceRole.admin,
        resolveServerOwner: (userId) async => userId == serverOwnerUserId,
        recordActivity:
            ({
              required String workspaceId,
              required String userId,
              required String deviceId,
              required String action,
              String? targetType,
              String? targetId,
              String? ip,
              Map<String, Object?>? details,
            }) async => activity.add('$userId $action'),
      );

  Future<Map<String, dynamic>> call(
    String userId,
    String op,
    Map<String, dynamic> args, {
    RepoOpDispatcher? via,
  }) async {
    final res = await (via ?? dispatcher()).call(
      id: 1,
      params: {
        'op': op,
        'args': {'workspace_id': 'ws-1', ...args},
      },
      deviceId: 'device-$userId',
      userId: userId,
      sessionCapability: SessionCapability.fullClient,
    );
    // The activity write is fire and forget; let it land.
    await Future<void>.delayed(Duration.zero);
    return res;
  }

  Map<String, dynamic> definition({required String placement}) => {
    'contract': 1,
    'name': 'Shop',
    'repos': {
      'app': {'repoId': 'repo-app', 'anchor': true},
    },
    'naming': {'template': '{branch}', 'project': 'shop'},
    'components': [
      {'kind': 'compose', 'id': 'stack', 'build': false},
    ],
    'placement': placement,
  };

  Future<Map<String, dynamic>> save(
    String userId,
    String placement, {
    String? id,
    Map<String, dynamic> extra = const {},
    RepoOpDispatcher? via,
  }) => call(userId, 'environments.setDefinition', {
    'definition': definition(placement: placement),
    'definition_id': ?id,
    ...extra,
  }, via: via);

  Future<Map<String, dynamic>> approve(String userId, String placement) {
    environments.file = definition(placement: placement);
    return call(userId, 'environments.approveSource', {
      'repo_id': 'repo-app',
      'path': 'env.json',
    });
  }

  void expectOwnerRequired(Map<String, dynamic> res) {
    final error = res['error'] as Map?;
    expect(error?['code'], RpcErrorCodes.unauthorized);
    expect((error?['data'] as Map?)?['kind'], 'server_owner_required');
  }

  group('environments.setDefinition', () {
    test('an admin who is not the server owner cannot save a host '
        'definition: told why, nothing written, nothing audited', () async {
      expectOwnerRequired(await save(admin, 'host'));
      expect(environments.saved, isEmpty);
      expect(activity, isEmpty);
    });

    test('an admin saves a definition that runs entirely in a rig', () async {
      final res = await save(admin, 'rig');
      expect(res['error'], isNull);
      expect(environments.saved.keys, ['def-1']);
      expect(activity, ['$admin environments.setDefinition']);
    });

    test('the server owner saves either', () async {
      expect((await save(owner, 'host'))['error'], isNull);
      expect((await save(owner, 'rig'))['error'], isNull);
      expect(environments.saved, hasLength(2));
    });

    test('a host definition stays the owner\'s to edit', () async {
      await save(owner, 'host', id: 'def-host');
      expectOwnerRequired(await save(admin, 'host', id: 'def-host'));
      expect(environments.saved['def-host']!['placement'], 'host');
    });

    test('an admin cannot move a rig definition to the host', () async {
      await save(admin, 'rig', id: 'def-rig');
      expectOwnerRequired(await save(admin, 'host', id: 'def-rig'));
      expect(environments.saved['def-rig']!['placement'], 'rig');
    });

    test('no argument makes the caller the owner', () async {
      expectOwnerRequired(
        await save(
          admin,
          'host',
          extra: const {
            'by_server_owner': true,
            'byServerOwner': true,
            'server_owner': true,
          },
        ),
      );
      expect(environments.saved, isEmpty);
    });

    test(
      'with no server owner recorded, nobody saves a host definition',
      () async {
        expectOwnerRequired(
          await save(owner, 'host', via: dispatcher(serverOwnerUserId: null)),
        );
      },
    );
  });

  group('environments.approveSource', () {
    test('an admin who is not the server owner cannot approve a host file: '
        'told why, nothing written, nothing audited', () async {
      expectOwnerRequired(await approve(admin, 'host'));
      expect(environments.saved, isEmpty);
      expect(activity, isEmpty);
    });

    test('an admin approves a rig file', () async {
      expect((await approve(admin, 'rig'))['error'], isNull);
      expect(environments.saved, hasLength(1));
    });

    test('the server owner approves a host file', () async {
      expect((await approve(owner, 'host'))['error'], isNull);
      expect(environments.saved, hasLength(1));
    });
  });
}

/// Stores definitions the way the service decides: refused for anyone but
/// the owner when the parsed definition runs on the host.
class _Environments implements EnvironmentPort {
  final Map<String, Map<String, dynamic>> saved = {};

  /// What the linked file holds on the default branch.
  Map<String, dynamic> file = const {};

  EnvironmentDefinitionRecord _store(
    String workspaceId,
    String? definitionId,
    Map<String, dynamic> definition, {
    required bool byServerOwner,
  }) {
    final parsed = EnvironmentDefinition.fromJson(definition);
    if (!byServerOwner && parsed.runsOnHost) {
      throw const ServerOwnerRequiredException('Runs on the host');
    }
    final id = definitionId ?? 'def-${saved.length + 1}';
    saved[id] = definition;
    return EnvironmentDefinitionRecord(
      id: id,
      workspaceId: workspaceId,
      name: parsed.name,
      definitionJson: '{}',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<EnvironmentDefinitionRecord> saveDefinition({
    required String workspaceId,
    String? definitionId,
    required Map<String, dynamic> definition,
    required Principal by,
    required bool byServerOwner,
  }) async => _store(
    workspaceId,
    definitionId,
    definition,
    byServerOwner: byServerOwner,
  );

  @override
  Future<EnvironmentDefinitionRecord> approveSource({
    required String workspaceId,
    String? definitionId,
    required String repoId,
    required String path,
    Map<String, dynamic>? overrides,
    String? expectedBlobHash,
    required Principal by,
    required bool byServerOwner,
  }) async =>
      _store(workspaceId, definitionId, file, byServerOwner: byServerOwner);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
