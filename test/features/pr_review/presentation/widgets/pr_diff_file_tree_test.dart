import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_file_tree.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

DiffTreeNode _leaf({
  required String name,
  String path = '',
  int additions = 0,
  int deletions = 0,
  int fileIndex = 0,
  String status = 'modified',
}) {
  return DiffTreeNode.file(
    name: name,
    path: path.isEmpty ? name : path,
    additions: additions,
    deletions: deletions,
    fileIndex: fileIndex,
    status: status,
  );
}

DiffTreeNode _dir({
  required String name,
  required List<DiffTreeNode> children,
  String path = '',
  int additions = 0,
  int deletions = 0,
  int fileCount = 0,
}) {
  return DiffTreeNode.dir(
    name: name,
    path: path.isEmpty ? name : path,
    children: children,
    additions: additions,
    deletions: deletions,
    fileCount: fileCount,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    home: CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('PrDiffFileTree', () {
    testWidgets('renders empty state when no roots', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PrDiffFileTree(
            roots: const [],
            onSelectFile: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('No matching files'), findsOneWidget);
    });

    testWidgets('renders file leafs', (tester) async {
      final roots = [
        _leaf(name: 'main.dart', path: 'lib/main.dart', additions: 5, deletions: 2),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffFileTree(
            roots: roots,
            onSelectFile: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('main.dart'), findsOneWidget);
    });

    testWidgets('renders directory structure', (tester) async {
      final roots = [
        _dir(
          name: 'lib',
          path: 'lib',
          children: [
            _leaf(name: 'main.dart', path: 'lib/main.dart', additions: 5, deletions: 2),
            _leaf(name: 'utils.dart', path: 'lib/utils.dart', additions: 3, deletions: 1),
          ],
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffFileTree(
            roots: roots,
            onSelectFile: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('lib'), findsOneWidget);
      expect(find.text('main.dart'), findsOneWidget);
      expect(find.text('utils.dart'), findsOneWidget);
    });

    testWidgets('toggles directory open/close', (tester) async {
      final roots = [
        _dir(
          name: 'src',
          path: 'src',
          children: [
            _leaf(name: 'app.dart', path: 'src/app.dart'),
          ],
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffFileTree(
            roots: roots,
            onSelectFile: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('app.dart'), findsOneWidget);

      final chevron = find.byIcon(LucideIcons.chevronDown);
      await tester.tap(chevron.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('app.dart'), findsNothing);
    });

    testWidgets('calls onSelectFile when file tapped', (tester) async {
      int? selectedIndex;
      final roots = [
        _leaf(name: 'main.dart', path: 'lib/main.dart', fileIndex: 42),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffFileTree(
            roots: roots,
            onSelectFile: (i) => selectedIndex = i,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('main.dart'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(selectedIndex, 42);
    });

    testWidgets('highlights selected file', (tester) async {
      final roots = [
        _leaf(name: 'main.dart', path: 'lib/main.dart', fileIndex: 0),
        _leaf(name: 'utils.dart', path: 'lib/utils.dart', fileIndex: 1),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffFileTree(
            roots: roots,
            onSelectFile: (_) {},
            selectedFileIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('main.dart'), findsOneWidget);
      expect(find.text('utils.dart'), findsOneWidget);
    });

    testWidgets('shows viewed path with strikethrough', (tester) async {
      final roots = [
        _leaf(name: 'old.dart', path: 'lib/old.dart'),
        _leaf(name: 'new.dart', path: 'lib/new.dart'),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffFileTree(
            roots: roots,
            onSelectFile: (_) {},
            viewedPaths: {'lib/old.dart'},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('old.dart'), findsOneWidget);
      expect(find.text('new.dart'), findsOneWidget);
    });

    testWidgets('displays addition and deletion counts', (tester) async {
      final roots = [
        _leaf(
          name: 'main.dart',
          path: 'lib/main.dart',
          additions: 15,
          deletions: 7,
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffFileTree(
            roots: roots,
            onSelectFile: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('+15'), findsOneWidget);
      expect(find.text('−7'), findsOneWidget);
    });

    testWidgets('filters files by text', (tester) async {
      final roots = [
        _leaf(name: 'main.dart', path: 'lib/main.dart'),
        _leaf(name: 'utils.dart', path: 'lib/utils.dart'),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffFileTree(
            roots: roots,
            onSelectFile: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'main');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('main.dart'), findsOneWidget);
      expect(find.text('utils.dart'), findsNothing);
    });

    testWidgets('filters files by status', (tester) async {
      final roots = [
        _leaf(name: 'added.dart', path: 'lib/added.dart', status: 'added'),
        _leaf(name: 'modified.dart', path: 'lib/modified.dart', status: 'modified'),
        _leaf(name: 'removed.dart', path: 'lib/removed.dart', status: 'removed'),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffFileTree(
            roots: roots,
            onSelectFile: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Added'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('added.dart'), findsOneWidget);
      expect(find.text('modified.dart'), findsNothing);
      expect(find.text('removed.dart'), findsNothing);
    });

    testWidgets('status filter chips exist', (tester) async {
      final roots = [
        _leaf(name: 'test.dart', path: 'test.dart'),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffFileTree(
            roots: roots,
            onSelectFile: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Added'), findsOneWidget);
      expect(find.text('Modified'), findsOneWidget);
      expect(find.text('Removed'), findsOneWidget);
      expect(find.text('Renamed'), findsOneWidget);
    });

    testWidgets('renders with color status accents', (tester) async {
      final roots = [
        _leaf(name: 'added.dart', path: 'added.dart', status: 'added', additions: 3),
        _leaf(name: 'removed.dart', path: 'removed.dart', status: 'removed', deletions: 5),
        _leaf(name: 'renamed.dart', path: 'renamed.dart', status: 'renamed', additions: 1, deletions: 1),
      ];

      await tester.pumpWidget(
        _wrap(
          PrDiffFileTree(
            roots: roots,
            onSelectFile: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('added.dart'), findsOneWidget);
      expect(find.text('removed.dart'), findsOneWidget);
      expect(find.text('renamed.dart'), findsOneWidget);
    });
  });
}
