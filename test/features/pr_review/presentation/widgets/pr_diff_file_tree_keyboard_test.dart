import 'dart:ui' show Tristate;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_file_tree.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

DiffTreeNode _leaf(String path, int index, {String status = 'modified'}) =>
    DiffTreeNode.file(
      name: path.split('/').last,
      path: path,
      additions: 1,
      deletions: 0,
      fileIndex: index,
      status: status,
    );

DiffTreeNode _dir(String path, List<DiffTreeNode> children) => DiffTreeNode.dir(
  name: path.split('/').last,
  path: path,
  children: children,
  additions: 0,
  deletions: 0,
  fileCount: children.length,
);

final _roots = [
  _dir('lib', [_leaf('lib/a.dart', 0), _leaf('lib/b.dart', 1)]),
  _dir('test', [_leaf('test/c.dart', 2, status: 'added')]),
];

Widget _wrap(Widget child, {TextDirection? textDirection}) {
  Widget body = CcTheme(
    data: CcThemeData.light(),
    child: Scaffold(body: SizedBox(width: 300, height: 600, child: child)),
  );
  if (textDirection != null) {
    body = Directionality(textDirection: textDirection, child: body);
  }
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: body,
  );
}

FocusNode _rowFocus(WidgetTester tester, String name) =>
    Focus.of(tester.element(find.text(name)));

bool _focused(WidgetTester tester, String name) =>
    _rowFocus(tester, name).hasPrimaryFocus;

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

void main() {
  group('PrDiffFileTree keyboard', () {
    testWidgets('↑/↓ walk the visible rows, Home/End jump to the ends', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(PrDiffFileTree(roots: _roots, onSelectFile: (_) {})),
      );
      _rowFocus(tester, 'lib').requestFocus();
      await tester.pump();

      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(tester, 'a.dart'), isTrue);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(tester, 'b.dart'), isTrue);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_focused(tester, 'a.dart'), isTrue);

      await _key(tester, LogicalKeyboardKey.end);
      expect(_focused(tester, 'c.dart'), isTrue);
      // ↓ on the last row stays in the tree.
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(tester, 'c.dart'), isTrue);
      await _key(tester, LogicalKeyboardKey.home);
      expect(_focused(tester, 'lib'), isTrue);
    });

    testWidgets('← closes a folder or climbs to it, → opens and enters', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(PrDiffFileTree(roots: _roots, onSelectFile: (_) {})),
      );
      _rowFocus(tester, 'a.dart').requestFocus();
      await tester.pump();

      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focused(tester, 'lib'), isTrue);

      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(find.text('a.dart'), findsNothing);
      expect(_focused(tester, 'lib'), isTrue);

      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(find.text('a.dart'), findsOneWidget);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focused(tester, 'a.dart'), isTrue);
    });

    testWidgets('in RTL, ← enters a folder and → leaves it', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PrDiffFileTree(roots: _roots, onSelectFile: (_) {}),
          textDirection: TextDirection.rtl,
        ),
      );
      _rowFocus(tester, 'a.dart').requestFocus();
      await tester.pump();

      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focused(tester, 'lib'), isTrue);
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focused(tester, 'a.dart'), isTrue);
    });

    testWidgets('Enter on a file row selects it', (tester) async {
      int? selected;
      await tester.pumpWidget(
        _wrap(PrDiffFileTree(roots: _roots, onSelectFile: (i) => selected = i)),
      );
      _rowFocus(tester, 'b.dart').requestFocus();
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.enter);
      expect(selected, 1);
    });

    testWidgets('only one row is a Tab stop, and it follows focus', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(PrDiffFileTree(roots: _roots, onSelectFile: (_) {})),
      );
      List<String> stops() => [
        for (final name in ['lib', 'a.dart', 'b.dart', 'test', 'c.dart'])
          if (!_rowFocus(tester, name).skipTraversal) name,
      ];
      expect(stops(), ['lib']);

      _rowFocus(tester, 'b.dart').requestFocus();
      await tester.pump();
      expect(stops(), ['b.dart']);
    });
  });

  group('PrDiffFileTree semantics', () {
    testWidgets('folders announce their file count and open state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(PrDiffFileTree(roots: _roots, onSelectFile: (_) {})),
      );
      final lib = tester.getSemantics(find.text('lib'));
      expect(lib.label, 'lib, folder, 2 files');
      expect(lib.flagsCollection.isExpanded, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('files announce status, viewed and selection', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          PrDiffFileTree(
            roots: _roots,
            onSelectFile: (_) {},
            selectedFileIndex: 2,
            viewedPaths: const {'lib/a.dart'},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('a.dart')).label,
        'a.dart, Modified, viewed',
      );
      final c = tester.getSemantics(find.text('c.dart'));
      expect(c.label, 'c.dart, Added');
      expect(c.flagsCollection.isSelected, Tristate.isTrue);
      handle.dispose();
    });
  });
}
