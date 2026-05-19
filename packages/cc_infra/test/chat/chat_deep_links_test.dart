import 'package:cc_infra/cc_infra.dart';
import 'package:test/test.dart';

/// [ChatDeepLinks]: the one place that decides what a "View in Control Center"
/// button points at.
///
/// Two things matter. The origin has to be derived from the RPC URL the server
/// already publishes (nobody configures a second one) and an id that did not
/// come from Control Center must never reach the URL — the page built from it
/// hands the browser a deep link, so a reflected id is a reflected navigation.
void main() {
  group('origin', () {
    test('the RPC scheme becomes the linkable one', () {
      // Same listener, same port: the WebSocket upgrade rides the HTTP server.
      expect(
        ChatDeepLinks.fromServerUrl('ws://127.0.0.1:8765/rpc')?.origin,
        'http://127.0.0.1:8765',
      );
      expect(
        ChatDeepLinks.fromServerUrl('wss://cc.example/rpc')?.origin,
        'https://cc.example',
      );
      // A default port is dropped, so the same server never yields two origins.
      expect(
        ChatDeepLinks.fromServerUrl('https://cc.example:443/')?.origin,
        'https://cc.example',
      );
    });

    test('a URL naming no reachable host builds nothing', () {
      // Better no button than a button that goes nowhere.
      expect(ChatDeepLinks.fromServerUrl(''), isNull);
      expect(ChatDeepLinks.fromServerUrl('rpc'), isNull);
      expect(ChatDeepLinks.fromServerUrl('unix:///tmp/cc.sock'), isNull);
    });

    test('loopback is kept, because the operator is sitting at it', () {
      expect(
        ChatDeepLinks.fromServerUrl('ws://localhost:1/rpc')?.origin,
        'http://localhost:1',
      );
    });
  });

  group('links', () {
    const links = ChatDeepLinks(origin: 'https://cc.example');

    test('a space and a ticket each get their route', () {
      expect(
        links.space('ws-1', 'chan-1'),
        'https://cc.example/open/workspaces/ws-1/spaces/chan-1',
      );
      expect(
        links.ticket('ws-1', 'ticket-9'),
        'https://cc.example/open/workspaces/ws-1/tickets/ticket-9',
      );
    });

    test('an id that is not one of ours is refused, not escaped', () {
      for (final bad in [
        '../../etc/passwd',
        'chan 1',
        'chan/1',
        'chan?x=1',
        'chan#frag',
        '',
        'a' * 129,
      ]) {
        expect(links.space('ws-1', bad), isNull, reason: bad);
        expect(links.ticket(bad, 'ticket-1'), isNull, reason: bad);
        expect(ChatDeepLinks.isSafeId(bad), isFalse, reason: bad);
      }
    });

    test('the shapes Control Center actually generates pass', () {
      for (final id in [
        '7f1c8e0a-1b2c-4d5e-8f90-abcdef123456',
        'chan_1',
        'ticket-CC-1',
        'v1.2',
      ]) {
        expect(ChatDeepLinks.isSafeId(id), isTrue, reason: id);
      }
    });
  });
}
