import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/browser_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/mobile_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_infra/src/rigs/adb_client.dart';
import 'package:cc_infra/src/rigs/cdp_client.dart';
import 'package:cc_infra/src/rigs/guest_agent_client.dart';
import 'package:cc_infra/src/rigs/host_ffmpeg.dart';
import 'package:cc_infra/src/rigs/qmp_client.dart';
import 'package:cc_infra/src/rigs/rig_drivers.dart';
import 'package:test/test.dart';

import 'fake_host_process.dart';

/// The same seam `cdp_client_test.dart` uses, so a driver can be exercised
/// without Chromium.
class _FakeCdpSocket implements CdpSocket {
  final StreamController<dynamic> _incoming =
      StreamController<dynamic>.broadcast();

  final List<Map<String, dynamic>> sent = [];
  final Map<String, Map<String, dynamic>> autoReply = {};

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  void add(String data) {
    final decoded = jsonDecode(data) as Map<String, dynamic>;
    sent.add(decoded);
    final reply = autoReply[decoded['method']];
    if (reply != null) {
      scheduleMicrotask(
        () => _incoming.add(jsonEncode({'id': decoded['id'], 'result': reply})),
      );
    }
  }

  @override
  Future<void> close() async {
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }

  /// Pushes a raw frame from the "browser" (an event, not a reply).
  void push(Map<String, dynamic> frame) {
    if (!_incoming.isClosed) {
      _incoming.add(jsonEncode(frame));
    }
  }
}

/// Lets every pending microtask and short timer run.
Future<void> _settle([int millis = 5]) =>
    Future<void>.delayed(Duration(milliseconds: millis));

BrowserRigDriver _driver(_FakeCdpSocket socket) => BrowserRigDriver(
  client: CdpClient.over(socket),
  viewport: RigDisplaySize(1280, 800),
);

const String _adbPath = '/fake/adb';
const String _ffmpegPath = '/fake/ffmpeg';
const String _serial = 'emulator-5554';

/// A device screen big enough that the agent ceiling actually bites.
final RigDisplaySize _deviceSize = RigDisplaySize(1080, 1920);

/// One PNG-shaped and one JPEG-shaped byte string. Nothing decodes them; they
/// exist so a test can tell which lane's bytes came out.
const List<int> _pngBytes = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
const List<int> _jpegBytes = [0xff, 0xd8, 0xff, 0xe0, 0xff, 0xd9];

/// Builds a mobile driver over scripted `adb` and `ffmpeg` children.
///
/// [hasFfmpeg] false is the host this whole surface used to fail silently on.
({MobileRigDriver driver, FakeSpawner spawner}) _mobile({
  bool hasFfmpeg = true,
  bool deviceReady = true,
}) {
  late final FakeSpawner spawner;
  spawner = FakeSpawner((process) {
    if (process.executable == _ffmpegPath) {
      // A real ffmpeg exits on stdin EOF; the segment loop waits for exactly
      // that before restarting.
      process
        ..onStdinClosed = process.finish
        ..emit(_jpegBytes);
      return;
    }
    final args = process.args;
    if (args.contains('getprop')) {
      process.complete(
        exitCode: deviceReady ? 0 : 1,
        stdout: deviceReady ? '1\n' : '',
        stderr: deviceReady ? '' : "error: device '$_serial' not found",
      );
      return;
    }
    if (args.contains('wm')) {
      process.complete(stdout: 'Physical size: 1080x1920\n');
      return;
    }
    if (args.contains('screencap')) {
      // The PNG arrives on stdout and then the child exits, like a real
      // capture.
      process
        ..emit(_pngBytes)
        ..finish();
      return;
    }
    if (args.contains('screenrecord')) {
      // Held open: the test drives the segment boundary itself.
      return;
    }
    process.complete();
  });
  final ffmpeg = HostFfmpeg(path: _ffmpegPath, spawn: spawner.call);
  return (
    driver: MobileRigDriver(
      adb: AdbClient(
        serial: _serial,
        adbPath: _adbPath,
        commandTimeout: const Duration(seconds: 2),
        captureTimeout: const Duration(seconds: 2),
        spawn: spawner.call,
      ),
      size: _deviceSize,
      ffmpeg: () async => hasFfmpeg ? ffmpeg : null,
    ),
    spawner: spawner,
  );
}

void main() {
  group('rigDriverFailure', () {
    test('a protocol failure names its channel and its exception type', () {
      final result = rigDriverFailure(
        'left_click',
        const QmpException('Device not found'),
      );
      expect(result.isError, isTrue);
      expect(result.text, contains('QmpException'));
      expect(result.text, contains('Device not found'));
      expect(result.text, contains('QMP'));
      expect(result.text, isNot(contains('internal error')));
    });

    test('each transport gets its own diagnosis', () {
      expect(
        rigDriverFailure('extract', const CdpException('Target closed')).text,
        contains('DevTools'),
      );
      expect(
        rigDriverFailure('tap', const AdbException('device offline')).text,
        contains('ADB'),
      );
      expect(
        rigDriverFailure(
          'screenshot',
          const GuestAgentException('no route'),
        ).text,
        contains('guest agent'),
      );
    });

    test('a programming error is shaped as OUR bug, not a dead channel', () {
      // The model must be able to tell "the control space is down" (stop
      // poking it) from "the host has a defect" (retrying will not help).
      final result = rigDriverFailure('type', TypeError());
      expect(result.isError, isTrue);
      expect(result.text, contains('internal error'));
      expect(result.text, contains('host-side defect'));
      expect(result.text, isNot(contains('channel')));
    });
  });

  group('BrowserRigDriver', () {
    test('scroll with a selector aims the wheel at that element', () async {
      // The regression this pins: the selector was parsed and dropped, so
      // scrolling a named container was accepted, logged as done, and moved
      // nothing.
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
      final driver = _driver(socket);

      final result = await driver.perform(
        const BrowserScroll(dy: 400, selector: '#list'),
      );

      expect(result.isError, isFalse);
      expect(result.text, contains('#list'));
      final wheel = socket.sent.last['params'] as Map;
      expect(wheel['type'], 'mouseWheel');
      expect(wheel['x'], 200);
      expect(wheel['y'], 300);
      await driver.dispose();
    });

    test('scroll with an unresolvable selector is an error', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['DOM.getDocument'] = {
          'root': {'nodeId': 1},
        }
        ..autoReply['DOM.querySelector'] = {'nodeId': 0};
      final driver = _driver(socket);

      final result = await driver.perform(
        const BrowserScroll(dy: 400, selector: '#missing'),
      );

      expect(result.isError, isTrue);
      expect(result.text, contains('#missing'));
      expect(
        socket.sent.map((f) => f['method']),
        isNot(contains('Input.dispatchMouseEvent')),
      );
      await driver.dispose();
    });

    test(
      'extract with an unresolvable selector is an error, not the page',
      () async {
        final socket = _FakeCdpSocket()
          ..autoReply['DOM.getDocument'] = {
            'root': {'nodeId': 1, 'nodeName': '#document', 'nodeType': 9},
          }
          ..autoReply['DOM.querySelector'] = {'nodeId': 0};
        final driver = _driver(socket);

        final result = await driver.perform(
          const BrowserExtract(kind: BrowserExtractKind.dom, selector: '#gone'),
        );

        expect(result.isError, isTrue);
        expect(result.text, contains('#gone'));
        await driver.dispose();
      },
    );

    test(
      'an unknown key name is refused rather than reported pressed',
      () async {
        final socket = _FakeCdpSocket();
        final driver = _driver(socket);

        final result = await driver.perform(const BrowserKey('Frobnicate'));

        expect(result.isError, isTrue);
        expect(result.text, contains('Frobnicate'));
        await driver.dispose();
      },
    );

    test('a printable key is inserted as text', () async {
      final socket = _FakeCdpSocket()..autoReply['Input.insertText'] = const {};
      final driver = _driver(socket);

      final result = await driver.perform(const BrowserKey('x'));

      expect(result.isError, isFalse);
      expect(socket.sent.single['method'], 'Input.insertText');
      await driver.dispose();
    });

    test('the browser lane declares MJPEG, which is what it emits', () {
      expect(_driver(_FakeCdpSocket()).watchCodec, RigStreamCodec.mjpeg);
    });

    test('type inserts the whole run in one call', () async {
      final socket = _FakeCdpSocket()..autoReply['Input.insertText'] = const {};
      final driver = _driver(socket);

      final result = await driver.perform(const BrowserType('hello there'));

      expect(result.isError, isFalse);
      expect(socket.sent.single['method'], 'Input.insertText');
      expect((socket.sent.single['params'] as Map)['text'], 'hello there');
      await driver.dispose();
    });

    test('an empty type is a declared no-op, not a protocol call', () async {
      final socket = _FakeCdpSocket();
      final driver = _driver(socket);

      final result = await driver.perform(const BrowserType(''));

      expect(result.isError, isFalse);
      expect(socket.sent, isEmpty);
      await driver.dispose();
    });

    test('reload reloads and reports where the page is', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Page.reload'] = const {}
        ..autoReply['Page.getNavigationHistory'] = const {
          'currentIndex': 0,
          'entries': [
            {'id': 1, 'url': 'https://a.test'},
          ],
        };
      final driver = _driver(socket);

      final result = await driver.perform(const BrowserReload());

      expect(result.isError, isFalse);
      expect(result.text, contains('https://a.test'));
      expect(socket.sent.first['method'], 'Page.reload');
      await driver.dispose();
    });

    test(
      'a drag is press, stepped moves with the button held, release',
      () async {
        final socket = _FakeCdpSocket()
          ..autoReply['Input.dispatchMouseEvent'] = const {};
        final driver = _driver(socket);

        final result = await driver.perform(
          const BrowserDrag(fromX: 0, fromY: 0, toX: 80, toY: 0),
        );

        expect(result.isError, isFalse);
        final types = [
          for (final f in socket.sent) (f['params'] as Map)['type'],
        ];
        expect(types.first, 'mouseMoved'); // position at the origin first
        expect(types[1], 'mousePressed');
        expect(types.last, 'mouseReleased');
        final draggedMoves = socket.sent
            .map((f) => f['params'] as Map)
            .where((p) => p['type'] == 'mouseMoved' && p['buttons'] == 1)
            .length;
        expect(
          draggedMoves,
          greaterThan(2),
          reason:
              'A single jump reads as a teleport to most drag handlers; '
              'the selection never starts.',
        );
        await driver.dispose();
      },
    );

    test(
      'a release with no coordinate uses the last pointer position',
      () async {
        final socket = _FakeCdpSocket()
          ..autoReply['Input.dispatchMouseEvent'] = const {};
        final driver = _driver(socket);

        await driver.perform(const BrowserMouseMove(x: 33, y: 44));
        final result = await driver.perform(
          const BrowserMouseButtonHold(pressed: false),
        );

        expect(result.isError, isFalse);
        final release = socket.sent.last['params'] as Map;
        expect(release['type'], 'mouseReleased');
        expect(release['x'], 33);
        expect(release['y'], 44);
        await driver.dispose();
      },
    );

    test('a release before any pointer placement is a named error', () async {
      final socket = _FakeCdpSocket();
      final driver = _driver(socket);

      final result = await driver.perform(
        const BrowserMouseButtonHold(pressed: false),
      );

      expect(result.isError, isTrue);
      expect(result.text, contains('mouse_move'));
      expect(socket.sent, isEmpty);
      await driver.dispose();
    });

    test('two quick presses at one spot become a double click', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Input.dispatchMouseEvent'] = const {};
      final driver = _driver(socket);

      for (var i = 0; i < 2; i++) {
        await driver.perform(
          const BrowserMouseButtonHold(pressed: true, x: 10, y: 10),
        );
        await driver.perform(const BrowserMouseButtonHold(pressed: false));
      }

      final pressCounts = [
        for (final f in socket.sent)
          if ((f['params'] as Map)['type'] == 'mousePressed')
            (f['params'] as Map)['clickCount'],
      ];
      final releaseCounts = [
        for (final f in socket.sent)
          if ((f['params'] as Map)['type'] == 'mouseReleased')
            (f['params'] as Map)['clickCount'],
      ];
      expect(
        pressCounts,
        [1, 2],
        reason:
            'Chromium only derives a word selection from clickCount 2; '
            'two count-1 presses are two clicks.',
      );
      expect(
        releaseCounts,
        [1, 2],
        reason:
            'The DOM click/dblclick event detail comes from the RELEASE, '
            'so the release must repeat the press\'s count — a count-1 '
            'release after a count-2 press is two single clicks to a page\'s '
            'own dblclick handler even though Blink selected the word.',
      );
      await driver.dispose();
    });

    test('presses far apart in space do not chain click counts', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Input.dispatchMouseEvent'] = const {};
      final driver = _driver(socket);

      for (final x in [10, 400]) {
        await driver.perform(
          BrowserMouseButtonHold(pressed: true, x: x, y: 10),
        );
        await driver.perform(const BrowserMouseButtonHold(pressed: false));
      }

      final pressCounts = [
        for (final f in socket.sent)
          if ((f['params'] as Map)['type'] == 'mousePressed')
            (f['params'] as Map)['clickCount'],
      ];
      expect(pressCounts, [1, 1]);
      await driver.dispose();
    });

    test('a click carries the button and click count', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Input.dispatchMouseEvent'] = const {};
      final driver = _driver(socket);

      final result = await driver.perform(
        const BrowserClick(x: 5, y: 6, button: RigMouseButton.right, clicks: 2),
      );

      expect(result.isError, isFalse);
      expect(result.text, contains('Right-clicked'));
      final press = socket.sent
          .map((f) => f['params'] as Map)
          .firstWhere((p) => p['type'] == 'mousePressed');
      expect(press['button'], 'right');
      expect(press['clickCount'], 2);
      await driver.dispose();
    });

    test('main-frame navigations publish the URL; subframes do not', () async {
      final socket = _FakeCdpSocket();
      final urls = <String>[];
      final driver = BrowserRigDriver(
        client: CdpClient.over(socket),
        viewport: RigDisplaySize(1280, 800),
        onUrlChanged: urls.add,
      );

      socket.push({
        'method': 'Page.frameNavigated',
        'params': {
          'frame': {'id': 'main', 'url': 'https://a.test'},
        },
      });
      socket.push({
        'method': 'Page.frameNavigated',
        'params': {
          'frame': {
            'id': 'frame-2',
            'parentId': 'main',
            'url': 'https://ad.example',
          },
        },
      });
      await _settle();

      expect(
        urls,
        ['https://a.test'],
        reason:
            'An iframe loading is not the page navigating — the address '
            'bar answers "where am I", not "what loaded".',
      );
      await driver.dispose();
    });

    test('a pushState navigation of the main frame publishes too', () async {
      final socket = _FakeCdpSocket();
      final urls = <String>[];
      final driver = BrowserRigDriver(
        client: CdpClient.over(socket),
        viewport: RigDisplaySize(1280, 800),
        onUrlChanged: urls.add,
      );

      socket.push({
        'method': 'Page.frameNavigated',
        'params': {
          'frame': {'id': 'main', 'url': 'https://a.test'},
        },
      });
      await _settle();
      socket.push({
        'method': 'Page.navigatedWithinDocument',
        'params': {'frameId': 'main', 'url': 'https://a.test/app#dash'},
      });
      socket.push({
        'method': 'Page.navigatedWithinDocument',
        'params': {'frameId': 'frame-2', 'url': 'https://a.test/embed#x'},
      });
      await _settle();

      expect(urls, ['https://a.test', 'https://a.test/app#dash']);
      await driver.dispose();
    });

    test('about:blank never overwrites a real address', () async {
      final socket = _FakeCdpSocket();
      final urls = <String>[];
      final driver = BrowserRigDriver(
        client: CdpClient.over(socket),
        viewport: RigDisplaySize(1280, 800),
        onUrlChanged: urls.add,
      );

      socket.push({
        'method': 'Page.frameNavigated',
        'params': {
          'frame': {'id': 'main', 'url': 'https://a.test'},
        },
      });
      socket.push({
        'method': 'Page.frameNavigated',
        'params': {
          'frame': {'id': 'main', 'url': 'about:blank'},
        },
      });
      await _settle();

      expect(urls, ['https://a.test']);
      await driver.dispose();
    });

    test('seedCurrentUrl publishes the page the driver attached to', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Page.getNavigationHistory'] = const {
          'currentIndex': 0,
          'entries': [
            {'id': 1, 'url': 'https://home.test'},
          ],
        };
      final urls = <String>[];
      final driver = BrowserRigDriver(
        client: CdpClient.over(socket),
        viewport: RigDisplaySize(1280, 800),
        onUrlChanged: urls.add,
      );

      await driver.seedCurrentUrl();

      expect(
        urls,
        ['https://home.test'],
        reason:
            'The home page loaded before this driver existed, so no '
            'navigation event will ever name it.',
      );
      await driver.dispose();
    });

    test('navState reads back/forward reachability from the history', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Page.getNavigationHistory'] = const {
          'currentIndex': 2,
          'entries': [
            {'id': 1, 'url': 'https://a.test'},
            {'id': 2, 'url': 'https://b.test'},
            {'id': 3, 'url': 'https://c.test'},
          ],
        };
      final driver = _driver(socket);

      final state = await driver.navState();

      expect(state.url, 'https://c.test');
      expect(state.canGoBack, isTrue);
      expect(state.canGoForward, isFalse);
      await driver.dispose();
    });

    test('loading follows the main frame\'s load events', () async {
      final socket = _FakeCdpSocket()
        ..autoReply['Page.getNavigationHistory'] = const {
          'currentIndex': 0,
          'entries': [
            {'id': 1, 'url': 'https://a.test'},
          ],
        };
      final driver = _driver(socket);

      expect((await driver.navState()).loading, isFalse);
      // A commit marks the load started even before this frame's id is known
      // (the first navigation after attach).
      socket.push({
        'method': 'Page.frameNavigated',
        'params': {
          'frame': {'id': 'main', 'url': 'https://a.test'},
        },
      });
      await _settle();
      expect((await driver.navState()).loading, isTrue);
      // A subframe stopping must not clear the main frame's load.
      socket.push({
        'method': 'Page.frameStoppedLoading',
        'params': {'frameId': 'frame-2'},
      });
      await _settle();
      expect((await driver.navState()).loading, isTrue);
      socket.push({
        'method': 'Page.frameStoppedLoading',
        'params': {'frameId': 'main'},
      });
      await _settle();
      expect((await driver.navState()).loading, isFalse);
      await driver.dispose();
    });

    test('stop_loading stops the load and clears the flag', () async {
      final socket = _FakeCdpSocket()..autoReply['Page.stopLoading'] = const {};
      final driver = _driver(socket);
      socket.push({
        'method': 'Page.frameNavigated',
        'params': {
          'frame': {'id': 'main', 'url': 'https://a.test'},
        },
      });
      await _settle();

      final result = await driver.perform(const BrowserStopLoading());

      expect(result.isError, isFalse);
      expect(socket.sent.last['method'], 'Page.stopLoading');
      await driver.dispose();
    });
  });

  group('MobileRigDriver stills', () {
    test(
      'a still is downscaled to the agent ceiling and encoded as JPEG',
      () async {
        // The regression this pins: mobile shipped a full-device PNG
        // (1080x1920+) where every other surface respects the 1280x800 agent
        // ceiling as JPEG — four times the pixel budget in the worst codec, on
        // every screenshot.
        final m = _mobile();
        final result = await m.driver.captureForAgent();

        expect(result.isError, isFalse);
        expect(result.imageMediaType, 'image/jpeg');
        expect(base64Decode(result.imageBase64!), _jpegBytes);

        final target = _deviceSize.fitInside(RigDisplaySize.agentCeiling);
        expect(result.text, contains('scaled to $target'));
        // The model clicks in GUEST pixels, so a downscaled frame whose text
        // does not say the full device size turns every derived coordinate into
        // a miss.
        expect(result.text, contains('DEVICE pixels ($_deviceSize)'));
        expect(result.displaySize, _deviceSize.toString());

        final ffmpeg = m.spawner.forBinary(_ffmpegPath).single;
        expect(ffmpeg.args, contains('mjpeg'));
        expect(
          ffmpeg.args.join(' '),
          contains('${target.width}'),
          reason: 'The scale filter carries the ceiling-fitted size.',
        );
        expect(
          ffmpeg.stdinBytes.toBytes(),
          _pngBytes,
          reason: 'The capture is piped in rather than written to a temp file.',
        );
      },
    );

    test('without ffmpeg the raw PNG is shipped AND says why', () async {
      // An oversized frame that explains itself beats a broken screenshot —
      // and it names the fix rather than quietly costing more every turn.
      final m = _mobile(hasFfmpeg: false);
      final result = await m.driver.captureForAgent();

      expect(result.isError, isFalse);
      expect(result.imageMediaType, 'image/png');
      expect(base64Decode(result.imageBase64!), _pngBytes);
      expect(result.text, contains('ffmpeg'));
      expect(result.text, contains('DEVICE pixels ($_deviceSize)'));
      expect(m.spawner.forBinary(_ffmpegPath), isEmpty);
    });

    test('the cached size is refreshed before the frame is taken', () async {
      // A phone rotates; a stale size sends every derived coordinate
      // somewhere else.
      final m = _mobile();
      await m.driver.captureForAgent();
      expect(m.spawner.started.any((p) => p.args.contains('wm')), isTrue);
    });
  });

  group('MobileRigDriver watch lane', () {
    test(
      'the lane declares MJPEG — what leaves the host, not what adb makes',
      () {
        expect(_mobile().driver.watchCodec, RigStreamCodec.mjpeg);
      },
    );

    test('a host with no ffmpeg fails loudly and by name', () async {
      // What shipped instead: raw H.264 relayed under an MJPEG content type,
      // into a viewer that scanned it for JPEG markers forever.
      final m = _mobile(hasFfmpeg: false);
      await expectLater(
        m.driver.openWatchStream(
          RigWatchRequest(size: RigDisplaySize(720, 1280)),
        ),
        throwsA(
          isA<RigStreamUnavailable>()
              .having((e) => e.code, 'code', 'ffmpeg-missing')
              .having((e) => e.message, 'message', contains('ffmpeg')),
        ),
      );
      expect(
        m.spawner.started,
        isEmpty,
        reason: 'Nothing should have been started on the device either.',
      );
    });

    test('H.264 goes into ffmpeg and JPEG comes out to the viewer', () async {
      final m = _mobile();
      final stream = await m.driver.openWatchStream(
        RigWatchRequest(size: RigDisplaySize(720, 1280), fps: 10, quality: 70),
      );
      final received = <int>[];
      final sub = stream!.listen(received.addAll);
      await pumpEventQueue();

      final ffmpeg = m.spawner.forBinary(_ffmpegPath).first;
      final record = m.spawner.started.firstWhere(
        (p) => p.args.contains('screenrecord'),
      );
      expect(record.args.take(2), ['-s', _serial]);
      expect(ffmpeg.args.join(' '), contains('fps=10'));
      expect(ffmpeg.args, contains('h264'));

      record.emit(const [0, 0, 0, 1, 0x67]);
      await pumpEventQueue();
      expect(ffmpeg.stdinBytes.toBytes(), [
        0,
        0,
        0,
        1,
        0x67,
      ], reason: 'The device stream is fed into the transcoder, not relayed.');
      expect(received, _jpegBytes);

      await sub.cancel();
      await pumpEventQueue();
      expect(record.killed, isTrue, reason: 'No orphaned screenrecord.');
      expect(ffmpeg.killed, isTrue, reason: 'No orphaned ffmpeg.');
    });

    test('the 180s segment boundary restarts BOTH halves', () async {
      // screenrecord ends every recording at its own cap and re-emits its
      // parameter sets on the next one. Feeding two segments into one decoder
      // is how the viewer froze three minutes in while every other signal
      // still said healthy.
      final m = _mobile();
      final stream = await m.driver.openWatchStream(
        RigWatchRequest(size: RigDisplaySize(720, 1280)),
      );
      final received = <int>[];
      final sub = stream!.listen(received.addAll);
      await pumpEventQueue();

      final firstRecord = m.spawner.started.firstWhere(
        (p) => p.args.contains('screenrecord'),
      );
      // The device ends the segment.
      firstRecord.finish();
      await pumpEventQueue();

      expect(
        m.spawner.forBinary(_ffmpegPath).length,
        2,
        reason: 'A fresh transcoder per segment, not one fed two of them.',
      );
      expect(
        m.spawner.started.where((p) => p.args.contains('screenrecord')).length,
        2,
      );
      final secondFfmpeg = m.spawner.forBinary(_ffmpegPath).last;
      secondFfmpeg.emit(const [0xff, 0xd8, 0x42, 0xff, 0xd9]);
      await pumpEventQueue();
      expect(
        received,
        containsAllInOrder(const [0xff, 0xd8, 0x42, 0xff, 0xd9]),
        reason: 'Frames keep flowing across the boundary.',
      );

      await sub.cancel();
    });
  });

  group('MobileRigDriver device affinity', () {
    test('an action on a vanished device names the serial', () async {
      // The rig pins one serial. Nothing re-checked it, so a disconnect
      // surfaced as a raw transport error that reads like a bad argument.
      final m = _mobile(deviceReady: false);
      final result = await m.driver.perform(const MobileTap(x: 10, y: 20));
      expect(result.isError, isTrue);
      expect(result.text, contains(_serial));
      expect(
        m.spawner.started.any((p) => p.args.contains('tap')),
        isFalse,
        reason: 'The tap must not be attempted against a device that is gone.',
      );
    });

    test('a ready device performs the action', () async {
      final m = _mobile();
      final result = await m.driver.perform(const MobileTap(x: 10, y: 20));
      expect(result.isError, isFalse);
      expect(m.spawner.started.any((p) => p.args.contains('tap')), isTrue);
    });
  });
}
