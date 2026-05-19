import 'package:cc_domain/cc_domain.dart';
import 'package:control_center/core/update/web_update_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves a manifest body for every poll; the test swaps [body] between
/// polls to simulate a new deploy landing.
class _Manifest {
  String? body;
  int calls = 0;

  Future<String?> fetch(Uri uri) async {
    calls++;
    return body;
  }
}

String _manifest(String sha) =>
    '{"version": "1.0.0", "gitSha": "$sha", "builtAt": ""}';

void main() {
  late ProviderContainer container;
  late _Manifest manifest;

  WebUpdateController controller() =>
      container.read(webUpdateProvider.notifier);
  WebUpdateState state() => container.read(webUpdateProvider);

  setUp(() {
    manifest = _Manifest();
    container = ProviderContainer();
    addTearDown(container.dispose);
    // Prime the notifier, lift the web-only gate, then install the injectable
    // fetcher. start() also arms the real timers; the tests drive
    // checkForUpdate() directly so nothing depends on wall-clock delays.
    container.read(webUpdateProvider);
    controller()
      ..debugForceEnabled = true
      ..start(fetcher: manifest.fetch);
  });

  test('a different sha at the origin raises the banner', () async {
    manifest.body = _manifest('deadbee');
    await controller().checkForUpdate();

    expect(state().updateAvailable, isTrue);
    expect(state().available?.gitSha, 'deadbee');
    expect(state().checking, isFalse);
  });

  test('the running build being deployed is not an update', () async {
    manifest.body = _manifest(BuildInfo.buildGitSha);
    await controller().checkForUpdate();

    expect(state().updateAvailable, isFalse);
  });

  test('a redeploy of the SAME build clears a stale banner', () async {
    manifest.body = _manifest('deadbee');
    await controller().checkForUpdate();
    expect(state().updateAvailable, isTrue);

    // The origin rolled back to this build — the banner must not persist.
    manifest.body = _manifest(BuildInfo.buildGitSha);
    await controller().checkForUpdate();
    expect(state().updateAvailable, isFalse);
  });

  test('dismissal is keyed on the sha, not a latch', () async {
    manifest.body = _manifest('deadbee');
    await controller().checkForUpdate();
    controller().dismiss();
    expect(state().updateAvailable, isFalse);

    // The SAME deploy stays dismissed…
    await controller().checkForUpdate();
    expect(state().updateAvailable, isFalse);

    // …but the NEXT one must be offered again.
    manifest.body = _manifest('c0ffee1');
    await controller().checkForUpdate();
    expect(state().updateAvailable, isTrue);
    expect(state().available?.gitSha, 'c0ffee1');
  });

  test('a malformed or missing manifest is never an update', () async {
    manifest.body = 'not json at all';
    await controller().checkForUpdate();
    expect(state().updateAvailable, isFalse);

    manifest.body = null;
    await controller().checkForUpdate();
    expect(state().updateAvailable, isFalse);
    expect(state().checking, isFalse);
  });

  test('refresh while busy queues instead of reloading', () async {
    manifest.body = _manifest('deadbee');
    await controller().checkForUpdate();

    controller().requestRefresh(busy: true);
    // The page did not reload (the test would die with it); consent is held.
    expect(state().pendingRefresh, isTrue);
    expect(state().updateAvailable, isTrue);
  });

  test('dismissing drops a queued refresh', () async {
    manifest.body = _manifest('deadbee');
    await controller().checkForUpdate();
    controller().requestRefresh(busy: true);
    expect(state().pendingRefresh, isTrue);

    controller().dismiss();
    expect(state().pendingRefresh, isFalse);
  });

  test('start() is idempotent — a second call does not re-arm', () async {
    final before = manifest.calls;
    controller()
      ..start(fetcher: manifest.fetch)
      ..start(fetcher: manifest.fetch);
    expect(manifest.calls, before);
  });
}
