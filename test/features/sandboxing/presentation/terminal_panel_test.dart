import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart'
    show workspaceFilesystemPortProvider;
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:xterm/xterm.dart';

import '../../../fakes/fake_filesystem_port.dart';

/// Wraps a widget with all overrides needed by `TerminalPanel`, plus the
/// baseline overrides from `testWrap` (to suppress side effects).
///
/// Sets a generous viewport to avoid RenderFlex overflow in error bodies.
Widget _terminalWrap(Widget child) {
  return ProviderScope(
    overrides: [
      // testWrap baseline overrides
      githubAuthTokenProvider.overrideWith((ref) => ''),
      activeWorkspaceProvider.overrideWith((ref) => null),
      activeRepoProvider.overrideWith((ref) => null),
      prReviewRepositoryProvider
          .overrideWith((ref) => const EmptyPrReviewRepository()),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      // TerminalPanel-specific overrides
      activeSandboxBackendProvider
          .overrideWithValue(SandboxBackend.none),
      codeFontFamilyProvider.overrideWithValue('monospace'),
      workspaceFilesystemPortProvider.overrideWithValue(_fs),
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

final _fs = FakeFilesystemPort();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
  });

  /// Sets a 1024×768 viewport so error bodies fit without overflow.
  Future<void> setLargeViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    // Pump a frame so the binding picks up the new size.
    await tester.pump();
  }

  group('TerminalPanel initial render', () {
    testWidgets('shows header with backend label', (tester) async {
      await setLargeViewport(tester);

      await tester.pumpWidget(_terminalWrap(
        const TerminalPanel(
          session: TerminalSession(
            sessionId: 'test-session',
            agentDirHostPath: '/tmp/test-agent',
            workspaceId: 'ws-1',
          ),
        ),
      ));

      // Before pump, widget is in initial state: _booting=false, _error=null.
      // The header shows: "Terminal · No isolation"
      expect(find.textContaining('Terminal'), findsOneWidget);
      expect(find.textContaining('No isolation'), findsOneWidget);

      // The restart button is an CcButton.icon with a Lucide rotateCcw icon.
      // CcButton renders as an CcButton widget.
      expect(find.byType(CcButton), findsOneWidget);
    });

    testWidgets('shows TerminalView before boot starts', (tester) async {
      await setLargeViewport(tester);

      await tester.pumpWidget(_terminalWrap(
        const TerminalPanel(
          session: TerminalSession(
            sessionId: 'test-session',
            agentDirHostPath: '/tmp/test-agent',
            workspaceId: 'ws-1',
          ),
        ),
      ));

      // TerminalView is rendered (xterm package) when _booting=false and
      // _error=null. This is the initial state before post-frame callback
      // triggers _boot(). The TerminalView renders a keyboard listener
      // and the xterm canvas.
      expect(find.byType(TerminalView), findsOneWidget);
    });
  });

  group('TerminalPanel after boot failure', () {
    testWidgets('shows error state with retry button', (tester) async {
      await setLargeViewport(tester);

      await tester.pumpWidget(_terminalWrap(
        const TerminalPanel(
          session: TerminalSession(
            sessionId: 'test-session',
            agentDirHostPath: '/tmp/test-agent',
            workspaceId: 'ws-1',
          ),
        ),
      ));

      // Pump to trigger post-frame callback → _boot() runs.
      // Pty.start() throws synchronously in test env, so the error
      // state is reached immediately.
      await tester.pump();

      // Header text updates to show "error"
      expect(find.textContaining('error'), findsOneWidget);

      // Error body shows the retry button
      expect(find.text('Retry'), findsOneWidget);

      // Error body shows the triangle-alert icon (Lucide)
      expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);
    });

    testWidgets('retry button triggers reboot', (tester) async {
      await setLargeViewport(tester);

      await tester.pumpWidget(_terminalWrap(
        const TerminalPanel(
          session: TerminalSession(
            sessionId: 'test-session',
            agentDirHostPath: '/tmp/test-agent',
            workspaceId: 'ws-1',
          ),
        ),
      ));

      // Let boot fail
      await tester.pump();

      // Verify we're in error state
      expect(find.text('Retry'), findsOneWidget);

      // Tap retry — triggers _boot() again
      await tester.tap(find.text('Retry'));
      // Pump to process the tap animation timer and the synchronous
      // _boot() failure (PTY start throws synchronously in test env).
      await tester.pump(const Duration(milliseconds: 200));

      // Widget still renders (doesn't crash on retry)
      expect(find.textContaining('Terminal'), findsOneWidget);
    });
  });

  group('TerminalPanel callbacks', () {
    testWidgets('accepts onShellExit callback', (tester) async {
      await setLargeViewport(tester);

      await tester.pumpWidget(_terminalWrap(
        TerminalPanel(
          session: const TerminalSession(
            sessionId: 'test-session',
            agentDirHostPath: '/tmp/test-agent',
            workspaceId: 'ws-1',
          ),
          onShellExit: () {},
        ),
      ));

      // Let boot fail
      await tester.pump();

      // Widget renders without crashing
      expect(find.textContaining('Terminal'), findsOneWidget);
    });

    testWidgets('renders with provided agentId', (tester) async {
      await setLargeViewport(tester);

      await tester.pumpWidget(_terminalWrap(
        const TerminalPanel(
          session: TerminalSession(
            sessionId: 'test-session',
            agentDirHostPath: '/tmp/test-agent',
            workspaceId: 'ws-1',
            agentId: 'agent-42',
          ),
        ),
      ));

      await tester.pump();

      // agentId is metadata only — widget still renders
      expect(find.textContaining('Terminal'), findsOneWidget);
    });
  });
}
