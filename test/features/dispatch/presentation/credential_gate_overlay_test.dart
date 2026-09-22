import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show RunCredentialBlockDto, RunCredentialLane, RunCredentialReason;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/widgets/credential_gate_overlay.dart';
import 'package:control_center/features/dispatch/providers/credential_gate_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

RunCredentialBlockDto _block({
  String id = 'cg-1',
  RunCredentialLane lane = RunCredentialLane.claudeCode,
  RunCredentialReason reason = RunCredentialReason.planSpent,
  String detail = '[claude] this Claude Code account is out of plan headroom.',
  String? agentName = 'Ada',
}) => RunCredentialBlockDto(
  id: id,
  lane: lane,
  reason: reason,
  detail: detail,
  runLogId: 'run-1',
  createdAt: DateTime.utc(2026, 8, 31, 12),
  workspaceId: 'ws-1',
  agentName: agentName,
  accountIds: const ['work'],
);

Future<void> _pump(
  WidgetTester tester,
  Stream<List<RunCredentialBlockDto>> blocks,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [blockedRunsProvider.overrideWith((ref) => blocks)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CcTheme(
          data: CcThemeData.light(),
          child: const Scaffold(body: CredentialGateOverlay()),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders nothing while no run is parked', (tester) async {
    await _pump(tester, Stream.value(const <RunCredentialBlockDto>[]));
    await tester.pumpAndSettle();

    expect(find.byType(CcDialog), findsNothing);
  });

  testWidgets('opens a dialog naming the specific problem', (tester) async {
    final controller = StreamController<List<RunCredentialBlockDto>>();
    addTearDown(controller.close);
    await _pump(tester, controller.stream);

    controller.add([_block()]);
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // The plan-limit title, not a generic "credential problem": the four
    // reasons have four different fixes.
    expect(find.text(l10n.credentialGatePlanSpentTitle), findsOneWidget);
    // The server's own sentence, so the dialog and the transcript agree.
    expect(
      find.text('[claude] this Claude Code account is out of plan headroom.'),
      findsOneWidget,
    );
    expect(find.text(l10n.credentialGateWaitingAgent('Ada')), findsOneWidget);
    expect(find.text(l10n.credentialGateCancelRun), findsOneWidget);
    expect(find.text(l10n.credentialGateCheckAgain), findsOneWidget);
  });

  testWidgets('closes itself when the block leaves the stream', (tester) async {
    final controller = StreamController<List<RunCredentialBlockDto>>();
    addTearDown(controller.close);
    await _pump(tester, controller.stream);

    controller.add([_block()]);
    await tester.pumpAndSettle();
    expect(find.byType(CcDialog), findsOneWidget);

    // The credential started working: the server resolved the block and the
    // run is already going again. Nothing left to ask, so the modal has to get
    // out of the way by itself — nobody should have to dismiss a question that
    // has already been answered.
    controller.add(const []);
    await tester.pumpAndSettle();

    expect(find.byType(CcDialog), findsNothing);
  });

  testWidgets('does not re-open over a block it already handled', (
    tester,
  ) async {
    final controller = StreamController<List<RunCredentialBlockDto>>();
    addTearDown(controller.close);
    await _pump(tester, controller.stream);

    controller.add([_block()]);
    await tester.pumpAndSettle();
    controller.add(const []);
    await tester.pumpAndSettle();
    // A resolved block can linger for a frame while the server's next snapshot
    // is in flight. Re-opening on it would put a modal over a dead run.
    controller.add([_block()]);
    await tester.pumpAndSettle();

    expect(find.byType(CcDialog), findsNothing);
  });

  testWidgets('a harness block names the provider', (tester) async {
    final controller = StreamController<List<RunCredentialBlockDto>>();
    addTearDown(controller.close);
    await _pump(tester, controller.stream);

    controller.add([
      RunCredentialBlockDto(
        id: 'cg-2',
        lane: RunCredentialLane.harness,
        reason: RunCredentialReason.noCredential,
        detail: '[harness] No credential for provider "anthropic".',
        runLogId: 'run-2',
        createdAt: DateTime.utc(2026, 8, 31, 12),
        workspaceId: 'ws-1',
        providerId: 'anthropic',
      ),
    ]);
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(
      find.text(l10n.credentialGateHarnessTitle('anthropic')),
      findsOneWidget,
    );
    // No agent name on this one — the run is still described, not skipped.
    expect(find.text(l10n.credentialGateWaitingRun), findsOneWidget);
  });

  testWidgets('open settings reaches Claude Code and back resumes the run', (
    tester,
  ) async {
    final controller = StreamController<List<RunCredentialBlockDto>>();
    addTearDown(controller.close);
    final router = GoRouter(
      initialLocation: '/workspaces/ws-1/spaces/sp-1',
      routes: [
        ShellRoute(
          builder: (_, _, child) =>
              Stack(children: [child, const CredentialGateOverlay()]),
          routes: [
            GoRoute(
              path: '/workspaces/:workspaceId/spaces/:spaceId',
              builder: (_, _) => const Text('space'),
            ),
            GoRoute(
              path: '/workspaces/:workspaceId/settings/server/providers',
              builder: (_, state) =>
                  Text('adapters:${state.uri.queryParameters['adapter']}'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          blockedRunsProvider.overrideWith((ref) => controller.stream),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      ),
    );

    controller.add([
      _block(
        reason: RunCredentialReason.signedOut,
        detail: '[claude] this Claude Code account is signed out.',
      ),
    ]);
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text(l10n.credentialGateOpenSettings));
    await tester.pumpAndSettle();

    expect(find.byType(CcDialog), findsNothing);
    expect(find.text('adapters:claude-code'), findsOneWidget);

    router.go('/workspaces/ws-1/spaces/sp-1');
    await tester.pumpAndSettle();

    // Still signed out: the dialog comes back, the run was not dropped.
    expect(find.text('space'), findsOneWidget);
    expect(find.byType(CcDialog), findsOneWidget);
    expect(find.text(l10n.credentialGateSignedOutTitle), findsOneWidget);
  });

  testWidgets(
    'leaving settings after the credential lands stays on the space',
    (tester) async {
      final controller = StreamController<List<RunCredentialBlockDto>>();
      addTearDown(controller.close);
      final router = GoRouter(
        initialLocation: '/workspaces/ws-1/spaces/sp-1',
        routes: [
          ShellRoute(
            builder: (_, _, child) =>
                Stack(children: [child, const CredentialGateOverlay()]),
            routes: [
              GoRoute(
                path: '/workspaces/:workspaceId/spaces/:spaceId',
                builder: (_, _) => const Text('space'),
              ),
              GoRoute(
                path: '/workspaces/:workspaceId/settings/server/providers',
                builder: (_, state) =>
                    Text('adapters:${state.uri.queryParameters['adapter']}'),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            blockedRunsProvider.overrideWith((ref) => controller.stream),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        ),
      );

      controller.add([
        _block(
          reason: RunCredentialReason.signedOut,
          detail: '[claude] this Claude Code account is signed out.',
        ),
      ]);
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.text(l10n.credentialGateOpenSettings));
      await tester.pumpAndSettle();
      expect(find.text('adapters:claude-code'), findsOneWidget);

      // Signed in while the page was open: the server dropped the block.
      controller.add(const []);
      await tester.pump();

      router.go('/workspaces/ws-1/spaces/sp-1');
      await tester.pumpAndSettle();

      expect(find.text('space'), findsOneWidget);
      expect(find.byType(CcDialog), findsNothing);
    },
  );
}
