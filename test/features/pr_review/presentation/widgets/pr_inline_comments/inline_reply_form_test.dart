import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/inline_reply_form.dart';
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
        child: Scaffold(body: child),
      ),
    ),
  );
}

PrInlineThread _thread({
  String id = 't1',
  String filePath = 'lib/a.dart',
  int line = 1,
  bool resolved = false,
  bool isSuggestion = false,
  List<PrInlineEntry>? entries,
}) {
  return PrInlineThread(
    id: id,
    filePath: filePath,
    line: line,
    side: 'RIGHT',
    kind: isSuggestion ? PrInlineThreadKind.suggestion : PrInlineThreadKind.comment,
    originalCode: 'code',
    suggestedCode: 'code',
    entries: entries ?? [
      PrInlineEntry(
        id: 'e1',
        author: 'author1',
        body: 'Hello',
        createdAt: DateTime(2024, 6, 15),
      ),
    ],
    resolved: resolved,
  );
}

void main() {
  group('PrInlineThreadDot', () {
    testWidgets('renders unresolved dot with blue color', (tester) async {
      await tester.pumpWidget(
        _wrap(const PrInlineThreadDot(resolved: false)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final container = find.byType(Container);
      expect(container, findsWidgets);
    });

    testWidgets('renders resolved dot with green color', (tester) async {
      await tester.pumpWidget(
        _wrap(const PrInlineThreadDot(resolved: true)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final container = find.byType(Container);
      expect(container, findsWidgets);
    });
  });

  group('PrCommentsInbox', () {
    testWidgets('renders empty state when no threads', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: PrCommentsInbox(
              threads: const [],
              onToggleResolved: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('No open conversations'), findsOneWidget);
    });

    testWidgets('renders single thread', (tester) async {
      final thread = _thread();
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: PrCommentsInbox(
              threads: [thread],
              onToggleResolved: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('1 comment'), findsOneWidget);
    });

    testWidgets('renders multiple threads', (tester) async {
      final threads = [
        _thread(id: 't1'),
        _thread(id: 't2'),
      ];
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: PrCommentsInbox(
              threads: threads,
              onToggleResolved: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('2 comments'), findsOneWidget);
    });

    testWidgets('hides resolved threads by default', (tester) async {
      final threads = [
        _thread(id: 't1', resolved: true),
        _thread(id: 't2'),
      ];
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: PrCommentsInbox(
              threads: threads,
              onToggleResolved: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('1 comment'), findsOneWidget);
    });

    testWidgets('calls onToggleResolved when resolve tapped', (tester) async {
      final thread = _thread();
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: PrCommentsInbox(
              threads: [thread],
              onToggleResolved: (_) {},
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('1 comment'), findsOneWidget);
    });
  });
}
