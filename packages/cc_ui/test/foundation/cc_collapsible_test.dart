import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../cc_test_app.dart';

const _bodyKey = ValueKey<String>('body');

/// A header that toggles a [CcCollapsible] over a 100px body. Tapping it is
/// pointer input; Enter on the focused header is keyboard input.
class _Host extends StatefulWidget {
  const _Host({this.initiallyExpanded = false, this.maintainState = false});

  final bool initiallyExpanded;
  final bool maintainState;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CcTappable(
          onPressed: () => setState(() => _expanded = !_expanded),
          builder: (_, _) => const SizedBox(height: 20, child: Text('Header')),
        ),
        CcCollapsible(
          expanded: _expanded,
          maintainState: widget.maintainState,
          child: const SizedBox(key: _bodyKey, height: 100),
        ),
      ],
    );
  }
}

double _height(WidgetTester tester) =>
    tester.getSize(find.byType(CcCollapsible)).height;

// FocusModality is a process-wide singleton whose key handler only survives
// the test that first registers it (the binding clears keyboard handlers
// between tests), so the keyboard case runs first. Its pointer route persists,
// so later taps still read as pointer input.
void main() {
  testWidgets('keyboard toggles snap without animating', (tester) async {
    await tester.pumpWidget(ccTestApp(const _Host()));
    Focus.of(tester.element(find.text('Header'))).requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(_height(tester), 100);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.byKey(_bodyKey), findsNothing);
    expect(_height(tester), 0);
  });

  testWidgets('pointer expand grows over the moderate token', (tester) async {
    await tester.pumpWidget(ccTestApp(const _Host()));
    expect(find.byKey(_bodyKey), findsNothing);
    expect(_height(tester), 0);

    await tester.tap(find.text('Header'));
    await tester.pump();
    await tester.pump(CcMotion.moderate ~/ 2);
    expect(_height(tester), greaterThan(0));
    expect(_height(tester), lessThan(100));

    await tester.pump(CcMotion.moderate);
    expect(_height(tester), 100);
  });

  testWidgets('pointer collapse keeps content visible until the exit ends', (
    tester,
  ) async {
    await tester.pumpWidget(ccTestApp(const _Host(initiallyExpanded: true)));
    expect(_height(tester), 100);

    await tester.tap(find.text('Header'));
    await tester.pump();
    await tester.pump(CcMotion.moderateExit ~/ 2);
    // The body still paints while it slides under the clip — no blank gap.
    expect(find.byKey(_bodyKey), findsOneWidget);
    expect(_height(tester), greaterThan(0));
    expect(_height(tester), lessThan(100));

    await tester.pump(CcMotion.moderateExit);
    expect(find.byKey(_bodyKey), findsNothing);
    expect(_height(tester), 0);
  });

  testWidgets('reduced motion snaps the size and keeps a short fade', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(const _Host(), theme: CcThemeData.light(reducedMotion: true)),
    );

    await tester.tap(find.text('Header'));
    await tester.pump();
    expect(_height(tester), 100);
    final fade = tester.widget<FadeTransition>(
      find.ancestor(
        of: find.byKey(_bodyKey),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, lessThan(1));

    await tester.pump(CcMotion.fade);
    expect(fade.opacity.value, 1);
  });

  testWidgets('maintainState keeps the body mounted offstage', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const _Host(initiallyExpanded: true, maintainState: true)),
    );
    final before = tester.element(find.byKey(_bodyKey));

    await tester.tap(find.text('Header'));
    await tester.pumpAndSettle();
    expect(_height(tester), 0);
    expect(find.byKey(_bodyKey, skipOffstage: false), findsOneWidget);

    await tester.tap(find.text('Header'));
    await tester.pumpAndSettle();
    expect(tester.element(find.byKey(_bodyKey)), same(before));
  });

  testWidgets('the body keeps its stretched width while it animates', (
    tester,
  ) async {
    const stretchKey = ValueKey<String>('stretch');
    await tester.pumpWidget(
      ccTestApp(
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CcCollapsible(
                  expanded: true,
                  child: ColoredBox(
                    key: stretchKey,
                    color: Color(0xFF000000),
                    child: SizedBox(height: 40, child: Text('narrow')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(stretchKey)), const Size(300, 40));
  });
}
