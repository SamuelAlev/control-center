import 'dart:async';
import 'dart:convert';

import 'package:cc_infra/src/rigs/cdp_client.dart';
import 'package:test/test.dart';

/// A `CdpSocket` driven entirely from the test, so the protocol layer is
/// exercised without Chromium installed. Without this seam every CDP test
/// would need a browser, which in practice means no CDP tests.
class _FakeCdpSocket implements CdpSocket {
  final StreamController<dynamic> _incoming =
      StreamController<dynamic>.broadcast();

  /// Frames the client sent, decoded.
  final List<Map<String, dynamic>> sent = [];

  bool closed = false;

  /// Canned replies keyed by CDP method name.
  final Map<String, Map<String, dynamic>> autoReply = {};

  /// Answers every method not in [autoReply] with an empty result, so a test
  /// that cares about WHICH commands were sent does not have to enumerate
  /// them.
  bool replyToAll = false;

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  void add(String data) {
    final decoded = jsonDecode(data) as Map<String, dynamic>;
    sent.add(decoded);
    final reply =
        autoReply[decoded['method']] ??
        (replyToAll ? const <String, dynamic>{} : null);
    if (reply != null) {
      // Answer on a later microtask, as a real socket would.
      scheduleMicrotask(
        () => _push(jsonEncode({'id': decoded['id'], 'result': reply})),
      );
    }
  }

  @override
  Future<void> close() async {
    closed = true;
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }

  /// Drops the connection from the BROWSER side — the case a client cannot
  /// tell from a deliberate close unless it tracks the difference.
  void kill() {
    if (!_incoming.isClosed) {
      unawaited(_incoming.close());
    }
  }

  /// Pushes a raw frame from the "browser".
  void push(Map<String, dynamic> frame) => _push(jsonEncode(frame));

  /// Delivers a raw wire string, so a test can stage a frame the encoder
  /// would never produce (a short reply, a malformed payload).
  void pushRaw(String frame) => _push(frame);

  void _push(String frame) {
    if (_incoming.isClosed) {
      return;
    }
    _incoming.add(frame);
  }

  /// Answers the pending command with id [id].
  void reply(int id, Map<String, dynamic> result) =>
      push({'id': id, 'result': result});

  /// Fails the pending command with id [id].
  void fail(int id, String message, {int code = -32000}) => push({
    'id': id,
    'error': {'code': code, 'message': message},
  });
}

/// Lets every pending microtask and short timer run.
Future<void> _settle([int millis = 5]) =>
    Future<void>.delayed(Duration(milliseconds: millis));

/// A reconnect policy that hands out [replacements] in order, then fails.
CdpReconnectPolicy _policyOver(
  List<_FakeCdpSocket> replacements, {
  Duration window = const Duration(seconds: 2),
  void Function()? onAttach,
  String? Function(String? preferred)? targetIdFor,
}) {
  var index = 0;
  return CdpReconnectPolicy(
    attach: (preferred) async {
      onAttach?.call();
      if (index >= replacements.length) {
        throw const CdpException('no page target on the DevTools endpoint');
      }
      return CdpAttachment(
        replacements[index++],
        targetId: targetIdFor == null ? preferred : targetIdFor(preferred),
      );
    },
    backoff: const [Duration(milliseconds: 1)],
    window: window,
  );
}

/// The frame a browser sends when a page target appears.
Map<String, dynamic> _created(String id, {String url = 'https://example'}) => {
  'method': 'Target.targetCreated',
  'params': {
    'targetInfo': {
      'targetId': id,
      'type': 'page',
      'url': url,
      'title': 'page $id',
    },
  },
};

void main() {
  group('command correlation', () {
    test('a reply resolves its own command', () async {
      final socket = _FakeCdpSocket();
      final client = CdpClient.over(socket);
      final future = client.send('Page.navigate', params: {'url': 'x'});
      await Future<void>.delayed(Duration.zero);
      socket.reply(socket.sent.single['id'] as int, {'frameId': 'f1'});
      expect(await future, containsPair('frameId', 'f1'));
      await client.close();
    });

    test('out-of-order replies still match their commands', () async {
      // CDP does not promise FIFO across concurrent commands, so correlating
      // by arrival order would pair the wrong answers together.
      final socket = _FakeCdpSocket();
      final client = CdpClient.over(socket);
      final first = client.send('A');
      final second = client.send('B');
      await Future<void>.delayed(Duration.zero);
      final idA = socket.sent[0]['id'] as int;
      final idB = socket.sent[1]['id'] as int;
      socket
        ..reply(idB, {'who': 'B'})
        ..reply(idA, {'who': 'A'});
      expect(await first, containsPair('who', 'A'));
      expect(await second, containsPair('who', 'B'));
      await client.close();
    });

    test('an error reply becomes a typed exception', () async {
      final socket = _FakeCdpSocket();
      final client = CdpClient.over(socket);
      final future = client.send('Bad.Method');
      await Future<void>.delayed(Duration.zero);
      socket.fail(socket.sent.single['id'] as int, 'no such method');
      await expectLater(
        future,
        throwsA(
          isA<CdpException>().having(
            (e) => e.message,
            'message',
            contains('no such method'),
          ),
        ),
      );
      await client.close();
    });

    test('a closed socket fails everything in flight', () async {
      // Otherwise a browser that dies mid-action leaves the caller awaiting a
      // future that never completes, and the rig looks hung rather than gone.
      final socket = _FakeCdpSocket();
      final client = CdpClient.over(socket);
      final future = client.send('Page.navigate');
      await Future<void>.delayed(Duration.zero);
      await socket.close();
      await expectLater(future, throwsA(isA<CdpException>()));
    });

    test('sending after close fails fast', () async {
      final socket = _FakeCdpSocket();
      final client = CdpClient.over(socket);
      await client.close();
      await expectLater(
        client.send('Page.enable'),
        throwsA(isA<CdpException>()),
      );
    });
  });

  group('console buffering', () {
    test('console output is buffered until drained', () async {
      final socket = _FakeCdpSocket();
      final client = CdpClient.over(socket);
      socket.push({
        'method': 'Runtime.consoleAPICalled',
        'params': {
          'type': 'error',
          'args': [
            {'value': 'boom'},
          ],
        },
      });
      await Future<void>.delayed(Duration.zero);
      final drained = client.drainConsole();
      expect(drained.single, contains('boom'));
      expect(drained.single, contains('error'));
      expect(
        client.drainConsole(),
        isEmpty,
        reason: 'Draining twice must not replay what was already read.',
      );
      await client.close();
    });

    test('the buffer is bounded', () async {
      // A page in a logging loop must not grow the host's memory or spend the
      // whole context window on its own noise.
      final socket = _FakeCdpSocket();
      final client = CdpClient.over(socket);
      for (var i = 0; i < 500; i++) {
        socket.push({
          'method': 'Log.entryAdded',
          'params': {
            'entry': {'level': 'info', 'text': 'line $i'},
          },
        });
      }
      await Future<void>.delayed(Duration.zero);
      final drained = client.drainConsole();
      expect(drained.length, lessThanOrEqualTo(200));
      expect(
        drained.last,
        contains('line 499'),
        reason: 'The newest lines are the ones worth keeping.',
      );
      await client.close();
    });
  });

  group('typing', () {
    test(
      'text goes in one insertText, not a key event per character',
      () async {
        final socket = _FakeCdpSocket()
          ..autoReply['Input.insertText'] = const {};
        final client = CdpClient.over(socket);
        await client.typeText('hello 🌍');
        expect(socket.sent, hasLength(1));
        expect(socket.sent.single['method'], 'Input.insertText');
        expect(
          (socket.sent.single['params'] as Map)['text'],
          'hello 🌍',
          reason:
              'A synthesized char event per rune mangles anything outside the '
              'BMP and costs one round trip per character.',
        );
        await client.close();
      },
    );

    test('empty text sends nothing', () async {
      final socket = _FakeCdpSocket();
      final client = CdpClient.over(socket);
      await client.typeText('');
      expect(socket.sent, isEmpty);
      await client.close();
    });

    test('select-all sends the ctrl modifier', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Input.dispatchKeyEvent'] = const {};
      final client = CdpClient.over(socket);
      await client.selectAll();
      expect(socket.sent, hasLength(2)); // keyDown + keyUp
      for (final frame in socket.sent) {
        expect((frame['params'] as Map)['modifiers'], 2);
        expect((frame['params'] as Map)['key'], 'a');
      }
      await client.close();
    });
  });

  group('pressKey', () {
    test('a printable character is inserted as text', () async {
      // The regression this pins: `dispatchKeyEvent` with no `text` and no
      // virtual-key code fires a keydown the page can see and inserts NOTHING,
      // so human take-over typing looked like it worked and typed nothing.
      final socket = _FakeCdpSocket()..autoReply['Input.insertText'] = const {};
      final client = CdpClient.over(socket);
      expect(await client.pressKey('a'), isTrue);
      expect(socket.sent.single['method'], 'Input.insertText');
      expect((socket.sent.single['params'] as Map)['text'], 'a');
      await client.close();
    });

    test('a non-ASCII printable character is inserted too', () async {
      final socket = _FakeCdpSocket()..autoReply['Input.insertText'] = const {};
      final client = CdpClient.over(socket);
      expect(await client.pressKey('é'), isTrue);
      expect((socket.sent.single['params'] as Map)['text'], 'é');
      await client.close();
    });

    test(
      'a named key dispatches a keydown/keyup pair with its vk code',
      () async {
        final socket = _FakeCdpSocket()
          ..autoReply['Input.dispatchKeyEvent'] = const {};
        final client = CdpClient.over(socket);
        expect(await client.pressKey('ArrowDown'), isTrue);
        expect(socket.sent, hasLength(2));
        expect((socket.sent[0]['params'] as Map)['type'], 'keyDown');
        expect((socket.sent[1]['params'] as Map)['type'], 'keyUp');
        for (final frame in socket.sent) {
          final params = frame['params'] as Map;
          expect(frame['method'], 'Input.dispatchKeyEvent');
          expect(params['key'], 'ArrowDown');
          expect(params['code'], 'ArrowDown');
          expect(params['windowsVirtualKeyCode'], 40);
          expect(params['nativeVirtualKeyCode'], 40);
          expect(
            params.containsKey('text'),
            isFalse,
            reason:
                'An arrow inserts no character; sending `text` would type '
                'one.',
          );
        }
        await client.close();
      },
    );

    test('function keys are covered', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Input.dispatchKeyEvent'] = const {};
      final client = CdpClient.over(socket);
      expect(await client.pressKey('F5'), isTrue);
      expect(
        (socket.sent.first['params'] as Map)['windowsVirtualKeyCode'],
        116,
      );
      expect((socket.sent.first['params'] as Map)['code'], 'F5');
      await client.close();
    });

    test('Enter carries its text, Escape does not', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Input.dispatchKeyEvent'] = const {};
      final client = CdpClient.over(socket);
      await client.pressKey('Enter');
      expect((socket.sent.first['params'] as Map)['text'], '\r');
      socket.sent.clear();
      await client.pressKey('Escape');
      expect((socket.sent.first['params'] as Map).containsKey('text'), isFalse);
      await client.close();
    });

    test('key names are matched case-insensitively', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Input.dispatchKeyEvent'] = const {};
      final client = CdpClient.over(socket);
      expect(await client.pressKey('pagedown'), isTrue);
      expect((socket.sent.first['params'] as Map)['key'], 'PageDown');
      await client.close();
    });

    test('an unknown key name is refused, not silently dispatched', () async {
      final socket = _FakeCdpSocket();
      final client = CdpClient.over(socket);
      expect(await client.pressKey('Frobnicate'), isFalse);
      expect(socket.sent, isEmpty);
      await client.close();
    });

    test(
      'a named key with modifiers carries the bitmask and no text',
      () async {
        final socket = _FakeCdpSocket()
          ..autoReply['Input.dispatchKeyEvent'] = const {};
        final client = CdpClient.over(socket);
        expect(await client.pressKey('Enter', modifiers: ['ctrl']), isTrue);
        for (final frame in socket.sent) {
          final params = frame['params'] as Map;
          expect(params['modifiers'], 2);
          expect(
            params.containsKey('text'),
            isFalse,
            reason: 'ctrl+Enter submits; it must not also type a newline.',
          );
        }
        await client.close();
      },
    );

    test(
      'shift+arrow extends the selection (the modifier reaches the page)',
      () async {
        final socket = _FakeCdpSocket()
          ..autoReply['Input.dispatchKeyEvent'] = const {};
        final client = CdpClient.over(socket);
        expect(
          await client.pressKey('ArrowLeft', modifiers: ['shift']),
          isTrue,
        );
        expect((socket.sent.first['params'] as Map)['modifiers'], 8);
        await client.close();
      },
    );

    test(
      'a letter chord dispatches a real key event, not insertText',
      () async {
        final socket = _FakeCdpSocket()
          ..autoReply['Input.dispatchKeyEvent'] = const {};
        final client = CdpClient.over(socket);
        expect(await client.pressKey('c', modifiers: ['ctrl']), isTrue);
        // insertText has no way to carry a modifier, so ctrl+c MUST be a
        // synthesized key event or the page never copies.
        expect(socket.sent.map((f) => f['method']), [
          'Input.dispatchKeyEvent',
          'Input.dispatchKeyEvent',
        ]);
        final params = socket.sent.first['params'] as Map;
        expect(params['key'], 'c');
        expect(params['code'], 'KeyC');
        expect(params['windowsVirtualKeyCode'], 67);
        expect(params['modifiers'], 2);
        await client.close();
      },
    );

    test('a chorded non-alphanumeric character is refused', () async {
      // '€' has no layout-independent physical key, so there is no honest
      // code to send — the same reason bare printable characters go through
      // insertText.
      final socket = _FakeCdpSocket();
      final client = CdpClient.over(socket);
      expect(await client.pressKey('€', modifiers: ['ctrl']), isFalse);
      expect(socket.sent, isEmpty);
      await client.close();
    });
  });

  group('pointer primitives', () {
    test(
      'hover moves report no buttons; a mid-drag move reports the held one',
      () async {
        final socket = _FakeCdpSocket()
          ..autoReply['Input.dispatchMouseEvent'] = const {};
        final client = CdpClient.over(socket);
        await client.moveMouse(10, 20);
        var params = socket.sent.single['params'] as Map;
        expect(params['type'], 'mouseMoved');
        expect(params['x'], 10);
        expect(params['y'], 20);
        expect(params['buttons'], 0);
        socket.sent.clear();
        await client.moveMouse(11, 21, dragging: true);
        params = socket.sent.single['params'] as Map;
        expect(
          params['buttons'],
          1,
          reason:
              'Chromium extends a selection only under a move that still '
              'reports the button held.',
        );
        await client.close();
      },
    );

    test('mouseDown carries the button mask and the click count', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Input.dispatchMouseEvent'] = const {};
      final client = CdpClient.over(socket);
      await client.mouseDown(5, 6, clickCount: 2);
      final params = socket.sent.single['params'] as Map;
      expect(params['type'], 'mousePressed');
      expect(params['button'], 'left');
      expect(params['buttons'], 1);
      expect(
        params['clickCount'],
        2,
        reason:
            'A double click exists ONLY as clickCount 2 on the press — '
            'two count-1 presses are two clicks, never a word selection.',
      );
      await client.close();
    });

    test('mouseUp releases with an empty mask', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Input.dispatchMouseEvent'] = const {};
      final client = CdpClient.over(socket);
      await client.mouseUp(5, 6);
      final params = socket.sent.single['params'] as Map;
      expect(params['type'], 'mouseReleased');
      expect(params['buttons'], 0);
      await client.close();
    });

    test('clickAt passes a click count through to the press', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Input.dispatchMouseEvent'] = const {};
      final client = CdpClient.over(socket);
      await client.clickAt(7, 8, button: 'right', clickCount: 2);
      expect(socket.sent, hasLength(2));
      final press = socket.sent.first['params'] as Map;
      expect(press['button'], 'right');
      expect(press['buttons'], 2);
      expect(press['clickCount'], 2);
      await client.close();
    });
  });

  group('reload and navigation state', () {
    test('reload forwards the cache flag', () async {
      final socket = _FakeCdpSocket()..autoReply['Page.reload'] = const {};
      final client = CdpClient.over(socket);
      await client.reload(ignoreCache: true);
      expect(socket.sent.single['method'], 'Page.reload');
      expect((socket.sent.single['params'] as Map)['ignoreCache'], isTrue);
      await client.close();
    });

    test('stopLoading is Page.stopLoading', () async {
      final socket = _FakeCdpSocket()..autoReply['Page.stopLoading'] = const {};
      final client = CdpClient.over(socket);
      await client.stopLoading();
      expect(socket.sent.single['method'], 'Page.stopLoading');
      await client.close();
    });

    test('navigationState reads the history position', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Page.getNavigationHistory'] = const {
          'currentIndex': 1,
          'entries': [
            {'id': 1, 'url': 'https://a.test'},
            {'id': 2, 'url': 'https://b.test'},
            {'id': 3, 'url': 'https://c.test'},
          ],
        };
      final client = CdpClient.over(socket);
      final state = await client.navigationState();
      expect(state.url, 'https://b.test');
      expect(state.canGoBack, isTrue);
      expect(state.canGoForward, isTrue);
      expect(await client.currentUrl(), 'https://b.test');
      await client.close();
    });

    test(
      'the first entry cannot go back, the last cannot go forward',
      () async {
        final socket = _FakeCdpSocket()
          ..autoReply['Page.getNavigationHistory'] = const {
            'currentIndex': 0,
            'entries': [
              {'id': 1, 'url': 'https://a.test'},
            ],
          };
        final client = CdpClient.over(socket);
        final state = await client.navigationState();
        expect(state.canGoBack, isFalse);
        expect(state.canGoForward, isFalse);
        await client.close();
      },
    );

    test(
      'a malformed history answer throws rather than reporting "no page"',
      () async {
        final socket = _FakeCdpSocket()
          ..autoReply['Page.getNavigationHistory'] = const {};
        final client = CdpClient.over(socket);
        expect(client.navigationState, throwsA(isA<CdpException>()));
        // currentUrl stays the forgiving one: the URL is context, not an answer.
        expect(await client.currentUrl(), '');
        await client.close();
      },
    );
  });

  group('domSnapshot', () {
    /// A document whose only content sits OUTSIDE the queried subtree, so a
    /// snapshot that quietly returns the whole page is visible as a failure.
    Map<String, dynamic> documentReply() => {
      'root': {
        'nodeId': 1,
        'nodeName': '#document',
        'nodeType': 9,
        'children': [
          {
            'nodeId': 2,
            'nodeName': 'DIV',
            'nodeType': 1,
            'attributes': ['id', 'outside'],
            'children': [
              {
                'nodeId': 3,
                'nodeName': '#text',
                'nodeType': 3,
                'nodeValue': 'not in the subtree',
              },
            ],
          },
        ],
      },
    };

    test('a selector scopes the walk to that node', () async {
      // The regression this pins: the selector was prepended as a label and
      // the WHOLE document returned under it, which reads to a model as "this
      // is everything inside that element".
      final socket = _FakeCdpSocket()
        ..autoReply['DOM.getDocument'] = documentReply()
        ..autoReply['DOM.querySelector'] = {'nodeId': 9}
        ..autoReply['DOM.describeNode'] = {
          'node': {
            'nodeId': 9,
            'nodeName': 'SECTION',
            'nodeType': 1,
            'attributes': ['id', 'panel'],
            'children': [
              {
                'nodeId': 10,
                'nodeName': '#text',
                'nodeType': 3,
                'nodeValue': 'inside the subtree',
              },
            ],
          },
        };
      final client = CdpClient.over(socket);
      final body = await client.domSnapshot(selector: '#panel');
      expect(body, isNotNull);
      expect(body, contains('inside the subtree'));
      expect(body, isNot(contains('not in the subtree')));
      expect(body, contains('<section id="panel">'));
      await client.close();
    });

    test(
      'a selector that matches nothing returns null, not the page',
      () async {
        final socket = _FakeCdpSocket()
          ..autoReply['DOM.getDocument'] = documentReply()
          // CDP answers a miss with nodeId 0 rather than an error.
          ..autoReply['DOM.querySelector'] = {'nodeId': 0};
        final client = CdpClient.over(socket);
        expect(await client.domSnapshot(selector: '#missing'), isNull);
        expect(
          socket.sent.map((f) => f['method']),
          isNot(contains('DOM.describeNode')),
        );
        await client.close();
      },
    );

    test('no selector still walks the whole document', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['DOM.getDocument'] = documentReply();
      final client = CdpClient.over(socket);
      final body = await client.domSnapshot();
      expect(body, contains('not in the subtree'));
      expect(body, isNot(contains('[subtree')));
      await client.close();
    });
  });

  group('scrollAt', () {
    test('a wheel event is dispatched at the element centre', () async {
      // A wheel event scrolls whatever is under the POINTER, so scrolling a
      // named container means aiming at it.
      final socket = _FakeCdpSocket()
        ..autoReply['DOM.getDocument'] = {
          'root': {'nodeId': 1},
        }
        ..autoReply['DOM.querySelector'] = {'nodeId': 7}
        ..autoReply['DOM.getBoxModel'] = {
          'model': {
            'content': [100, 200, 300, 200, 300, 400, 100, 400],
          },
        }
        ..autoReply['Input.dispatchMouseEvent'] = const {};
      final client = CdpClient.over(socket);
      expect(await client.scrollAt('#list', 0, 400), isTrue);
      final wheel = socket.sent.last;
      expect(wheel['method'], 'Input.dispatchMouseEvent');
      final params = wheel['params'] as Map;
      expect(params['type'], 'mouseWheel');
      expect(params['x'], 200);
      expect(params['y'], 300);
      expect(params['deltaY'], 400);
      await client.close();
    });

    test('a selector that matches nothing scrolls nothing', () async {
      // Falling back to the page would move something else entirely and log
      // as if the container had scrolled.
      final socket = _FakeCdpSocket()
        ..autoReply['DOM.getDocument'] = {
          'root': {'nodeId': 1},
        }
        ..autoReply['DOM.querySelector'] = {'nodeId': 0};
      final client = CdpClient.over(socket);
      expect(await client.scrollAt('#missing', 0, 400), isFalse);
      expect(
        socket.sent.map((f) => f['method']),
        isNot(contains('Input.dispatchMouseEvent')),
      );
      await client.close();
    });
  });

  group('screencast', () {
    test('a requested fps maps onto an every-Nth-frame throttle', () async {
      // CDP has no fps dial; it drops frames instead.
      final socket = _FakeCdpSocket()
        ..autoReply['Page.startScreencast'] = const {};
      final client = CdpClient.over(socket);
      await client.startScreencast(maxWidth: 1280, maxHeight: 800, quality: 60);
      final params = socket.sent.single['params'] as Map;
      expect(params['maxWidth'], 1280);
      expect(params['quality'], 60);
      expect(params['everyNthFrame'], greaterThanOrEqualTo(1));
      await client.close();
    });

    test('quality is clamped', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Page.startScreencast'] = const {};
      final client = CdpClient.over(socket);
      await client.startScreencast(maxWidth: 100, maxHeight: 100, quality: 900);
      expect((socket.sent.single['params'] as Map)['quality'], 100);
      await client.close();
    });
  });

  group('screenshot', () {
    test('an empty payload is an error, not an empty image', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Page.captureScreenshot'] = const {'data': ''};
      final client = CdpClient.over(socket);
      await expectLater(
        client.captureScreenshot(),
        throwsA(isA<CdpException>()),
      );
      await client.close();
    });
  });

  group('request timeout', () {
    test('the per-request deadline is configurable', () async {
      final socket = _FakeCdpSocket();
      final client = CdpClient.over(
        socket,
        requestTimeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        client.send('Never.answered'),
        throwsA(
          isA<CdpException>().having(
            (e) => e.message,
            'message',
            contains('timed out'),
          ),
        ),
      );
      await client.close();
    });
  });

  group('reconnect', () {
    test(
      'a drop re-attaches and re-applies domains, viewport and screencast',
      () async {
        // The regression this pins: a dropped WebSocket was terminal even though
        // the in-guest Chromium restarts and would accept a new connection — and
        // a re-attach that forgot the session state comes back with no events,
        // a default viewport and a dead watch lane.
        final first = _FakeCdpSocket()..replyToAll = true;
        final second = _FakeCdpSocket()..replyToAll = true;
        final client = CdpClient.over(
          first,
          targetId: 'A',
          reconnect: _policyOver([second]),
        );
        await client.enableDomains();
        await client.setViewport(
          width: 1280,
          height: 800,
          deviceScaleFactor: 2,
        );
        await client.startScreencast(
          maxWidth: 2560,
          maxHeight: 1600,
          quality: 45,
        );

        first.kill();
        await client.connectionStates.firstWhere(
          (s) => s == CdpConnectionState.connected,
        );

        final methods = second.sent.map((f) => f['method']).toList();
        expect(
          methods,
          containsAll([
            'Page.enable',
            'Runtime.enable',
            'DOM.enable',
            'Log.enable',
            'Emulation.setDeviceMetricsOverride',
            'Page.startScreencast',
          ]),
        );
        final metrics =
            second.sent.firstWhere(
                  (f) => f['method'] == 'Emulation.setDeviceMetricsOverride',
                )['params']
                as Map;
        expect(metrics['width'], 1280);
        expect(metrics['height'], 800);
        // The SCALE has to survive too. Coming back at 1x would halve the watch
        // lane's resolution mid-session, and nothing about that looks like a
        // dropped socket — it looks like the stream just got worse.
        expect(metrics['deviceScaleFactor'], 2);
        final cast =
            second.sent.firstWhere(
                  (f) => f['method'] == 'Page.startScreencast',
                )['params']
                as Map;
        expect(cast['quality'], 45);
        await client.close();
      },
    );

    test(
      'the viewport lays out in CSS pixels and renders in device pixels',
      () async {
        // The two halves of one request, and swapping them is the failure this
        // guards: multiplying the SIZE gives a guest that lays out as if it had
        // a 2560px window and renders text at half size, which is exactly what
        // sending physical pixels used to do.
        final socket = _FakeCdpSocket()..replyToAll = true;
        final client = CdpClient.over(socket, targetId: 'A');
        await client.setViewport(
          width: 1276,
          height: 960,
          deviceScaleFactor: 2,
        );
        final metrics =
            socket.sent.firstWhere(
                  (f) => f['method'] == 'Emulation.setDeviceMetricsOverride',
                )['params']
                as Map;
        expect(metrics['width'], 1276);
        expect(metrics['height'], 960);
        expect(metrics['deviceScaleFactor'], 2);
        await client.close();
      },
    );

    test('an unspecified scale stays 1x', () async {
      final socket = _FakeCdpSocket()..replyToAll = true;
      final client = CdpClient.over(socket, targetId: 'A');
      await client.setViewport(width: 800, height: 600);
      final metrics =
          socket.sent.firstWhere(
                (f) => f['method'] == 'Emulation.setDeviceMetricsOverride',
              )['params']
              as Map;
      expect(metrics['deviceScaleFactor'], 1);
      await client.close();
    });

    test(
      'a viewer holding the frame stream keeps working across a re-attach',
      () async {
        // The watch lane is `screencastFrames` — its own stream, NOT `events`,
        // so a 50–500 KB base64 frame never has to be parsed into an event map
        // at 30 fps. Ending it on a drop would close the human's video with no
        // way back short of reopening the tab.
        final first = _FakeCdpSocket()..replyToAll = true;
        final second = _FakeCdpSocket()..replyToAll = true;
        final client = CdpClient.over(first, reconnect: _policyOver([second]));
        await client.startScreencast(maxWidth: 800, maxHeight: 600);

        final frames = <String>[];
        var ended = false;
        final sub = client.screencastFrames.listen(
          (f) => frames.add(utf8.decode(f.bytes)),
          onDone: () => ended = true,
        );
        first.push({
          'method': 'Page.screencastFrame',
          'params': {'data': base64.encode(utf8.encode('one')), 'sessionId': 1},
        });
        await _settle();

        first.kill();
        await client.connectionStates.firstWhere(
          (s) => s == CdpConnectionState.connected,
        );
        second.push({
          'method': 'Page.screencastFrame',
          'params': {'data': base64.encode(utf8.encode('two')), 'sessionId': 2},
        });
        await _settle();

        expect(frames, ['one', 'two']);
        expect(
          ended,
          isFalse,
          reason: 'The viewer must see a gap, not an end.',
        );
        expect(
          second.sent.map((f) => f['method']),
          contains('Page.startScreencast'),
        );
        await sub.cancel();
        await client.close();
      },
    );

    test('in-flight commands fail saying a re-attach is under way', () async {
      final first = _FakeCdpSocket();
      final second = _FakeCdpSocket()..replyToAll = true;
      final client = CdpClient.over(first, reconnect: _policyOver([second]));

      final inFlight = client.send('Page.navigate');
      await _settle();
      first.kill();

      await expectLater(
        inFlight,
        throwsA(
          isA<CdpException>().having(
            (e) => e.message,
            'message',
            contains('re-attach is in progress'),
          ),
        ),
      );
      await client.connectionStates.firstWhere(
        (s) => s == CdpConnectionState.connected,
      );
      await client.close();
    });

    test(
      'the state stream reports connected → reconnecting → connected',
      () async {
        final first = _FakeCdpSocket()..replyToAll = true;
        final second = _FakeCdpSocket()..replyToAll = true;
        final client = CdpClient.over(first, reconnect: _policyOver([second]));
        final states = <CdpConnectionState>[];
        final sub = client.connectionStates.listen(states.add);
        await _settle();

        first.kill();
        await client.connectionStates.firstWhere(
          (s) => s == CdpConnectionState.connected,
        );
        await _settle();

        expect(states, [
          CdpConnectionState.connected,
          CdpConnectionState.reconnecting,
          CdpConnectionState.connected,
        ]);
        await sub.cancel();
        await client.close();
      },
    );

    test('an exhausted window ends in the terminal closed state', () async {
      final first = _FakeCdpSocket();
      final client = CdpClient.over(
        first,
        reconnect: _policyOver([], window: const Duration(milliseconds: 10)),
      );
      final states = <CdpConnectionState>[];
      final sub = client.connectionStates.listen(states.add);
      await _settle();

      first.kill();
      await _settle(120);

      expect(client.connectionState, CdpConnectionState.closed);
      expect(states.last, CdpConnectionState.closed);
      await expectLater(
        client.send('Page.enable'),
        throwsA(isA<CdpException>()),
      );
      await sub.cancel();
      await client.close();
    });

    test('a deliberate close never re-attaches', () async {
      var attaches = 0;
      final socket = _FakeCdpSocket();
      final client = CdpClient.over(
        socket,
        reconnect: _policyOver([_FakeCdpSocket()], onAttach: () => attaches++),
      );

      await client.close();
      await _settle(20);

      expect(attaches, 0);
      expect(client.connectionState, CdpConnectionState.closed);
    });

    test('without a policy a drop is terminal, as before', () async {
      final socket = _FakeCdpSocket();
      final client = CdpClient.over(socket);
      socket.kill();
      await _settle();
      expect(client.connectionState, CdpConnectionState.closed);
      await expectLater(
        client.send('Page.enable'),
        throwsA(isA<CdpException>()),
      );
    });
  });

  group('targets', () {
    test('created and destroyed page targets are tracked', () async {
      // A popup or a `target=_blank` link is otherwise invisible: only the
      // FIRST page target was ever attached to.
      final socket = _FakeCdpSocket()..replyToAll = true;
      final client = CdpClient.over(socket, targetId: 'A');
      socket
        ..push(_created('B', url: 'https://b'))
        ..push(_created('C', url: 'https://c'))
        ..push({
          'method': 'Target.targetCreated',
          'params': {
            'targetInfo': {
              'targetId': 'W',
              'type': 'service_worker',
              'url': 'https://w',
            },
          },
        });
      await _settle();

      expect(client.pageTargets.map((t) => t.id), ['B', 'C']);
      expect(client.pageTargets.first.url, 'https://b');

      socket.push({
        'method': 'Target.targetDestroyed',
        'params': {'targetId': 'B'},
      });
      await _settle();
      expect(client.pageTargets.map((t) => t.id), ['C']);
      await client.close();
    });

    test(
      'the newest survivor is attached when the current target dies',
      () async {
        // window.close() (or a popup replacing the page) otherwise leaves the
        // client pointed at a target that no longer exists.
        final first = _FakeCdpSocket()..replyToAll = true;
        final second = _FakeCdpSocket()..replyToAll = true;
        final client = CdpClient.over(
          first,
          targetId: 'A',
          reconnect: _policyOver([second]),
        );
        await client.enableDomains();
        first
          ..push(_created('B'))
          ..push(_created('C'));
        await _settle();

        first.push({
          'method': 'Target.targetDestroyed',
          'params': {'targetId': 'A'},
        });
        await _settle(50);

        expect(client.currentTargetId, 'C');
        expect(client.connectionState, CdpConnectionState.connected);
        expect(second.sent.map((f) => f['method']), contains('Page.enable'));
        await client.close();
      },
    );

    test('attachToTarget refuses a substitute target', () async {
      // Landing on a different page would make every later action address
      // something the caller never asked for.
      final first = _FakeCdpSocket()..replyToAll = true;
      final client = CdpClient.over(
        first,
        targetId: 'A',
        reconnect: _policyOver([
          _FakeCdpSocket()..replyToAll = true,
        ], targetIdFor: (_) => 'SOMETHING-ELSE'),
      );

      await expectLater(
        client.attachToTarget('B'),
        throwsA(isA<CdpException>()),
      );
      expect(client.currentTargetId, 'A');
      expect(
        client.connectionState,
        CdpConnectionState.connected,
        reason: 'A failed switch must not wedge the client.',
      );
      await client.close();
    });

    test('attachToTarget without an endpoint is refused, not silent', () async {
      final client = CdpClient.over(_FakeCdpSocket());
      await expectLater(
        client.attachToTarget('B'),
        throwsA(isA<CdpException>()),
      );
      await client.close();
    });
  });

  group('javascript dialogs', () {
    test('a confirm is dismissed and recorded', () async {
      // Unhandled, it blocks the renderer: the page stops answering, the
      // screencast freezes and every later action times out saying nothing.
      final socket = _FakeCdpSocket()..replyToAll = true;
      final client = CdpClient.over(socket);
      socket.push({
        'method': 'Page.javascriptDialogOpening',
        'params': {
          'type': 'confirm',
          'message': 'Delete everything?',
          'url': 'https://example/danger',
        },
      });
      await _settle();

      final handled = socket.sent.singleWhere(
        (f) => f['method'] == 'Page.handleJavaScriptDialog',
      );
      expect((handled['params'] as Map)['accept'], isFalse);
      final record = client.dialogs.single;
      expect(record.type, 'confirm');
      expect(record.message, 'Delete everything?');
      expect(record.url, 'https://example/danger');
      expect(record.accepted, isFalse);
      await client.close();
    });

    test('beforeunload is ACCEPTED so navigation is not wedged', () async {
      // Dismissing a beforeunload cancels the navigation that triggered it,
      // which leaves the page stuck on a form it can never leave.
      final socket = _FakeCdpSocket()..replyToAll = true;
      final client = CdpClient.over(socket);
      socket.push({
        'method': 'Page.javascriptDialogOpening',
        'params': {'type': 'beforeunload', 'message': '', 'url': 'https://x'},
      });
      await _settle();

      final handled = socket.sent.singleWhere(
        (f) => f['method'] == 'Page.handleJavaScriptDialog',
      );
      expect((handled['params'] as Map)['accept'], isTrue);
      expect(client.dialogs.single.accepted, isTrue);
      await client.close();
    });

    test('the record survives for a driver to read, then drains', () async {
      final socket = _FakeCdpSocket()..replyToAll = true;
      final client = CdpClient.over(socket);
      socket.push({
        'method': 'Page.javascriptDialogOpening',
        'params': {'type': 'alert', 'message': 'hi', 'url': 'https://x'},
      });
      await _settle();

      expect(client.dialogs, hasLength(1));
      expect(
        client.dialogs,
        hasLength(1),
        reason: 'Reading the dialogs must not consume them.',
      );
      expect(client.drainDialogs(), hasLength(1));
      expect(client.dialogs, isEmpty);
      await client.close();
    });

    test('the dialog buffer is bounded', () async {
      final socket = _FakeCdpSocket()..replyToAll = true;
      final client = CdpClient.over(socket);
      for (var i = 0; i < 400; i++) {
        socket.push({
          'method': 'Page.javascriptDialogOpening',
          'params': {'type': 'alert', 'message': 'n $i', 'url': 'https://x'},
        });
      }
      await _settle(20);

      final recorded = client.dialogs;
      expect(recorded.length, lessThanOrEqualTo(200));
      expect(recorded.last.message, 'n 399');
      await client.close();
    });

    test('auto-dismissal can be turned off', () async {
      final socket = _FakeCdpSocket()..replyToAll = true;
      final client = CdpClient.over(socket, autoDismissDialogs: false);
      socket.push({
        'method': 'Page.javascriptDialogOpening',
        'params': {'type': 'confirm', 'message': 'q', 'url': 'https://x'},
      });
      await _settle();

      expect(
        socket.sent.map((f) => f['method']),
        isNot(contains('Page.handleJavaScriptDialog')),
      );
      expect(client.dialogs, hasLength(1));
      await client.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Attach-address validation. `/json/list` is read over loopback but its BODY
  // is written by the browser INSIDE the guest, so `webSocketDebuggerUrl` is
  // untrusted data like every other extract. Attaching to whatever it names
  // would let a compromised guest have the HOST dial an arbitrary address and
  // then feed it attacker-chosen "CDP frames".
  // ---------------------------------------------------------------------------
  group('requireDebuggerSocketUri', () {
    test('accepts the normal loopback target', () {
      final uri = requireDebuggerSocketUri(
        'ws://127.0.0.1:9222/devtools/page/ABC',
        host: '127.0.0.1',
        port: 9222,
      );
      expect(uri.pathSegments.last, 'ABC');
    });

    test('accepts localhost against a 127.0.0.1 endpoint', () {
      // Chromium reports whichever spelling it was started with; both name the
      // same machine, which is the property that actually matters.
      expect(
        requireDebuggerSocketUri(
          'ws://localhost:9222/devtools/page/ABC',
          host: '127.0.0.1',
          port: 9222,
        ).host,
        'localhost',
      );
    });

    test('refuses a foreign host', () {
      expect(
        () => requireDebuggerSocketUri(
          'ws://attacker.example/devtools/page/ABC',
          host: '127.0.0.1',
          port: 9222,
        ),
        throwsA(isA<CdpException>()),
      );
    });

    test('refuses a different port on the same host', () {
      expect(
        () => requireDebuggerSocketUri(
          'ws://127.0.0.1:9333/devtools/page/ABC',
          host: '127.0.0.1',
          port: 9222,
        ),
        throwsA(isA<CdpException>()),
      );
    });

    test('refuses a non-WebSocket scheme', () {
      for (final url in const [
        'http://127.0.0.1:9222/devtools/page/ABC',
        'file:///etc/passwd',
        'not a url at all::::',
      ]) {
        expect(
          () => requireDebuggerSocketUri(url, host: '127.0.0.1', port: 9222),
          throwsA(isA<CdpException>()),
          reason: url,
        );
      }
    });

    test('refuses a URL carrying credentials', () {
      expect(
        () => requireDebuggerSocketUri(
          'ws://user:pw@127.0.0.1:9222/devtools/page/ABC',
          host: '127.0.0.1',
          port: 9222,
        ),
        throwsA(isA<CdpException>()),
      );
    });

    test('refuses a portless URL against a ported endpoint', () {
      expect(
        () => requireDebuggerSocketUri(
          'ws://127.0.0.1/devtools/page/ABC',
          host: '127.0.0.1',
          port: 9222,
        ),
        throwsA(isA<CdpException>()),
      );
    });

    test('checks only the scheme when no endpoint is supplied', () {
      // The `CdpClient.connect` case: the CALLER named the URL, so there is no
      // second source to cross-check against — but a non-ws scheme would still
      // have `WebSocket.connect` resolve something else entirely.
      expect(
        requireDebuggerSocketUri('wss://example.test:443/x').scheme,
        'wss',
      );
      expect(
        () => requireDebuggerSocketUri('http://example.test/x'),
        throwsA(isA<CdpException>()),
      );
    });
  });

  // The screencast fast path skips a full `jsonDecode` for the 30 fps frame
  // lane. It is an OPTIMIZATION, so it must never be able to affect anything
  // else — an exception escaping it kills the frame loop and every pending
  // command hangs until its timeout. It did exactly that once: the probe
  // passed a fixed start offset to `lastIndexOf`, which throws a RangeError
  // for any frame shorter than that offset, i.e. essentially every reply.
  group('screencast fast path robustness', () {
    test('a SHORT frame does not break command correlation', () async {
      final socket = _FakeCdpSocket();
      final client = CdpClient.over(socket);
      final pending = client.send('Page.enable');
      await _settle();

      // Well under the 200-char probe window.
      socket.pushRaw('{"id":0,"result":{"ok":true}}');
      await _settle();

      expect(await pending, equals({'ok': true}));
      await client.close();
    });

    test('a malformed screencast frame does not break the loop', () async {
      final socket = _FakeCdpSocket();
      final client = CdpClient.over(socket);
      // Claims to be a screencast frame but its data is not base64.
      socket.pushRaw(
        '{"method":"Page.screencastFrame","params":'
        '{"data":"!!!not base64!!!","sessionId":1}}',
      );
      await _settle();

      final pending = client.send('Page.enable');
      await _settle();
      socket.pushRaw('{"id":0,"result":{"ok":true}}');
      await _settle();
      expect(await pending, equals({'ok': true}));
      await client.close();
    });
  });
}
