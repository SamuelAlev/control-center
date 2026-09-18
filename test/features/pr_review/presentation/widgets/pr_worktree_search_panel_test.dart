import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/messaging/providers/repo_content_search_provider.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_worktree_search_panel.dart';
import 'package:control_center/features/pr_review/providers/pr_worktree_search_provider.dart';
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

Widget _wrap(
  Widget child, {
  required List<FileContentMatch> Function(WorktreeContentSearchArgs args)
  search,
}) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      prWorktreeSearchProvider.overrideWith((ref, args) async => search(args)),
    ],
    child: testWrap(SizedBox(width: 360, height: 640, child: child)),
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
  });
}
