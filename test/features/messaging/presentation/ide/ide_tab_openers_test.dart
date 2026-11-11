import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_conversation_tabs.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_host.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_tab_openers.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_terminal_sessions.dart';
import 'package:control_center/features/messaging/presentation/ide/messaging_ide_tabs.dart';
import 'package:control_center/features/sandboxing/providers/terminal_registry_provider.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_rpc_client.dart';
import '../../../../helpers/test_wrap.dart';

class _Host implements IdeHost {
  _Host(this.context, this.ref, this.layout, this.terminals);

  @override
  final BuildContext context;

  @override
  final WidgetRef ref;

  @override
  EditorLayoutController layout;

  @override
  final IdeTerminalSessions terminals;

  @override
  bool mounted = true;

  @override
  String? selectedSpaceId = 'space';

  @override
  String get hostWorkspaceId => 'ws';

  @override
  String? get activeWorkspaceId => 'ws';

  @override
  IdeConversationView get conversations => const IdeConversationView();
}

EditorTab _selected(EditorLayoutController layout) {
  final group = layout.activeLeaf.controller;
  return group.tabs[group.selectedIndex];
}

void main() {
  late _Host host;
  late IdeTabOpeners open;
  late int publishes;

  Future<void> pump(WidgetTester tester, {bool canUseHost = true}) async {
    final group = EditorTabGroupController()
      ..insert(0, MessagingIdeTabs.chat('space'));
    final layout = EditorLayoutController.single(controller: group);
    addTearDown(layout.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rpcClientProvider.overrideWithValue(fakeRpcClient()),
          canUseHostProvider.overrideWithValue(canUseHost),
        ],
        child: testWrap(
          Consumer(
            builder: (context, ref, _) {
              host = _Host(
                context,
                ref,
                layout,
                IdeTerminalSessions(
                  registry: () => ref.read(terminalRegistryProvider.notifier),
                  registryState: () => ref.read(terminalRegistryProvider),
                ),
              );
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    publishes = 0;
    open = IdeTabOpeners(
      host,
      defaultEditorRepoId: () => 'repo-1',
      publishTerminals: () => publishes++,
    );
  }

  testWidgets('a worktree file opens once and is refocused after', (
    tester,
  ) async {
    await pump(tester);
    const file = (repoId: 'repo-1', path: 'lib/main.dart');

    open.openWorktreeFile(file);
    final tab = _selected(host.layout);
    expect(tab.kind, MessagingTabKinds.codeServer);
    expect(tab.label, 'main.dart');
    expect(tab.args['spaceId'], 'space');

    host.layout.focusTab((t) => t.kind == MessagingTabKinds.chat);
    open.openWorktreeFile(file);
    expect(host.layout.allTabs(), hasLength(2));
    expect(_selected(host.layout), same(tab));
  });

  testWidgets('the bare editor opens on the default repo, once', (
    tester,
  ) async {
    await pump(tester);
    open
      ..openEditor()
      ..openEditor();
    final editors = host.layout.allTabs().where(
      (t) => t.kind == MessagingTabKinds.codeServer,
    );
    expect(editors.single.args['repoId'], 'repo-1');
  });

  testWidgets('without host access there is no editor: files open read-only', (
    tester,
  ) async {
    await pump(tester, canUseHost: false);
    open.openEditor();
    expect(host.layout.allTabs(), hasLength(1));

    open.openWorktreeFile((repoId: 'repo-1', path: 'lib/main.dart'));
    expect(
      host.layout.allTabs().where(
        (t) => t.kind == MessagingTabKinds.codeServer,
      ),
      isEmpty,
    );
    expect(_selected(host.layout).kind, MessagingTabKinds.file);
  });

  testWidgets('nothing opens without a space', (tester) async {
    await pump(tester);
    host.selectedSpaceId = null;
    open
      ..openEditor()
      ..openWorktreeFile((repoId: 'r', path: 'a.txt'));
    expect(host.layout.allTabs(), hasLength(1));
  });

  testWidgets('a tab-body request de-dupes across the tree next frame', (
    tester,
  ) async {
    await pump(tester);
    const plan = EditorTab(
      kind: MessagingTabKinds.plan,
      label: 'Plan',
      dedupKey: 'plan:1',
    );
    open.openFromScope(plan);
    expect(host.layout.allTabs(), hasLength(1));
    await tester.pump();
    expect(host.layout.allTabs(), hasLength(2));

    open.openFromScope(
      const EditorTab(
        kind: MessagingTabKinds.plan,
        label: 'Plan',
        dedupKey: 'plan:1',
      ),
    );
    await tester.pump();
    expect(host.layout.allTabs(), hasLength(2));

    // An IDE gone by the next frame opens nothing.
    host.mounted = false;
    open.openFromScope(MessagingIdeTabs.newTerminal());
    await tester.pump();
    expect(host.layout.allTabs(), hasLength(2));
  });

  testWidgets('a TERMINALS row re-opens the tab of its kept session', (
    tester,
  ) async {
    await pump(tester);
    open.focusOrOpenTerminal('gone');
    final fresh = _selected(host.layout);
    expect(fresh.kind, MessagingTabKinds.terminal);
    expect(fresh.args['termSessionId'], isNot('gone'));

    open.focusOrOpenTerminal(fresh.args['termSessionId'] as String);
    expect(host.layout.allTabs(), hasLength(2));
  });

  testWidgets('trashing a tabless shell republishes the mirror', (
    tester,
  ) async {
    await pump(tester);
    open.killTerminal('nobody');
    expect(publishes, 1);
  });
}
