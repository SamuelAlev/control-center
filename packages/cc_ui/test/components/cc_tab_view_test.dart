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

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
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

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(selected.last, _tabs.length - 2);
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

    testWidgets('handles a changing number of tabs without leaking nodes', (
      tester,
    ) async {
      // didUpdateWidget disposes/recreates the focus nodes when the tab count
      // changes. Pumping a different length must not throw.
      late void Function(void Function()) mutate;
      var tabCount = 3;
      await tester.pumpWidget(
        ccTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              mutate = setState;
              final tabs = tabCount == 3
                  ? _tabs
                  : const [
                      CcTabViewEntry(
                        label: Text('Only'),
                        content: Text('Only body'),
                      ),
                    ];
              return CcTabView(tabs: tabs, selectedIndex: 0, onChanged: (_) {});
            },
          ),
        ),
      );
      expect(find.text('Overview'), findsOneWidget);

      // Rebuild with a single tab — exercises didUpdateWidget's node teardown.
      mutate(() => tabCount = 1);
      await tester.pumpAndSettle();
      expect(find.text('Only'), findsOneWidget);
      expect(find.text('Overview'), findsNothing);
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
