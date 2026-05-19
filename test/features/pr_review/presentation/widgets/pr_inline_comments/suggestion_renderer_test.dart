import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/suggestion_renderer.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
    ],
    child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

void main() {
  group('SuggestionAwareMarkdown', () {
    testWidgets('renders plain markdown body without suggestion fence', (tester) async {
      await tester.pumpWidget(
        _wrap(const SuggestionAwareMarkdown(
          body: 'Just a comment',
          originalCode: 'original code',
        )),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('renders suggestion diff when fence is present', (tester) async {
      await tester.pumpWidget(
        _wrap(const SuggestionAwareMarkdown(
          body: '```suggestion\nnew code\n```',
          originalCode: 'old code',
        )),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });

    testWidgets('renders suggestion with before text', (tester) async {
      await tester.pumpWidget(
        _wrap(const SuggestionAwareMarkdown(
          body: 'Before text\n\n```suggestion\nnew code\n```',
          originalCode: 'old code',
        )),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
      expect(find.text('Before text'), findsOneWidget);
    });

    testWidgets('renders suggestion with after text', (tester) async {
      await tester.pumpWidget(
        _wrap(const SuggestionAwareMarkdown(
          body: '```suggestion\nnew code\n```\nAfter text',
          originalCode: 'old code',
        )),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
      expect(find.text('After text'), findsOneWidget);
    });

    testWidgets('renders suggestion with before and after text', (tester) async {
      await tester.pumpWidget(
        _wrap(const SuggestionAwareMarkdown(
          body: 'Before\n```suggestion\nnew code\n```\nAfter',
          originalCode: 'old code',
        )),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });

    testWidgets('handles empty suggested code in fence', (tester) async {
      await tester.pumpWidget(
        _wrap(const SuggestionAwareMarkdown(
          body: '```suggestion\n```',
          originalCode: 'original code',
        )),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });

    testWidgets('renders with file path', (tester) async {
      await tester.pumpWidget(
        _wrap(const SuggestionAwareMarkdown(
          body: '```suggestion\nnew code\n```',
          originalCode: 'old code',
          filePath: 'lib/main.dart',
          originalStartLine: 42,
        )),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });

    testWidgets('renders multiline suggestion', (tester) async {
      await tester.pumpWidget(
        _wrap(const SuggestionAwareMarkdown(
          body: '```suggestion\nline1\nline2\nline3\n```',
          originalCode: 'old1\nold2\nold3',
        )),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });

    testWidgets('handles null suggestion fence match gracefully', (tester) async {
      await tester.pumpWidget(
        _wrap(const SuggestionAwareMarkdown(
          body: 'Normal **markdown** text',
          originalCode: 'original',
        )),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(SuggestionAwareMarkdown), findsOneWidget);
    });

    testWidgets('renders with compact markdown style', (tester) async {
      await tester.pumpWidget(
        _wrap(const SuggestionAwareMarkdown(
          body: '```suggestion\nnew\n```',
          originalCode: 'old',
        )),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });
  });

  group('_SuggestionMiniDiff', () {
    testWidgets('renders original and suggested lines', (tester) async {
      await tester.pumpWidget(
        _wrap(const SuggestionAwareMarkdown(
          body: '```suggestion\nchanged line\n```',
          originalCode: 'original line',
        )),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });

    testWidgets('renders multiline original and suggested', (tester) async {
      await tester.pumpWidget(
        _wrap(const SuggestionAwareMarkdown(
          body: '```suggestion\na\nb\nc\n```',
          originalCode: 'x\ny\nz',
        )),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });
  });
}
