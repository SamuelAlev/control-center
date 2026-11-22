import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/shell/presentation/widgets/notification_bell.dart';
import 'package:control_center/features/shell/providers/notification_center_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/test_wrap.dart';

/// Records what the bell asked the server to do. The real facade writes through
/// the repository port; the widget's contract is only which call it makes.
class _RecordingActions implements NotificationCenterActions {
  int markAllReadCalls = 0;
  int clearAllCalls = 0;
  final List<(String id, bool read)> readCalls = [];
  final List<String> dismissed = [];
  int loadMoreCalls = 0;

  @override
  void loadMore() => loadMoreCalls++;

  @override
  Future<void> markAllRead() async => markAllReadCalls++;

  @override
  Future<void> clearAll() async => clearAllCalls++;

  @override
  Future<void> setRead(String itemId, {required bool read}) async =>
      readCalls.add((itemId, read));

  @override
  Future<void> dismiss(String itemId) async => dismissed.add(itemId);
}

NotificationEntry _entry({
  required String id,
  required bool read,
  String title = 'Review requested',
  NotificationCategory category = NotificationCategory.reviewRequested,
}) => NotificationEntry(
  id: id,
  read: read,
  receivedAt: DateTime.now().subtract(const Duration(minutes: 5)),
  notification: AppNotification(
    category: category,
    title: title,
    body: 'chore: release packages (acme/cli#409)',
    route: '/workspaces/ws-1/prs',
    workspaceId: 'ws-1',
  ),
);

void main() {
  late _RecordingActions actions;

  List<Override> feedOverrides(
    List<NotificationEntry> entries, {
    bool hasMore = false,
    bool loadingMore = false,
  }) => [
    notificationCenterProvider.overrideWithValue(entries),
    notificationCenterActionsProvider.overrideWithValue(actions),
    notificationFeedHasMoreProvider.overrideWithValue(hasMore),
    notificationFeedLoadingMoreProvider.overrideWithValue(loadingMore),
  ];

  Future<void> pumpBell(
    WidgetTester tester,
    List<NotificationEntry> entries, {
    bool hasMore = false,
    bool loadingMore = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: feedOverrides(
          entries,
          hasMore: hasMore,
          loadingMore: loadingMore,
        ),
        child: testWrap(const Align(child: NotificationBell())),
      ),
    );
    // The footer spinner never settles.
    if (loadingMore) {
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
  }

  /// Mounts the bell under a real router, for the tests that follow a row.
  /// Tapping a row navigates, so those need `GoRouter.of` to resolve.
  Future<GoRouter> pumpBellWithRouter(
    WidgetTester tester,
    List<NotificationEntry> entries,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Align(child: NotificationBell()),
        ),
        GoRoute(
          path: '/workspaces/:workspaceId/prs',
          builder: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: feedOverrides(entries),
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          builder: (context, child) => CcTheme(
            data: CcThemeData.light(),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> openPanel(WidgetTester tester) async {
    await tester.tap(find.byIcon(AppIcons.bell));
    await tester.pumpAndSettle();
  }

  /// Hovers the row so its overflow trigger is revealed.
  Future<void> hoverRow(WidgetTester tester, Finder row) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(row));
    await tester.pumpAndSettle();
  }

  setUp(() {
    actions = _RecordingActions();
  });

  testWidgets('badges the unread count', (tester) async {
    await pumpBell(tester, [
      _entry(id: 'a', read: false),
      _entry(id: 'b', read: false),
      _entry(id: 'c', read: true),
    ]);

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('shows no badge when everything is read', (tester) async {
    await pumpBell(tester, [_entry(id: 'a', read: true)]);

    expect(find.text('1'), findsNothing);
  });

  testWidgets('opening the panel does not mark anything read', (tester) async {
    // The regression this file exists for: acknowledging on open erased the
    // one thing the panel is for — which of these you have not seen.
    await pumpBell(tester, [_entry(id: 'a', read: false)]);

    await openPanel(tester);

    expect(actions.markAllReadCalls, 0);
    expect(find.text('1'), findsOneWidget, reason: 'the badge must survive');
  });

  testWidgets('the header marks all read on request', (tester) async {
    await pumpBell(tester, [_entry(id: 'a', read: false)]);
    await openPanel(tester);

    await tester.tap(find.byIcon(AppIcons.checkCheck));
    await tester.pumpAndSettle();

    expect(actions.markAllReadCalls, 1);
  });

  testWidgets('the header hides mark-all-read with nothing unread', (
    tester,
  ) async {
    await pumpBell(tester, [_entry(id: 'a', read: true)]);
    await openPanel(tester);

    expect(find.byIcon(AppIcons.checkCheck), findsNothing);
    // Clearing is still offered: a read history is still a history.
    expect(find.byIcon(AppIcons.trash2), findsOneWidget);
  });

  testWidgets('the header clears all on request', (tester) async {
    await pumpBell(tester, [_entry(id: 'a', read: false)]);
    await openPanel(tester);

    await tester.tap(find.byIcon(AppIcons.trash2));
    await tester.pumpAndSettle();

    expect(actions.clearAllCalls, 1);
  });

  testWidgets('the row overflow trigger reserves space but stays hidden until '
      'hover', (tester) async {
    await pumpBell(tester, [_entry(id: 'a', read: false)]);
    await openPanel(tester);

    final trigger = find.byWidgetPredicate(
      (widget) =>
          widget is CcIconButton && widget.icon == AppIcons.moreHorizontal,
    );
    // Laid out from the start — revealing it must never reflow the row.
    expect(trigger, findsOneWidget);

    AnimatedOpacity fade() => tester.widget<AnimatedOpacity>(
      find.ancestor(of: trigger, matching: find.byType(AnimatedOpacity)),
    );
    expect(fade().opacity, 0);

    await hoverRow(tester, find.text('Review requested'));
    expect(fade().opacity, 1);
  });

  group('timestamp slide', () {
    final trigger = find.byWidgetPredicate(
      (widget) =>
          widget is CcIconButton && widget.icon == AppIcons.moreHorizontal,
    );
    final timestamp = find.text('5m');

    Future<void> pumpRtlAware(
      WidgetTester tester,
      TextDirection direction,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: feedOverrides([_entry(id: 'a', read: false)]),
          child: testWrap(
            const Align(child: NotificationBell()),
            textDirection: direction,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openPanel(tester);
    }

    for (final direction in TextDirection.values) {
      testWidgets('rests flush with the row end and makes room on hover '
          '(${direction.name})', (tester) async {
        await pumpRtlAware(tester, direction);
        final rtl = direction == TextDirection.rtl;
        double endOf(Rect r) => rtl ? r.left : r.right;

        // At rest the hidden trigger's slot is the timestamp's: both end on
        // the row's end edge.
        expect(
          endOf(tester.getRect(timestamp)),
          moreOrLessEquals(endOf(tester.getRect(trigger)), epsilon: 0.5),
        );

        await hoverRow(tester, find.text('Review requested'));

        // Revealed, the timestamp has slid start-ward clear of the button.
        final stamp = tester.getRect(timestamp);
        final button = tester.getRect(trigger);
        if (rtl) {
          expect(stamp.left, greaterThanOrEqualTo(button.right));
        } else {
          expect(stamp.right, lessThanOrEqualTo(button.left));
        }
      });
    }

    testWidgets('snaps instead of sliding under reduced motion', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpRtlAware(tester, TextDirection.ltr);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Review requested')));
      // One frame: no travel to wait for.
      await tester.pump();
      await tester.pump();

      expect(
        tester.getRect(timestamp).right,
        lessThanOrEqualTo(tester.getRect(trigger).left),
      );
    });
  });

  testWidgets('a row marks itself read from its menu', (tester) async {
    await pumpBell(tester, [_entry(id: 'a', read: false)]);
    await openPanel(tester);
    await hoverRow(tester, find.text('Review requested'));

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is CcIconButton && widget.icon == AppIcons.moreHorizontal,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as read'));
    await tester.pumpAndSettle();

    expect(actions.readCalls, [('a', true)]);
  });

  testWidgets('a read row offers mark as unread instead', (tester) async {
    await pumpBell(tester, [_entry(id: 'a', read: true)]);
    await openPanel(tester);
    await hoverRow(tester, find.text('Review requested'));

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is CcIconButton && widget.icon == AppIcons.moreHorizontal,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mark as read'), findsNothing);
    await tester.tap(find.text('Mark as unread'));
    await tester.pumpAndSettle();

    expect(actions.readCalls, [('a', false)]);
  });

  testWidgets('a row deletes itself from its menu', (tester) async {
    await pumpBell(tester, [_entry(id: 'a', read: false)]);
    await openPanel(tester);
    await hoverRow(tester, find.text('Review requested'));

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is CcIconButton && widget.icon == AppIcons.moreHorizontal,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(actions.dismissed, ['a']);
    expect(actions.readCalls, isEmpty, reason: 'delete is not a read');
  });

  testWidgets('following a row reads it and navigates', (tester) async {
    final router = await pumpBellWithRouter(tester, [
      _entry(id: 'a', read: false),
    ]);
    await openPanel(tester);

    await tester.tap(find.text('Review requested'));
    await tester.pumpAndSettle();

    // Acting on a notification is reading it; leaving it bold afterwards is
    // the badge lying.
    expect(actions.readCalls, [('a', true)]);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/workspaces/ws-1/prs',
    );
  });

  testWidgets('following an already-read row writes nothing', (tester) async {
    await pumpBellWithRouter(tester, [_entry(id: 'a', read: true)]);
    await openPanel(tester);

    await tester.tap(find.text('Review requested'));
    await tester.pumpAndSettle();

    expect(actions.readCalls, isEmpty);
  });

  group('swipe actions', () {
    /// Holds the row until the swipe arms, then moves it [dx] horizontally.
    /// Returns the still-down gesture so a test can inspect the uncovered
    /// panel before deciding to commit.
    Future<TestGesture> holdAndDrag(
      WidgetTester tester,
      Finder row,
      double dx,
    ) async {
      final gesture = await tester.startGesture(tester.getCenter(row));
      await tester.pump(
        CcSwipeActions.defaultHoldDuration + const Duration(milliseconds: 20),
      );
      await gesture.moveBy(Offset(dx, 0));
      await tester.pump();
      return gesture;
    }

    testWidgets('the hold is shorter than a platform long press', (
      tester,
    ) async {
      // The gate exists to make the drag deliberate, not to make it a context
      // menu; at kLongPressTimeout the row reads as unresponsive to someone
      // already trying to drag it.
      expect(CcSwipeActions.defaultHoldDuration, lessThan(kLongPressTimeout));
      // ...but it still has to outlast a tap, or a click would fire it.
      expect(
        CcSwipeActions.defaultHoldDuration,
        greaterThan(const Duration(milliseconds: 150)),
      );
    });

    testWidgets('a hold shorter than the gate does not arm', (tester) async {
      await pumpBell(tester, [_entry(id: 'a', read: false)]);
      await openPanel(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Review requested')),
      );
      await tester.pump(CcSwipeActions.defaultHoldDuration ~/ 2);
      await gesture.moveBy(const Offset(140, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(actions.dismissed, isEmpty);
      expect(actions.readCalls, isEmpty);
    });

    testWidgets('dragging left past the threshold marks the row read', (
      tester,
    ) async {
      await pumpBell(tester, [_entry(id: 'a', read: false)]);
      await openPanel(tester);

      final gesture = await holdAndDrag(
        tester,
        find.text('Review requested'),
        -140,
      );
      // The uncovered panel names the verb, so committing is never a guess
      // about which side does what.
      expect(find.text('Mark as read'), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(actions.readCalls, [('a', true)]);
      expect(actions.dismissed, isEmpty);
    });

    testWidgets('dragging right past the threshold deletes the row', (
      tester,
    ) async {
      await pumpBell(tester, [_entry(id: 'a', read: false)]);
      await openPanel(tester);

      final gesture = await holdAndDrag(
        tester,
        find.text('Review requested'),
        140,
      );
      expect(find.text('Delete'), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(actions.dismissed, ['a']);
      expect(actions.readCalls, isEmpty, reason: 'delete is not a read');
    });

    testWidgets('releasing short of the threshold commits nothing', (
      tester,
    ) async {
      await pumpBell(tester, [_entry(id: 'a', read: false)]);
      await openPanel(tester);

      final gesture = await holdAndDrag(
        tester,
        find.text('Review requested'),
        -30,
      );
      await gesture.up();
      await tester.pumpAndSettle();

      expect(actions.readCalls, isEmpty);
      expect(actions.dismissed, isEmpty);
    });

    testWidgets('a read row swipes back to unread', (tester) async {
      await pumpBell(tester, [_entry(id: 'a', read: true)]);
      await openPanel(tester);

      final gesture = await holdAndDrag(
        tester,
        find.text('Review requested'),
        -140,
      );
      // The swipe mirrors the menu item rather than hard-coding "read" — the
      // side you cleared a row with is the side that brings it back.
      expect(find.text('Mark as unread'), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(actions.readCalls, [('a', false)]);
    });

    testWidgets('a drag that never held is not a swipe', (tester) async {
      await pumpBell(tester, [_entry(id: 'a', read: false)]);
      await openPanel(tester);

      // Same movement, no hold. The gate is the whole reason a mis-aimed
      // scroll cannot delete something.
      await tester.drag(find.text('Review requested'), const Offset(140, 0));
      await tester.pumpAndSettle();

      expect(actions.dismissed, isEmpty);
      expect(actions.readCalls, isEmpty);
    });

    testWidgets('following a row still works with the gesture attached', (
      tester,
    ) async {
      final router = await pumpBellWithRouter(tester, [
        _entry(id: 'a', read: false),
      ]);
      await openPanel(tester);

      // The swipe recognizer competes with the row's tap; a plain tap must
      // still win it.
      await tester.tap(find.text('Review requested'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/workspaces/ws-1/prs',
      );
    });
  });

  testWidgets('an empty feed says so', (tester) async {
    await pumpBell(tester, const []);
    await openPanel(tester);

    expect(find.text("You're all caught up"), findsOneWidget);
    // Nothing to act on, so neither bulk action is offered.
    expect(find.byIcon(AppIcons.checkCheck), findsNothing);
    expect(find.byIcon(AppIcons.trash2), findsNothing);
  });

  group('lazy loading', () {
    List<NotificationEntry> many(int n) => [
      for (var i = 0; i < n; i++)
        _entry(id: 'n$i', read: i > 0, title: 'Notification $i'),
    ];

    testWidgets('shows every loaded row, not a fixed first few', (
      tester,
    ) async {
      await pumpBell(tester, many(40));
      await openPanel(tester);

      // Rows are built lazily, so the last one exists once scrolled to.
      await tester.scrollUntilVisible(
        find.text('Notification 39'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Notification 39'), findsOneWidget);
    });

    testWidgets('nearing the end asks for the next page', (tester) async {
      await pumpBell(tester, many(40), hasMore: true);
      await openPanel(tester);
      expect(actions.loadMoreCalls, 0);

      await tester.scrollUntilVisible(
        find.text('Notification 39'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(actions.loadMoreCalls, greaterThan(0));
    });

    testWidgets('a short window with more behind it loads without a scroll', (
      tester,
    ) async {
      // Every row of the window was filtered out for this viewer: nothing to
      // scroll, so the list must ask on its own instead of claiming "empty".
      await pumpBell(tester, const [], hasMore: true);
      await openPanel(tester);

      expect(actions.loadMoreCalls, greaterThan(0));
      expect(find.text("You're all caught up"), findsNothing);
    });

    testWidgets('the end of the stored feed asks for nothing', (tester) async {
      await pumpBell(tester, many(40));
      await openPanel(tester);
      await tester.scrollUntilVisible(
        find.text('Notification 39'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      // The notifier refuses past the end, but the list should not even call.
      expect(actions.loadMoreCalls, 0);
    });

    testWidgets('a page in flight shows a footer spinner', (tester) async {
      await pumpBell(tester, many(3), hasMore: true, loadingMore: true);
      await tester.tap(find.byIcon(AppIcons.bell));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CcSpinner), findsOneWidget);
    });
  });
}
