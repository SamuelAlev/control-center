import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RemoteCalendarConnect] — the device-code Google Calendar connect
/// over RPC. Pins the begin/poll/disconnect ops, the args shape, the status
/// switch (incl. the unknown fallback) and the duration parsing defaults.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteCalendarConnect.begin', () {
    test('maps the begin DTO and forwards client id + secret', () async {
      host.callResults['calendar.beginConnect'] = {
        'handle': 'h-1',
        'user_code': 'ABC-123',
        'verification_url': 'https://google.com/device',
        'interval_seconds': 7,
        'expires_in_seconds': 1800,
      };
      final connect = RemoteCalendarConnect(client);
      final begin = await connect.begin(clientId: 'cid', clientSecret: 'sec');
      expect(begin.handle, 'h-1');
      expect(begin.userCode, 'ABC-123');
      expect(begin.verificationUrl, 'https://google.com/device');
      expect(begin.interval, const Duration(seconds: 7));
      expect(begin.expiresIn, const Duration(seconds: 1800));
      final call = host.lastCall('calendar.beginConnect')!;
      expect(call.args['client_id'], 'cid');
      expect(call.args['client_secret'], 'sec');
    });

    test('defaults interval/expiresIn when the fields are absent', () async {
      host.callResults['calendar.beginConnect'] = {
        'handle': 'h-1',
        'user_code': 'X',
        'verification_url': 'u',
      };
      final connect = RemoteCalendarConnect(client);
      final begin = await connect.begin(clientId: 'c', clientSecret: 's');
      expect(begin.interval, const Duration(seconds: 5));
      expect(begin.expiresIn, const Duration(seconds: 1800));
    });
  });

  group('RemoteCalendarConnect.poll', () {
    test('maps each status and the account_email', () async {
      host.callResults['calendar.pollConnect'] = {
        'status': 'connected',
        'account_email': 'sam@example.com',
      };
      final connect = RemoteCalendarConnect(client);
      final poll = await connect.poll('h-1');
      expect(poll.status, CalendarConnectPollStatus.connected);
      expect(poll.accountEmail, 'sam@example.com');
      expect(host.lastCall('calendar.pollConnect')!.args['handle'], 'h-1');
    });

    test('maps the pending status', () async {
      host.callResults['calendar.pollConnect'] = {'status': 'pending'};
      final connect = RemoteCalendarConnect(client);
      expect(
        (await connect.poll('h-1')).status,
        CalendarConnectPollStatus.pending,
      );
    });

    test('maps the denied status', () async {
      host.callResults['calendar.pollConnect'] = {'status': 'denied'};
      final connect = RemoteCalendarConnect(client);
      expect(
        (await connect.poll('h-1')).status,
        CalendarConnectPollStatus.denied,
      );
    });

    test('maps the expired status', () async {
      host.callResults['calendar.pollConnect'] = {'status': 'expired'};
      final connect = RemoteCalendarConnect(client);
      expect(
        (await connect.poll('h-1')).status,
        CalendarConnectPollStatus.expired,
      );
    });

    test('falls back to unknown for an unrecognised status', () async {
      host.callResults['calendar.pollConnect'] = {'status': 'weird'};
      final connect = RemoteCalendarConnect(client);
      expect(
        (await connect.poll('h-1')).status,
        CalendarConnectPollStatus.unknown,
      );
    });
  });

  group('RemoteCalendarConnect.disconnect', () {
    test('forwards the account_id', () async {
      final connect = RemoteCalendarConnect(client);
      await connect.disconnect('acc-1');
      expect(host.lastCall('calendar.disconnect')!.args['account_id'], 'acc-1');
    });
  });
}

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

class _Host {
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<_Call> calls = [];
  final Map<String, Map<String, dynamic>> callResults = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
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
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
