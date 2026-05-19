import 'package:control_center/app/window_visibility_guard.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pushes [state] the way the engine does, so the framework runs its real
/// transition logic (`framesEnabled` included) rather than a stubbed one.
Future<void> pushLifecycle(WidgetTester tester, AppLifecycleState state) async {
  ServicesBinding.instance.channelBuffers.push(
    SystemChannels.lifecycle.name,
    const StringCodec().encodeMessage(state.toString()),
    (ByteData? _) {},
  );
  await tester.pump();
  // The guard defers its repair to a microtask (see
  // `didChangeAppLifecycleState`). Platform-message dispatch — and therefore
  // that microtask — runs OUTSIDE the fake-async zone, so no amount of
  // pumping drains it: let the real event loop turn once instead.
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

void main() {
  setUp(() {
    // Both the lifecycle state and `framesEnabled` are process-wide on the
    // binding, so a test that leaves the app "resumed" would hand the next one
    // a state it never set.
    TestWidgetsFlutterBinding.ensureInitialized().resetInternalState();
  });

  testWidgets('re-enables frames when the app is demonstrably on screen', (
    tester,
  ) async {
    final guard = WindowVisibilityGuard(
      mainWindowFocused: () => true,
      nudgeMainWindow: () => true,
    );
    guard.install();

    // What the engine sends at launch, when the headless runner has no window
    // yet: frames off, so nothing the app does after this can paint.
    await pushLifecycle(tester, AppLifecycleState.hidden);
    expect(tester.binding.lifecycleState, AppLifecycleState.hidden);
    expect(tester.binding.framesEnabled, isFalse);

    guard.onMainWindowShown();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(tester.binding.lifecycleState, AppLifecycleState.resumed);
    expect(tester.binding.framesEnabled, isTrue);
    guard.dispose();
  });

  testWidgets('leaves a genuine hidden state alone', (tester) async {
    // No focused window of ours AND nothing visible to nudge: the app really
    // is hidden (Cmd-H, minimized, fully occluded) and muting it is what keeps
    // the primary window from rendering frames nobody can see.
    final guard = WindowVisibilityGuard(
      mainWindowFocused: () => false,
      nudgeMainWindow: () => false,
    );
    guard.install();

    guard.onMainWindowShown();
    await pushLifecycle(tester, AppLifecycleState.hidden);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(tester.binding.lifecycleState, AppLifecycleState.hidden);
    guard.dispose();
  });

  testWidgets('nudges, but does not rewrite the state, when the window is only visible', (
    tester,
  ) async {
    // The invite-code / SSO shape: the handoff completes while this app is not
    // frontmost, so no window of ours holds focus — the focus proof is
    // unavailable exactly where the repair is needed. A visible main window
    // still authorizes the REAL nudge (the engine recomputes occlusion and
    // pushes its own correction), but the guard must not push `resumed` on
    // the platform's behalf: whether the app is truly hidden is the engine's
    // call, and the nudge is how the engine gets to make it.
    var nudges = 0;
    final guard = WindowVisibilityGuard(
      mainWindowFocused: () => false,
      nudgeMainWindow: () {
        nudges++;
        return true;
      },
    );
    guard.install();
    guard.onMainWindowShown();

    await pushLifecycle(tester, AppLifecycleState.hidden);
    expect(tester.binding.framesEnabled, isFalse);

    // The staged passes keep nudging while the state stays stale — including
    // past the original 3-second horizon, because the content that needs the
    // frame (the screen behind the splash) settles when identity and the
    // workspace list come back over RPC, not when the window appears.
    await tester.pump(const Duration(seconds: 4));
    expect(nudges, greaterThanOrEqualTo(4));
    // And the synthetic push never happened: the framework state is still
    // whatever the engine last said.
    expect(tester.binding.lifecycleState, AppLifecycleState.hidden);
    guard.dispose();
  });

  testWidgets('stops nudging once the state is healthy', (tester) async {
    var nudges = 0;
    final guard = WindowVisibilityGuard(
      mainWindowFocused: () => false,
      nudgeMainWindow: () {
        nudges++;
        return true;
      },
    );
    guard.install();
    guard.onMainWindowShown();

    // The nudge's whole point is that the ENGINE sends the correction; let it.
    await pushLifecycle(tester, AppLifecycleState.hidden);
    await pushLifecycle(tester, AppLifecycleState.resumed);
    final settled = nudges;
    expect(settled, greaterThan(0));

    await tester.pump(const Duration(seconds: 35));
    expect(nudges, settled);
    guard.dispose();
  });

  testWidgets('stays out of the way until a main window exists', (
    tester,
  ) async {
    // Before the first window, `hidden` is the plain truth — there is nothing
    // on screen to argue about.
    final guard = WindowVisibilityGuard(
      mainWindowFocused: () => true,
      nudgeMainWindow: () => true,
    );
    guard.install();

    await pushLifecycle(tester, AppLifecycleState.hidden);
    await tester.pump(const Duration(seconds: 4));

    expect(tester.binding.lifecycleState, AppLifecycleState.hidden);
    guard.dispose();
  });

  testWidgets('does not re-enter the dispatch it was notified from', (
    tester,
  ) async {
    // The repair is a lifecycle message, and `ChannelBuffers.push` invokes the
    // handler synchronously — so repairing straight from
    // `didChangeAppLifecycleState` re-enters the binding's observer loop.
    // Observers later in the list are then handed the repaired `resumed`
    // BEFORE the `hidden` still being delivered, and the app's own
    // `AppLifecycleListener` (bootstrap_io, for the server shutdown) asserts
    // on the resulting resumed → hidden jump.
    final guard = WindowVisibilityGuard(
      mainWindowFocused: () => true,
      nudgeMainWindow: () => true,
    );
    guard.install();
    guard.onMainWindowShown();
    // Registered AFTER the guard, so it is the observer that would be caught
    // mid-dispatch.
    final listener = AppLifecycleListener();

    await pushLifecycle(tester, AppLifecycleState.resumed);
    await pushLifecycle(tester, AppLifecycleState.hidden);
    await tester.pump();

    expect(tester.takeException(), isNull);
    listener.dispose();
    guard.dispose();
  });

  testWidgets('repairs the second main window, not just the first', (
    tester,
  ) async {
    // The pairing path: the pre-app setup window goes up first (arming the
    // guard and using its staged passes), the user pastes a key, and only then
    // is the primary window created — with the setup window destroyed first,
    // so the app owns nothing visible in between and the engine disables
    // frames again. The window that actually renders the app is therefore the
    // SECOND one, and it needs the staged passes too: inside the will-show
    // hook it is not on screen yet, so the immediate check cannot prove the
    // `hidden` wrong.
    var focused = false;
    final guard = WindowVisibilityGuard(
      mainWindowFocused: () => focused,
      nudgeMainWindow: () => false,
    );
    guard.install();

    // Setup window: up, focused, healthy.
    focused = true;
    guard.onMainWindowShown();
    await tester.pump(const Duration(seconds: 4));

    // Handoff: the setup window is destroyed, nothing is on screen, frames go
    // off — and the lifecycle observer's own pass cannot argue, because there
    // is no focused window of ours at that instant.
    focused = false;
    await pushLifecycle(tester, AppLifecycleState.hidden);
    expect(tester.binding.framesEnabled, isFalse);

    // Primary window shows. Still not key inside the hook; macOS makes it so a
    // moment later.
    guard.onMainWindowShown();
    await tester.pump();
    focused = true;
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(tester.binding.lifecycleState, AppLifecycleState.resumed);
    expect(tester.binding.framesEnabled, isTrue);
    guard.dispose();
  });

  testWidgets('repairs a hidden state that arrives after the window', (
    tester,
  ) async {
    // The stale-occlusion case: the window is already up and focused when the
    // engine pushes `hidden`.
    final guard = WindowVisibilityGuard(
      mainWindowFocused: () => true,
      nudgeMainWindow: () => true,
    );
    guard.install();
    guard.onMainWindowShown();
    // Let every scheduled pass run against a healthy state, so only the
    // lifecycle observer is left to catch what follows.
    await tester.pump(const Duration(seconds: 4));

    await pushLifecycle(tester, AppLifecycleState.hidden);

    expect(tester.binding.lifecycleState, AppLifecycleState.resumed);
    expect(tester.binding.framesEnabled, isTrue);
    guard.dispose();
  });

  testWidgets('keeps repairing past the old 3-second horizon', (tester) async {
    // The regression this pins: the staged passes used to stop at 3 seconds,
    // which is shorter than a cold first-run server (or a remote login) takes
    // to answer `identity.me` and the workspace list — so the guard "repaired"
    // the window while it still showed the splash, and the content that
    // replaced the splash landed in a frame nobody scheduled.
    var nudges = 0;
    final guard = WindowVisibilityGuard(
      mainWindowFocused: () => false,
      nudgeMainWindow: () {
        nudges++;
        return true;
      },
    );
    guard.install();
    guard.onMainWindowShown();

    await pushLifecycle(tester, AppLifecycleState.hidden);
    await tester.pump(const Duration(seconds: 16));

    // Immediate + 250ms + 1s + 3s + 8s + 15s have all fired by now.
    expect(nudges, greaterThanOrEqualTo(6));
    guard.dispose();
  });
}
