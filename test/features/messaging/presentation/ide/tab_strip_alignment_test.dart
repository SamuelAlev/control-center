import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_sidebar_view_strip.dart';
import 'package:control_center/features/messaging/providers/ide_sidebar_prefs_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The messaging IDE puts an [EditorTabBar] and the sidebar's
/// [IdeSidebarViewStrip] side by side, separated only by the resizable divider.
/// Their bottom rules and their active underlines therefore have to land on the
/// same scanline — the two strips read as one band. Both pin themselves to
/// [EditorTabBar.height] rather than sizing to content, which lands on a
/// fractional height (~35.85) and leaves a visible jog in the rule at the seam.
///
/// [CcTabs] is still the design system's labelled strip (used elsewhere), so its
/// own height-pinning behavior is covered here too.
void main() {
  const editorTabs = [
    EditorTab(kind: 'chat', label: 'Chat'),
    EditorTab(kind: 'terminal', label: 'Terminal'),
  ];
  const sidebarTabs = [CcTab('General'), CcTab('Explorer')];

  final accent = DesignSystemTokens.light().accent;

  /// The 2px accent underline of the active editor tab.
  final editorUnderline = find.byWidgetPredicate(
    (w) => w is ColoredBox && w.color == accent,
  );

  /// The 2px accent underline of the active sidebar cell.
  final sidebarUnderline = find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).color == accent,
  );

  Future<void> pumpStrips(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 400,
                    child: EditorTabBar(
                      leafId: 'leaf-0',
                      tabs: editorTabs,
                      labels: const ['Chat', 'Terminal'],
                      selectedIndex: 0,
                      onTabSelected: (_) {},
                      onReorderDrop: (_, _) {},
                    ),
                  ),
                  const SizedBox(
                    width: 300,
                    child: IdeSidebarViewStrip(
                      selected: IdeSidebarView.general,
                      onChanged: _noopView,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('both strips are exactly as tall as the editor tab bar', (
    tester,
  ) async {
    await pumpStrips(tester);

    expect(
      tester.getSize(find.byType(EditorTabBar)).height,
      EditorTabBar.height,
    );
    expect(
      tester.getSize(find.byType(IdeSidebarViewStrip)).height,
      EditorTabBar.height,
    );
    // No overflow from squeezing the cells into the fixed height.
    expect(tester.takeException(), isNull);
  });

  testWidgets('the active underlines sit on the same scanline', (tester) async {
    await pumpStrips(tester);
    await tester.pumpAndSettle();

    final editor = tester.getRect(editorUnderline.first);
    final sidebar = tester.getRect(sidebarUnderline.first);

    expect(editor.height, 2);
    expect(sidebar.height, 2);
    expect(sidebar.top, editor.top);
    expect(sidebar.bottom, editor.bottom);
    // Both sit ON the 1px bottom rule, not over it.
    expect(editor.bottom, EditorTabBar.height - 1);
  });

  testWidgets('CcTabs sizes to its content when no height is given', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: CcTabs(
              tabs: sidebarTabs,
              selectedIndex: 0,
              onChanged: _noop,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(CcTabs)).height,
      greaterThan(EditorTabBar.height),
    );
    expect(tester.takeException(), isNull);
  });
}

void _noop(int _) {}

void _noopView(IdeSidebarView _) {}
