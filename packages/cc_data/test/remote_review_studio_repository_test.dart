import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/visual_diff.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RemoteReviewStudioRepository] — the Review Studio surface over
/// RPC. Pins every watch + one-shot + decision op + args shape.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteReviewStudioRepository cohorts', () {
    test(
      'watchCohorts maps the cohorts array and forwards owner/repo/pr',
      () async {
        host.snapshotFor('review_studio.watchCohorts', {
          'cohorts': [
            {
              'id': 'c-1',
              'cohortKey': 'auth',
              'title': 'Auth flow',
              'impactScore': 3,
              'orderIndex': 0,
            },
          ],
        });
        final repo = RemoteReviewStudioRepository(client);
        final cohorts = await repo.watchCohorts('o', 'r', 42).first;
        expect(cohorts.length, 1);
        expect(cohorts.first.id, 'c-1');
        expect(cohorts.first.cohortKey, 'auth');
        final sub = host.lastSubscribe!;
        expect(sub.args['owner'], 'o');
        expect(sub.args['repo'], 'r');
        expect(sub.args['pr_number'], 42);
      },
    );

    test('cohorts one-shot maps the same payload', () async {
      host.callResults['review_studio.cohorts'] = {
        'cohorts': [
          {'id': 'c-1', 'cohortKey': 'auth', 'title': 'X'},
        ],
      };
      final repo = RemoteReviewStudioRepository(client);
      expect((await repo.cohorts('o', 'r', 1)).first.id, 'c-1');
    });

    test('compute returns the raw payload', () async {
      host.callResults['review_studio.compute'] = {'cohorts': [], 'axes': []};
      final repo = RemoteReviewStudioRepository(client);
      final result = await repo.compute('o', 'r', 7);
      expect(result.containsKey('cohorts'), isTrue);
      expect(host.lastCall('review_studio.compute')!.args['pr_number'], 7);
    });
  });

  group('RemoteReviewStudioRepository contract diffs', () {
    test('watchContractDiffs maps the diffs array', () async {
      host.snapshotFor('review_studio.watchContractDiffs', {
        'diffs': [
          {
            'id': 'd-1',
            'title': 'endpoint',
            'changes': [],
            'decision': 'undecided',
          },
        ],
      });
      final repo = RemoteReviewStudioRepository(client);
      final diffs = await repo.watchContractDiffs('o', 'r', 1).first;
      expect(diffs.first.id, 'd-1');
    });

    test('setContractDecision forwards the decision wire name', () async {
      final repo = RemoteReviewStudioRepository(client);
      await repo.setContractDecision(
        diffId: 'd-1',
        changeId: 'ch-1',
        decision: ApiChangeDecision.approved,
      );
      final call = host.lastCall('review_studio.setContractDecision')!;
      expect(call.args['diff_id'], 'd-1');
      expect(call.args['change_id'], 'ch-1');
      expect(call.args['decision'], 'approved');
    });
  });

  group('RemoteReviewStudioRepository visual diffs', () {
    test('watchVisualDiffs maps the snapshots array', () async {
      host.snapshotFor('review_studio.watchVisualDiffs', {
        'snapshots': [
          {
            'id': 's-1',
            'componentKey': 'HomePage',
            'componentTitle': 'Home',
            'status': 'unchanged',
            'variants': [],
          },
        ],
      });
      final repo = RemoteReviewStudioRepository(client);
      final snapshots = await repo.watchVisualDiffs('o', 'r', 1).first;
      expect(snapshots.first.id, 's-1');
      expect(snapshots.first.componentKey, 'HomePage');
    });

    test('approveVisual forwards the status wire name', () async {
      final repo = RemoteReviewStudioRepository(client);
      await repo.approveVisual(
        snapshotId: 's-1',
        status: VisualDiffStatus.approved,
      );
      final call = host.lastCall('review_studio.approveVisual')!;
      expect(call.args['snapshot_id'], 's-1');
      expect(call.args['status'], 'approved');
    });
  });

  group('RemoteReviewStudioRepository axis results', () {
    test('watchAxisResults maps the axes array', () async {
      host.snapshotFor('review_studio.watchAxisResults', {
        'axes': [
          {
            'axis': 'correctness',
            'verdict': 'pass',
            'findingsCount': 0,
            'gated': true,
            'confidence': 0.9,
          },
        ],
      });
      final repo = RemoteReviewStudioRepository(client);
      final axes = await repo.watchAxisResults('o', 'r', 1).first;
      expect(axes.first.axis, ReviewAxis.correctness);
    });
  });

  group('RemoteReviewStudioRepository blastRadius', () {
    test('returns the raw payload and forwards file_path + depth', () async {
      host.callResults['review_studio.blastRadius'] = {
        'indexed': true,
        'root': 'lib/main.dart',
      };
      final repo = RemoteReviewStudioRepository(client);
      final result = await repo.blastRadius(
        owner: 'o',
        repo: 'r',
        filePath: 'lib/main.dart',
        depth: 3,
      );
      expect(result['indexed'], isTrue);
      final call = host.lastCall('review_studio.blastRadius')!;
      expect(call.args['file_path'], 'lib/main.dart');
      expect(call.args['depth'], 3);
    });
  });
}

/// A recorded `sub/subscribe`.
class _Sub {
  const _Sub({required this.query, required this.args});
  final String query;
  final Map<String, dynamic> args;
}

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

class _Host {
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
  final List<_Call> calls = [];
  final List<_Sub> subs = [];
  final Map<String, Map<String, dynamic>> callResults = {};
  final Map<String, Map<String, dynamic>> snapshots = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );
  _Sub? get lastSubscribe => subs.isEmpty ? null : subs.last;

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
          space.send({
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
        _reply(id, {
          'op': op,
          'data': callResults[op] ?? const <String, dynamic>{},
        });
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
