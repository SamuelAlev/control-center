import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RemoteWeatherRepository] and [RpcWeatherRepository] — the weather
/// surface over RPC. Pins the ops, the args shape, the DTO→entity mapping and
/// the write helpers. Both reads share the same in-process host.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  const weatherPayload = {
    'latitude': 52.5,
    'longitude': 13.4,
    'condition': 'clouds',
    'is_day': false,
    'temperature_celsius': 18.5,
    'wind_speed_kmh': 12.0,
    'observed_at': '2026-07-01T09:00:00.000',
    'location_label': 'Berlin',
  };

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteWeatherRepository', () {
    test('getCurrent maps the weather map', () async {
      host.callResults['weather.getCurrent'] = {'weather': weatherPayload};
      final repo = RemoteWeatherRepository(client);
      final dto = await repo.getCurrent();
      expect(dto, isNotNull);
      expect(dto!.condition, 'clouds');
      expect(dto.temperatureCelsius, 18.5);
      expect(dto.isDay, isFalse);
      expect(dto.locationLabel, 'Berlin');
    });

    test('getCurrent returns null when weather is absent', () async {
      host.callResults['weather.getCurrent'] = const {};
      final repo = RemoteWeatherRepository(client);
      expect(await repo.getCurrent(), isNull);
    });

    test('getCurrent returns null when weather is not a Map', () async {
      host.callResults['weather.getCurrent'] = {'weather': 'nope'};
      final repo = RemoteWeatherRepository(client);
      expect(await repo.getCurrent(), isNull);
    });

    test('watchCurrent maps the live stream', () async {
      host.snapshotFor('weather.watchCurrent', {'weather': weatherPayload});
      final repo = RemoteWeatherRepository(client);
      final dto = await repo.watchCurrent().first;
      expect(dto, isNotNull);
      expect(dto!.windSpeedKmh, 12.0);
      final sub = host.lastSubscribe!;
      expect(sub.query, 'weather.watchCurrent');
      expect(sub.args, isEmpty);
    });

    test('refreshNow forwards the op', () async {
      final repo = RemoteWeatherRepository(client);
      await repo.refreshNow();
      expect(host.lastCall('weather.refreshNow'), isNotNull);
    });

    test('setManualLocation forwards coordinates + label', () async {
      final repo = RemoteWeatherRepository(client);
      await repo.setManualLocation(
        latitude: 52.5,
        longitude: 13.4,
        label: 'Berlin',
      );
      final call = host.lastCall('weather.setManualLocation')!;
      expect(call.args['latitude'], 52.5);
      expect(call.args['longitude'], 13.4);
      expect(call.args['label'], 'Berlin');
    });

    test('setManualLocation omits label when null', () async {
      final repo = RemoteWeatherRepository(client);
      await repo.setManualLocation(latitude: 1, longitude: 2);
      expect(
        host.lastCall('weather.setManualLocation')!.args.containsKey('label'),
        isFalse,
      );
    });

    test('clearManualLocation forwards the op', () async {
      final repo = RemoteWeatherRepository(client);
      await repo.clearManualLocation();
      expect(host.lastCall('weather.clearManualLocation'), isNotNull);
    });
  });

  group('RpcWeatherRepository', () {
    test('getCurrent maps the DTO to the entity', () async {
      host.callResults['weather.getCurrent'] = {'weather': weatherPayload};
      final repo = RpcWeatherRepository(client);
      final snap = await repo.getCurrent('ws-1');
      expect(snap, isNotNull);
      expect(snap!.condition.name, 'clouds');
      expect(snap.temperatureCelsius, 18.5);
    });

    test('getCurrent returns null when absent', () async {
      host.callResults['weather.getCurrent'] = const {};
      final repo = RpcWeatherRepository(client);
      expect(await repo.getCurrent('ws-1'), isNull);
    });

    test('watchCurrent maps the live stream to entities', () async {
      host.snapshotFor('weather.watchCurrent', {'weather': weatherPayload});
      final repo = RpcWeatherRepository(client);
      final snap = await repo.watchCurrent('ws-1').first;
      expect(snap, isNotNull);
      expect(snap!.windSpeedKmh, 12.0);
    });

    test('write helpers delegate to the remote layer', () async {
      final repo = RpcWeatherRepository(client);
      await repo.refreshNow('ws-1');
      await repo.setManualLocation('ws-1', latitude: 1, longitude: 2);
      await repo.clearManualLocation('ws-1');
      expect(host.lastCall('weather.refreshNow'), isNotNull);
      expect(host.lastCall('weather.setManualLocation')!.args['latitude'], 1);
      expect(host.lastCall('weather.clearManualLocation'), isNotNull);
    });
  });
}

/// Records a `repo/call` invocation.
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
