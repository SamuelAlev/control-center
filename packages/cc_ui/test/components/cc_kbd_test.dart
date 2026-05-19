import 'package:cc_ui/src/components/cc_kbd.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('renders the key label', (tester) async {
    await tester.pumpWidget(ccTestApp(const CcKbd(keyLabel: '⌘K')));

    expect(find.text('⌘K'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders with a custom font size and family', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcKbd(keyLabel: 'Esc', fontSize: 13, fontFamily: 'Courier'),
      ),
    );

    expect(find.text('Esc'), findsOneWidget);
    expect(find.byType(CcKbd), findsOneWidget);
  });

  testWidgets('CcKbdGroup renders one cap per key', (tester) async {
    await tester.pumpWidget(ccTestApp(const CcKbdGroup(keys: ['⌘', '↵'])));

    expect(find.byType(CcKbd), findsNWidgets(2));
    expect(find.text('⌘'), findsOneWidget);
    expect(find.text('↵'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CcShortcutHint shows the chord and label', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcShortcutHint(keys: ['⌘', '↵'], label: 'Allow')),
    );

    expect(find.byType(CcKbdGroup), findsOneWidget);
    expect(find.text('Allow'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CcKbdGroup renders a custom separator between caps', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(const CcKbdGroup(keys: ['G', 'P'], separator: Text('+'))),
    );
    expect(find.text('+'), findsOneWidget);
    expect(find.byType(CcKbd), findsNWidgets(2));
  });

  testWidgets('CcKbd resolves the monospace family from the CcTheme', (
    tester,
  ) async {
    await tester.pumpWidget(
      CcTheme(
        data: CcThemeData.light(monoFontFamily: 'Fira Code'),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: CcKbd(keyLabel: 'K'),
        ),
      ),
    );
    expect(find.text('K'), findsOneWidget);
  });

  group('CcKeys platform symbols', () {
    test('resolve to glyphs on macOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(CcKeys.cmdOrCtrl, '⌘');
      expect(CcKeys.optionOrAlt, '⌥');
      expect(CcKeys.shift, '⇧');
      expect(CcKeys.enter, '↵');
      expect(CcKeys.escape, 'Esc');
    });

    test('resolve to word labels off macOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(CcKeys.cmdOrCtrl, 'Ctrl');
      expect(CcKeys.optionOrAlt, 'Alt');
      expect(CcKeys.shift, 'Shift');
    });
  });
}
