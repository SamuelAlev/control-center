@Timeout(Duration(minutes: 3))
@TestOn('mac-os')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:cc_natives/cc_natives.dart';
import 'package:test/test.dart';

/// Real windows through the real library, on macOS.
///
/// Two throwaway windows, compiled here and owned by this test: no other app
/// is launched. Needs a built library (`CC_WINDOW_DYLIB`, or
/// `scripts/natives/build_window.sh`) and Screen Recording, and skips without
/// them. Input is never delivered here: a shell has no Accessibility grant, so
/// these prove refusal and that a missing grant is not reported as success.
const String _windowApp = r'''
import AppKit
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
                 styleMask: [.titled], backing: .buffered, defer: false)
w.title = CommandLine.arguments[1]
w.setFrameOrigin(NSPoint(x: Double(CommandLine.arguments[2])!, y: 200))
w.orderFrontRegardless()
DispatchQueue.main.asyncAfter(deadline: .now() + 120) { exit(0) }
app.run()
''';

void main() {
  CcWindow? native;
  String? skip;
  Directory? scratch;
  final launched = <Process>[];

  Future<Process> launch(String binary, String title, int x) async {
    final process = await Process.start(binary, [title, '$x']);
    launched.add(process);
    return process;
  }

  /// The process's window, once its size has stopped changing. The opening
  /// animation is a spring: the frame passes through and past its final size.
  Future<int> windowOf(Process process) async {
    final target = CcWindowTarget(pids: [process.pid]);
    Object? lastWidth;
    var steady = 0;
    for (var attempt = 0; attempt < 100; attempt++) {
      final windows = await native!.list(target);
      final width = windows.isEmpty ? null : windows.first['width'];
      steady = width != null && width == lastWidth ? steady + 1 : 0;
      lastWidth = width;
      if (steady >= 3) {
        return (windows.first['id'] as num).toInt();
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('The throwaway window never settled.');
  }

  late Process mine;
  late Process other;
  late int myWindow;
  late int otherWindow;

  setUpAll(() async {
    if (!CcWindow.isAvailable) {
      skip = 'libcc_window is not built';
      return;
    }
    native = CcWindow.require;
    final permissions = await native!.permissions();
    if (permissions['screen_capture'] != 'granted') {
      skip = 'Screen Recording is not granted to this process';
      return;
    }
    scratch = await Directory.systemTemp.createTemp('cc_window_test');
    final source = File('${scratch!.path}/app.swift')
      ..writeAsStringSync(_windowApp);
    final binary = '${scratch!.path}/app';
    final built = await Process.run('swiftc', [source.path, '-o', binary]);
    if (built.exitCode != 0) {
      skip = 'swiftc could not build the throwaway window';
      return;
    }
    mine = await launch(binary, 'Acme One', 200);
    other = await launch(binary, 'Acme Two', 600);
    myWindow = await windowOf(mine);
    otherWindow = await windowOf(other);
  });

  tearDownAll(() async {
    for (final process in launched) {
      process.kill();
    }
    await scratch?.delete(recursive: true);
  });

  Matcher refusedWith(CcWindowStatus status) =>
      throwsA(isA<CcWindowFailure>().having((e) => e.status, 'status', status));

  void guarded(String name, Future<void> Function() body) {
    test(name, () async {
      if (skip != null) {
        markTestSkipped(skip!);
        return;
      }
      await body();
    });
  }

  (int, int) pngSize(Uint8List png) {
    final data = ByteData.sublistView(png);
    return (data.getUint32(16), data.getUint32(20));
  }

  guarded('lists only the windows of the given process', () async {
    final windows = await native!.list(CcWindowTarget(pids: [mine.pid]));
    expect(windows.map((w) => w['id']), [myWindow]);
    expect(windows.single['pid'], mine.pid);
    expect(windows.single['width'], 320);
  });

  guarded('captures a window that is not active, within the cap', () async {
    final image = await native!.capture(
      CcWindowTarget(pids: [mine.pid], windowId: myWindow),
      maxWidth: 200,
      maxHeight: 100,
    );
    expect(image.png.take(4), [0x89, 0x50, 0x4e, 0x47]);
    expect(image.width, lessThanOrEqualTo(200));
    expect(image.height, lessThanOrEqualTo(100));
    expect(pngSize(image.png), (image.width, image.height));
  });

  guarded('never scales a capture up', () async {
    final image = await native!.capture(
      CcWindowTarget(pids: [mine.pid], windowId: myWindow),
      maxWidth: 8000,
      maxHeight: 8000,
    );
    // At most the backing scale times the window's size in points.
    expect(image.width, lessThanOrEqualTo(320 * 3));
  });

  guarded('refuses to capture another app', () async {
    await expectLater(
      native!.capture(
        CcWindowTarget(pids: [mine.pid], windowId: otherWindow),
        maxWidth: 200,
        maxHeight: 200,
      ),
      refusedWith(CcWindowStatus.notOwned),
    );
  });

  guarded('refuses input to another app', () async {
    await expectLater(
      native!.mouse(
        CcWindowTarget(pids: [mine.pid], windowId: otherWindow),
        mode: 0,
        phase: CcWindowPointerPhase.down,
        button: 0,
        x: 5,
        y: 5,
        clickCount: 1,
        modifiers: 0,
      ),
      refusedWith(CcWindowStatus.notOwned),
    );
    await expectLater(
      native!.text(
        CcWindowTarget(pids: [mine.pid], windowId: otherWindow),
        mode: 1,
        text: 'hello',
      ),
      refusedWith(CcWindowStatus.notOwned),
    );
  });

  guarded('refuses to read another app\'s UI', () async {
    await expectLater(
      native!.readUi(
        CcWindowTarget(pids: [mine.pid], windowId: otherWindow),
        maxNodes: 10,
      ),
      refusedWith(CcWindowStatus.notOwned),
    );
  });

  guarded('a tree rooted at or above this process owns nothing', () async {
    for (final root in [1, pid]) {
      await expectLater(
        native!.capture(
          CcWindowTarget(pids: [root], windowId: otherWindow),
          maxWidth: 200,
          maxHeight: 200,
        ),
        refusedWith(CcWindowStatus.invalid),
        reason: 'root $root',
      );
      await expectLater(
        native!.list(CcWindowTarget(pids: [root])),
        refusedWith(CcWindowStatus.invalid),
        reason: 'root $root',
      );
    }
  });

  guarded('a window that is gone is not found', () async {
    await expectLater(
      native!.capture(
        CcWindowTarget(pids: [mine.pid], windowId: 0x7ffffff0),
        maxWidth: 200,
        maxHeight: 200,
      ),
      refusedWith(CcWindowStatus.notFound),
    );
  });

  guarded('input without the grant is an error, never a silent drop', () async {
    final permissions = await native!.permissions();
    if (permissions['input'] == 'granted') {
      markTestSkipped('this process has the grant, so input would be real');
      return;
    }
    await expectLater(
      native!.mouse(
        CcWindowTarget(pids: [mine.pid], windowId: myWindow),
        mode: 0,
        phase: CcWindowPointerPhase.move,
        button: 0,
        x: 5,
        y: 5,
        clickCount: 1,
        modifiers: 0,
      ),
      refusedWith(CcWindowStatus.permission),
    );
  });

  test('a missing library reads as unavailable, not as a crash', () {
    final previous = CcWindow.libraryCandidates;
    CcWindow.libraryCandidates = () => ['/nonexistent/libcc_window.dylib'];
    addTearDown(() => CcWindow.libraryCandidates = previous);
    expect(CcWindow.isAvailable, isFalse);
    expect(() => CcWindow.require, throwsA(isA<CcWindowUnavailable>()));
  });
}
