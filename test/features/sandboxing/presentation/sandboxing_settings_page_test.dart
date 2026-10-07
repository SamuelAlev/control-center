import 'dart:async';

import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/sandboxing_sections.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
// ignore: implementation_imports
import 'package:riverpod/src/framework.dart' show Override;

import '../../../helpers/test_wrap.dart';

// ── Helpers ─────────────────────────────────────────────────────────────────

SandboxDetectionResult _detectionResult({
  SandboxBackend recommendation = SandboxBackend.native,
  Map<SandboxBackend, SandboxBackendCapabilities>? caps,
}) {
  return SandboxDetectionResult(
    platform: 'macos',
    recommendation: recommendation,
    capabilities:
        caps ??
        <SandboxBackend, SandboxBackendCapabilities>{
          SandboxBackend.native: const SandboxBackendCapabilities(
            backend: SandboxBackend.native,
            available: true,
          ),
          SandboxBackend.none: const SandboxBackendCapabilities(
            backend: SandboxBackend.none,
            available: true,
          ),
        },
  );
}

Future<List<Override>> _baseOverrides({
  bool enabled = true,
  SandboxBackend? pinned,
  SandboxDetectionResult? detection,
  bool includeDetection = true,
}) async {
  final prefsValues = <String, Object>{'sandbox_enabled': enabled};
  if (pinned != null) {
    prefsValues['sandbox_backend'] = pinned.name;
  }
  final sp = AppPreferences.inMemory(prefsValues);

  return [
    appPreferencesProvider.overrideWithValue(sp),
    if (includeDetection)
      sandboxDetectionProvider.overrideWith(
        (ref) async => detection ?? _detectionResult(),
      ),
  ];
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(1080, 3500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: testWrap(const SandboxingSections()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() {});

  group('SandboxingSections rendering', () {
    testWidgets('renders the sandboxing sections', (tester) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);
      expect(find.byType(SandboxingSections), findsOneWidget);
      expect(find.text('SANDBOXING'), findsOneWidget);
    });

    // One card, two groups: the five-card split ("Master toggle", "Backend",
    // "Requirements", "Default capabilities", "Maintenance") was one subject
    // wearing five boxes. The second group is now a pointer to agent
    // permissions, the only place what an agent may do is decided.
    testWidgets('renders one card with its groups when detection succeeds', (
      tester,
    ) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      expect(find.byType(SectionCard), findsOneWidget);
      expect(find.text('SANDBOXING'), findsOneWidget);
      expect(find.text('Isolation'), findsOneWidget);
      expect(find.text('Backend'), findsOneWidget);
      expect(find.text('Requirements'), findsOneWidget);
      expect(find.text('What agents may do'), findsOneWidget);
      expect(find.text('Default capabilities \u00b7 new spaces'), findsNothing);
    });

    testWidgets('shows progress indicator while detection is pending', (
      tester,
    ) async {
      final completer = Completer<SandboxDetectionResult>();
      final overrides = await _baseOverrides(includeDetection: false);
      await _pumpScreen(
        tester,
        overrides: [
          ...overrides,
          sandboxDetectionProvider.overrideWith((ref) => completer.future),
        ],
      );
      expect(find.byType(CcProgressBar), findsOneWidget);
    });

    testWidgets('shows error text when detection fails', (tester) async {
      final overrides = await _baseOverrides(includeDetection: false);
      await _pumpScreen(
        tester,
        overrides: [
          ...overrides,
          sandboxDetectionProvider.overrideWith(
            (ref) => Future.error(Exception('probe failed')),
          ),
        ],
      );
      // Pump and settle to let the future error propagate through Riverpod.
      await tester.pumpAndSettle();

      // Use skipOffstage: false to find text in the scrolled-out portion
      // if necessary, or check any Text containing 'Exception'.
      expect(
        find.descendant(
          of: find.byType(SectionCard),
          matching: find.textContaining('Exception'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders auto-recommended backend option as selected', (
      tester,
    ) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      expect(find.text('Auto (recommended)'), findsOneWidget);
      expect(find.byIcon(AppIcons.circleCheck), findsOneWidget);
    });

    testWidgets('renders native and none backend option labels', (
      tester,
    ) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      // Twice by design: the summary reports the backend in force, the picker
      // lists it as a choice.
      expect(find.text('Native sandbox'), findsNWidgets(2));
      expect(find.text('No isolation'), findsOneWidget);
    });

    testWidgets('unavailable backend shows not-available label', (
      tester,
    ) async {
      final unavailableNativeCaps =
          <SandboxBackend, SandboxBackendCapabilities>{
            SandboxBackend.native: const SandboxBackendCapabilities(
              backend: SandboxBackend.native,
              available: false,
            ),
            SandboxBackend.none: const SandboxBackendCapabilities(
              backend: SandboxBackend.none,
              available: true,
            ),
          };
      final overrides = await _baseOverrides(
        detection: _detectionResult(caps: unavailableNativeCaps),
      );
      await _pumpScreen(tester, overrides: overrides);

      expect(find.text('Not available'), findsOneWidget);
    });

    // The sandbox no longer carries a second permission system: push, pull
    // requests and network access are decided by the action policy alone.
    testWidgets('points to agent permissions instead of capability toggles', (
      tester,
    ) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      expect(
        find.text(
          'Pushing, opening a pull request and accessing the network are '
          'each allowed, asked about or denied in agent permissions.',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(CcButton, 'Agent permissions'),
        findsOneWidget,
      );
      expect(find.text('Allow git push'), findsNothing);
      expect(find.text('Allow GitHub API calls'), findsNothing);
      expect(find.text('Allow ticketing API calls'), findsNothing);
      expect(find.text('Allow general network access'), findsNothing);
    });

    testWidgets('the pointer opens agent permissions for this workspace', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 3500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final overrides = await _baseOverrides();
      final router = GoRouter(
        initialLocation: settingsSandboxRoute('ws-1'),
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId/settings/server/sandbox',
            builder: (context, state) => const Scaffold(
              body: SingleChildScrollView(child: SandboxingSections()),
            ),
          ),
          GoRoute(
            path: '/workspaces/:workspaceId/settings/workspace/permissions',
            builder: (context, state) => const Text('permissions page'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
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
      await tester.pump();

      final button = find.widgetWithText(CcButton, 'Agent permissions');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(router.state.uri.path, settingsGuardrailsRoute('ws-1'));
      expect(find.text('permissions page'), findsOneWidget);
    });

    // "Reset all sandboxes" was removed, not restyled: it raised a success
    // toast and destroyed nothing, because no reset op exists behind it.
    testWidgets('does not offer a reset control that does nothing', (
      tester,
    ) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      expect(find.text('Reset all sandboxes'), findsNothing);
    });

    testWidgets('shows macOS install hint text', (tester) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      expect(find.textContaining('built in on macOS'), findsOneWidget);
    });

    testWidgets(
      'disabled sandboxing shows disabled description and alert icon',
      (tester) async {
        final overrides = await _baseOverrides(enabled: false);
        await _pumpScreen(tester, overrides: overrides);

        expect(
          find.text(
            'Agents run directly on the host with full env - not recommended.',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(AppIcons.shieldAlert), findsOneWidget);
      },
    );

    testWidgets('enabled sandboxing shows enabled description and check icon', (
      tester,
    ) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      expect(
        find.textContaining(
          'All agent invocations route through Native sandbox',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(AppIcons.shieldCheck), findsOneWidget);
    });
  });

  group('SandboxingSections toggles', () {
    testWidgets('master toggle value is true when enabled', (tester) async {
      final overrides = await _baseOverrides(enabled: true);
      await _pumpScreen(tester, overrides: overrides);

      final switches = find.byType(CcSwitch);
      final masterSwitch = tester.widget<CcSwitch>(switches.first);
      expect(masterSwitch.value, isTrue);
    });

    testWidgets('master toggle value is false when disabled', (tester) async {
      final overrides = await _baseOverrides(enabled: false);
      await _pumpScreen(tester, overrides: overrides);

      final switches = find.byType(CcSwitch);
      final masterSwitch = tester.widget<CcSwitch>(switches.first);
      expect(masterSwitch.value, isFalse);
    });

    testWidgets('the master toggle is the only switch on the card', (
      tester,
    ) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      expect(find.byType(CcSwitch), findsOneWidget);
    });
  });
}
