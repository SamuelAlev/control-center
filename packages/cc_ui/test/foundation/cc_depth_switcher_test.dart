import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A page whose label sits at its leading edge, so the label's x reports the
/// page's horizontal travel.
Widget _page(String label) => Align(
  alignment: AlignmentDirectional.topStart,
  child: Text(label, key: ValueKey(label)),
);

Widget _host(
  int depth, {
  TextDirection textDirection = TextDirection.ltr,
  bool reducedMotion = false,
  Widget? child,
}) {
  // Not ccTestApp: its Overlay captures the child on the first pump, so a
  // re-pump with a new depth would never reach the switcher.
  return CcTheme(
    data: CcThemeData.light(),
    child: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            width: 200,
            height: 100,
            child: CcDepthSwitcher(
              depth: depth,
              child: child ?? _page(depth == 0 ? 'root' : 'depth $depth'),
            ),
          ),
        ),
      ),
    ),
  );
}

double _x(WidgetTester tester, String label) =>
    tester.getTopLeft(find.byKey(ValueKey(label), skipOffstage: false)).dx;

double _opacity(WidgetTester tester, String label) => tester
    .widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(ValueKey(label), skipOffstage: false),
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;

void main() {
  testWidgets('drilling in: the root drifts to the start, the page arrives '
      'from the end', (tester) async {
    await tester.pumpWidget(_host(0));
    final restX = _x(tester, 'root');

    await tester.pumpWidget(_host(1));
    await tester.pump(const Duration(milliseconds: 60));

    expect(_x(tester, 'root'), lessThan(restX));
    expect(_x(tester, 'depth 1'), greaterThan(restX));
    expect(_opacity(tester, 'root'), lessThan(1));

    await tester.pumpAndSettle();
    expect(_x(tester, 'depth 1'), restX);
    expect(_opacity(tester, 'depth 1'), 1);
    // The root stays mounted beneath, offstage, to come back to.
    expect(find.text('root'), findsNothing);
    expect(find.text('root', skipOffstage: false), findsOneWidget);
  });

  testWidgets('going back runs the motion mirrored and disposes the deeper '
      'page', (tester) async {
    await tester.pumpWidget(_host(0));
    final restX = _x(tester, 'root');
    await tester.pumpWidget(_host(1));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(0));
    await tester.pump(const Duration(milliseconds: 60));

    expect(_x(tester, 'root'), lessThan(restX));
    expect(_x(tester, 'depth 1'), greaterThan(restX));

    await tester.pumpAndSettle();
    expect(_x(tester, 'root'), restX);
    expect(find.text('depth 1', skipOffstage: false), findsNothing);
  });

  testWidgets('mirrors under RTL', (tester) async {
    await tester.pumpWidget(_host(0, textDirection: TextDirection.rtl));
    final restX = _x(tester, 'root');

    await tester.pumpWidget(_host(1, textDirection: TextDirection.rtl));
    await tester.pump(const Duration(milliseconds: 60));

    expect(_x(tester, 'root'), greaterThan(restX));
    expect(_x(tester, 'depth 1'), lessThan(restX));
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion cross-fades in place on the fade token', (
    tester,
  ) async {
    await tester.pumpWidget(_host(0, reducedMotion: true));
    final restX = _x(tester, 'root');

    await tester.pumpWidget(_host(1, reducedMotion: true));
    await tester.pump(CcMotion.fade ~/ 2);

    expect(_x(tester, 'root'), restX);
    expect(_x(tester, 'depth 1'), restX);
    expect(_opacity(tester, 'root'), lessThan(1));

    await tester.pump(CcMotion.fade);
    // The settle lands on the frame after the controller completes.
    await tester.pump();
    expect(find.text('root'), findsNothing);
    expect(_opacity(tester, 'depth 1'), 1);
  });

  testWidgets('backing out mid-drill retraces from where it is', (
    tester,
  ) async {
    await tester.pumpWidget(_host(0));
    final restX = _x(tester, 'root');
    await tester.pumpWidget(_host(1));
    await tester.pump(const Duration(milliseconds: 120));
    final midX = _x(tester, 'root');

    await tester.pumpWidget(_host(0));
    await tester.pump(const Duration(milliseconds: 1));
    // No jump: the root resumes from (about) where it was, heading home.
    expect(_x(tester, 'root'), closeTo(midX, 1));

    await tester.pumpAndSettle();
    expect(_x(tester, 'root'), restX);
    expect(find.text('depth 1', skipOffstage: false), findsNothing);
  });

  testWidgets('a retained page keeps its state across a drill', (tester) async {
    final root = _Stateful(key: GlobalKey());
    await tester.pumpWidget(_host(0, child: root));
    final state = tester.state(find.byType(_Stateful));

    await tester.pumpWidget(_host(1));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_host(0, child: root));
    await tester.pumpAndSettle();

    expect(tester.state(find.byType(_Stateful)), same(state));
  });

  testWidgets('focus in the leaving page lands on the arriving one', (
    tester,
  ) async {
    final rootNode = FocusNode(debugLabel: 'root');
    final deepNode = FocusNode(debugLabel: 'deep');
    addTearDown(rootNode.dispose);
    addTearDown(deepNode.dispose);

    await tester.pumpWidget(
      _host(
        0,
        child: Focus(focusNode: rootNode, child: const Text('root')),
      ),
    );
    rootNode.requestFocus();
    await tester.pump();
    expect(rootNode.hasFocus, isTrue);

    await tester.pumpWidget(
      _host(
        1,
        child: Focus(focusNode: deepNode, child: const Text('deep')),
      ),
    );
    await tester.pumpAndSettle();

    expect(rootNode.hasFocus, isFalse);
    expect(deepNode.hasFocus, isTrue);
  });
}

class _Stateful extends StatefulWidget {
  const _Stateful({super.key});

  @override
  State<_Stateful> createState() => _StatefulState();
}

class _StatefulState extends State<_Stateful> {
  @override
  Widget build(BuildContext context) => const Text('stateful');
}
