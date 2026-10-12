import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_session_controller.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xterm/xterm.dart' show TerminalView;

/// In-memory [RemoteRpcChannelPort] that answers `terminal.*` ops directly,
/// without a real transport — lets the panel's RPC round trips be driven from
/// the test instead of needing a live `cc_server`.
class _FakeChannel implements RemoteRpcChannelPort {
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  final _stateCtl = StreamController<RemoteChannelState>.broadcast();
  bool _open = true;

  /// When set, `terminal.spawn` replies with this RPC error code instead of a
  /// session id (used to exercise the "unavailable" / generic-error paths).
  int? spawnErrorCode;

  /// When true, `terminal.spawn` never replies — keeps the panel in its
  /// booting state for assertions on the pre-boot render.
  bool hangSpawn = false;

  /// Decoded bytes of every `terminal.write` this space received — the
  /// keystrokes the panel forwarded to the PTY.
  final List<List<int>> writes = [];

  /// How many `terminal.spawn` calls this space served (a respawn after a
  /// lost session shows up as a second one).
  int spawnCount = 0;

  /// How many `terminal.kill` calls this space served (a disposed session
  /// shows up here; a kept-alive one must NOT).
  int killCount = 0;

  int _outputSubscriptions = 0;

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Stream<RemoteChannelState> get state => _stateCtl.stream;

  @override
  bool get isOpen => _open;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    final method = frame['method'] as String?;
    final id = frame['id'];
    if (method == 'repo/call') {
      final params = (frame['params'] as Map).cast<String, dynamic>();
      final op = params['op'] as String?;
      if (op == 'terminal.spawn') {
        final code = spawnErrorCode;
        if (code != null) {
          _incoming.add({
            'jsonrpc': '2.0',
            'id': id,
            'error': {'code': code, 'message': 'terminal unavailable'},
          });
        } else if (!hangSpawn) {
          spawnCount++;
          _incoming.add({
            'jsonrpc': '2.0',
            'id': id,
            'result': {
              'data': {'session_id': 'fake-session-$spawnCount'},
            },
          });
        }
        return;
      }
      if (op == 'terminal.kill') {
        killCount++;
      }
      if (op == 'terminal.write') {
        final args = (params['args'] as Map?)?.cast<String, dynamic>();
        final data = args?['data'] as String?;
        if (data != null) {
          writes.add(base64Decode(data));
        }
      }
      if (op == 'terminal.kill' ||
          op == 'terminal.write' ||
          op == 'terminal.resize') {
        _incoming.add({
          'jsonrpc': '2.0',
          'id': id,
          'result': {'data': <String, dynamic>{}},
        });
        return;
      }
      // Host-shell port affordances issue `terminal.*Port*` calls; answer
      // them so pumpAndSettle cannot hang on an unanswered RPC.
      if (id != null) {
        _incoming.add({
          'jsonrpc': '2.0',
          'id': id,
          'result': {'data': <String, dynamic>{}},
        });
      }
    }
    if (method == 'sub/subscribe') {
      // Subscription ids are unique across respawns, as on a real server:
      // an old stream's late frames must not be routed to its replacement.
      final params = (frame['params'] as Map).cast<String, dynamic>();
      final query = params['query'] as String? ?? '';
      final subId = switch (query) {
        'terminal.titles' => 'fake-sub-titles',
        'terminal.watchPorts' => 'fake-sub-ports',
        'rig.watchPorts' => 'fake-sub-rig-ports',
        _ => 'fake-sub-${++_outputSubscriptions}',
      };
      _incoming.add({
        'jsonrpc': '2.0',
        'id': id,
        'result': {'subscriptionId': subId},
      });
      return;
    }
    if (method == 'sub/unsubscribe') {
      _incoming.add({
        'jsonrpc': '2.0',
        'id': id,
        'result': <String, dynamic>{},
      });
    }
  }

  /// Pushes [bytes] as PTY output on the current fake output subscription —
  /// the base64-framed `sub/snapshot` shape the server emits per PTY chunk.
  void pushOutput(List<int> bytes) {
    _incoming.add({
      'jsonrpc': '2.0',
      'method': 'sub/snapshot',
      'params': {
        'subscriptionId': 'fake-sub-$_outputSubscriptions',
        'data': {'chunk': base64Encode(bytes)},
      },
    });
  }

  /// Pushes [title] as a foreground-process title event on the fake
  /// `terminal.titles` subscription — the shape the server's `ps` polling
  /// emits when the PTY's foreground process group changes.
  void pushTitle(String title) {
    _incoming.add({
      'jsonrpc': '2.0',
      'method': 'sub/snapshot',
      'params': {
        'subscriptionId': 'fake-sub-titles',
        'data': {'title': title},
      },
    });
  }

  /// Pushes the `sub/error` frame the host sends when a watch query fails —
  /// [code] `notFound` is what an unknown terminal session id yields after a
  /// `cc_server` restart.
  void pushSubError(String subscriptionId, int code) {
    _incoming.add({
      'jsonrpc': '2.0',
      'method': 'sub/error',
      'params': {
        'subscriptionId': subscriptionId,
        'code': code,
        'data': {'kind': 'stream_error'},
      },
    });
  }

  @override
  Future<void> close() async {
    _open = false;
    _stateCtl.add(RemoteChannelState.closed);
    await _incoming.close();
    await _stateCtl.close();
  }
}

Widget _terminalWrap(Widget child, {RemoteRpcClient? rpcClient}) {
  final client = rpcClient ?? (RemoteRpcClient(_FakeChannel())..start());
  return ProviderScope(
    overrides: [
      activeWorkspaceProvider.overrideWith((ref) => null),
      activeRepoProvider.overrideWith((ref) => null),
      prReviewRepositoryProvider.overrideWith(
        (ref) => const EmptyPrReviewRepository(),
      ),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      rpcClientProvider.overrideWithValue(client),
    ],
    child: MaterialApp(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(body: child),
      ),
    ),
  );
}

String _terminalText(TerminalSessionController controller) {
  final lines = controller.terminal.buffer.lines;
  return [for (var i = 0; i < lines.length; i++) lines[i].getText()].join();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setLargeViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pump();
  }

  void closePanelAfterTest(WidgetTester tester, RemoteRpcClient client) {
    addTearDown(() async {
      // Widget disposal starts asynchronous subscription cancellation and PTY
      // teardown. Drain those replies before closing the transport or checking
      // the binding's pending-timer invariant.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await client.close();
    });
  }

  const session = TerminalSession(
    sessionId: 'test-session',
    spaceId: 'chan-1',
    workspaceId: 'ws-1',
  );

  group('terminal byte ingestion', () {
    testWidgets('decodes split UTF-8 and ANSI escapes in order while hidden', (
      tester,
    ) async {
      final space = _FakeChannel();
      final client = RemoteRpcClient(space)..start();
      final controller = TerminalSessionController(
        session: session,
        rpcClient: client,
      );
      addTearDown(controller.dispose);
      await controller.ensureBooted();
      await tester.pump();
      controller.updateVisibility(false);
      final titles = <String>[];
      controller.onTitleChange = titles.add;

      final glyph = utf8.encode('€');
      space.pushOutput([
        ...utf8.encode('\x1b[3'),
        0x31,
        0x6d,
        ...glyph.take(1),
      ]);
      space.pushOutput([...glyph.skip(1), ...utf8.encode('red\x1b[0')]);
      space.pushOutput(utf8.encode('m\x1b]0;hidden-'));
      space.pushOutput(utf8.encode('title\x07!'));
      final supplementary = utf8.encode('🔐');
      for (var split = 1; split < supplementary.length; split++) {
        space.pushOutput(supplementary.sublist(0, split));
        space.pushOutput(supplementary.sublist(split));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(_terminalText(controller), contains('€red!🔐🔐🔐'));
      expect(titles, ['hidden-title']);
      expect(space.killCount, 0);
      controller.updateVisibility(true);
      expect(_terminalText(controller), contains('€red!🔐🔐🔐'));
    });

    testWidgets('replaces malformed bytes and one incomplete end tail', (
      tester,
    ) async {
      final space = _FakeChannel();
      final client = RemoteRpcClient(space)..start();
      final controller = TerminalSessionController(
        session: session,
        rpcClient: client,
      );
      addTearDown(controller.dispose);
      await controller.ensureBooted();
      await tester.pump();

      space.pushOutput([0xc3]);
      space.pushOutput([0x28, 0x20, 0xe2]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(_terminalText(controller), contains('�( '));
      expect(_terminalText(controller), isNot(contains('�( �')));

      // A server-side subscription EOF flushes the incomplete UTF-8 tail.
      // Closing the whole RPC client would prevent terminal.kill during
      // disposal from receiving its acknowledgement.
      space.pushSubError('fake-sub-1', RpcErrorCodes.notFound);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      final text = _terminalText(controller);
      expect(text, contains('�( �'));
      expect(text.indexOf('�( �'), lessThan(text.indexOf('session ended')));
    });

    testWidgets('bounds each xterm notification and drains a burst fully', (
      tester,
    ) async {
      final space = _FakeChannel();
      final client = RemoteRpcClient(space)..start();
      final controller = TerminalSessionController(
        session: session,
        rpcClient: client,
      );
      addTearDown(controller.dispose);
      await controller.ensureBooted();
      await tester.pump();
      final deliveredAt = <int>[];
      controller.terminal.addListener(
        () => deliveredAt.add(_terminalText(controller).length),
      );
      const payload = 96 * 1024;
      for (var i = 0; i < 96; i++) {
        space.pushOutput(List<int>.filled(1024, 0x58));
      }
      await tester.pump();
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 1));
      }

      expect(
        _terminalText(controller),
        String.fromCharCodes(List<int>.filled(payload, 0x58)),
      );
      expect(deliveredAt, isNotEmpty);
      expect(deliveredAt.first, greaterThan(0));
      expect(deliveredAt.first, lessThanOrEqualTo(16 * 1024));
      expect(deliveredAt.last, payload);
      for (var i = 1; i < deliveredAt.length; i++) {
        expect(
          deliveredAt[i] - deliveredAt[i - 1],
          lessThanOrEqualTo(16 * 1024),
        );
      }
      expect(deliveredAt.length, lessThan(96));
    });

    testWidgets('keeps a supplementary rune whole at a drain boundary', (
      tester,
    ) async {
      final space = _FakeChannel();
      final client = RemoteRpcClient(space)..start();
      final controller = TerminalSessionController(
        session: session,
        rpcClient: client,
      );
      addTearDown(controller.dispose);
      await controller.ensureBooted();
      await tester.pump();

      final prefix = String.fromCharCodes(
        List<int>.filled(16 * 1024 - 1, 0x61),
      );
      final text = '$prefix😀Z';
      final bytes = utf8.encode(text);
      space.pushOutput(bytes.sublist(0, 16 * 1024 + 1));
      space.pushOutput(bytes.sublist(16 * 1024 + 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));

      expect(_terminalText(controller), text);
    });

    test('restart and dispose discard queued old-stream output', () async {
      final space = _FakeChannel();
      final client = RemoteRpcClient(space)..start();
      addTearDown(client.close);
      final controller = TerminalSessionController(
        session: session,
        rpcClient: client,
      );
      addTearDown(controller.dispose);
      await controller.ensureBooted();
      // The fake channel and RPC fan-out dispatch asynchronously. One event
      // turn after boot lets the subscribe acknowledgement reach its listener.
      await Future<void>.delayed(Duration.zero);
      expect(space._outputSubscriptions, 1);

      // One xterm notification drains at most 16 Ki characters. Restart from
      // that first notification: the suffix is still queued in the controller,
      // while the incomplete UTF-8 code point remains in its old decoder.
      final oldPrefix = String.fromCharCodes(List<int>.filled(16 * 1024, 0x78));
      final restartStarted = Completer<void>();
      late Future<void> restart;
      void restartOnFirstDrain() {
        if (restartStarted.isCompleted) {
          return;
        }
        restart = controller.restart();
        restartStarted.complete();
      }

      controller.terminal.addListener(restartOnFirstDrain);
      space.pushOutput(utf8.encode('$oldPrefix discarded-old-tail'));
      space.pushOutput([0xe2]);
      await restartStarted.future;
      controller.terminal.removeListener(restartOnFirstDrain);
      await restart;
      expect(_terminalText(controller), '');
      expect(space.killCount, 1);
      expect(space.spawnCount, 2);

      // A fresh subscription must get a distinct server id. Deliver the old
      // stream's trailing bytes explicitly as well as the new stream's bytes.
      await Future<void>.delayed(Duration.zero);
      expect(space._outputSubscriptions, 2);
      space.pushSubError('fake-sub-1', RpcErrorCodes.notFound);
      final freshOutput = Completer<void>();
      void observeFreshOutput() {
        if (!freshOutput.isCompleted &&
            _terminalText(controller) == '��new-stream') {
          freshOutput.complete();
        }
      }

      controller.terminal.addListener(observeFreshOutput);
      space.pushOutput([0x82, 0xac]);
      space.pushOutput(utf8.encode('new-stream'));
      await freshOutput.future;
      controller.terminal.removeListener(observeFreshOutput);
      expect(_terminalText(controller), '��new-stream');

      final disposePrefix = String.fromCharCodes(
        List<int>.filled(16 * 1024, 0x79),
      );
      final disposeStarted = Completer<void>();
      late Future<void> dispose;
      void disposeOnFirstDrain() {
        if (disposeStarted.isCompleted) {
          return;
        }
        dispose = controller.dispose();
        disposeStarted.complete();
      }

      controller.terminal.addListener(disposeOnFirstDrain);
      space.pushOutput(utf8.encode('$disposePrefix pending-after-dispose'));
      await disposeStarted.future;
      controller.terminal.removeListener(disposeOnFirstDrain);
      await dispose;
      space.pushOutput(utf8.encode('late-after-dispose'));
      await Future<void>.delayed(Duration.zero);
      // The first drain happened before disposal; neither its queued suffix
      // nor a subsequent server push can add bytes to the disposed terminal.
      expect(_terminalText(controller), '��new-stream$disposePrefix');
      expect(space.killCount, 2);
      expect(space.spawnCount, 2);
    });

    testWidgets('drains output before a lost-session notice and respawn', (
      tester,
    ) async {
      final space = _FakeChannel();
      final client = RemoteRpcClient(space)..start();
      final controller = TerminalSessionController(
        session: session,
        rpcClient: client,
      );
      addTearDown(controller.dispose);
      await controller.ensureBooted();
      await tester.pump();

      space.pushOutput(utf8.encode('last-old-output'));
      space.pushOutput([0xe2]); // Incomplete final code point on the dead PTY.
      space.pushSubError('fake-sub-1', RpcErrorCodes.notFound);
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 1));
      }
      final text = _terminalText(controller);
      expect(text, contains('last-old-output�'));
      expect(text.indexOf('�'), lessThan(text.indexOf('session ended')));
      expect(space.spawnCount, 2);
      expect(space.killCount, 0);
    });
  });

  group('TerminalPanel initial render', () {
    testWidgets('shows the booting body while the shell starts — no header', (
      tester,
    ) async {
      await setLargeViewport(tester);

      final space = _FakeChannel()..hangSpawn = true;
      final client = RemoteRpcClient(space)..start();

      await tester.pumpWidget(
        _terminalWrap(const TerminalPanel(session: session), rpcClient: client),
      );
      // The post-frame boot kicks; the spawn never answers, so the panel
      // stays in its booting state.
      await tester.pump();

      expect(find.textContaining('starting shell'), findsOneWidget);
      // The redundant pane header ("Terminal · server host" + restart icon)
      // is gone: restart lives on the tab's context menu.
      expect(find.textContaining('Terminal · server host'), findsNothing);
      expect(find.byType(CcIconButton), findsNothing);

      // Flush the spawn's own request timeout (the spawn never answers) so no
      // timer outlives the test. NOT the client-wide 30s: `terminal.spawn`
      // overrides it to 180s, because a `microvm` spawn legitimately boots a
      // VM and syncs a worktree first — see RemoteTerminalRepository.
      await tester.pump(const Duration(seconds: 181));
    });
  });

  group('TerminalPanel against a server with no terminal ops', () {
    testWidgets('shows the "runs on the server host" placeholder', (
      tester,
    ) async {
      await setLargeViewport(tester);

      final space = _FakeChannel()..spawnErrorCode = RpcErrorCodes.opUnknown;
      final client = RemoteRpcClient(space)..start();

      await tester.pumpWidget(
        _terminalWrap(const TerminalPanel(session: session), rpcClient: client),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('not available on this server'),
        findsOneWidget,
      );
    });
  });

  group('keep-alive', () {
    testWidgets(
      'unmounting the view keeps the session alive; a fresh view reattaches '
      'with the buffer intact',
      (tester) async {
        await setLargeViewport(tester);

        final space = _FakeChannel();
        final client = RemoteRpcClient(space)..start();
        final controller = TerminalSessionController(
          session: session,
          rpcClient: client,
        );
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          _terminalWrap(
            TerminalSessionView(controller: controller),
            rpcClient: client,
          ),
        );
        await tester.pumpAndSettle();
        expect(space.spawnCount, 1);

        space.pushOutput(utf8.encode('hello-from-kept-shell'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));

        // Space switch: the view unmounts entirely. The session must NOT
        // die with it — no kill, no respawn.
        await tester.pumpWidget(
          _terminalWrap(const SizedBox(), rpcClient: client),
        );
        await tester.pumpAndSettle();
        expect(
          space.spawnCount,
          1,
          reason: 'unmounting the view must not respawn the shell',
        );
        expect(
          space.killCount,
          0,
          reason: 'unmounting the view must not kill the server PTY',
        );

        // Back on the space: a fresh view reattaches to the same session.
        await tester.pumpWidget(
          _terminalWrap(
            TerminalSessionView(controller: controller),
            rpcClient: client,
          ),
        );
        await tester.pumpAndSettle();
        expect(space.spawnCount, 1);
        expect(space.killCount, 0);
        expect(find.byType(TerminalView), findsOneWidget);

        // The scrollback pushed before the unmount survived in the retained
        // xterm buffer (xterm paints cells; assert on the buffer directly).
        final lines = controller.terminal.buffer.lines;
        final bufferText = [
          for (var i = 0; i < lines.length; i++) lines[i].getText(),
        ].join('\n');
        expect(bufferText, contains('hello-from-kept-shell'));
      },
    );

    testWidgets('a re-attached view does not respawn a running shell', (
      tester,
    ) async {
      await setLargeViewport(tester);

      final space = _FakeChannel();
      final client = RemoteRpcClient(space)..start();
      final controller = TerminalSessionController(
        session: session,
        rpcClient: client,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _terminalWrap(
          TerminalSessionView(controller: controller),
          rpcClient: client,
        ),
      );
      await tester.pumpAndSettle();
      expect(space.spawnCount, 1);

      // Unmount → remount → unmount → remount: ensureBooted is idempotent for
      // a live session.
      for (var i = 0; i < 2; i++) {
        await tester.pumpWidget(
          _terminalWrap(const SizedBox(), rpcClient: client),
        );
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          _terminalWrap(
            TerminalSessionView(controller: controller),
            rpcClient: client,
          ),
        );
        await tester.pumpAndSettle();
      }
      expect(space.spawnCount, 1);
      expect(space.killCount, 0);
    });
  });

  group('TerminalPanel callbacks', () {
    testWidgets(
      'respawns in place when the server no longer knows the session',
      (tester) async {
        await setLargeViewport(tester);

        final space = _FakeChannel();
        final client = RemoteRpcClient(space)..start();
        closePanelAfterTest(tester, client);
        var exits = 0;

        await tester.pumpWidget(
          _terminalWrap(
            TerminalPanel(session: session, onShellExit: () => exits++),
            rpcClient: client,
          ),
        );
        await tester.pumpAndSettle();
        expect(space.spawnCount, 1);

        // A cc_server restart kills every PTY; the subscription replayed on
        // reconnect names a session the new process never minted, so the host
        // rejects it with notFound.
        space.pushSubError('fake-sub-1', RpcErrorCodes.notFound);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pumpAndSettle();

        expect(
          space.spawnCount,
          2,
          reason: 'a lost session must be replaced with a fresh shell in place',
        );
        expect(
          exits,
          0,
          reason:
              'a session lost with the server is not a user shell exit — '
              'reporting one closes the tab out from under the user',
        );
      },
    );

    testWidgets('forwards the shell title (OSC 0/2) via onTitleChange', (
      tester,
    ) async {
      await setLargeViewport(tester);

      final space = _FakeChannel();
      final client = RemoteRpcClient(space)..start();
      closePanelAfterTest(tester, client);
      final titles = <String>[];

      await tester.pumpWidget(
        _terminalWrap(
          TerminalPanel(session: session, onTitleChange: titles.add),
          rpcClient: client,
        ),
      );
      await tester.pumpAndSettle();

      // The escape wezterm/ghostty/iTerm honor: OSC 0 (icon+title), BEL-ended.
      space.pushOutput(utf8.encode('\x1b]0;my-shell-title\x07'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(titles, ['my-shell-title']);
    });

    testWidgets('titles the tab after the foreground process, ghostty-style', (
      tester,
    ) async {
      await setLargeViewport(tester);

      final space = _FakeChannel();
      final client = RemoteRpcClient(space)..start();
      closePanelAfterTest(tester, client);
      final titles = <String>[];

      await tester.pumpWidget(
        _terminalWrap(
          TerminalPanel(session: session, onTitleChange: titles.add),
          rpcClient: client,
        ),
      );
      await tester.pumpAndSettle();

      // A long-running command takes the PTY's foreground: the server-polled
      // title retitles the tab even though the shell emitted no OSC at all.
      space.pushTitle('pnpm dev serve');
      await tester.pump();
      expect(titles, ['pnpm dev serve']);

      // The command ends (shell back at its prompt): the tab falls back to
      // its default label.
      space.pushTitle('');
      await tester.pump();
      expect(titles, ['pnpm dev serve', '']);
    });

    testWidgets(
      'a new foreground process replaces a stale prompt-time OSC title, '
      'and the process\'s own OSC wins again',
      (tester) async {
        await setLargeViewport(tester);

        final space = _FakeChannel();
        final client = RemoteRpcClient(space)..start();
        closePanelAfterTest(tester, client);
        final titles = <String>[];

        await tester.pumpWidget(
          _terminalWrap(
            TerminalPanel(session: session, onTitleChange: titles.add),
            rpcClient: client,
          ),
        );
        await tester.pumpAndSettle();

        // The shell titles the terminal at its prompt (a precmd hook)…
        space.pushOutput(utf8.encode('\x1b]0;~/repo\x07'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        // …then a long build starts. The prompt-time title is stale — exactly
        // the reported bug — so the foreground process replaces it.
        space.pushTitle('cargo build');
        await tester.pump();
        // A program that retitles itself DURING the run (vim, claude) wins over
        // the plain process name.
        space.pushOutput(utf8.encode('\x1b]2;claude – fixing tests\x07'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));

        expect(titles, ['~/repo', 'cargo build', 'claude – fixing tests']);
      },
    );

    testWidgets('macOS hardware keys type into the PTY without the IME', (
      tester,
    ) async {
      // Reset inline (not addTearDown): the binding verifies foundation debug
      // variables BEFORE tearDowns run.
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await setLargeViewport(tester);

        final space = _FakeChannel();
        final client = RemoteRpcClient(space)..start();
        closePanelAfterTest(tester, client);
        await tester.pumpWidget(
          _terminalWrap(
            const TerminalPanel(session: session),
            rpcClient: client,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(TerminalView), warnIfMissed: false);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.pump();

        expect(
          space.writes.map(utf8.decode),
          contains('a'),
          reason:
              'a plain printable key must reach the PTY via '
              'terminal.write even when the macOS IME path declines the '
              'key event',
        );

        // Command-modified strokes stay out of the PTY (app shortcuts own
        // them).
        space.writes.clear();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await tester.pump();
        expect(space.writes.map(utf8.decode), isNot(contains('a')));

        // Let the tap gesture's double-tap disambiguation timer expire so no
        // timer is pending when the binding verifies invariants.
        await tester.pump(const Duration(seconds: 1));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('a drag selection takes focus so ⌘C copies it', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await setLargeViewport(tester);
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );

        final space = _FakeChannel();
        final client = RemoteRpcClient(space)..start();
        closePanelAfterTest(tester, client);
        // Something else holds focus first — the chat composer, in the app.
        final elsewhere = FocusNode();
        addTearDown(elsewhere.dispose);
        await tester.pumpWidget(
          _terminalWrap(
            Column(
              children: [
                Focus(focusNode: elsewhere, child: const SizedBox(height: 20)),
                const Expanded(child: TerminalPanel(session: session)),
              ],
            ),
            rpcClient: client,
          ),
        );
        await tester.pumpAndSettle();
        space.pushOutput(utf8.encode('hello world\r\n'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        elsewhere.requestFocus();
        await tester.pump();

        // A quick mouse drag: the drag wins the arena before xterm's tap-down
        // (its only focus request) fires.
        final origin = tester.getTopLeft(find.byType(TerminalView));
        final drag = await tester.startGesture(
          origin + const Offset(4, 6),
          kind: PointerDeviceKind.mouse,
        );
        await drag.moveBy(const Offset(40, 0));
        await drag.moveBy(const Offset(10, 0));
        await drag.up();
        await tester.pump();

        expect(elsewhere.hasFocus, isFalse);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await tester.pump();

        expect(copied, startsWith('hello'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  group('CcTerminalStyle', () {
    test('resolves the bundled mono font and pins the weight axis', () {
      final style = CcTerminalStyle(
        family: AppFonts.codeFamily,
        fontSize: 13,
        height: 1.35,
      );

      final regular = style.toTextStyle();
      expect(regular.fontFamily, AppFonts.codeFamily);
      expect(regular.fontWeight, FontWeight.normal);
      expect(
        regular.fontVariations,
        contains(const FontVariation('wght', 400)),
      );

      // Bold must be a real instanced weight (wght 700), never a synthetic
      // embolden of the variable font's default instance.
      final bold = style.toTextStyle(bold: true);
      expect(bold.fontFamily, AppFonts.codeFamily);
      expect(bold.fontWeight, FontWeight.bold);
      expect(bold.fontVariations, contains(const FontVariation('wght', 700)));
    });
  });
}
