import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/suggestion_renderer.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// The PR identity SuggestionAwareMarkdown links `#N` references against.
const _prRef = (workspaceId: 'ws', repoFullName: 'owner/repo', number: 1);

void main() {
  group('SuggestionAwareMarkdown', () {
    testWidgets('renders plain markdown body without suggestion fence', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: 'Just a comment',
            originalCode: 'original code',
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('renders suggestion diff when fence is present', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: '```suggestion\nnew code\n```',
            originalCode: 'old code',
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });

    testWidgets('renders suggestion with before text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: 'Before text\n\n```suggestion\nnew code\n```',
            originalCode: 'old code',
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
      expect(find.text('Before text'), findsOneWidget);
    });

    testWidgets('renders suggestion with after text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: '```suggestion\nnew code\n```\nAfter text',
            originalCode: 'old code',
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
      expect(find.text('After text'), findsOneWidget);
    });

    testWidgets('renders suggestion with before and after text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: 'Before\n```suggestion\nnew code\n```\nAfter',
            originalCode: 'old code',
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });

    testWidgets('handles empty suggested code in fence', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: '```suggestion\n```',
            originalCode: 'original code',
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });

    testWidgets('renders with file path', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: '```suggestion\nnew code\n```',
            originalCode: 'old code',
            filePath: 'lib/main.dart',
            originalStartLine: 42,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });

    testWidgets('renders multiline suggestion', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: '```suggestion\nline1\nline2\nline3\n```',
            originalCode: 'old1\nold2\nold3',
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });

    testWidgets('handles null suggestion fence match gracefully', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: 'Normal **markdown** text',
            originalCode: 'original',
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(SuggestionAwareMarkdown), findsOneWidget);
    });

    testWidgets('renders with compact markdown style', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: '```suggestion\nnew\n```',
            originalCode: 'old',
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });
  });

  group('_SuggestionMiniDiff', () {
    testWidgets('renders original and suggested lines', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: '```suggestion\nchanged line\n```',
            originalCode: 'original line',
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });

    testWidgets('renders multiline original and suggested', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: '```suggestion\na\nb\nc\n```',
            originalCode: 'x\ny\nz',
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
    });

    // A suggestion with an EMPTY fence is legal on GitHub and means "delete
    // these lines". With no original code it has nothing to diff against and
    // rendered as a header over an empty box — which is what a reader saw for
    // every server-side suggestion, since server threads passed originalCode:
    // ''.
    testWidgets('a deletion suggestion still shows the removed lines', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: '```suggestion\n```',
            originalCode: 'first removed\nsecond removed',
            originalStartLine: 13,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Suggested change'), findsOneWidget);
      expect(find.textContaining('first removed'), findsOneWidget);
      expect(find.textContaining('second removed'), findsOneWidget);
    });

    // Every line used to be its own `SelectableText`, each owning its own
    // selection, so dragging down the block only ever highlighted the line the
    // drag started on.
    testWidgets('a drag selects across lines, and skips the gutter', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: '```suggestion\n```',
            originalCode: 'first removed\nsecond removed\nthird removed',
            originalStartLine: 13,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final start = tester.getTopLeft(find.textContaining('first removed'));
      final end = tester.getBottomRight(find.textContaining('third removed'));
      final gesture = await tester.startGesture(
        start + const Offset(1, 4),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(end - const Offset(1, 4));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      tester
          .state<SelectableRegionState>(find.byType(SelectableRegion))
          // The non-deprecated copy paths all go through the selection toolbar
          // or a focused key event; this is the direct call the toolbar makes.
          // ignore: deprecated_member_use
          .copySelection(SelectionChangedCause.keyboard);
      await tester.pumpAndSettle();

      expect(copied, isNotNull);
      expect(copied, contains('first removed'));
      expect(copied, contains('third removed'));
      // The line-number gutter is excluded, so the copy pastes as code.
      expect(copied, isNot(contains('13')));
      expect(copied, isNot(contains('15')));
    });

    testWidgets('suggested code is syntax highlighted for a known language', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: '```suggestion\nfinal int answer = 42;\n```',
            originalCode: 'var answer = 41;',
            filePath: 'lib/main.dart',
            originalStartLine: 7,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // At least one span carries a grammar-derived color: the block is
      // tokenized, not dumped as one flat run in the base text color.
      final colors = <Color?>{};
      for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
        rich.text.visitChildren((span) {
          if (span is TextSpan && (span.text?.isNotEmpty ?? false)) {
            colors.add(span.style?.color);
          }
          return true;
        });
      }
      expect(
        colors.length,
        greaterThan(2),
        reason: 'expected several distinct token colors, got $colors',
      );
    });

    testWidgets('numbers the original lines from the range start', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SuggestionAwareMarkdown(
            prRef: _prRef,
            body: '```suggestion\nreplacement\n```',
            originalCode: 'line thirteen\nline fourteen',
            originalStartLine: 13,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The deletion rows carry the real file line numbers, not 1..n.
      expect(find.text('13'), findsWidgets);
      expect(find.text('14'), findsWidgets);
    });
  });
}
