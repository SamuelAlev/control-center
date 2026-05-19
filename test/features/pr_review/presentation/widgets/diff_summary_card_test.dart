import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/domain/entities/file_change.dart';
import 'package:control_center/features/pr_review/presentation/widgets/diff_summary_card.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _wrapPS(Widget child) {
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
  group('FileChange', () {
    test('const constructor sets all fields', () {
      const change = FileChange(
        path: 'src/main.dart',
        additions: 10,
        deletions: 3,
        isNew: false,
        isDeleted: false,
      );

      expect(change.path, 'src/main.dart');
      expect(change.additions, 10);
      expect(change.deletions, 3);
      expect(change.isNew, isFalse);
      expect(change.isDeleted, isFalse);
    });

    test('defaults for optional fields', () {
      const change = FileChange(path: 'lib/foo.dart');

      expect(change.additions, 0);
      expect(change.deletions, 0);
      expect(change.isNew, isFalse);
      expect(change.isDeleted, isFalse);
    });

    test('new file flag', () {
      const change = FileChange(path: 'new.dart', isNew: true);

      expect(change.isNew, isTrue);
      expect(change.isDeleted, isFalse);
    });

    test('deleted file flag', () {
      const change = FileChange(path: 'old.dart', isDeleted: true);

      expect(change.isDeleted, isTrue);
      expect(change.isNew, isFalse);
    });

    test('both new and deleted flags', () {
      const change = FileChange(
        path: 'temp.dart',
        isNew: true,
        isDeleted: true,
      );

      expect(change.isNew, isTrue);
      expect(change.isDeleted, isTrue);
    });

    test('equality compares all fields', () {
      const a = FileChange(path: 'a.dart', additions: 5, deletions: 2);
      const b = FileChange(path: 'a.dart', additions: 5, deletions: 2);
      const c = FileChange(path: 'a.dart', additions: 10, deletions: 2);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent', () {
      const a = FileChange(path: 'a.dart', additions: 5, deletions: 2);
      const b = FileChange(path: 'a.dart', additions: 5, deletions: 2);

      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString contains path and stats', () {
      const change = FileChange(path: 'src/main.dart', additions: 10, deletions: 3);

      final str = change.toString();
      expect(str, contains('src/main.dart'));
      expect(str, contains('10'));
      expect(str, contains('3'));
    });

    test('isNew is independent of isDeleted', () {
      const change = FileChange(
        path: 'file.dart',
        isNew: true,
        isDeleted: false,
        additions: 5,
        deletions: 0,
      );

      expect(change.isNew, isTrue);
      expect(change.isDeleted, isFalse);
    });
  });

  group('DiffSummaryCard', () {
    testWidgets('renders empty state with zero changes', (tester) async {
      await tester.pumpWidget(
        _wrapPS(const Scaffold(body: DiffSummaryCard())),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Changes summary'), findsOneWidget);
      expect(find.text('0 files changed'), findsOneWidget);
      expect(find.text('+0'), findsOneWidget);
      expect(find.text('-0'), findsOneWidget);
    });

    testWidgets('renders with additions and deletions', (tester) async {
      await tester.pumpWidget(
        _wrapPS(
          const Scaffold(
            body: DiffSummaryCard(
              filesChanged: 3,
              additions: 25,
              deletions: 7,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('+25'), findsOneWidget);
      expect(find.text('-7'), findsOneWidget);
      expect(find.text('3 files changed'), findsOneWidget);
    });

    testWidgets('renders singular file text', (tester) async {
      await tester.pumpWidget(
        _wrapPS(
          const Scaffold(body: DiffSummaryCard(filesChanged: 1)),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('1 file changed'), findsOneWidget);
    });

    testWidgets('renders file list', (tester) async {
      const files = [
        FileChange(path: 'src/main.dart', additions: 5, deletions: 2),
        FileChange(
          path: 'src/utils.dart',
          additions: 10,
          deletions: 0,
          isNew: true,
        ),
        FileChange(
          path: 'src/old.dart',
          additions: 0,
          deletions: 15,
          isDeleted: true,
        ),
      ];

      await tester.pumpWidget(
        _wrapPS(
          const Scaffold(
            body: DiffSummaryCard(
              filesChanged: 3,
              additions: 15,
              deletions: 17,
              files: files,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('src/main.dart'), findsOneWidget);
      expect(find.text('src/utils.dart'), findsOneWidget);
      expect(find.text('src/old.dart'), findsOneWidget);
      expect(find.text('+5  -2'), findsOneWidget);
      expect(find.text('+10  -0'), findsOneWidget);
      expect(find.text('+0  -15'), findsOneWidget);
    });

    testWidgets('does not render file list when files is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapPS(
          const Scaffold(
            body: DiffSummaryCard(
              filesChanged: 2,
              additions: 5,
              deletions: 3,
              files: [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Changes summary'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
      expect(find.text('-3'), findsOneWidget);
      expect(find.text('2 files changed'), findsOneWidget);
    });

    testWidgets('icons for new, deleted, and modified files', (
      tester,
    ) async {
      const files = [
        FileChange(path: 'new.dart', additions: 5, deletions: 0, isNew: true),
        FileChange(
          path: 'del.dart',
          additions: 0,
          deletions: 5,
          isDeleted: true,
        ),
        FileChange(path: 'mod.dart', additions: 5, deletions: 2),
      ];

      await tester.pumpWidget(
        _wrapPS(
          const Scaffold(
            body: DiffSummaryCard(
              filesChanged: 3,
              additions: 10,
              deletions: 7,
              files: files,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byIcon(LucideIcons.filePlus), findsOneWidget);
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
      expect(find.byIcon(LucideIcons.fileEdit), findsOneWidget);
    });

    testWidgets('FBadge variant differences for add/delete', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapPS(
          const Scaffold(
            body: DiffSummaryCard(
              filesChanged: 1,
              additions: 42,
              deletions: 7,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(FBadge), findsNWidgets(2));
      expect(find.text('+42'), findsOneWidget);
      expect(find.text('-7'), findsOneWidget);
    });

    testWidgets('single file with only additions', (tester) async {
      await tester.pumpWidget(
        _wrapPS(
          const Scaffold(
            body: DiffSummaryCard(filesChanged: 1, additions: 15, deletions: 0),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('+15'), findsOneWidget);
      expect(find.text('-0'), findsOneWidget);
    });

    testWidgets('single file with only deletions', (tester) async {
      await tester.pumpWidget(
        _wrapPS(
          const Scaffold(
            body: DiffSummaryCard(filesChanged: 1, additions: 0, deletions: 9),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('+0'), findsOneWidget);
      expect(find.text('-9'), findsOneWidget);
    });
  });
}
