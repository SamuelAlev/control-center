import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_sidebar_view_strip.dart';
import 'package:control_center/features/messaging/providers/ide_sidebar_prefs_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab_bar.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sidebar rail's contract: icon-only cells for the pinned views, a caret
/// that always opens the full list, the active view never folded away and a
/// pin set that survives a restart.
void main() {
  /// A cell is the strip's own glyph for [view]; the caret menu draws the same
  /// glyph at 16px, so size is what separates a rail cell from a menu row.
  Finder cell(IdeSidebarView view) => find.byWidgetPredicate(
    (w) => w is Icon && w.icon == viewIcon(view) && w.size == 15,
  );

  Finder menuRow(IdeSidebarView view) => find.byWidgetPredicate(
    (w) => w is Icon && w.icon == viewIcon(view) && w.size == 16,
  );

  final caret = find.byWidgetPredicate(
    (w) =>
        w is Icon &&
        (w.icon == AppIcons.chevronDown || w.icon == AppIcons.chevronUp),
  );

  /// Every row's pin toggle (14px, `pin` at rest and `pinOff` while hovered).
  final pinToggles = find.byWidgetPredicate(
    (w) =>
        w is Icon &&
        (w.icon == AppIcons.pin || w.icon == AppIcons.pinOff) &&
        w.size == 14,
  );

  /// The screen position of [view]'s pin toggle: the one sharing a scanline
  /// with that row's glyph.
  Offset pinCenter(WidgetTester tester, IdeSidebarView view) {
    final rowY = tester.getCenter(menuRow(view)).dy;
    final matches = <Offset>[];
    for (final element in pinToggles.evaluate()) {
      final box = element.renderObject! as RenderBox;
      final center = box.localToGlobal(box.size.center(Offset.zero));
      if ((center.dy - rowY).abs() < 1) {
        matches.add(center);
      }
    }
    expect(matches, hasLength(1), reason: 'one pin per row, on the row');
    return matches.single;
  }

  /// Pumps the rail at [width] inside a sidebar-shaped column.
  ///
  /// Returns the container so a test can read the persisted pins back out.
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    double width = 300,
    IdeSidebarView selected = IdeSidebarView.general,
    ValueChanged<IdeSidebarView>? onChanged,
    Map<String, Object> prefs = const {},
  }) async {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(
          AppPreferences.inMemory(prefs),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData(
              tokens: DesignSystemTokens.light(),
              brightness: CcBrightness.light,
            ),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: IdeSidebarViewStrip(
                    selected: selected,
                    onChanged: onChanged ?? (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('layout', () {
    testWidgets('is exactly as tall as the editor tab bar', (tester) async {
      await pump(tester);

      expect(
        tester.getSize(find.byType(IdeSidebarViewStrip)).height,
        EditorTabBar.height,
        reason: 'a fractional height leaves a visible jog at the divider seam',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the active cell underline sits on the bottom rule', (
      tester,
    ) async {
      await pump(tester);

      final accent = DesignSystemTokens.light().accent;
      final underline = tester.getRect(
        find
            .byWidgetPredicate(
              (w) =>
                  w is DecoratedBox &&
                  w.decoration is BoxDecoration &&
                  (w.decoration as BoxDecoration).color == accent,
            )
            .first,
      );

      expect(underline.height, 2);
      expect(underline.bottom, EditorTabBar.height - 1);
    });

    testWidgets('every view gets a cell at the default width', (tester) async {
      await pump(tester);

      for (final view in IdeSidebarView.values) {
        expect(cell(view), findsOneWidget, reason: '${view.name} needs a cell');
      }
    });
  });

  group('overflow', () {
    testWidgets('folds the trailing cells away when the sidebar narrows', (
      tester,
    ) async {
      // 150px leaves 30px for the caret and room for three 34px cells, so the
      // last two views have to fold.
      await pump(tester, width: 150);

      expect(cell(IdeSidebarView.general), findsOneWidget);
      expect(
        cell(IdeSidebarView.artifacts),
        findsNothing,
        reason: 'the last view past the fold moves into the caret menu',
      );
      expect(caret, findsOneWidget, reason: 'the caret is the way back to it');
    });

    testWidgets('keeps the active view visible even past the fold', (
      tester,
    ) async {
      await pump(tester, width: 150, selected: IdeSidebarView.artifacts);

      expect(
        cell(IdeSidebarView.artifacts),
        findsOneWidget,
        reason: 'the selection underline needs a cell to sit on',
      );
      expect(
        cell(IdeSidebarView.notes),
        findsNothing,
        reason: 'the active view evicts the last cell that fit, not the first',
      );
      // Canonical order is preserved: the active cell does not jump to the end.
      expect(
        tester.getCenter(cell(IdeSidebarView.general)).dx,
        lessThan(tester.getCenter(cell(IdeSidebarView.artifacts)).dx),
      );
    });

    testWidgets('narrower than one cell plus the caret does not overflow', (
      tester,
    ) async {
      // Far below the sidebar's 200px minimum nothing can be dropped further:
      // the active view still needs its cell and the caret is the only way to
      // any other view. The rail becomes scrollable rather than throwing a
      // flex-overflow assertion and the caret stays whole.
      await pump(tester, width: 50);

      expect(tester.takeException(), isNull);
      expect(cell(IdeSidebarView.general), findsOneWidget);
      expect(
        tester.getSize(find.byIcon(AppIcons.chevronDown)).width,
        greaterThan(0),
        reason: 'the caret is never the thing that gets squeezed out',
      );
    });

    testWidgets('brings folded cells back when the sidebar widens', (
      tester,
    ) async {
      await pump(tester, width: 150);
      expect(cell(IdeSidebarView.artifacts), findsNothing);

      await pump(tester, width: 400);
      expect(cell(IdeSidebarView.artifacts), findsOneWidget);
    });
  });

  group('caret menu', () {
    testWidgets('lists every view, folded or not', (tester) async {
      await pump(tester, width: 200);
      await tester.tap(caret);
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      for (final label in [
        l10n.ideTabGeneral,
        l10n.ideTabExplorer,
        l10n.ideTabSourceControl,
        l10n.ideTabNotes,
        l10n.artifactsTabLabel,
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('selecting a folded view reports it and closes the menu', (
      tester,
    ) async {
      final picked = <IdeSidebarView>[];
      await pump(tester, width: 200, onChanged: picked.add);

      await tester.tap(caret);
      await tester.pumpAndSettle();
      await tester.tap(menuRow(IdeSidebarView.artifacts));
      await tester.pumpAndSettle();

      expect(picked, [IdeSidebarView.artifacts]);
      expect(
        menuRow(IdeSidebarView.artifacts),
        findsNothing,
        reason: 'the menu closes on selection',
      );
    });
  });

  group('pinning', () {
    testWidgets('every view ships pinned', (tester) async {
      final container = await pump(tester);

      expect(
        container.read(ideSidebarPinsProvider),
        IdeSidebarView.values.toSet(),
      );
    });

    testWidgets('unpinning removes the cell and persists the set', (
      tester,
    ) async {
      final container = await pump(tester);

      await tester.tap(caret);
      await tester.pumpAndSettle();
      await tester.tapAt(pinCenter(tester, IdeSidebarView.notes));
      await tester.pumpAndSettle();

      expect(
        container.read(ideSidebarPinsProvider),
        isNot(contains(IdeSidebarView.notes)),
      );
      expect(
        container
            .read(appPreferencesProvider)
            .getStringList(ideSidebarPinnedViewsKey),
        isNot(contains(IdeSidebarView.notes.name)),
        reason: 'the pin set has to survive a restart',
      );
    });

    testWidgets('a stored pin set is restored and drives the strip', (
      tester,
    ) async {
      await pump(
        tester,
        prefs: {
          ideSidebarPinnedViewsKey: [
            IdeSidebarView.general.name,
            IdeSidebarView.sourceControl.name,
          ],
        },
      );

      expect(cell(IdeSidebarView.general), findsOneWidget);
      expect(cell(IdeSidebarView.sourceControl), findsOneWidget);
      expect(cell(IdeSidebarView.explorer), findsNothing);
      expect(cell(IdeSidebarView.notes), findsNothing);
    });

    testWidgets('an unpinned view still gets a cell while it is active', (
      tester,
    ) async {
      await pump(
        tester,
        selected: IdeSidebarView.notes,
        prefs: {
          ideSidebarPinnedViewsKey: [IdeSidebarView.general.name],
        },
      );

      expect(cell(IdeSidebarView.notes), findsOneWidget);
      expect(cell(IdeSidebarView.general), findsOneWidget);
    });

    testWidgets('an unknown stored name is dropped, not crashed on', (
      tester,
    ) async {
      final container = await pump(
        tester,
        prefs: {
          ideSidebarPinnedViewsKey: ['general', 'someRemovedView'],
        },
      );

      expect(container.read(ideSidebarPinsProvider), {IdeSidebarView.general});
      expect(tester.takeException(), isNull);
    });
  });
}
