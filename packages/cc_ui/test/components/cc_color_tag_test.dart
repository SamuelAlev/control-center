import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../cc_test_app.dart';

void main() {
  group('CcColorTag.parseHex', () {
    test('reads 6-digit hex with or without a hash', () {
      expect(CcColorTag.parseHex('d73a4a'), const Color(0xFFD73A4A));
      expect(CcColorTag.parseHex('#0366d6'), const Color(0xFF0366D6));
    });

    test('expands 3-digit hex', () {
      expect(CcColorTag.parseHex('#abc'), const Color(0xFFAABBCC));
    });

    test('returns null for empty or unparseable input', () {
      expect(CcColorTag.parseHex(''), isNull);
      expect(CcColorTag.parseHex('zz'), isNull);
      expect(CcColorTag.parseHex('12345'), isNull);
    });
  });

  group('CcColorTag.inkOn', () {
    test('picks dark ink on a light yellow fill', () {
      expect(
        CcColorTag.inkOn(const Color(0xFFFFFF00)),
        const Color(0xFF0D0D0D),
      );
    });

    test('picks white ink on a dark blue fill', () {
      expect(
        CcColorTag.inkOn(const Color(0xFF0366D6)),
        const Color(0xFFFFFFFF),
      );
    });
  });

  testWidgets('renders the label text', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcColorTag(label: 'dependencies', color: '0366d6')),
    );
    expect(find.text('dependencies'), findsOneWidget);
    expect(find.byIcon(CcIcons.x), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty color still shows the name', (tester) async {
    await tester.pumpWidget(ccTestApp(const CcColorTag(label: 'needs-review')));
    expect(find.text('needs-review'), findsOneWidget);
    expect(find.byIcon(CcIcons.x), findsNothing);
  });

  testWidgets(
    'read-only tag has no extra trailing space compared to removable tag',
    (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CcColorTag(
                  key: ValueKey('readonly'),
                  label: 'brand checker',
                  color: '8e4452',
                ),
                CcColorTag(
                  key: const ValueKey('removable'),
                  label: 'brand checker',
                  color: '8e4452',
                  onRemove: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final readOnlyWidth = tester
          .getSize(find.byKey(const ValueKey('readonly')))
          .width;
      final removableWidth = tester
          .getSize(find.byKey(const ValueKey('removable')))
          .width;
      expect(readOnlyWidth, lessThan(removableWidth));
    },
  );

  testWidgets(
    'always shows X when onRemove is set, fires callback, and exposes semantics',
    (tester) async {
      final handle = tester.ensureSemantics();
      var removed = 0;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcColorTag(
              label: 'brand checker',
              color: '8e4452',
              onRemove: () => removed++,
            ),
          ),
        ),
      );

      expect(find.byIcon(CcIcons.x), findsOneWidget);
      final removeButton = find.bySemanticsLabel('Remove brand checker');
      expect(removeButton, findsOneWidget);
      expect(
        tester.getSemantics(removeButton),
        isSemantics(
          label: 'Remove brand checker',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );

      await tester.tap(find.byIcon(CcIcons.x));
      await tester.pump();
      expect(removed, 1);

      handle.dispose();
    },
  );

  testWidgets('supports custom removeSemanticLabel', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ccTestApp(
        CcColorTag(
          label: 'bug',
          color: 'd73a4a',
          onRemove: () {},
          removeSemanticLabel: 'Delete bug label',
        ),
      ),
    );
    expect(find.bySemanticsLabel('Delete bug label'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('ghost remove button matches tag ink and washes on hover', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CcColorTag(
                key: const ValueKey('dark-tag'),
                label: 'dark',
                color: '8e4452',
                onRemove: () {},
              ),
              CcColorTag(
                key: const ValueKey('light-tag'),
                label: 'light',
                color: 'a2eeef',
                onRemove: () {},
              ),
              CcColorTag(
                key: const ValueKey('fallback-tag'),
                label: 'fallback',
                onRemove: () {},
              ),
            ],
          ),
        ),
      ),
    );

    Color? buttonFillFor(Key tagKey) {
      final box = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byKey(tagKey),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      return (box.decoration as BoxDecoration?)?.color;
    }

    expect(buttonFillFor(const ValueKey('dark-tag'))?.a, 0);
    expect(buttonFillFor(const ValueKey('light-tag'))?.a, 0);
    expect(buttonFillFor(const ValueKey('fallback-tag'))?.a, 0);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();

    // Dark tag uses white ink for ghost hover wash.
    await gesture.moveTo(
      tester.getCenter(
        find.descendant(
          of: find.byKey(const ValueKey('dark-tag')),
          matching: find.byIcon(CcIcons.x),
        ),
      ),
    );
    await tester.pump();
    final darkHover = buttonFillFor(const ValueKey('dark-tag'))!;
    expect(darkHover.a, greaterThan(0));
    expect(darkHover.toARGB32() & 0x00FFFFFF, 0x00FFFFFF);

    // Light tag uses near-black ink for ghost hover wash.
    await gesture.moveTo(
      tester.getCenter(
        find.descendant(
          of: find.byKey(const ValueKey('light-tag')),
          matching: find.byIcon(CcIcons.x),
        ),
      ),
    );
    await tester.pump();
    final lightHover = buttonFillFor(const ValueKey('light-tag'))!;
    expect(lightHover.a, greaterThan(0));
    expect(lightHover.toARGB32() & 0x00FFFFFF, 0x000D0D0D);

    // Fallback tag uses theme hover token.
    await gesture.moveTo(
      tester.getCenter(
        find.descendant(
          of: find.byKey(const ValueKey('fallback-tag')),
          matching: find.byIcon(CcIcons.x),
        ),
      ),
    );
    await tester.pump();
    expect(
      buttonFillFor(const ValueKey('fallback-tag')),
      DesignSystemTokens.light().hover,
    );

    await gesture.removePointer();
  });

  testWidgets(
    'removing shows ink-colored CcSpinner instead of X and ignores taps',
    (tester) async {
      var removed = 0;
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: CcColorTag(
              label: 'brand checker',
              color: '8e4452',
              removing: true,
              onRemove: () => removed++,
            ),
          ),
        ),
      );

      expect(find.byIcon(CcIcons.x), findsNothing);
      final spinner = tester.widget<CcSpinner>(find.byType(CcSpinner));
      expect(spinner.color, const Color(0xFFFFFFFF));

      await tester.tap(find.byType(CcSpinner));
      await tester.pump();
      expect(removed, 0);
    },
  );

  testWidgets('RTL places remove button to the left of label text', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: CcColorTag(
            label: 'brand checker',
            color: '8e4452',
            onRemove: () {},
          ),
        ),
        textDirection: TextDirection.rtl,
      ),
    );

    final iconCenter = tester.getCenter(find.byIcon(CcIcons.x)).dx;
    final textCenter = tester.getCenter(find.text('brand checker')).dx;
    expect(iconCenter, lessThan(textCenter));
  });
}
