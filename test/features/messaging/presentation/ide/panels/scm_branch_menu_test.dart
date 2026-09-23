import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/scm_branch_menu.dart';
import 'package:control_center/features/messaging/providers/space_stack_provider.dart';
import 'package:control_center/features/messaging/providers/worktree_file_ops_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

const _emptyRefs = (
  current: 'main',
  detached: false,
  refs: <WorktreeRefEntry>[],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('stack layers are numbered bottom to top', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ScmBranchMenu(
          branch: 'move-catalog',
          enabled: true,
          load: () async => _emptyRefs,
          onCheckout: (_) async {},
          layers: const [
            SpaceStackLayer(
              repoId: 'repo-1',
              position: 1,
              branch: 'conv/6b2256bb--move-catalog',
              baseBranch: 'conv/6b2256bb',
              label: 'move-catalog',
              current: true,
              prNumber: 4,
            ),
            SpaceStackLayer(
              repoId: 'repo-1',
              position: 0,
              branch: 'conv/6b2256bb',
              baseBranch: 'main',
              label: '6b2256bb',
              current: false,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('move-catalog'));
    await tester.pumpAndSettle();

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .toList();
    final bottom = texts.indexOf('6b2256bb');
    final one = texts.indexOf('1/2');
    final top = texts.indexOf('move-catalog #4');
    final two = texts.indexOf('2/2');
    expect(bottom, greaterThanOrEqualTo(0));
    expect(bottom, lessThan(one));
    expect(one, lessThan(top));
    expect(top, lessThan(two));
    expect(find.byIcon(AppIcons.layers), findsNWidgets(2));
  });

  testWidgets('a single layer stays out of the menu', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ScmBranchMenu(
          branch: 'main',
          enabled: true,
          load: () async => _emptyRefs,
          onCheckout: (_) async {},
          layers: const [
            SpaceStackLayer(
              repoId: 'repo-1',
              position: 0,
              branch: 'main',
              baseBranch: 'main',
              label: 'secret-layer',
              current: true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('main'));
    await tester.pumpAndSettle();

    expect(find.text('secret-layer'), findsNothing);
    expect(find.text('STACK'), findsNothing);
  });

  testWidgets('a long branch name stays inside the chip', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ScmBranchMenu(
          branch: 'conv/6b2256bb--move-catalog',
          enabled: true,
          load: () async => _emptyRefs,
          onCheckout: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  });
}
