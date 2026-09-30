import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/repos/presentation/unlinked_repo_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

final _epoch = DateTime.utc(2026);

final _current = Workspace(
  id: 'ws-oss',
  name: 'Open source',
  createdAt: _epoch,
  updatedAt: _epoch,
);

/// Opens the dialog from a button and records what it resolves to.
Widget _launcher(
  void Function(UnlinkedRepoAction?) onResult, {
  Workspace? currentWorkspace,
}) => Builder(
  builder: (context) => CcButton(
    onPressed: () async => onResult(
      await showUnlinkedRepoDialog(
        context: context,
        repoFullName: 'SamuelAlev/control-center',
        currentWorkspace: currentWorkspace,
      ),
    ),
    child: const Text('launch'),
  ),
);

void main() {
  testWidgets('names the repository and preselects the current workspace', (
    tester,
  ) async {
    UnlinkedRepoAction? action;
    await tester.pumpWidget(
      testWrapWithToastOverlay(
        _launcher((a) => action = a, currentWorkspace: _current),
      ),
    );
    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();

    expect(find.textContaining('SamuelAlev/control-center'), findsOneWidget);
    final selected = tester
        .widgetList<CcTile>(find.byType(CcTile))
        .where((tile) => tile.selected);
    expect(selected.map((tile) => tile.title), ['Add to Open source']);

    await tester.tap(find.text('Add repository'));
    await tester.pumpAndSettle();

    expect(action, UnlinkedRepoAction.addToCurrentWorkspace);
  });

  testWidgets('picking a new workspace relabels the action and returns it', (
    tester,
  ) async {
    UnlinkedRepoAction? action;
    await tester.pumpWidget(
      testWrapWithToastOverlay(
        _launcher((a) => action = a, currentWorkspace: _current),
      ),
    );
    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New workspace'));
    await tester.pump();
    expect(find.text('Add repository'), findsNothing);
    await tester.tap(find.text('Add workspace'));
    await tester.pumpAndSettle();

    expect(action, UnlinkedRepoAction.createWorkspace);
  });

  testWidgets('without a current workspace only creating one is offered', (
    tester,
  ) async {
    UnlinkedRepoAction? action;
    await tester.pumpWidget(
      testWrapWithToastOverlay(_launcher((a) => action = a)),
    );
    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();

    expect(find.byType(CcTile), findsOneWidget);
    expect(find.textContaining('Add to'), findsNothing);
    await tester.tap(find.text('Add workspace'));
    await tester.pumpAndSettle();

    expect(action, UnlinkedRepoAction.createWorkspace);
  });

  testWidgets('cancelling resolves to null', (tester) async {
    var resolved = false;
    UnlinkedRepoAction? action;
    await tester.pumpWidget(
      testWrapWithToastOverlay(
        _launcher((a) {
          resolved = true;
          action = a;
        }, currentWorkspace: _current),
      ),
    );
    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(resolved, isTrue);
    expect(action, isNull);
  });

  testWidgets('lays out right-to-left without overflowing', (tester) async {
    await tester.pumpWidget(
      testWrapWithToastOverlay(
        _launcher((_) {}, currentWorkspace: _current),
        locale: const Locale('ar'),
        textDirection: TextDirection.rtl,
      ),
    );
    await tester.tap(find.text('launch'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final radio = tester.getCenter(
      find.byType(CcRadio<UnlinkedRepoAction>).first,
    );
    final title = tester.getCenter(find.textContaining('Open source'));
    // The radio leads the row, so under RTL it sits right of the title.
    expect(radio.dx, greaterThan(title.dx));
  });
}
