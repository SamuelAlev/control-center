import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/focusable_bubble.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The wrapped bubble content, big enough to hover unambiguously.
const Key _bubbleKey = Key('bubble-content');

Widget _host(Widget child) => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CcTheme(
        data: CcThemeData.light(),
        // A bounded column so the bubble row gets real constraints, as the feed
        // gives it.
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: 300, child: child),
        ),
      ),
    ),
  ),
);

/// Moves a mouse pointer onto [target] and settles.
Future<TestGesture> _hover(WidgetTester tester, Finder target) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getCenter(target));
  await tester.pumpAndSettle();
  return gesture;
}

/// The rail's current opacity. The rail is ALWAYS mounted — that is what
/// reserves its space — so "is it showing" is a question about opacity, never
/// about whether the icons are in the tree.
double _railOpacity(WidgetTester tester, {Finder? of}) {
  final fade = find.ancestor(
    of: of ?? find.byIcon(AppIcons.trash2),
    matching: find.byType(FadeTransition),
  );
  return tester.widget<FadeTransition>(fade.first).opacity.value;
}

void main() {
  group('FocusableBubble action rail', () {
    testWidgets('the rail reserves its space, so revealing it shifts nothing', (
      tester,
    ) async {
      // The point of moving the rail under the message: hovering must not
      // change a single box in the feed. The strip is laid out whether or not
      // the icons are painted, so the bubble's rect is identical before and
      // after — and so is the height of the whole row.
      await tester.pumpWidget(
        _host(
          FocusableBubble(
            onEdit: () {},
            onDelete: () {},
            child: const SizedBox(
              key: _bubbleKey,
              width: double.infinity,
              height: 40,
            ),
          ),
        ),
      );

      final bubbleBefore = tester.getRect(find.byKey(_bubbleKey));
      final railBefore = tester.getRect(find.byIcon(AppIcons.trash2));
      final rowBefore = tester.getSize(find.byType(FocusableBubble));
      expect(bubbleBefore.width, 300);
      expect(_railOpacity(tester), 0);

      await _hover(tester, find.byKey(_bubbleKey));

      expect(_railOpacity(tester), 1);
      expect(tester.getRect(find.byKey(_bubbleKey)), bubbleBefore);
      expect(tester.getRect(find.byIcon(AppIcons.trash2)), railBefore);
      expect(tester.getSize(find.byType(FocusableBubble)), rowBefore);
    });

    testWidgets('the rail sits under the message, in one horizontal row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FocusableBubble(
            onEdit: () {},
            onDelete: () {},
            child: const SizedBox(key: _bubbleKey, width: 200, height: 80),
          ),
        ),
      );

      await _hover(tester, find.byKey(_bubbleKey));

      final bubble = tester.getRect(find.byKey(_bubbleKey));
      final firstIcon = tester.getRect(find.byIcon(AppIcons.pencil));
      final lastIcon = tester.getRect(find.byIcon(AppIcons.trash2));

      // Below the message, never beside it.
      expect(firstIcon.top, greaterThanOrEqualTo(bubble.bottom));
      // Horizontal: the second action sits after the first, on the same line.
      expect(lastIcon.left, greaterThan(firstIcon.left));
      expect(lastIcon.top, firstIcon.top);
      // …and it stays inside the message's own column.
      expect(lastIcon.right, lessThanOrEqualTo(bubble.right));
    });

    testWidgets('the rail is left-aligned with the message body', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FocusableBubble(
            onEdit: () {},
            child: const SizedBox(
              key: _bubbleKey,
              width: double.infinity,
              height: 40,
            ),
          ),
        ),
      );

      await _hover(tester, find.byKey(_bubbleKey));

      final bubble = tester.getRect(find.byKey(_bubbleKey));
      final icon = tester.getRect(find.byIcon(AppIcons.pencil));
      // The glyph carries 4px of its button's padding; anything more would read
      // as an indent.
      expect(icon.left - bubble.left, lessThanOrEqualTo(4));
    });

    testWidgets('a right-aligned bubble puts its rail on the right', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Align(
            alignment: Alignment.topRight,
            child: FocusableBubble(
              alignRight: true,
              onEdit: () {},
              onDelete: () {},
              child: const SizedBox(key: _bubbleKey, width: 200, height: 40),
            ),
          ),
        ),
      );

      await _hover(tester, find.byKey(_bubbleKey));

      final bubble = tester.getRect(find.byKey(_bubbleKey));
      expect(
        bubble.right - tester.getRect(find.byIcon(AppIcons.trash2)).right,
        lessThanOrEqualTo(4),
      );
    });

    testWidgets('the rail is reachable and its actions fire', (tester) async {
      var edited = false;

      await tester.pumpWidget(
        _host(
          FocusableBubble(
            onEdit: () => edited = true,
            child: const SizedBox(key: _bubbleKey, width: 200, height: 40),
          ),
        ),
      );

      await _hover(tester, find.byKey(_bubbleKey));
      await tester.tap(find.byIcon(AppIcons.pencil));
      await tester.pumpAndSettle();

      expect(edited, isTrue);
    });

    testWidgets('the cursor can travel from the message onto the icons', (
      tester,
    ) async {
      // In flow and inside the message's own hover region, the trip to the
      // icons never leaves that region — which is what let the old overlay rail
      // vanish from under the pointer and forced a grace timer.
      var deleted = false;

      await tester.pumpWidget(
        _host(
          FocusableBubble(
            onEdit: () {},
            onDelete: () => deleted = true,
            child: const SizedBox(key: _bubbleKey, width: 200, height: 120),
          ),
        ),
      );

      final gesture = await _hover(tester, find.byKey(_bubbleKey));
      final icon = tester.getCenter(find.byIcon(AppIcons.trash2));

      // Step through the gap between the message's bottom edge and the rail.
      final bubble = tester.getRect(find.byKey(_bubbleKey));
      await gesture.moveTo(Offset(icon.dx, bubble.bottom + 1));
      await tester.pumpAndSettle();
      expect(_railOpacity(tester), 1);

      await gesture.moveTo(icon);
      await tester.pumpAndSettle();
      expect(_railOpacity(tester), 1);

      await tester.tap(find.byIcon(AppIcons.trash2));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('a hidden rail is inert: no clicks, no tab stops', (
      tester,
    ) async {
      // The rail is mounted at all times, so it has to be actively neutralised
      // while invisible — otherwise every message would contribute a handful of
      // invisible buttons to the pointer and focus trees.
      var deleted = false;

      await tester.pumpWidget(
        _host(
          FocusableBubble(
            onDelete: () => deleted = true,
            child: const SizedBox(key: _bubbleKey, width: 200, height: 40),
          ),
        ),
      );

      expect(_railOpacity(tester), 0);

      // `FocusNode.canRequestFocus` folds in every ancestor's
      // `descendantsAreFocusable`, so this is the button's real traversal
      // status, not just the flag on its own node.
      bool buttonIsFocusable() => Focus.of(
        tester.element(find.byIcon(AppIcons.trash2)),
      ).canRequestFocus;

      expect(
        buttonIsFocusable(),
        isFalse,
        reason: 'a hidden action must not be a tab stop',
      );

      // A tap where the icon sits must fall through to whatever is behind it.
      await tester.tapAt(tester.getCenter(find.byIcon(AppIcons.trash2)));
      await tester.pumpAndSettle();
      expect(deleted, isFalse);

      // Revealed, it is a real control again.
      await _hover(tester, find.byKey(_bubbleKey));
      expect(buttonIsFocusable(), isTrue);
      await tester.tap(find.byIcon(AppIcons.trash2));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    testWidgets('the rail hides once the pointer settles elsewhere', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FocusableBubble(
            onDelete: () {},
            child: const SizedBox(key: _bubbleKey, width: 200, height: 120),
          ),
        ),
      );

      final gesture = await _hover(tester, find.byKey(_bubbleKey));
      expect(_railOpacity(tester), 1);

      await gesture.moveTo(const Offset(400, 400));
      await tester.pumpAndSettle();

      expect(_railOpacity(tester), 0);
    });

    testWidgets('exactly one rail shows at a time while moving down the feed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              FocusableBubble(
                onDelete: () {},
                child: const SizedBox(
                  key: Key('first'),
                  width: double.infinity,
                  height: 80,
                ),
              ),
              FocusableBubble(
                onDelete: () {},
                child: const SizedBox(
                  key: Key('second'),
                  width: double.infinity,
                  height: 80,
                ),
              ),
            ],
          ),
        ),
      );

      Finder railOf(String key) => find.descendant(
        of: find.ancestor(
          of: find.byKey(Key(key)),
          matching: find.byType(FocusableBubble),
        ),
        matching: find.byIcon(AppIcons.trash2),
      );

      final gesture = await _hover(tester, find.byKey(const Key('first')));
      expect(_railOpacity(tester, of: railOf('first')), 1);
      expect(_railOpacity(tester, of: railOf('second')), 0);

      await gesture.moveTo(tester.getCenter(find.byKey(const Key('second'))));
      await tester.pumpAndSettle();

      expect(_railOpacity(tester, of: railOf('first')), 0);
      expect(_railOpacity(tester, of: railOf('second')), 1);
    });

    testWidgets('every action fits on one line under a one-line bubble', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FocusableBubble(
            messageId: 'm-1',
            spaceId: 'ch-1',
            copyText: 'hello',
            canRevert: true,
            onEdit: () {},
            onDelete: () {},
            child: const SizedBox(key: _bubbleKey, width: 200, height: 28),
          ),
        ),
      );

      await _hover(tester, find.byKey(_bubbleKey));

      expect(tester.takeException(), isNull);
      for (final icon in [
        AppIcons.copy,
        AppIcons.link,
        AppIcons.smile,
        AppIcons.rotateCcw,
        AppIcons.pencil,
        AppIcons.trash2,
      ]) {
        expect(find.byIcon(icon), findsOneWidget);
      }

      // One row: six 22px actions side by side, all on the same baseline.
      final rail = find.ancestor(
        of: find.byIcon(AppIcons.pencil),
        matching: find.byType(RepaintBoundary),
      );
      final size = tester.getSize(rail.first);
      expect(size.height, closeTo(22, 1));
      expect(size.width, closeTo(22 * 6, 1));
      expect(
        tester.getRect(find.byIcon(AppIcons.copy)).top,
        tester.getRect(find.byIcon(AppIcons.trash2)).top,
      );
    });
  });
}
