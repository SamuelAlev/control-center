import 'dart:convert';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:cc_domain/features/governance/domain/value_objects/work_product_type.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcWorkProductRepository] — the client's only path to work
/// products / artifacts — over an in-process JSON-RPC host.
///
/// The op NAMES are the load-bearing assertion: the catalog is a closed
/// allow-list, so a typo here is `opUnknown` at runtime in the real app, which
/// unit tests of the parsers alone would never catch.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  final envelope = jsonEncode({
    'format': 'blocks@1',
    'blocks': [
      {'type': 'markdown', 'id': 'b1', 'text': 'Hello'},
      {
        'type': 'code',
        'id': 'b2',
        'code': 'void main() {}',
        'language': 'dart',
      },
    ],
  });

  Map<String, dynamic> wireProduct({String id = 'wp-1'}) => {
    'id': id,
    'workspace_id': 'ws-1',
    'title': 'Backend options',
    'artifact_type': 'report',
    'agent_id': 'a-1',
    'current_revision_id': 'rev-2',
    'created_at': '2026-07-20T09:00:00.000',
    'updated_at': '2026-07-25T11:30:00.000',
  };

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  test('getById forwards the id and maps the wire row', () async {
    host.callResults['workProduct.getById'] = {'work_product': wireProduct()};
    final product = await RpcWorkProductRepository(client).getById('wp-1');

    expect(product, isNotNull);
    expect(product!.id, 'wp-1');
    expect(product.workspaceId, 'ws-1');
    expect(product.title, 'Backend options');
    expect(product.artifactType, WorkProductType.report);
    expect(product.agentId, 'a-1');
    expect(product.currentRevisionId, 'rev-2');
    expect(product.updatedAt, DateTime(2026, 7, 25, 11, 30));
    expect(
      host.lastCall('workProduct.getById')!.args['work_product_id'],
      'wp-1',
    );
  });

  test('getById maps a null row to null', () async {
    host.callResults['workProduct.getById'] = {'work_product': null};
    expect(await RpcWorkProductRepository(client).getById('wp-1'), isNull);
  });

  test(
    'listForWorkspace carries no workspace arg (the host binds it)',
    () async {
      host.callResults['workProduct.listForWorkspace'] = {
        'work_products': [wireProduct(), wireProduct(id: 'wp-2')],
      };
      final products = await RpcWorkProductRepository(
        client,
      ).listForWorkspace();
      expect(products.map((p) => p.id), ['wp-1', 'wp-2']);
      expect(host.lastCall('workProduct.listForWorkspace')!.args, isEmpty);
    },
  );

  test('revisions maps the history and decodes the block envelope', () async {
    host.callResults['workProduct.revisions'] = {
      'revisions': [
        {
          'id': 'rev-2',
          'work_product_id': 'wp-1',
          'workspace_id': 'ws-1',
          'revision_number': 2,
          'content': envelope,
          'base_revision_id': 'rev-1',
          'author_type': 'agent',
          'author_id': 'a-1',
          'summary': 'Added the code sample',
          'created_at': '2026-07-25T11:30:00.000',
        },
      ],
    };
    final revisions = await RpcWorkProductRepository(client).revisions('wp-1');
    expect(revisions, hasLength(1));
    final revision = revisions.single;
    expect(revision.revisionNumber, 2);
    expect(revision.baseRevisionId, 'rev-1');
    expect(revision.summary, 'Added the code sample');

    // Decoded by the SAME cc_domain codec the server validates with — there is
    // no second wire schema for blocks that could drift.
    final document = RpcWorkProductRepository.documentOf(revision);
    expect(document, isNotNull);
    expect(document!.blocks.map((b) => b.type), ['markdown', 'code']);
    expect(document.blocks.map((b) => b.id), ['b1', 'b2']);
    expect((document.blocks.last as ArtifactCodeBlock).language, 'dart');
  });

  test('a plain-markdown revision is not a block document', () async {
    host.callResults['workProduct.revisions'] = {
      'revisions': [
        {
          'id': 'rev-1',
          'work_product_id': 'wp-1',
          'workspace_id': 'ws-1',
          'revision_number': 1,
          'content': '# just markdown',
          'created_at': '2026-07-20T09:00:00.000',
        },
      ],
    };
    final revisions = await RpcWorkProductRepository(client).revisions('wp-1');
    expect(RpcWorkProductRepository.documentOf(revisions.single), isNull);
  });

  test('watchById subscribes with the id and streams the row', () async {
    host.snapshotFor('workProduct.watchById', {'work_product': wireProduct()});
    final product = await RpcWorkProductRepository(
      client,
    ).watchById('wp-1').first;
    expect(product?.id, 'wp-1');
    expect(host.lastSubscribe!.query, 'workProduct.watchById');
    expect(host.lastSubscribe!.args['work_product_id'], 'wp-1');
  });

  test(
    'watchForChannel forwards the channel + optional conversation',
    () async {
      host.snapshotFor('workProduct.watchForChannel', {
        'work_products': [wireProduct()],
      });
      final products = await RpcWorkProductRepository(
        client,
      ).watchForChannel('chan-1', conversationId: 'conv-2').first;
      expect(products.single.id, 'wp-1');
      expect(host.lastSubscribe!.query, 'workProduct.watchForChannel');
      expect(host.lastSubscribe!.args['channel_id'], 'chan-1');
      expect(host.lastSubscribe!.args['conversation_id'], 'conv-2');
    },
  );

  test('watchForChannel omits conversation_id when not supplied', () async {
    host.snapshotFor('workProduct.watchForChannel', const {
      'work_products': <Object>[],
    });
    await RpcWorkProductRepository(client).watchForChannel('chan-1').first;
    expect(host.lastSubscribe!.args.containsKey('conversation_id'), isFalse);
  });

  test('a malformed envelope degrades to no document, never a throw', () async {
    // Render-path tolerance: content already accepted must not blow up a rebuild.
    expect(ArtifactDocument.tryParseContent('{"format":"blocks@1"}'), isNull);
    final salvaged = ArtifactDocument.tryParseContent(
      jsonEncode({
        'format': 'blocks@1',
        'blocks': [
          {'type': 'markdown', 'text': 'kept'},
          {'type': 'nope'},
        ],
      }),
    );
    expect(salvaged!.blocks.map((b) => b.type), ['markdown']);
    expect(artifactBlockKinds, contains('markdown'));
  });
}

/// A recorded `repo/call`.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

/// A recorded `sub/subscribe`.
class _Sub {
  const _Sub({required this.query, required this.args});
  final String query;
  final Map<String, dynamic> args;
}

/// In-process host that scripts `repo/call` results and `sub/subscribe`
/// snapshots. Mirrors the wire shape the server catalog emits.
class _Host {
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<_Call> calls = [];
  final List<_Sub> subs = [];

  /// Scripted `repo/call` results keyed by op name.
  final Map<String, Map<String, dynamic>> callResults = {};

  /// Scripted snapshots keyed by watch query (pushed on subscribe).
  final Map<String, Map<String, dynamic>> snapshots = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );

  _Sub? get lastSubscribe => subs.isEmpty ? null : subs.last;

  /// Scripts the snapshot pushed to the next subscription for [query].
  void snapshotFor(String query, Map<String, dynamic> data) =>
      snapshots[query] = data;

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        final query = params['query'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        subs.add(_Sub(query: query, args: args));
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
        final snapshot = snapshots[query];
        if (snapshot != null) {
          channel.send({
            'jsonrpc': '2.0',
            'method': RpcMethods.subSnapshot,
            'params': {
              'subscriptionId': 's1',
              'rev': 1,
              'full': true,
              'data': snapshot,
            },
          });
        }
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        calls.add(_Call(op: op, args: args));
        final data = callResults[op] ?? const <String, dynamic>{};
        _reply(id, {'op': op, 'data': data});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
