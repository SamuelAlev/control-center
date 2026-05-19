import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The desktop's will-show hook must show the window it just styled.
///
/// nativeapi swizzles `NSWindow makeKeyAndOrderFront:` and, once a will-show
/// hook is registered, calls the hook INSTEAD of the original implementation —
/// the hook owns the decision, and the window appears only if it asks for it
/// via `callOriginalShow`. A hook that merely styles and returns produces the
/// worst possible failure: every window (the app, the pre-app setup screen,
/// the HUDs) is silently never shown, so the process runs with nothing on
/// screen, no exception and no log. There is no unit test that can catch that
/// — the swizzle is native — so pin the call itself.
String _willShowHookBody() {
  final source = File('lib/bootstrap/bootstrap_io.dart').readAsStringSync();
  final start = source.indexOf('setWillShowHook(');
  expect(
    start,
    isNonNegative,
    reason: 'the desktop bootstrap should still install a will-show hook',
  );
  final end = source.indexOf('\n  });', start);
  expect(end, isNonNegative, reason: 'could not find the end of the hook');
  return source.substring(start, end);
}

void main() {
  test('the will-show hook re-styles once the title is set', () {
    // A window's title is applied AFTER the call that created and showed it
    // (`WindowControllerMacOS` calls `setTitle` after `createWindow` returns),
    // so the hook's own pass runs against an untitled window and
    // `styleWindowOnShow`'s title switch matches nothing. Without a deferred
    // pass the app wears the stock macOS title bar and the HUDs come up as
    // ordinary windows.
    expect(
      _willShowHookBody(),
      contains('dressKnownWindows'),
      reason:
          'the hook must re-dress windows once their titles have landed; a '
          'microtask scheduled from the hook is what makes the chrome apply',
    );
  });

  test('the will-show hook shows the window (callOriginalShow)', () {
    final source = File('lib/bootstrap/bootstrap_io.dart').readAsStringSync();
    final start = source.indexOf('setWillShowHook(');
    expect(
      start,
      isNonNegative,
      reason: 'the desktop bootstrap should still install a will-show hook',
    );
    // The hook body ends at the `});` that closes the setWillShowHook call.
    final end = source.indexOf('\n  });', start);
    expect(end, isNonNegative, reason: 'could not find the end of the hook');
    final body = source.substring(start, end);

    expect(
      body,
      contains('callOriginalShow(windowId)'),
      reason:
          'A registered will-show hook SUPPRESSES the native show. Without '
          'callOriginalShow(windowId) no window ever appears — the app boots '
          'into an invisible window with no error anywhere.',
    );
    expect(
      body.indexOf('styleWindowOnShow'),
      lessThan(body.indexOf('callOriginalShow')),
      reason:
          'style the window BEFORE showing it, or its chrome (hidden title '
          'bar, transparent background, restored geometry) flashes on screen',
    );
  });
}
