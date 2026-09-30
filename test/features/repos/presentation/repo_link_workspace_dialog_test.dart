import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/repos/presentation/repo_link_workspace_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

final _epoch = DateTime.utc(2026);

Workspace _workspace(String id, String name) =>
    Workspace(id: id, name: name, createdAt: _epoch, updatedAt: _epoch);

final _workspaces = [
  _workspace('ws-cc', 'Control Center'),
  _workspace('ws-oss', 'Open source'),
];

/// Opens the dialog from a button and records what it resolves to.
Widget _launcher(void Function(RepoLinkWorkspaceDecision?) onResult) => Builder(
  builder: (context) => CcButton(
    onPressed: () async => onResult(
      await showRepoLinkWorkspaceDialog(
        context: context,
        repoFullName: 'SamuelAlev/control-center',
        workspaces: _workspaces,
        initialWorkspaceId: 'ws-oss',
      ),
    ),
    child: const Text('launch'),
  ),
);

void main() {
  testWidgets('names the repository and preselects the initial workspace', (
    tester,
  ) async {
    await tester.pumpWidget(testWrapWithToastOverlay(_launcher((_) {})));
    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();

    expect(find.textContaining('SamuelAlev/control-center'), findsOneWidget);
    final selected = tester
        .widgetList<CcTile>(find.byType(CcTile))
        .where((tile) => tile.selected);
    expect(selected.map((tile) => tile.title), ['Open source']);
  });

  testWidgets('returns the picked workspace and the remember choice', (
    tester,
  ) async {
    RepoLinkWorkspaceDecision? decision;
    await tester.pumpWidget(
      testWrapWithToastOverlay(_launcher((d) => decision = d)),
    );
    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Control Center'));
    await tester.tap(find.text('Remember my choice for this repository'));
    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(decision?.workspaceId, 'ws-cc');
    expect(decision?.remember, isTrue);
  });

  testWidgets('does not remember unless asked', (tester) async {
    RepoLinkWorkspaceDecision? decision;
    await tester.pumpWidget(
      testWrapWithToastOverlay(_launcher((d) => decision = d)),
    );
    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(decision?.workspaceId, 'ws-oss');
    expect(decision?.remember, isFalse);
  });

  testWidgets('cancelling resolves to null', (tester) async {
    var resolved = false;
    RepoLinkWorkspaceDecision? decision;
    await tester.pumpWidget(
      testWrapWithToastOverlay(
        _launcher((d) {
          resolved = true;
          decision = d;
        }),
      ),
    );
    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(decision, isNull);
  });

  testWidgets('lays out right-to-left without overflowing', (tester) async {
    await tester.pumpWidget(
      testWrapWithToastOverlay(
        _launcher((_) {}),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
      ),
    );
    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final radio = tester.getCenter(find.byType(CcRadio<String>).first);
    final name = tester.getCenter(find.text('Control Center'));
    // The radio leads the row, so under RTL it sits right of the name.
    expect(radio.dx, greaterThan(name.dx));
  });
}
