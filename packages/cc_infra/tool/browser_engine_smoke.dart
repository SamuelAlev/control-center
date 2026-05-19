// Drives a live browser rig through the engine client, end to end.
//
// A rig cannot be booted in CI, so the protocol clients' unit tests run
// against fakes and this exists for the other half: pointing the REAL client
// at a REAL guest and watching every verb the driver uses come back. Run it
// against a machine started by hand (or by `rig_smoke.dart`) when changing
// anything in `bidi_client.dart` / `webdriver_client.dart`.
//
//   dart run tool/browser_engine_smoke.dart firefox <hostPort> <guestPort>
//   dart run tool/browser_engine_smoke.dart webkit  <hostPort>
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/rigs/bidi_client.dart';
import 'package:cc_infra/src/rigs/browser_engine_client.dart';
import 'package:cc_infra/src/rigs/webdriver_client.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: browser_engine_smoke.dart <firefox|webkit> <hostPort> '
      '[guestPort]',
    );
    exitCode = 64;
    return;
  }
  final engine = args.first;
  final port = int.parse(args[1]);
  final BrowserEngineClient client;
  if (engine == 'firefox') {
    client = await BidiClient.attach(
      host: '127.0.0.1',
      port: port,
      guestPort: args.length > 2 ? int.parse(args[2]) : port,
    );
  } else {
    client = await WebDriverClient.attach(host: '127.0.0.1', port: port);
  }

  Future<void> step(String label, Future<Object?> Function() body) async {
    try {
      final value = await body();
      stdout.writeln('ok   $label${value == null ? '' : ' -> $value'}');
    } on Object catch (e) {
      stdout.writeln('FAIL $label -> $e');
    }
  }

  const page =
      'data:text/html,<title>P1</title>'
      '<button id=b onclick="document.title=\'clicked\'">Hit</button>'
      '<input id=i><script>console.log("from the page")</script>';

  client.pageEvents.listen((e) {
    if (e is BrowserPageUrlChanged) {
      stdout.writeln('     event url -> ${e.url}');
    }
  });

  await step('setViewport', () async {
    await client.setViewport(width: 1280, height: 800);
    return null;
  });
  await step('navigate', () => client.navigate(page));
  await step('currentUrl', () async => (await client.currentUrl()).length);
  await step('centerOf(#b)', () => client.centerOf('#b'));
  await step('click #b', () async {
    final centre = await client.centerOf('#b');
    if (centre == null) {
      return 'no centre';
    }
    await client.clickAt(centre.$1, centre.$2);
    return null;
  });
  await step('fill #i', () => client.fill('#i', 'hello'));
  await step('typeText', () async {
    await client.typeText(' world');
    return null;
  });
  await step('pressKey End', () => client.pressKey('End'));
  await step('scrollBy', () async {
    await client.scrollBy(0, 120);
    return null;
  });
  await step(
    'waitFor #i',
    () => client.waitFor('#i', const Duration(seconds: 3)),
  );
  await step('domSnapshot', () async {
    final snap = await client.domSnapshot();
    return '${snap?.split('\n').length} lines';
  });
  await step('a11y', () async {
    final snap = await client.accessibilitySnapshot();
    return '${snap.split('\n').length} lines';
  });
  await step('console', () async => client.drainConsole().join(' | '));
  await step('screenshot', () async {
    final data = await client.captureScreenshot();
    final bytes = base64Decode(data);
    return '${bytes.length} bytes, magic ${bytes.take(4).toList()}';
  });
  await step('fullpage', () async {
    final data = await client.captureScreenshot(
      fullPage: true,
      maxWidth: 1280,
      maxHeight: 800,
    );
    return '${base64Decode(data).length} bytes';
  });
  await step(
    'navigate 2',
    () => client.navigate('data:text/html,<title>P2</title>two'),
  );
  await step('navState', client.navigationState);
  await step('back', () => client.goHistory(-1));
  await step('navState after back', client.navigationState);
  await step('forward', () => client.goHistory(1));
  await step('overshoot', () => client.goHistory(5));
  await step('reload', () async {
    await client.reload();
    return null;
  });
  await step('stopLoading', () async {
    await client.stopLoading();
    return null;
  });
  await step('readSelection', client.readSelectionText);
  await step('readClipboard', () async {
    final clip = await client.readClipboard();
    return clip.ok ? 'ok "${clip.text}"' : 'unavailable: ${clip.unavailable}';
  });
  await step('setFileInputFiles', () async {
    // No file input on the page — a false here is the correct answer and
    // proves the call path rather than the upload.
    return client.setFileInputFiles(
      selector: '#nope',
      guestPaths: ['/etc/hostname'],
    );
  });

  await client.close();
  stdout.writeln('done');
}
