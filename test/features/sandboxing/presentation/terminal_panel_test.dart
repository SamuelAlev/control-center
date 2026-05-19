import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/keybindings/text_input_surface.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_session_controller.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  /// Decoded bytes of every `terminal.write` this channel received — the
  /// keystrokes the panel forwarded to the PTY.
  final List<List<int>> writes = [];

  /// How many `terminal.spawn` calls this channel served (a respawn after a
  /// lost session shows up as a second one).
  int spawnCount = 0;

  /// How many `terminal.kill` calls this channel served (a disposed session
  /// shows up here; a kept-alive one must NOT).
  int killCount = 0;

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
    }
    if (method == 'sub/subscribe') {
      // No pushes until the test drives them; acknowledge with a per-query
      // subscription id so `output()` / `titles()` streams don't collide.
      final params = (frame['params'] as Map).cast<String, dynamic>();
      final query = params['query'] as String? ?? '';
      final subId = query == 'terminal.titles'
          ? 'fake-sub-titles'
          : 'fake-sub-1';
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

  /// Pushes [bytes] as PTY output on the (sole) fake output subscription —
  /// the base64-framed `sub/snapshot` shape the server emits per PTY chunk.
  void pushOutput(List<int> bytes) {
    _incoming.add({
      'jsonrpc': '2.0',
      'method': 'sub/snapshot',
      'params': {
        'subscriptionId': 'fake-sub-1',
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
      githubAuthTokenProvider.overrideWith((ref) => ''),
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
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
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

  const session = TerminalSession(
    sessionId: 'test-session',
    channelId: 'chan-1',
    workspaceId: 'ws-1',
  );

  group('TerminalPanel initial render', () {
    testWidgets('shows the booting body while the shell starts — no header', (
      tester,
    ) async {
      await setLargeViewport(tester);

      final channel = _FakeChannel()..hangSpawn = true;
      final client = RemoteRpcClient(channel)..start();

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

  group('TerminalPanel against a server that hosts terminal ops', () {
    testWidgets('boots and renders the terminal view', (tester) async {
      await setLargeViewport(tester);

      await tester.pumpWidget(
        _terminalWrap(const TerminalPanel(session: session)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('error'), findsNothing);
    });
  });

  group('TerminalPanel against a server with no terminal ops', () {
    testWidgets('shows the "runs on the server host" placeholder', (
      tester,
    ) async {
      await setLargeViewport(tester);

      final channel = _FakeChannel()..spawnErrorCode = RpcErrorCodes.opUnknown;
      final client = RemoteRpcClient(channel)..start();

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

        final channel = _FakeChannel();
        final client = RemoteRpcClient(channel)..start();
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
        expect(channel.spawnCount, 1);

        channel.pushOutput(utf8.encode('hello-from-kept-shell'));
        await tester.pump();

        // Channel switch: the view unmounts entirely. The session must NOT
        // die with it — no kill, no respawn.
        await tester.pumpWidget(
          _terminalWrap(const SizedBox(), rpcClient: client),
        );
        await tester.pumpAndSettle();
        expect(
          channel.spawnCount,
          1,
          reason: 'unmounting the view must not respawn the shell',
        );
        expect(
          channel.killCount,
          0,
          reason: 'unmounting the view must not kill the server PTY',
        );

        // Back on the channel: a fresh view reattaches to the same session.
        await tester.pumpWidget(
          _terminalWrap(
            TerminalSessionView(controller: controller),
            rpcClient: client,
          ),
        );
        await tester.pumpAndSettle();
        expect(channel.spawnCount, 1);
        expect(channel.killCount, 0);
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

      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)..start();
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
      expect(channel.spawnCount, 1);

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
      expect(channel.spawnCount, 1);
      expect(channel.killCount, 0);
    });
  });

  group('TerminalPanel callbacks', () {
    testWidgets('accepts onShellExit callback without crashing', (
      tester,
    ) async {
      await setLargeViewport(tester);

      await tester.pumpWidget(
        _terminalWrap(TerminalPanel(session: session, onShellExit: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TerminalView), findsOneWidget);
    });

    testWidgets(
      'respawns in place when the server no longer knows the session',
      (tester) async {
        await setLargeViewport(tester);

        final channel = _FakeChannel();
        final client = RemoteRpcClient(channel)..start();
        var exits = 0;

        await tester.pumpWidget(
          _terminalWrap(
            TerminalPanel(session: session, onShellExit: () => exits++),
            rpcClient: client,
          ),
        );
        await tester.pumpAndSettle();
        expect(channel.spawnCount, 1);

        // A cc_server restart kills every PTY; the subscription replayed on
        // reconnect names a session the new process never minted, so the host
        // rejects it with notFound.
        channel.pushSubError('fake-sub-1', RpcErrorCodes.notFound);
        await tester.pumpAndSettle();

        expect(
          channel.spawnCount,
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

      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)..start();
      final titles = <String>[];

      await tester.pumpWidget(
        _terminalWrap(
          TerminalPanel(session: session, onTitleChange: titles.add),
          rpcClient: client,
        ),
      );
      await tester.pumpAndSettle();

      // The escape wezterm/ghostty/iTerm honor: OSC 0 (icon+title), BEL-ended.
      channel.pushOutput(utf8.encode('\x1b]0;my-shell-title\x07'));
      await tester.pump();

      expect(titles, ['my-shell-title']);
    });

    testWidgets('titles the tab after the foreground process, ghostty-style', (
      tester,
    ) async {
      await setLargeViewport(tester);

      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)..start();
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
      channel.pushTitle('pnpm dev serve');
      await tester.pump();
      expect(titles, ['pnpm dev serve']);

      // The command ends (shell back at its prompt): the tab falls back to
      // its default label.
      channel.pushTitle('');
      await tester.pump();
      expect(titles, ['pnpm dev serve', '']);
    });

    testWidgets(
      'a new foreground process replaces a stale prompt-time OSC title, '
      'and the process\'s own OSC wins again',
      (tester) async {
        await setLargeViewport(tester);

        final channel = _FakeChannel();
        final client = RemoteRpcClient(channel)..start();
        final titles = <String>[];

        await tester.pumpWidget(
          _terminalWrap(
            TerminalPanel(session: session, onTitleChange: titles.add),
            rpcClient: client,
          ),
        );
        await tester.pumpAndSettle();

        // The shell titles the terminal at its prompt (a precmd hook)…
        channel.pushOutput(utf8.encode('\x1b]0;~/repo\x07'));
        await tester.pump();
        // …then a long build starts. The prompt-time title is stale — exactly
        // the reported bug — so the foreground process replaces it.
        channel.pushTitle('cargo build');
        await tester.pump();
        // A program that retitles itself DURING the run (vim, claude) wins over
        // the plain process name.
        channel.pushOutput(utf8.encode('\x1b]2;claude – fixing tests\x07'));
        await tester.pump();

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

        final channel = _FakeChannel();
        final client = RemoteRpcClient(channel)..start();
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
          channel.writes.map(utf8.decode),
          contains('a'),
          reason:
              'a plain printable key must reach the PTY via '
              'terminal.write even when the macOS IME path declines the '
              'key event',
        );

        // Command-modified strokes stay out of the PTY (app shortcuts own
        // them).
        channel.writes.clear();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await tester.pump();
        expect(channel.writes.map(utf8.decode), isNot(contains('a')));

        // Let the tap gesture's double-tap disambiguation timer expire so no
        // timer is pending when the binding verifies invariants.
        await tester.pump(const Duration(seconds: 1));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('renders inside a TextInputSurface so typing reaches the IME', (
      tester,
    ) async {
      await setLargeViewport(tester);

      await tester.pumpWidget(
        _terminalWrap(const TerminalPanel(session: session)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextInputSurface), findsOneWidget);
    });

    testWidgets('renders with provided agentId', (tester) async {
      await setLargeViewport(tester);

      await tester.pumpWidget(
        _terminalWrap(
          const TerminalPanel(
            session: TerminalSession(
              sessionId: 'test-session',
              channelId: 'chan-1',
              workspaceId: 'ws-1',
              agentId: 'agent-42',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // agentId is metadata only — widget still renders.
      expect(find.byType(TerminalView), findsOneWidget);
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
