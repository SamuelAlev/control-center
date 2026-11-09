import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_terminal_sessions.dart';
import 'package:control_center/features/messaging/presentation/ide/messaging_ide_tabs.dart';
import 'package:control_center/features/sandboxing/providers/terminal_registry_provider.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/host/editor_layout_codec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_rpc_client.dart';

void main() {
  late ProviderContainer container;
  late IdeTerminalSessions sessions;
  late int notifications;
  final l10n = AppLocalizationsEn();

  TerminalRegistryState registry() => container.read(terminalRegistryProvider);

  setUp(() {
    container = ProviderContainer(
      overrides: [rpcClientProvider.overrideWithValue(fakeRpcClient())],
    );
    sessions = IdeTerminalSessions(
      registry: () => container.read(terminalRegistryProvider.notifier),
      registryState: registry,
      mintSessionId: () => 'minted',
    );
    notifications = 0;
    sessions.addListener(() => notifications++);
  });

  tearDown(() {
    sessions.dispose();
    container.dispose();
  });

  /// Claims [tab]'s session the way the IDE's terminal pane does.
  void claim(
    EditorTab tab, {
    bool stillOpen = true,
    void Function(String)? onExit,
  }) {
    expect(sessions.beginClaim(tab), isTrue);
    sessions.completeClaim(
      tab,
      spaceId: 'space-1',
      workspaceId: 'ws-1',
      stillOpen: stillOpen,
      onShellExit: onExit ?? (_) {},
    );
  }

  test('a tab claims its session from the registry exactly once', () {
    final tab = MessagingIdeTabs.terminal('t1');

    expect(sessions.beginClaim(tab), isTrue);
    // A second build before the claim lands schedules nothing more.
    expect(sessions.beginClaim(tab), isFalse);
    final controller = sessions.completeClaim(
      tab,
      spaceId: 'space-1',
      workspaceId: 'ws-1',
      stillOpen: true,
      onShellExit: (_) {},
    );

    expect(controller, isNotNull);
    expect(sessions.controllerFor(tab), same(controller));
    expect(controller!.session.sessionId, 't1');
    expect(controller.session.spaceId, 'space-1');
    expect(registry().controllers.keys, ['t1']);
    expect(sessions.claimedSessionIds, {'t1'});
    expect(sessions.beginClaim(tab), isFalse);
    expect(notifications, 1);
  });

  test('a legacy tab without a session id gets a fresh one', () {
    const legacy = EditorTab(kind: 'terminal', label: 'Terminal');
    claim(legacy);
    expect(sessions.controllerFor(legacy)!.session.sessionId, 'minted');
  });

  test('a tab closed before its claim landed kills the session', () {
    final tab = MessagingIdeTabs.terminal('t1');
    claim(tab, stillOpen: false);

    expect(sessions.controllerFor(tab), isNull);
    expect(registry().controllers, isEmpty);
    // Nothing is pending, so a reopened tab would claim again.
    expect(sessions.beginClaim(tab), isTrue);
  });

  test('a restored enclosed terminal waits for its Start press', () {
    const tab = EditorTab(
      kind: 'terminal',
      label: 'Terminal',
      args: {
        'termSessionId': 'vm',
        'backend': 'microvm',
        EditorLayoutCodec.deferStartArg: true,
      },
    );

    expect(sessions.awaitsStart(tab), isTrue);
    expect(sessions.beginClaim(tab), isFalse);

    sessions.start(tab);
    expect(notifications, 1);
    expect(sessions.awaitsStart(tab), isFalse);
    claim(tab);
    expect(sessions.controllerFor(tab)!.session.backend, 'microvm');
  });

  group('reconcile', () {
    test('a user close kills the shell', () {
      final tab = MessagingIdeTabs.terminal('t1');
      claim(tab);

      sessions.reconcile(Set.identity(), killOrphaned: true);

      expect(sessions.controllerFor(tab), isNull);
      expect(registry().controllers, isEmpty);
    });

    test('a close the user chose to keep detaches the shell', () {
      final tab = MessagingIdeTabs.terminal('t1');
      claim(tab);
      sessions.keepShell(tab);

      sessions.reconcile(Set.identity(), killOrphaned: true);

      expect(sessions.controllerFor(tab), isNull);
      final kept = registry().controllers['t1'];
      expect(kept, isNotNull);
      expect(kept!.onTitleChange, isNull);
      // Its row in TERMINALS is the way back to it.
      expect(sessions.mirrorsFor('space-1').single.sessionId, 't1');
      // Exiting while detached ends it: there is no tab to close.
      kept.onShellExit!();
      expect(registry().controllers, isEmpty);
    });

    test('a layout swap keeps the shell for the tab that re-claims it', () {
      final tab = MessagingIdeTabs.terminal('t1');
      claim(tab);
      final controller = sessions.controllerFor(tab);

      sessions.reconcile(Set.identity(), killOrphaned: false);
      expect(registry().controllers['t1'], same(controller));

      // The restored tab (a new instance with the same session id).
      final restored = MessagingIdeTabs.terminal('t1');
      claim(restored);
      expect(sessions.controllerFor(restored), same(controller));
    });

    test('a keep decision does not survive a layout swap', () {
      final tab = MessagingIdeTabs.terminal('t1');
      claim(tab);
      sessions
        ..keepShell(tab)
        ..forgetKeptShells()
        ..reconcile(Set.identity(), killOrphaned: true);
      expect(registry().controllers, isEmpty);
    });

    test('live tabs keep their claims', () {
      final tab = MessagingIdeTabs.terminal('t1');
      claim(tab);
      sessions.reconcile(Set.identity()..add(tab), killOrphaned: true);
      expect(sessions.controllerFor(tab), isNotNull);
    });
  });

  group('titles', () {
    test('a live shell title labels the tab until cleared', () {
      final tab = MessagingIdeTabs.terminal('t1');
      claim(tab);
      expect(sessions.label(tab, l10n), l10n.terminal);

      sessions.controllerFor(tab)!.terminal.onTitleChange!('pnpm dev');
      expect(sessions.label(tab, l10n), 'pnpm dev');
      expect(notifications, 2);

      // The same title again changes nothing.
      sessions.setTitle(tab, ' pnpm dev ');
      expect(notifications, 2);

      // The shell clears its title: back to the default label.
      sessions.controllerFor(tab)!.terminal.onTitleChange!('');
      expect(sessions.label(tab, l10n), l10n.terminal);
    });

    test('an unclaimed restored tab reads its kept shell title', () {
      final tab = MessagingIdeTabs.terminal('t1');
      claim(tab);
      sessions.controllerFor(tab)!.terminal.onTitleChange!('vim');
      sessions.reconcile(Set.identity(), killOrphaned: false);

      final restored = MessagingIdeTabs.terminal('t1');
      expect(sessions.label(restored, l10n), 'vim');
    });

    test('an environment process keeps its name until it titles itself', () {
      final tab = MessagingIdeTabs.environmentTerminal('proc', 'web');
      expect(sessions.label(tab, l10n), 'web');
    });
  });

  test('ending a shell closes its tab, or kills a tabless one', () {
    final tab = MessagingIdeTabs.terminal('t1');
    claim(tab);
    sessions.keepShell(tab);
    expect(sessions.end('t1'), same(tab));
    // The trash is explicit: the keep decision no longer applies.
    sessions.reconcile(Set.identity(), killOrphaned: true);
    expect(registry().controllers, isEmpty);

    final other = MessagingIdeTabs.terminal('t2');
    claim(other);
    sessions.reconcile(Set.identity(), killOrphaned: false);
    expect(sessions.end('t2'), isNull);
    expect(registry().controllers, isEmpty);
  });

  test('an exited shell closes its tab, or is killed when hidden', () {
    final exits = <String>[];
    final tab = MessagingIdeTabs.terminal('t1');
    claim(tab, onExit: exits.add);
    sessions.controllerFor(tab)!.onShellExit!();
    expect(exits, ['t1']);
    expect(sessions.shellExited('t1'), same(tab));

    sessions.reconcile(Set.identity(), killOrphaned: false);
    expect(sessions.shellExited('t1'), isNull);
    expect(registry().controllers, isEmpty);
  });

  test('mirrors list this space only', () {
    final tab = MessagingIdeTabs.terminal('t1');
    claim(tab);
    expect(sessions.mirrorsFor('space-1').map((m) => m.sessionId), ['t1']);
    expect(sessions.mirrorsFor('space-2'), isEmpty);
  });

  test('a disposed host ignores late title events', () {
    final tab = MessagingIdeTabs.terminal('t1');
    claim(tab);
    final controller = sessions.controllerFor(tab)!;
    sessions.dispose();
    // The controller outlives the IDE in the registry.
    expect(() => controller.terminal.onTitleChange!('late'), returnsNormally);
    sessions = IdeTerminalSessions(
      registry: () => container.read(terminalRegistryProvider.notifier),
      registryState: registry,
    );
  });
}
