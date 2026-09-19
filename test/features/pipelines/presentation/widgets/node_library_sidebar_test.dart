import 'package:cc_domain/features/pipelines/domain/services/node_type_library.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_library_sidebar.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

Finder _cardOf(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(CcCard)).first;

MouseCursor? _paletteCursor(WidgetTester tester, String title) {
  final regions = tester.widgetList<MouseRegion>(
    find.ancestor(of: find.text(title), matching: find.byType(MouseRegion)),
  );
  for (final region in regions) {
    if (region.cursor == SystemMouseCursors.grab ||
        region.cursor == SystemMouseCursors.grabbing) {
      return region.cursor;
    }
  }
  return null;
}

bool _cardHasHoverWash(WidgetTester tester, String title) {
  final hover = CcCardTokens.panel(DesignSystemTokens.light()).hoverBg;
  return tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: _cardOf(title),
          matching: find.byType(DecoratedBox),
        ),
      )
      .any((box) {
        final decoration = box.decoration;
        return decoration is BoxDecoration && decoration.color == hover;
      });
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Future<void> pumpSidebar(WidgetTester tester) async {
    await tester.pumpWidget(
      testWrap(
        SizedBox(
          width: 280,
          height: 800,
          child: NodeLibrarySidebar(library: defaultNodeTypeLibrary()),
        ),
      ),
    );
  }

  testWidgets('palette rows wash on hover and use a grab cursor', (
    tester,
  ) async {
    await pumpSidebar(tester);
    final title = l10n.triggerEventManual;

    expect(_paletteCursor(tester, title), SystemMouseCursors.grab);
    expect(_cardHasHoverWash(tester, title), isFalse);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.text(title)));
    await tester.pump();

    expect(_cardHasHoverWash(tester, title), isTrue);
    expect(_paletteCursor(tester, title), SystemMouseCursors.grab);
  });

  testWidgets('palette rows switch to grabbing while a drag is in flight', (
    tester,
  ) async {
    await pumpSidebar(tester);
    final title = l10n.triggerEventManual;

    final gesture = await tester.startGesture(
      tester.getCenter(find.text(title)),
    );
    await tester.pump();
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump();

    expect(_paletteCursor(tester, title), SystemMouseCursors.grabbing);

    await gesture.up();
    await tester.pump();
    expect(_paletteCursor(tester, title), SystemMouseCursors.grab);
  });

  testWidgets('searching the palette finds a specific event node', (
    tester,
  ) async {
    await pumpSidebar(tester);

    expect(find.text(l10n.triggerEventWebhook), findsOneWidget);

    await tester.enterText(find.byType(CcTextField), 'merged');
    await tester.pump();

    expect(find.text(l10n.triggerEventPrMerged), findsOneWidget);
    expect(find.text(l10n.triggerPrMergedHelp), findsOneWidget);
    expect(find.text(l10n.triggerEventWebhook), findsNothing);
    expect(find.text('PrMerged'), findsNothing);
  });

  testWidgets('searching by type name still finds the event node', (
    tester,
  ) async {
    await pumpSidebar(tester);

    await tester.enterText(find.byType(CcTextField), 'PrMerged');
    await tester.pump();

    expect(find.text(l10n.triggerEventPrMerged), findsOneWidget);
    expect(find.text(l10n.triggerPrMergedHelp), findsOneWidget);
  });
}
