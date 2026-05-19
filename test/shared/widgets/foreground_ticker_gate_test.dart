import 'package:control_center/shared/widgets/foreground_ticker_gate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A ticker owner INSIDE the gated subtree, so its ticker is muted by the
/// gate's ancestor [TickerMode]. A controller built with `vsync: tester` sits
/// OUTSIDE the widget tree entirely and the gate can never reach it — testing
/// through one would assert nothing.
class _Spinner extends StatefulWidget {
  const _Spinner();

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    // Eager, NOT a `late final` initializer: a lazy field would only call
    // `repeat()` on first access from the test, so the animation would not
    // actually be running at the moment the gate mutes it — which is the whole
    // thing under test. Real spinners start in initState too.
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  group('ForegroundTickerGate', () {
    bool tickerModeOf(WidgetTester tester) {
      // Read BELOW the gate's TickerMode — the gate's own context is an
      // ancestor of the TickerMode it builds and would never see it.
      final ctx = tester.element(find.byType(SizedBox));
      return TickerMode.valuesOf(ctx).enabled;
    }

    testWidgets('starts with tickers enabled when foreground', (tester) async {
      await tester.pumpWidget(const ForegroundTickerGate(child: SizedBox()));
      expect(tickerModeOf(tester), isTrue);
    });

    // `inactive` is the state this gate exists for: the engine keeps frames
    // ENABLED (another app merely took focus, the window may still be covered),
    // so without the gate every repeating animation keeps burning frames nobody
    // can see. See the group below for why the deeper states differ.
    testWidgets('mutes tickers on inactive', (tester) async {
      await tester.pumpWidget(const ForegroundTickerGate(child: SizedBox()));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(tickerModeOf(tester), isFalse);
      expect(
        tester.binding.framesEnabled,
        isTrue,
        reason:
            'frames stay enabled on inactive — the gate is what stops the '
            'animation-driven ones',
      );
    });

    testWidgets('unmutes tickers when the app resumes', (tester) async {
      await tester.pumpWidget(const ForegroundTickerGate(child: SizedBox()));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(tickerModeOf(tester), isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(tickerModeOf(tester), isTrue);
    });

    // Below `inactive`, the SCHEDULER itself disables frames, so no ticker can
    // produce one whatever the gate says — and the gate's pending `setState`
    // cannot even be pumped (a rebuild needs a frame). Asserting a muted
    // TickerMode here would be asserting something the framework has already
    // made unreachable; assert the actual guarantee instead.
    group('states where the engine disables frames outright', () {
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.detached,
      ]) {
        testWidgets('$state disables frames, so tickers cannot burn any', (
          tester,
        ) async {
          await tester.pumpWidget(
            const ForegroundTickerGate(child: SizedBox()),
          );
          expect(tester.binding.framesEnabled, isTrue);

          tester.binding.handleAppLifecycleStateChanged(state);
          await tester.pump();

          expect(tester.binding.framesEnabled, isFalse);
        });
      }

      testWidgets('returning to resumed re-enables frames and tickers', (
        tester,
      ) async {
        await tester.pumpWidget(const ForegroundTickerGate(child: SizedBox()));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        await tester.pump();
        expect(tester.binding.framesEnabled, isFalse);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(tester.binding.framesEnabled, isTrue);
        expect(tickerModeOf(tester), isTrue);
      });
    });

    testWidgets('a repeating animation freezes while backgrounded', (
      tester,
    ) async {
      await tester.pumpWidget(const ForegroundTickerGate(child: _Spinner()));
      // No tearDown on the controller: `_SpinnerState.dispose` owns it, and the
      // widget is torn down before test tearDowns run.
      final state = tester.state<_SpinnerState>(find.byType(_Spinner));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      final atMute = state.controller.value;

      // Muting stops the ticker's CALLBACKS, not the ticker: `isAnimating`
      // stays true, so the observable contract is that the value stops
      // advancing while time passes.
      await tester.pump(const Duration(seconds: 2));
      expect(
        state.controller.value,
        atMute,
        reason: 'a muted ticker must not advance the animation',
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        state.controller.value,
        greaterThan(atMute),
        reason: 'the animation continues where it left off on resume',
      );
    });
  });
}
