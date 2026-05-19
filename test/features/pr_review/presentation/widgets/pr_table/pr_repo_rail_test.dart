import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_repo_rail.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

Repo _repo({required String id, required String name}) => Repo(
  id: id,
  name: name,
  path: '/tmp/$name',
  githubOwner: 'Frontify',
  githubRepoName: name,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

void main() {
  final frontend = _repo(id: '1', name: 'frontend-components');
  final appServer = _repo(id: '2', name: 'app-server');

  Widget rail({String? selected}) => SizedBox(
    width: 224,
    child: PrRepoRail(
      entries: [(repo: frontend, count: 70), (repo: appServer, count: 78)],
      selectedRepoId: selected,
      onSelect: (_) {},
    ),
  );

  testWidgets('shows owner/repo names and counts', (tester) async {
    await tester.pumpWidget(testWrap(rail()));

    expect(find.text('Frontify/frontend-components'), findsOneWidget);
    expect(find.text('Frontify/app-server'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    expect(find.text('78'), findsOneWidget);
  });

  testWidgets(
    'selected label keeps the idle weight so SkWasm does not ellipsize',
    (tester) async {
      await tester.pumpWidget(testWrap(rail(selected: frontend.id)));

      final selected = tester.widget<Text>(
        find.text('Frontify/frontend-components'),
      );
      final idle = tester.widget<Text>(find.text('Frontify/app-server'));
      expect(selected.style!.fontWeight, FontWeight.w500);
      expect(idle.style!.fontWeight, FontWeight.w500);
    },
  );

  testWidgets('selected name is laid out across the rail, not a stub width', (
    tester,
  ) async {
    await tester.pumpWidget(testWrap(rail(selected: frontend.id)));

    final box = tester.getRect(find.text('Frontify/frontend-components'));
    // A premature ellipsis ("Frontif...") is ~50px. The 224px rail minus
    // padding, gap, and count leaves well over 100px for the label.
    expect(box.width, greaterThan(100));
  });

  testWidgets('selected row uses an opaque canvas-blended wash', (
    tester,
  ) async {
    await tester.pumpWidget(testWrap(rail(selected: frontend.id)));

    final tokens = DesignSystemTokens.light();
    final expected = Color.alphaBlend(tokens.hoverStrong, tokens.canvas);
    expect(expected.a, 1.0);

    final washes = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .where((box) => box.color == expected);
    expect(washes, hasLength(1));
  });
}
