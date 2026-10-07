import 'dart:ui' show Tristate;

import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/file_header.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_gap_row.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_view.dart';
import 'package:control_center/features/pr_review/providers/diff_view_settings_provider.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/confined_directional_focus.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../helpers/test_wrap.dart';

/// A patch tall enough (~120 rows) that the next file's header is far outside
/// the sliver's cache band, so it is not built when the previous header has
/// focus — the condition under which arrow keys used to fall into the tree.
String _tallPatch(int lines) =>
    '@@ -1,$lines +1,${lines + 1} @@\n'
    '${List.generate(lines, (i) => ' line $i\n').join()}'
    '+added\n';

PrFile _file(String name, {String? patch}) => PrFile(
  filename: name,
  status: PrFileStatus.modified,
  additions: 5,
  deletions: 2,
  patch: patch ?? _tallPatch(120),
);

/// The diff beside a column of focusable "tree rows", like the Diff tab.
Widget _diffBesideTree(List<PrFile> files) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      diffOverflowModeProvider.overrideWith(DiffOverflowModeNotifier.new),
    ],
    child: testWrap(
      Row(
        children: [
          SizedBox(
            width: 200,
            child: ConfinedDirectionalFocus(
              child: ListView(
                children: [
                  for (var i = 0; i < 40; i++)
                    CcTappable(
                      onPressed: () {},
                      builder: (_, _) =>
                          SizedBox(height: 24, child: Text('tree row $i')),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ConfinedDirectionalFocus(
              child: CustomScrollView(slivers: [UnifiedDiffView(files: files)]),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

String? _focusedHeaderFile() {
  final context = FocusManager.instance.primaryFocus?.context;
  return context
      ?.findAncestorWidgetOfExactType<FastFileHeader>()
      ?.file
      .filename;
}

bool _focusInTree() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) {
    return false;
  }
  return context.findAncestorWidgetOfExactType<ListView>() != null;
}

void _focusHeaderOf(WidgetTester tester, String filename) {
  final path = find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is FastFileHeader && w.file.filename == filename,
    ),
    matching: find.byType(FileHeaderPath),
  );
  Focus.of(tester.element(path)).requestFocus();
}

List<SemanticsNode> _allNodes(WidgetTester tester) =>
    find.semantics.byPredicate((_) => true).evaluate().toList();

void main() {
  setUpAll(() => DiffWorkerPool.debugForceInline = true);
  tearDownAll(() => DiffWorkerPool.debugForceInline = false);

  group('diff arrow keys', () {
    testWidgets('↓ walks file headers and never falls into the tree', (
      tester,
    ) async {
      final files = [for (var i = 0; i < 5; i++) _file('lib/f$i.dart')];
      await tester.pumpWidget(_diffBesideTree(files));
      await _settle(tester);

      _focusHeaderOf(tester, 'lib/f0.dart');
      await tester.pump();
      expect(_focusedHeaderFile(), 'lib/f0.dart');

      for (var i = 1; i < files.length; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await _settle(tester);
        expect(_focusInTree(), isFalse, reason: 'step $i left the diff');
        expect(_focusedHeaderFile(), 'lib/f$i.dart');
      }

      // At the last file ↓ stays put rather than leaking out of the diff.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await _settle(tester);
      expect(_focusedHeaderFile(), 'lib/f4.dart');
    });

    testWidgets('↑ walks back to earlier files', (tester) async {
      final files = [for (var i = 0; i < 3; i++) _file('lib/f$i.dart')];
      await tester.pumpWidget(_diffBesideTree(files));
      await _settle(tester);

      _focusHeaderOf(tester, 'lib/f0.dart');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await _settle(tester);
      expect(_focusedHeaderFile(), 'lib/f2.dart');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await _settle(tester);
      expect(_focusedHeaderFile(), 'lib/f1.dart');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await _settle(tester);
      expect(_focusedHeaderFile(), 'lib/f0.dart');
    });

    testWidgets('←/→ move along the header controls and stop at its edge', (
      tester,
    ) async {
      await tester.pumpWidget(_diffBesideTree([_file('lib/a.dart')]));
      await _settle(tester);

      _focusHeaderOf(tester, 'lib/a.dart');
      await tester.pump();
      final row = FocusManager.instance.primaryFocus;

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      final copy = FocusManager.instance.primaryFocus;
      expect(copy, isNot(row));
      expect(
        copy!.context!.findAncestorWidgetOfExactType<CcIconButton>()?.icon,
        AppIcons.copy,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, row);

      // The tree sits to the left; ← at the row's start must not reach it.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, row);
      expect(_focusInTree(), isFalse);
    });
  });

  group('diff semantics', () {
    testWidgets('a file header reads as one heading with the full path', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _diffBesideTree([_file('lib/src/deeply/nested/file.dart')]),
      );
      await _settle(tester);

      final header = _allNodes(tester).firstWhere(
        (n) => n.label.startsWith('lib/src/deeply/nested/file.dart'),
      );
      expect(
        header.label,
        'lib/src/deeply/nested/file.dart, Modified, 5 additions, 2 deletions',
      );
      expect(header.flagsCollection.isHeader, isTrue);
      expect(header.flagsCollection.isExpanded, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('painted code rows are exposed with kind and line number', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _diffBesideTree([
          _file(
            'lib/a.dart',
            patch: '@@ -1,3 +1,3 @@\n unchanged\n-old\n+new\n',
          ),
        ]),
      );
      await _settle(tester);

      final labels = _allNodes(tester).map((n) => n.label).toList();
      expect(labels, contains('Line 1: unchanged'));
      expect(labels, contains('Removed line 2: old'));
      expect(labels, contains('Added line 2: new'));
      handle.dispose();
    });
  });

  group('GapRow', () {
    testWidgets('is a focusable button activated by Enter', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        testWrap(
          GapRow(
            label: 'Show 20 lines',
            icon: AppIcons.chevronDown,
            enabled: true,
            onTap: () => taps++,
          ),
        ),
      );
      final node = Focus.of(tester.element(find.text('Show 20 lines')));
      expect(node.canRequestFocus, isTrue);
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('is not a focus stop while disabled', (tester) async {
      await tester.pumpWidget(
        testWrap(
          GapRow(
            label: 'Show 20 lines',
            icon: AppIcons.chevronDown,
            enabled: false,
            onTap: () {},
          ),
        ),
      );
      final node = Focus.of(tester.element(find.text('Show 20 lines')));
      expect(node.canRequestFocus, isFalse);
    });
  });
}
