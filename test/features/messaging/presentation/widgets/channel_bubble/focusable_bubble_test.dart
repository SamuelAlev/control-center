import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/focusable_bubble.dart';
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

void main() {
  group('FocusableBubble hover rail', () {
    testWidgets('the rail is reachable and its actions fire', (tester) async {
      // The regression: the rail used to be a `Positioned` at a negative offset,
      // i.e. outside the Stack's box. Painting worked (Clip.none) but
      // `RenderBox.hitTest` rejects anything outside `size`, so the icons could
      // never receive a pointer. `tester.tap` fails outright on a widget that
      // would not receive pointer events, so this test IS the assertion.
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

    testWidgets('hover survives the cursor travelling onto the rail', (
      tester,
    ) async {
      // The reported symptom: the icons appeared on hover, then vanished the
      // moment the pointer moved toward them, because the whole rail sat
      // outside every MouseRegion. Asserted functionally — park the cursor ON
      // the rail and the action must still be clickable from there.
      var deleted = false;

      await tester.pumpWidget(
        _host(
          FocusableBubble(
            onEdit: () {},
            onDelete: () => deleted = true,
            child: const SizedBox(key: _bubbleKey, width: 200, height: 40),
          ),
        ),
      );

      final gesture = await _hover(tester, find.byKey(_bubbleKey));
      await gesture.moveTo(tester.getCenter(find.byIcon(AppIcons.trash2)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.trash2));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('the rail survives the trip from the message to the icons', (
      tester,
    ) async {
      // The reported symptom, reproduced honestly: a real cursor does not
      // teleport onto the icons, it crosses the gap beside the message first.
      // The rail is a narrow strip, so that intermediate position belongs to
      // neither the message nor the rail — hiding on exit made the icons vanish
      // from under the pointer before it ever arrived.
      var deleted = false;

      await tester.pumpWidget(
        _host(
          FocusableBubble(
            onDelete: () => deleted = true,
            // Full width, as an agent turn is: the message's own hover region
            // ends exactly where the rail's begins, so the pixels between them
            // belong to neither. A narrower child would let the message's region
            // extend past the icons and mask the bug.
            child: const SizedBox(
              key: _bubbleKey,
              width: double.infinity,
              height: 120,
            ),
          ),
        ),
      );

      final gesture = await _hover(tester, find.byKey(_bubbleKey));
      final bubble = tester.getRect(find.byKey(_bubbleKey));
      final icon = tester.getCenter(find.byIcon(AppIcons.trash2));

      // Step out of the message at mid-height — well below the icon band, and
      // past the rail's own hit region.
      await gesture.moveTo(Offset(bubble.right + 40, bubble.center.dy));
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        find.byIcon(AppIcons.trash2),
        findsOneWidget,
        reason: 'the rail must outlive the pointer leaving the message',
      );

      // …then arrive, and act.
      await gesture.moveTo(icon);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(AppIcons.trash2), findsOneWidget);
      await tester.tap(find.byIcon(AppIcons.trash2));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('the rail lets go once the pointer settles elsewhere', (
      tester,
    ) async {
      // The grace period is a bridge, not a pin: park the cursor away from both
      // and the rail must go.
      await tester.pumpWidget(
        _host(
          FocusableBubble(
            onDelete: () {},
            child: const SizedBox(key: _bubbleKey, width: 200, height: 120),
          ),
        ),
      );

      final gesture = await _hover(tester, find.byKey(_bubbleKey));
      expect(find.byIcon(AppIcons.trash2), findsOneWidget);

      await gesture.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 40));
      expect(
        find.byIcon(AppIcons.trash2),
        findsOneWidget,
        reason: 'still within the grace period',
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(AppIcons.trash2), findsNothing);
    });

    testWidgets('hovering the next message drops the previous rail at once', (
      tester,
    ) async {
      // The grace period must not let rails pile up: moving down the feed shows
      // exactly one rail — the one belonging to the row under the cursor.
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

      final gesture = await _hover(tester, find.byKey(const Key('first')));
      expect(find.byIcon(AppIcons.trash2), findsOneWidget);

      await gesture.moveTo(tester.getCenter(find.byKey(const Key('second'))));
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byIcon(AppIcons.trash2), findsOneWidget);
    });

    testWidgets('a visible rail leaves the pane beside it clickable', (
      tester,
    ) async {
      // The regression behind the scroll "ghosting": an OverlayPortal lays its
      // overlay child out with the Overlay's TIGHT (full-window) constraints, so
      // the rail's opaque MouseRegion covered the whole quadrant right of and
      // below the message. Everything under it stopped receiving pointers —
      // neighbouring rows never lit up, and the stale rail stayed lit instead.
      // `tester.tap` fails when the hit test does not reach its target, so this
      // is the assertion.
      var tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CcTheme(
                data: CcThemeData.light(),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 300,
                        child: FocusableBubble(
                          onDelete: () {},
                          child: const SizedBox(
                            key: _bubbleKey,
                            width: 200,
                            height: 80,
                          ),
                        ),
                      ),
                    ),
                    // Down and to the right of the message's top-right corner —
                    // squarely inside the old full-window hit region.
                    Positioned(
                      right: 24,
                      bottom: 24,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => tapped = true,
                        child: const SizedBox(
                          key: Key('pane-action'),
                          width: 80,
                          height: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await _hover(tester, find.byKey(_bubbleKey));
      expect(find.byIcon(AppIcons.trash2), findsOneWidget);

      await tester.tap(find.byKey(const Key('pane-action')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('the rail hit region shrink-wraps the icons', (tester) async {
      // Same regression, measured: an unconstrained overlay child also turned
      // the rail's RepaintBoundary into a screen-sized layer.
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

      final rail = find.ancestor(
        of: find.byIcon(AppIcons.pencil),
        matching: find.byType(RepaintBoundary),
      );
      final size = tester.getSize(rail.first);
      expect(size.width, lessThan(64));
      // Two 22px actions.
      expect(size.height, closeTo(44, 1));
    });

    testWidgets('revealing the rail shifts no layout and costs no width', (
      tester,
    ) async {
      // The rail overlays the message's corner rather than reserving space, so
      // the row measures the same whether or not it is showing.
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

      final before = tester.getRect(find.byKey(_bubbleKey));
      expect(before.width, 300);

      await _hover(tester, find.byKey(_bubbleKey));
      expect(tester.getRect(find.byKey(_bubbleKey)), before);
    });

    testWidgets('the rail hangs outside the message, past its right edge', (
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

      // Beside the message, never over it.
      expect(firstIcon.left, greaterThanOrEqualTo(bubble.right));
      // Vertical: the second action sits below the first, not next to it.
      expect(lastIcon.top, greaterThan(firstIcon.top));
      expect(lastIcon.left, firstIcon.left);
    });

    testWidgets('a one-line bubble hosts a rail taller than itself', (
      tester,
    ) async {
      // Five stacked 22px actions are ~110px — far taller than this 28px
      // bubble. Hosting the rail in the overlay is what allows that: inside the
      // row's own box it would have been a RenderFlex overflow.
      await tester.pumpWidget(
        _host(
          FocusableBubble(
            messageId: 'm-1',
            channelId: 'ch-1',
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
      expect(find.byIcon(AppIcons.copy), findsOneWidget);
      expect(find.byIcon(AppIcons.link), findsOneWidget);
      expect(find.byIcon(AppIcons.rotateCcw), findsOneWidget);
      expect(find.byIcon(AppIcons.pencil), findsOneWidget);
      expect(find.byIcon(AppIcons.trash2), findsOneWidget);
      // The rail really is taller than the message it belongs to.
      final bubble = tester.getRect(find.byKey(_bubbleKey));
      expect(
        tester.getRect(find.byIcon(AppIcons.trash2)).bottom,
        greaterThan(bubble.bottom),
      );
    });
  });
}
