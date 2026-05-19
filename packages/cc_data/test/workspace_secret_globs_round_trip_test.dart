import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// `workspaces.secret_exclude_globs` must survive a client-side round trip.
///
/// The regression this pins: [RpcWorkspaceRepository] used to drop the field in
/// both mapping directions. Because `WorkspaceDto.toJson` writes
/// `secret_exclude_globs` UNCONDITIONALLY (unlike its null-guarded neighbours),
/// dropping it did not omit the key — it sent `[]`. The host decodes that as
/// "no custom exclusions", so an ordinary rename or logo change from the
/// workspace picker silently wiped the operator's secret-path exclusions for
/// viewer/guest callers.
///
/// A carry-over-on-omit guard on the host would NOT have caught this, because
/// the field arrives present-and-empty. Fixing the mapping is the only fix,
/// which is why this test lives here rather than server-side.
class _StubHost {
  _StubHost(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;

  /// Every `workspace.upsert` payload the client sent, verbatim.
  final List<Map<String, dynamic>> upserts = [];

  /// The custom exclusions the stub's stored workspace carries.
  static const globs = ['**/secrets/**', '**/*.internal.md'];

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};

    switch (method) {
      case RpcMethods.subscribe:
        _reply(id, {'subscriptionId': 'sub-1'});
        space.send({
          'jsonrpc': '2.0',
          'method': RpcMethods.subSnapshot,
          'params': {
            'subscriptionId': 'sub-1',
            'data': {
              'workspaces': [_workspaceJson()],
            },
          },
        });
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      default:
        final op = params['op'] as String?;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        if (op == 'workspace.upsert') {
          upserts.add(args);
          _reply(id, {
            'op': op,
            'data': {'workspace_id': 'ws1'},
          });
        } else {
          _reply(id, {'op': op, 'data': <String, dynamic>{}});
        }
    }
  }

  void _reply(Object? id, Map<String, dynamic> result) =>
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});

  Map<String, dynamic> _workspaceJson() => {
    'id': 'ws1',
    'name': 'Alpha',
    'owner_user_id': 'user-1',
    'secret_exclude_globs': globs,
    'review_concurrency': 5,
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-02T00:00:00.000Z',
  };
}

void main() {
  late RemoteRpcClient client;
  late _StubHost host;

  setUp(() async {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _StubHost(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  test('reading a workspace carries secretExcludeGlobs onto the entity', () async {
    final workspaces = await RpcWorkspaceRepository(client).getAll();

    expect(workspaces, hasLength(1));
    expect(
      workspaces.single.secretExcludeGlobs,
      _StubHost.globs,
      reason:
          'The entity must carry the host\'s globs. Defaulting to const [] is '
          'what makes the next upsert wipe them.',
    );
    expect(workspaces.single.ownerUserId, 'user-1');
  });

  test('renaming a workspace does not wipe secretExcludeGlobs', () async {
    final repo = RpcWorkspaceRepository(client);
    final loaded = (await repo.getAll()).single;

    // Exactly what the picker's rename path does: change one field, upsert.
    await repo.upsert(
      Workspace(
        id: loaded.id,
        name: 'Alpha renamed',
        logoPath: loaded.logoPath,
        ownerUserId: loaded.ownerUserId,
        secretExcludeGlobs: loaded.secretExcludeGlobs,
        reviewConcurrency: loaded.reviewConcurrency,
        createdAt: loaded.createdAt,
        updatedAt: loaded.updatedAt,
      ),
    );

    expect(host.upserts, hasLength(1));
    final sent = (host.upserts.single['workspace'] as Map)
        .cast<String, dynamic>();
    expect(sent['name'], 'Alpha renamed');
    expect(
      (sent['secret_exclude_globs'] as List).cast<String>(),
      _StubHost.globs,
      reason:
          'A rename must not send an empty glob list. The host decodes [] as '
          '"no custom exclusions" and persists it.',
    );
    expect(
      sent.containsKey('owner_user_id'),
      isFalse,
      reason:
          'Ownership stays server-authoritative: the host stamps it on create '
          'and carries the stored value over on update, so the client must not '
          'assert who owns a workspace.',
    );
  });
}
