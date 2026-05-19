import 'package:control_center/core/update/desktop_update_controller.dart';
import 'package:control_center/core/update/desktop_updater_port.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for Sparkle/WinSparkle: records what the controller asked for
/// and lets the test fire the outcomes the native listener would.
class _FakeUpdaterPort implements DesktopUpdaterPort {
  _FakeUpdaterPort({this.supported = true});

  @override
  final bool supported;

  int initCalls = 0;
  int releasesPageOpened = 0;
  final List<bool> checks = [];

  /// Set when [check] should fail instead of completing.
  Object? failWith;

  void Function(String? version, String? notes)? _onAvailable;
  void Function()? _onNotAvailable;
  void Function(String message)? _onError;

  /// Whether the controller registered its outcome handlers — the thing that
  /// makes a check's result observable at all.
  bool get handlersRegistered => _onAvailable != null;

  @override
  Future<void> init() async => initCalls++;

  @override
  DesktopUpdaterHandlerRegistration setHandlers({
    void Function(String? version, String? notes)? onAvailable,
    void Function()? onNotAvailable,
    void Function(String message)? onError,
  }) {
    _onAvailable = onAvailable;
    _onNotAvailable = onNotAvailable;
    _onError = onError;
    return const DesktopUpdaterHandlerRegistration.inert();
  }

  @override
  Future<void> check({required bool background}) async {
    checks.add(background);
    final failure = failWith;
    if (failure != null) {
      throw failure;
    }
  }

  @override
  void openReleasesPage() => releasesPageOpened++;

  void fireAvailable(String version) => _onAvailable?.call(version, 'notes');
  void fireNotAvailable() => _onNotAvailable?.call();
  void fireError(String message) => _onError?.call(message);
}

void main() {
  late ProviderContainer container;
  late _FakeUpdaterPort port;

  DesktopUpdateController controller() =>
      container.read(desktopUpdateProvider.notifier);
  DesktopUpdateState state() => container.read(desktopUpdateProvider);

  void build({bool supported = true}) {
    port = _FakeUpdaterPort(supported: supported);
    container = ProviderContainer(
      overrides: [desktopUpdaterPortProvider.overrideWithValue(port)],
    );
    addTearDown(container.dispose);
    container.read(desktopUpdateProvider);
  }

  setUp(build);

  test('checkNow arms the updater even if start() never ran', () async {
    // The macOS app-menu item reaches checkNow() through a method channel
    // that can fire before the shell mounts. Without the lazy init the check
    // would run with no handlers registered and the UI would sit on
    // "checking" forever.
    await controller().checkNow();

    expect(port.initCalls, 1);
    expect(port.handlersRegistered, isTrue);
    expect(port.checks, [false]);
  });

  test('the updater is armed once across repeated checks', () async {
    await controller().checkNow();
    await controller().checkNow();

    expect(port.initCalls, 1);
    expect(port.checks, [false, false]);
  });

  test('an available outcome carries the version', () async {
    await controller().checkNow();
    port.fireAvailable('9.9.9');

    expect(state().status, DesktopUpdateStatus.available);
    expect(state().version, '9.9.9');
  });

  test('an up-to-date outcome drops a stale version string', () async {
    await controller().checkNow();
    port.fireAvailable('9.9.9');
    expect(state().version, '9.9.9');

    // A later check finding nothing must not leave the old version attached.
    await controller().checkNow();
    port.fireNotAvailable();

    expect(state().status, DesktopUpdateStatus.upToDate);
    expect(state().version, isNull);
  });

  test('an error outcome is reported and then cleared by a new check', () async {
    await controller().checkNow();
    port.fireError('feed unreachable');
    expect(state().status, DesktopUpdateStatus.error);
    expect(state().errorMessage, 'feed unreachable');

    await controller().checkNow();
    expect(state().status, DesktopUpdateStatus.checking);
    expect(state().errorMessage, isNull);
  });

  test('a throwing check surfaces as an error, not a stuck spinner', () async {
    port.failWith = StateError('boom');
    await controller().checkNow();

    expect(state().status, DesktopUpdateStatus.error);
    expect(state().errorMessage, contains('boom'));
  });

  test('a busy app defers instead of prompting', () async {
    controller().start(busyProbe: () => true);
    await controller().checkNow();

    expect(state().status, DesktopUpdateStatus.deferred);
    // Nothing was checked: a prompt now would interrupt the recording.
    expect(port.checks, isEmpty);
  });

  test('an unsupported platform opens the releases page and says so', () async {
    build(supported: false);
    await controller().checkNow();

    expect(port.releasesPageOpened, 1);
    expect(state().status, DesktopUpdateStatus.openedReleasesPage);
    // No native check was attempted.
    expect(port.checks, isEmpty);
  });

  test('start() is a no-op on a platform with no updater', () {
    build(supported: false);
    controller().start();

    expect(port.initCalls, 0);
  });

  test('the scheduled check runs in the background, then daily', () {
    fakeAsync((async) {
      controller().start();
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 61));

      expect(port.checks, [true], reason: 'first check is a silent probe');

      async.elapse(const Duration(hours: 24));
      expect(port.checks, [true, true]);
    });
  });

  test('a background find escalates to the interactive prompt', () {
    fakeAsync((async) {
      controller().start();
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 61));
      expect(port.checks, [true]);

      // The native updater reports the find. Because the check that produced
      // it was silent, the controller must re-run it interactively so the
      // user actually sees Sparkle's prompt.
      port.fireAvailable('9.9.9');
      async.flushMicrotasks();

      expect(state().status, DesktopUpdateStatus.available);
      expect(port.checks, [true, false]);
    });
  });

  test('a foreground find does NOT double-prompt', () {
    fakeAsync((async) {
      controller().checkNow();
      async.flushMicrotasks();
      expect(port.checks, [false]);

      port.fireAvailable('9.9.9');
      async.flushMicrotasks();

      // Sparkle already showed its own prompt for this check.
      expect(port.checks, [false]);
    });
  });

  test('a deferred check retries without waiting out the full day', () {
    fakeAsync((async) {
      var busy = true;
      controller().start(busyProbe: () => busy);
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 61));

      expect(state().status, DesktopUpdateStatus.deferred);
      expect(port.checks, isEmpty);

      // Recording ends; the retry must arrive long before the 24h tick.
      busy = false;
      async.elapse(const Duration(minutes: 31));
      expect(port.checks, [true]);
    });
  });

  test('a check with no outcome event does not hang on "checking"', () {
    fakeAsync((async) {
      controller().checkNow();
      async.flushMicrotasks();
      expect(state().status, DesktopUpdateStatus.checking);

      // The user dismissed Sparkle's window: no terminal event ever arrives.
      async.elapse(const Duration(minutes: 3));
      expect(state().status, DesktopUpdateStatus.idle);
    });
  });
}
