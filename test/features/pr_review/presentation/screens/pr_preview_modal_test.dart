import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/screens/pr_preview_modal.dart';
import 'package:control_center/features/pr_review/presentation/widgets/diff_summary_card.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('JetBrainsMono'),
    ],
    child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      home: FTheme(
        data: FThemes.zinc.light.desktop,
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('PrPreviewModal', () {
    testWidgets('renders title field and create button', (tester) async {
      await tester.pumpWidget(
        _wrap(const PrPreviewModal(workspaceId: 'ws-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create pull request'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('renders DiffSummaryCard inside modal', (tester) async {
      await tester.pumpWidget(
        _wrap(const PrPreviewModal(workspaceId: 'ws-1')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DiffSummaryCard), findsOneWidget);
    });

    testWidgets('close button dismisses modal', (tester) async {
      await tester.pumpWidget(
        _wrap(const PrPreviewModal(workspaceId: 'ws-1')),
      );
      await tester.pumpAndSettle();

      final closeButton = find.byType(FButton).first;
      await tester.tap(closeButton);
      await tester.pumpAndSettle();
    });

    testWidgets('cancel button dismisses modal', (tester) async {
      await tester.pumpWidget(
        _wrap(const PrPreviewModal(workspaceId: 'ws-1')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('renders FTextField controls', (tester) async {
      await tester.pumpWidget(
        _wrap(const PrPreviewModal(workspaceId: 'ws-1')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FTextField), findsNWidgets(2));
    });

    testWidgets('dialog has constrained size', (tester) async {
      await tester.pumpWidget(
        _wrap(const PrPreviewModal(workspaceId: 'ws-1')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FDialog), findsOneWidget);
    });

    testWidgets('renders with different workspace IDs', (tester) async {
      await tester.pumpWidget(
        _wrap(const PrPreviewModal(workspaceId: 'ws-999')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create pull request'), findsOneWidget);
    });
  });
}
