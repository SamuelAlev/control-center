import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/messaging/providers/repo_content_search_provider.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_worktree_search_panel.dart';
import 'package:control_center/features/pr_review/providers/pr_worktree_search_provider.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

const _inPr = (
  repoId: 'repo',
  relativePath: 'lib/in_pr.dart',
  lines: [(line: 4, text: 'needle here')],
);

const _outside = (
  repoId: 'repo',
  relativePath: 'lib/outside.dart',
  lines: [(line: 1, text: 'needle outside')],
);

const _rootFile = (
  repoId: 'repo',
  relativePath: 'lock.yaml',
  lines: [
    (line: 10, text: 'needle a'),
    (line: 20, text: 'needle b'),
    (line: 30, text: 'needle c'),
  ],
);

Widget _wrap(
  Widget child, {
  required List<FileContentMatch> Function(WorktreeContentSearchArgs args)
  search,
  TextDirection? textDirection,
}) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      prWorktreeSearchProvider.overrideWith((ref, args) async => search(args)),
    ],
    child: testWrap(
      SizedBox(width: 360, height: 640, child: child),
      textDirection: textDirection,
    ),
  );
}

PrWorktreeSearchPanel _panel({
  required void Function(String path, {int? line}) onOpenResult,
}) {
  return PrWorktreeSearchPanel(
    workspaceId: 'ws',
    spaceId: 'space',
    repoId: 'repo',
    focusToken: 1,
    onShowFileTree: () {},
    onOpenResult: onOpenResult,
    prTouchedPaths: const {'lib/in_pr.dart'},
  );
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(CcTextField), query);
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pumpAndSettle();
}

void main() {
  group('PrWorktreeSearchPanel', () {
    testWidgets('defaults to PR files; footer expands to the whole repo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _panel(onOpenResult: (_, {int? line}) {}),
          search: (args) {
            const mixed = <FileContentMatch>[_inPr, _outside];
            if (args.wholeRepo) {
              return mixed;
            }
            final allowed = args.pathsKey.split('\n').toSet();
            return mixed
                .where((h) => allowed.contains(h.relativePath))
                .toList();
          },
        ),
      );
      await tester.pumpAndSettle();
      await _search(tester, 'needle');

      expect(find.text('in_pr.dart'), findsOneWidget);
      expect(find.text('outside.dart'), findsNothing);
      expect(find.text('Search in the whole repo'), findsOneWidget);

      await tester.tap(find.text('Search in the whole repo'));
      await tester.pumpAndSettle();

      expect(find.text('in_pr.dart'), findsOneWidget);
      expect(find.text('outside.dart'), findsOneWidget);
      expect(find.text('Search in this pull request'), findsOneWidget);
    });

    testWidgets('tapping an in-PR match reports path and line', (tester) async {
      String? openedPath;
      int? openedLine;
      await tester.pumpWidget(
        _wrap(
          _panel(
            onOpenResult: (path, {int? line}) {
              openedPath = path;
              openedLine = line;
            },
          ),
          search: (args) {
            if (args.wholeRepo) {
              return const [_inPr, _outside];
            }
            return const [_inPr];
          },
        ),
      );
      await tester.pumpAndSettle();
      await _search(tester, 'needle');

      expect(find.text('in_pr.dart'), findsOneWidget);
      await tester.tap(find.text('4'));
      await tester.pump();

      expect(openedPath, 'lib/in_pr.dart');
      expect(openedLine, 4);
    });

    testWidgets('file match count pins to the trailing edge in LTR and RTL', (
      tester,
    ) async {
      Future<void> pump(TextDirection direction) async {
        await tester.pumpWidget(
          _wrap(
            _panel(onOpenResult: (_, {int? line}) {}),
            textDirection: direction,
            search: (_) => const [_rootFile],
          ),
        );
        await tester.pumpAndSettle();
        await _search(tester, 'needle');
      }

      await pump(TextDirection.ltr);
      final ltrPanel = tester.getRect(find.byType(PrWorktreeSearchPanel));
      final ltrCount = tester.getRect(find.text('3'));
      // Row end inset (8) + badge horizontal padding (6).
      expect(ltrPanel.right - ltrCount.right, lessThan(20));
      expect(
        ltrCount.left - tester.getTopRight(find.text('lock.yaml')).dx,
        greaterThan(40),
      );

      await pump(TextDirection.rtl);
      final rtlPanel = tester.getRect(find.byType(PrWorktreeSearchPanel));
      final rtlCount = tester.getRect(find.text('3'));
      expect(rtlCount.left - rtlPanel.left, lessThan(20));
      expect(
        tester.getTopLeft(find.text('lock.yaml')).dx - rtlCount.right,
        greaterThan(40),
      );
    });

    testWidgets('match rows start at the file icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _panel(onOpenResult: (_, {int? line}) {}),
          search: (_) => const [_rootFile],
        ),
      );
      await tester.pumpAndSettle();
      await _search(tester, 'needle');

      final icon = tester.getTopLeft(find.byIcon(AppIcons.fileCode));
      final line = tester.getTopRight(find.text('10'));
      final name = tester.getTopLeft(find.text('lock.yaml'));
      // 28px line-number slot starting at the icon, just in front of the name.
      expect(line.dx, closeTo(icon.dx + 28, 2));
      expect(line.dx, lessThan(name.dx + 28));
    });
  });
}
