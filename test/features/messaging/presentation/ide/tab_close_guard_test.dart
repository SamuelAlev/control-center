import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/tab_close_guard.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_session_controller.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

class _Host implements TabCloseHost {
  _Host(this.context, this.ref);

  @override
  final BuildContext context;

  @override
  final WidgetRef ref;

  @override
  bool mounted = true;

  final kept = <EditorTab>[];

  /// Each archive request: the tab and whether its agents were just stopped.
  final archived = <(EditorTab, bool)>[];

  @override
  String? get closeGuardWorkspaceId => 'ws';

  @override
  String? get closeGuardSpaceId => 'space';

  @override
  String? get closeGuardStandingConversationId => null;

  @override
  bool isTabDirty(EditorTab tab) => false;

  @override
  TerminalSessionController? terminalFor(EditorTab tab) => null;

  @override
  void keepShell(EditorTab tab) => kept.add(tab);

  @override
  void archiveClosedConversation(EditorTab tab, {bool agentsStopped = false}) =>
      archived.add((tab, agentsStopped));

  @override
  String terminalLabel(EditorTab tab, AppLocalizations l10n) => tab.label;

  @override
  String chatLabel(EditorTab tab, AppLocalizations l10n) => tab.label;
}

class _StopRecordingPort implements MessagingPort {
  final stopped = <String>[];

  @override
  Future<void> stopRun(String workspaceId, String runLogId) async =>
      stopped.add(runLogId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _chatTab = EditorTab(
  kind: MessagingTabKinds.chat,
  label: 'Design review',
  args: {'spaceId': 'space', 'conversationId': 'conv-1'},
);

void main() {
  Future<_Host> pumpHost(
    WidgetTester tester, {
    List<AgentRunLog> activeRuns = const [],
    MessagingPort? messaging,
  }) async {
    late _Host host;
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            conversationActiveRunsProvider((
              workspaceId: 'ws',
              conversationId: 'conv-1',
            )).overrideWith((ref) => Stream.value(activeRuns)),
            if (messaging != null)
              messagingServiceProvider.overrideWithValue(messaging),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              host = _Host(context, ref);
              // The IDE's chat body keeps the runs watched while it is open.
              ref.watch(
                conversationActiveRunsProvider((
                  workspaceId: 'ws',
                  conversationId: 'conv-1',
                )),
              );
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    return host;
  }

  AgentRunLog run(String id) => AgentRunLog(
    id: id,
    agentId: 'a1',
    workspaceId: 'ws',
    conversationId: 'conv-1',
    startedAt: DateTime(2026, 11, 10),
    status: RunStatus.running,
  );

  testWidgets('closing a quiet chat tab archives its conversation', (
    tester,
  ) async {
    final host = await pumpHost(tester);

    expect(await TabCloseGuard(host).confirmClose(_chatTab), isTrue);
    expect(host.archived, [(_chatTab, false)]);
  });

  testWidgets('keeping an agent running keeps its conversation active', (
    tester,
  ) async {
    final host = await pumpHost(tester, activeRuns: [run('run-1')]);
    final l10n = AppLocalizations.of(host.context);

    final closing = TabCloseGuard(host).confirmClose(_chatTab);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.ideCloseKeepRunning));
    await tester.pumpAndSettle();

    expect(await closing, isTrue);
    expect(host.archived, isEmpty);
  });

  testWidgets('stopping the agents archives the conversation', (tester) async {
    final port = _StopRecordingPort();
    final host = await pumpHost(
      tester,
      activeRuns: [run('run-1'), run('run-2')],
      messaging: port,
    );
    final l10n = AppLocalizations.of(host.context);

    final closing = TabCloseGuard(host).confirmClose(_chatTab);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.ideCloseStopAgent));
    await tester.pumpAndSettle();

    expect(await closing, isTrue);
    expect(port.stopped, ['run-1', 'run-2']);
    expect(host.archived, [(_chatTab, true)]);
  });

  testWidgets('cancelling the prompt neither closes nor archives', (
    tester,
  ) async {
    final host = await pumpHost(tester, activeRuns: [run('run-1')]);
    final l10n = AppLocalizations.of(host.context);

    final closing = TabCloseGuard(host).confirmClose(_chatTab);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();

    expect(await closing, isFalse);
    expect(host.archived, isEmpty);
  });

  testWidgets('a tab with no live work and no unsaved file closes at once', (
    tester,
  ) async {
    final host = await pumpHost(tester);
    final guard = TabCloseGuard(host);

    expect(
      await guard.confirmClose(
        const EditorTab(kind: MessagingTabKinds.browser, label: 'Docs'),
      ),
      isTrue,
    );
    // An idle shell (no attached controller) closes without a prompt and is
    // not kept.
    expect(
      await guard.confirmClose(
        const EditorTab(kind: MessagingTabKinds.terminal, label: 'zsh'),
      ),
      isTrue,
    );
    expect(host.kept, isEmpty);
  });

  testWidgets('an IDE that unmounted while asking closes nothing', (
    tester,
  ) async {
    final host = await pumpHost(tester)
      ..mounted = false;

    expect(
      await TabCloseGuard(host).confirmClose(
        const EditorTab(kind: MessagingTabKinds.browser, label: 'Docs'),
      ),
      isFalse,
    );
  });
}
