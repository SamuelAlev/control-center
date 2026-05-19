import 'dart:async';
import 'dart:io';

import 'package:cc_infra/src/rigs/adb_client.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'fake_host_process.dart';

const String _adb = '/fake/sdk/platform-tools/adb';
const String _serial = 'emulator-5554';

/// An [AdbClient] over a scripted process runner.
///
/// [answer] sees each spawn's argv and returns what `adb` would have printed;
/// returning null leaves the process open (the streaming cases).
({AdbClient client, FakeSpawner spawner}) _client({
  ({int exitCode, String stdout, String stderr})? Function(List<String> args)?
  answer,
  List<String> apkRoots = const [],
  Duration commandTimeout = const Duration(milliseconds: 200),
}) {
  late final FakeSpawner spawner;
  spawner = FakeSpawner((process) {
    final scripted = answer?.call(process.args);
    if (scripted != null) {
      process.complete(
        exitCode: scripted.exitCode,
        stdout: scripted.stdout,
        stderr: scripted.stderr,
      );
    }
  });
  return (
    client: AdbClient(
      serial: _serial,
      adbPath: _adb,
      apkRoots: apkRoots,
      // The real budget is 15s; a unit test has no business waiting it out to
      // prove the child is killed.
      commandTimeout: commandTimeout,
      installTimeout: commandTimeout,
      captureTimeout: commandTimeout,
      spawn: spawner.call,
    ),
    spawner: spawner,
  );
}

({int exitCode, String stdout, String stderr}) _out(
  String stdout, {
  int exitCode = 0,
  String stderr = '',
}) => (exitCode: exitCode, stdout: stdout, stderr: stderr);

void main() {
  group('device affinity', () {
    test('every command carries the pinned -s <serial>', () async {
      // The rig picks one serial at boot. An unqualified `adb shell` picks
      // whichever device ADB feels like, which is how you tap the wrong phone.
      final f = _client(answer: (_) => _out('1'));
      await f.client.tap(10, 20);
      await f.client.keyEvent('KEYCODE_BACK');
      await f.client.swipe(1, 2, 3, 4, const Duration(milliseconds: 300));
      expect(f.spawner.started, hasLength(3));
      for (final process in f.spawner.started) {
        expect(process.executable, _adb);
        expect(
          process.args.take(2),
          ['-s', _serial],
          reason: 'The serial must lead every argv, before the sub-command.',
        );
      }
    });

    test('the streaming commands are pinned too', () async {
      final f = _client();
      // Failed on purpose below; the argv is what this test is about.
      unawaited(f.client.screencap().then<void>((_) {}, onError: (Object _) {}));
      await pumpEventQueue();
      final capture = f.spawner.started.single;
      expect(capture.args.take(2), ['-s', _serial]);
      expect(capture.args, contains('screencap'));
      capture.finish(exitCode: 1);

      final segment = await f.client.startScreenSegment(bitRate: 1000000);
      final record = f.spawner.started.last;
      expect(record.args.take(2), ['-s', _serial]);
      expect(record.args, contains('screenrecord'));
      await segment.stop();
      expect(record.killed, isTrue);
    });

    test('ensureReady accepts a booted device', () async {
      final f = _client(answer: (_) => _out('1\n'));
      await f.client.ensureReady();
      expect(f.spawner.started.single.args, contains('sys.boot_completed'));
    });

    test('a disconnected device is named, not left as a raw adb error',
        () async {
      final f = _client(
        answer: (_) => _out(
          '',
          exitCode: 1,
          stderr: "error: device '$_serial' not found",
        ),
      );
      await expectLater(
        f.client.ensureReady(),
        throwsA(
          isA<AdbDeviceGoneException>()
              .having((e) => e.serial, 'serial', _serial)
              .having((e) => e.message, 'message', contains(_serial)),
        ),
      );
    });

    test('an attached but unbooted device is refused', () async {
      // Acting between "ADB answers" and "Android is up" gets taps swallowed
      // by the boot animation and reads as a broken app.
      final f = _client(answer: (_) => _out('0\n'));
      await expectLater(
        f.client.ensureReady(),
        throwsA(
          isA<AdbDeviceGoneException>().having(
            (e) => e.message,
            'message',
            contains('booting'),
          ),
        ),
      );
    });
  });

  group('timeouts', () {
    test('a wedged command is killed rather than awaited forever', () async {
      // There was no timeout at all: a device that answers the transport and
      // nothing else hung the action, and with it the agent turn.
      final f = _client(); // Nothing answers; the process stays open.
      final pending = f.client.screenSize();
      await expectLater(pending, throwsA(isA<TimeoutException>()));
      expect(
        f.spawner.started.single.killed,
        isTrue,
        reason:
            'Abandoning the child frees the caller and leaves adb holding the '
            'device transport for everybody else.',
      );
    });
  });

  group('install', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('adb-apk-root');
    });

    tearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    File apk(String name, {Directory? inside}) {
      final file = File(p.join((inside ?? root).path, name))
        ..createSync(recursive: true)
        ..writeAsStringSync('PK');
      return file;
    }

    test('an APK inside an allowed root installs', () async {
      final file = apk('app.apk');
      final f = _client(
        answer: (_) => _out('Performing Streamed Install\nSuccess\n'),
        apkRoots: [root.path],
      );
      await f.client.installApk(file.path);
      expect(f.spawner.started.single.args, contains('install'));
    });

    test('an APK outside every root is refused, naming the root', () async {
      final outside = Directory.systemTemp.createTempSync('adb-apk-outside');
      addTearDown(() => outside.deleteSync(recursive: true));
      final file = apk('secret.apk', inside: outside);
      final f = _client(
        answer: (_) => _out('Success'),
        apkRoots: [root.path],
      );
      await expectLater(
        f.client.installApk(file.path),
        throwsA(
          isA<AdbException>().having(
            (e) => e.message,
            'message',
            allOf(contains('confined to'), contains(root.path)),
          ),
        ),
      );
      expect(
        f.spawner.started,
        isEmpty,
        reason: 'A refused install must never reach the device.',
      );
    });

    test('a symlink out of an allowed root is refused', () async {
      // The path is inside the root by string and outside it by content, and
      // it is the content that lands on the device.
      final outside = Directory.systemTemp.createTempSync('adb-apk-outside');
      addTearDown(() => outside.deleteSync(recursive: true));
      final real = apk('real.apk', inside: outside);
      final link = Link(p.join(root.path, 'link.apk'))
        ..createSync(real.path);
      final f = _client(answer: (_) => _out('Success'), apkRoots: [root.path]);
      await expectLater(
        f.client.installApk(link.path),
        throwsA(isA<AdbException>()),
      );
    });

    test('no configured roots installs nothing at all', () async {
      // Fail-closed: "unconfigured" must not read as "the whole filesystem".
      final file = apk('app.apk');
      final f = _client(answer: (_) => _out('Success'));
      await expectLater(
        f.client.installApk(file.path),
        throwsA(
          isA<AdbException>().having(
            (e) => e.message,
            'message',
            contains('no directory'),
          ),
        ),
      );
    });

    test('a missing file is reported before any confinement talk', () async {
      final f = _client(apkRoots: [root.path]);
      await expectLater(
        f.client.installApk(p.join(root.path, 'nope.apk')),
        throwsA(
          isA<AdbException>().having(
            (e) => e.message,
            'message',
            contains('No APK at'),
          ),
        ),
      );
    });

    test('Failure [CODE] on a zero exit is still a failure', () async {
      // Older platform-tools exit 0 and print the failure, which is why the
      // old `stdout.contains("Success")` test existed — but that test also
      // called a killed adb and an empty output a failure with no reason.
      final file = apk('app.apk');
      final f = _client(
        answer: (_) => _out('Failure [INSTALL_FAILED_OLDER_SDK]\n'),
        apkRoots: [root.path],
      );
      await expectLater(
        f.client.installApk(file.path),
        throwsA(
          isA<AdbException>().having(
            (e) => e.message,
            'message',
            contains('INSTALL_FAILED_OLDER_SDK'),
          ),
        ),
      );
    });

    test('a non-zero exit with no wording is still a failure', () async {
      final file = apk('app.apk');
      final f = _client(
        answer: (_) => _out('', exitCode: 1, stderr: 'adb: device offline'),
        apkRoots: [root.path],
      );
      await expectLater(
        f.client.installApk(file.path),
        throwsA(
          isA<AdbException>().having(
            (e) => e.message,
            'message',
            contains('device offline'),
          ),
        ),
      );
    });
  });

  group('startApp', () {
    test('am reporting an error on a zero exit is a failure', () async {
      final f = _client(
        answer: (_) => _out(
          'Starting: Intent { cmp=com.example/.Main }\n'
          'Error: Activity class {com.example/.Main} does not exist.\n',
        ),
      );
      await expectLater(
        f.client.startApp('com.example', activity: '.Main'),
        throwsA(
          isA<AdbException>().having(
            (e) => e.message,
            'message',
            contains('does not exist'),
          ),
        ),
      );
    });

    test('monkey finding no launchable activity is a failure', () async {
      final f = _client(
        answer: (_) => _out('** No activities found to run, monkey aborted.\n'),
      );
      await expectLater(
        f.client.startApp('com.example'),
        throwsA(isA<AdbException>()),
      );
    });

    test('a package whose own name contains "Error" still starts', () async {
      // The old check was `stdout.contains('Error')`, which called this a
      // failure and left the model retrying a launch that had worked.
      final f = _client(
        answer: (_) =>
            _out('Starting: Intent { cmp=com.example/.ErrorReporterActivity }\n'),
      );
      await f.client.startApp('com.example', activity: '.ErrorReporterActivity');
      expect(f.spawner.started.single.args, contains('start'));
    });

    test('a non-zero exit fails even with no wording', () async {
      final f = _client(answer: (_) => _out('', exitCode: 1));
      await expectLater(
        f.client.startApp('com.example'),
        throwsA(isA<AdbException>()),
      );
    });
  });

  group('uiDump', () {
    test('a non-zero exit is a failure, not an empty hierarchy', () async {
      final f = _client(
        answer: (_) => _out('', exitCode: 1, stderr: 'ERROR: null root node'),
      );
      await expectLater(
        f.client.uiDump(),
        throwsA(
          isA<AdbException>().having(
            (e) => e.message,
            'message',
            contains('null root node'),
          ),
        ),
      );
    });

    test('a zero exit with no hierarchy is still a failure', () async {
      // uiautomator exits 0 while printing "could not get idle state".
      final f = _client(
        answer: (_) => _out('ERROR: could not get idle state.\n'),
      );
      await expectLater(f.client.uiDump(), throwsA(isA<AdbException>()));
    });

    test('a real dump is summarised down to what a tap needs', () async {
      final f = _client(
        answer: (_) => _out(
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<hierarchy rotation="0">'
          '<node class="android.widget.FrameLayout" bounds="[0,0][1080,1920]"/>'
          '<node text="Send" resource-id="com.x:id/send" clickable="true" '
          'class="android.widget.Button" bounds="[100,200][300,400]"/>'
          '</hierarchy>',
        ),
      );
      final dump = await f.client.uiDump();
      expect(dump, contains('Button'));
      expect(dump, contains('"Send"'));
      expect(dump, contains('id=com.x:id/send'));
      expect(dump, contains('@(200,300)'));
      expect(
        dump,
        isNot(contains('FrameLayout')),
        reason: 'A layout container with no label and no tap is noise.',
      );
    });
  });

  group('hierarchy tokenizer', () {
    test('an attribute value containing > does not end the tag', () {
      // The regression this pins: `<node\b[^>]*>` ended at the FIRST `>`, and
      // a button labelled "Next >" mis-split every node after it in the dump.
      const xml =
          '<hierarchy>'
          '<node text="Next >" class="android.widget.Button" clickable="true" '
          'bounds="[0,0][100,100]"/>'
          '<node text="After" class="android.widget.TextView" '
          'bounds="[0,100][100,200]"/>'
          '</hierarchy>';
      final nodes = AdbClient.parseNodeAttributes(xml);
      expect(nodes, hasLength(2));
      expect(nodes.first['text'], 'Next >');
      expect(nodes.first['bounds'], '[0,0][100,100]');
      expect(nodes.last['text'], 'After');
    });

    test('escaped quotes inside a value survive', () {
      const xml = '<node text="Say &quot;hi&quot;" class="a.B" '
          'content-desc="a &amp; b"/>';
      final node = AdbClient.parseNodeAttributes(xml).single;
      expect(node['text'], 'Say "hi"');
      expect(node['content-desc'], 'a & b');
    });

    test('single-quoted values and numeric entities are handled', () {
      const xml = "<node text='It&apos;s &#65;&#x42;' class='a.B'/>";
      final node = AdbClient.parseNodeAttributes(xml).single;
      expect(node['text'], "It's AB");
    });

    test('an unknown entity is left verbatim rather than invented', () {
      const xml = '<node text="100&euro; &amp; more" class="a.B"/>';
      final node = AdbClient.parseNodeAttributes(xml).single;
      expect(node['text'], '100&euro; & more');
    });

    test('an element merely starting with "node" is not one', () {
      const xml = '<nodelist count="2"/><node text="real" class="a.B"/>';
      final nodes = AdbClient.parseNodeAttributes(xml);
      expect(nodes, hasLength(1));
      expect(nodes.single['text'], 'real');
    });

    test('a truncated dump yields what it can instead of throwing', () {
      const xml = '<node text="ok" class="a.B"/><node text="trunca';
      final nodes = AdbClient.parseNodeAttributes(xml);
      expect(nodes.first['text'], 'ok');
      expect(nodes, hasLength(2));
    });

    test('summarising survives a label full of markup', () {
      const xml =
          '<hierarchy><node text="a &lt;b&gt; c > d" clickable="true" '
          'class="android.widget.Button" bounds="[0,0][10,10]"/></hierarchy>';
      final summary = AdbClient.summarizeHierarchy(xml);
      expect(summary, contains('a <b> c > d'));
      expect(summary, contains('@(5,5)'));
    });
  });
}
