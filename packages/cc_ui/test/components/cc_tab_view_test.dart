import 'package:cc_ui/src/components/cc_tab_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

const _tabs = <CcTabViewEntry>[
  CcTabViewEntry(label: Text('Overview'), content: Text('Overview body')),
  CcTabViewEntry(label: Text('Activity'), content: Text('Activity body')),
  CcTabViewEntry(label: Text('Settings'), content: Text('Settings body')),
];

void main() {
  group('CcTabView', () {
    testWidgets('renders every tab label and the selected panel', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(CcTabView(tabs: _tabs, selectedIndex: 0, onChanged: (_) {})),
      );

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      // The first tab's content is visible.
      expect(find.text('Overview body'), findsOneWidget);
    });

    testWidgets('switches the content panel when selectedIndex changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(CcTabView(tabs: _tabs, selectedIndex: 1, onChanged: (_) {})),
      );

      expect(find.text('Activity body'), findsOneWidget);
      expect(find.text('Overview body'), findsNothing);
    });

    testWidgets('fires onChanged with the tapped index', (tester) async {
      int? selected;
      await tester.pumpWidget(
        ccTestApp(
          CcTabView(
            tabs: _tabs,
            selectedIndex: 0,
            onChanged: (i) => selected = i,
          ),
        ),
      );

      await tester.tap(find.text('Settings'));

      expect(selected, 2);
    });

    testWidgets('arrow keys move selection forward and wrap', (tester) async {
      final selected = <int>[];
      await tester.pumpWidget(
        ccTestApp(
          _MirrorSelection(
            tabs: _tabs,
            initial: 0,
            onChanged: selected.add,
          ),
        ),
      );

      // Focus the selected (0th) tab so it receives key events.
      await tester.tap(find.text('Overview'));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(selected.last, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(selected.last, 2);

      // Wraps back to the first tab.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(selected.last, 0);
    });

    testWidgets('arrow left moves selection backward and wraps', (
      tester,
    ) async {
      final selected = <int>[];
      await tester.pumpWidget(
        ccTestApp(
          _MirrorSelection(
            tabs: _tabs,
            initial: 0,
            onChanged: selected.add,
          ),
        ),
      );

      await tester.tap(find.text('Overview'));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      // From 0, wrapping backward lands on the last tab.
      expect(selected.last, _tabs.length - 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(selected.last, _tabs.length - 2);
    });

    testWidgets('arrow up/down are left to directional focus', (
      tester,
    ) async {
      final selected = <int>[];
      await tester.pumpWidget(
        ccTestApp(
          _MirrorSelection(tabs: _tabs, initial: 0, onChanged: selected.add),
        ),
      );
      await tester.tap(find.text('Overview'));
      await tester.pump();
      selected.clear();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(selected, isEmpty);
    });

    testWidgets('arrow keys follow the reading direction under RTL', (
      tester,
    ) async {
      final selected = <int>[];
      await tester.pumpWidget(
        ccTestApp(
          _MirrorSelection(tabs: _tabs, initial: 0, onChanged: selected.add),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.tap(find.text('Overview'));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(selected.last, 1);
      expect(_hasFocus(tester, 'Activity'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(selected.last, 0);
    });

    testWidgets('the strip is one Tab stop and Tab leaves it', (tester) async {
      final before = FocusNode(debugLabel: 'before');
      final after = FocusNode(debugLabel: 'after');
      addTearDown(before.dispose);
      addTearDown(after.dispose);
      await tester.pumpWidget(
        ccTestApp(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(
                focusNode: before,
                child: const SizedBox(width: 20, height: 20),
              ),
              CcTabView(tabs: _tabs, selectedIndex: 1, onChanged: (_) {}),
              Focus(
                focusNode: after,
                child: const SizedBox(width: 20, height: 20),
              ),
            ],
          ),
        ),
      );
      before.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_hasFocus(tester, 'Activity'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(after.hasPrimaryFocus, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_hasFocus(tester, 'Activity'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(before.hasPrimaryFocus, isTrue);
    });

    testWidgets('the selected tab is announced as selected', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        ccTestApp(CcTabView(tabs: _tabs, selectedIndex: 1, onChanged: (_) {})),
      );
      expect(
        tester.getSemantics(find.text('Activity')),
        matchesSemantics(
          label: 'Activity',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('Home and End jump to the first and last tab', (tester) async {
      final selected = <int>[];
      await tester.pumpWidget(
        ccTestApp(
          _MirrorSelection(
            tabs: _tabs,
            initial: 1,
            onChanged: selected.add,
          ),
        ),
      );

      await tester.tap(find.text('Activity'));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(selected.last, _tabs.length - 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(selected.last, 0);
    });

    testWidgets('expand wraps the content in an Expanded', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          SizedBox(
            height: 400,
            child: CcTabView(
              tabs: _tabs,
              selectedIndex: 0,
              onChanged: (_) {},
              expand: true,
            ),
          ),
        ),
      );

      // Expanded is only present when expand is set.
      expect(find.byType(Expanded), findsOneWidget);
      expect(find.text('Overview body'), findsOneWidget);
    });

    testWidgets('without expand the content is not wrapped in Expanded', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(CcTabView(tabs: _tabs, selectedIndex: 0, onChanged: (_) {})),
      );

      expect(find.byType(Expanded), findsNothing);
    });

    testWidgets(
      'renders nothing for the panel when the index is out of range',
      (tester) async {
        await tester.pumpWidget(
          ccTestApp(
            CcTabView(tabs: _tabs, selectedIndex: 99, onChanged: (_) {}),
          ),
        );

        // No content panel rendered; the strip labels are still present.
        expect(find.text('Overview body'), findsNothing);
        expect(find.text('Activity body'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('focus stays on its tab when the tab count changes', (
      tester,
    ) async {
      final count = ValueNotifier(2);
      addTearDown(count.dispose);
      await tester.pumpWidget(
        ccTestApp(
          ValueListenableBuilder<int>(
            valueListenable: count,
            builder: (context, n, _) => CcTabView(
              tabs: _tabs.sublist(0, n),
              selectedIndex: 0,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('Activity'));
      await tester.pump();
      expect(_hasFocus(tester, 'Activity'), isTrue);

      count.value = 3;
      await tester.pumpAndSettle();
      expect(_hasFocus(tester, 'Activity'), isTrue);

      // Dropping the focused tab hands focus to the tab now at the end.
      count.value = 1;
      await tester.pumpAndSettle();
      expect(find.text('Activity'), findsNothing);
      expect(_hasFocus(tester, 'Overview'), isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}

/// A tiny host that mirrors the tab view's selection back into its
/// [selectedIndex] prop, so keyboard navigation (which reads the prop to compute
/// the next index) advances correctly.
class _MirrorSelection extends StatefulWidget {
  const _MirrorSelection({
    required this.tabs,
    required this.initial,
    required this.onChanged,
  });

  final List<CcTabViewEntry> tabs;
  final int initial;
  final ValueChanged<int> onChanged;

  @override
  State<_MirrorSelection> createState() => _MirrorSelectionState();
}

class _MirrorSelectionState extends State<_MirrorSelection> {
  late int _index = widget.initial;

  @override
  Widget build(BuildContext context) {
    return CcTabView(
      tabs: widget.tabs,
      selectedIndex: _index,
      onChanged: (i) {
        setState(() => _index = i);
        widget.onChanged(i);
      },
    );
  }
}

/// Whether the tab labelled [label] holds primary focus.
bool _hasFocus(WidgetTester tester, String label) =>
    Focus.of(tester.element(find.text(label))).hasPrimaryFocus;
