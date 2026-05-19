import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/ports/sandbox_port.dart';
import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:control_center/features/sandboxing/presentation/sandboxing_settings_page.dart';
import 'package:control_center/features/sandboxing/providers/is_wsl2_provider.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
// ignore: implementation_imports
import 'package:riverpod/src/framework.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_wrap.dart';

// ── Helpers ─────────────────────────────────────────────────────────────────

SandboxDetectionResult _detectionResult({
  SandboxBackend recommendation = SandboxBackend.native,
  Map<SandboxBackend, SandboxBackendCapabilities>? caps,
}) {
  return SandboxDetectionResult(
    platform: 'macos',
    recommendation: recommendation,
    capabilities: caps ??
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
  AgentCapabilities? caps,
  bool isWsl2 = false,
  bool includeDetection = true,
}) async {
  final prefsValues = <String, Object>{
    'sandbox_enabled': enabled,
  };
  if (pinned != null) {
    prefsValues['sandbox_backend'] = pinned.name;
  }
  if (caps != null) {
    prefsValues['sandbox_default_capabilities'] = caps.toJsonString();
  }
  SharedPreferences.setMockInitialValues(prefsValues);
  final sp = await SharedPreferences.getInstance();

  return [
    sharedPreferencesProvider.overrideWithValue(sp),
    if (includeDetection)
      sandboxDetectionProvider.overrideWith(
        (ref) async => detection ?? _detectionResult(),
      ),
    isWsl2Provider.overrideWith((ref) => isWsl2),
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
      child: testWrap(const SandboxingSettingsScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SandboxingSettingsScreen rendering', () {
    testWidgets('renders page title and description', (tester) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);
      expect(find.text('Sandboxing'), findsOneWidget);
    });

    testWidgets('renders all section labels when detection succeeds', (tester) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      expect(find.text('MASTER TOGGLE'), findsOneWidget);
      expect(find.text('BACKEND'), findsOneWidget);
      expect(find.text('REQUIREMENTS'), findsOneWidget);
      expect(
        find.text('DEFAULT CAPABILITIES \u00b7 NEW CONVERSATIONS'),
        findsOneWidget,
      );
      expect(find.text('MAINTENANCE'), findsOneWidget);
    });

    testWidgets('shows progress indicator while detection is pending', (tester) async {
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
          of: find.byType(SectionCard).at(1),
          matching: find.textContaining('Exception'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders auto-recommended backend option as selected', (tester) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      expect(find.text('Auto (recommended)'), findsOneWidget);
      expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);
    });

    testWidgets('renders native and none backend option labels', (tester) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      expect(find.text('Native sandbox'), findsOneWidget);
      expect(find.text('No isolation'), findsOneWidget);
    });

    testWidgets('unavailable backend shows not-available label', (tester) async {
      final unavailableNativeCaps = <SandboxBackend, SandboxBackendCapabilities>{
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

    testWidgets('renders capability toggle labels and icons', (tester) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      expect(find.text('Allow git push'), findsOneWidget);
      expect(find.text('Allow GitHub API calls'), findsOneWidget);
      expect(find.text('Allow ticketing API calls'), findsOneWidget);
      expect(find.text('Allow general network access'), findsOneWidget);

      expect(find.byIcon(LucideIcons.gitBranch), findsOneWidget);
      expect(find.byIcon(LucideIcons.gitPullRequest), findsOneWidget);
      expect(find.byIcon(LucideIcons.listTodo), findsOneWidget);
      expect(find.byIcon(LucideIcons.globe), findsOneWidget);
    });

    testWidgets('renders reset section with destructive button', (tester) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      expect(find.text('Reset all sandboxes'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('shows macOS install hint text', (tester) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      expect(find.textContaining('built in on macOS'), findsOneWidget);
    });

    testWidgets('disabled sandboxing shows disabled description and alert icon', (tester) async {
      final overrides = await _baseOverrides(enabled: false);
      await _pumpScreen(tester, overrides: overrides);

      expect(
        find.text('Agents run directly on the host with full env - not recommended.'),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.shieldAlert), findsOneWidget);
    });

    testWidgets('enabled sandboxing shows enabled description and check icon', (tester) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      expect(
        find.textContaining('All agent invocations route through Native sandbox'),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.shieldCheck), findsOneWidget);
    });
  });

  group('SandboxingSettingsScreen toggles', () {
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

    testWidgets('capability switches reflect all-on state', (tester) async {
      const caps = AgentCapabilities(
        canPushToRepo: true,
        canCallGitHubApi: true,
        canCallTicketing: true,
        canAccessNetwork: true,
      );
      final overrides = await _baseOverrides(caps: caps);
      await _pumpScreen(tester, overrides: overrides);

      final switches = find.byType(CcSwitch).evaluate().toList();
      expect(switches.length, 5);
      expect((switches[1].widget as CcSwitch).value, isTrue);
      expect((switches[2].widget as CcSwitch).value, isTrue);
      expect((switches[3].widget as CcSwitch).value, isTrue);
      expect((switches[4].widget as CcSwitch).value, isTrue);
    });

    testWidgets('capability switches reflect mixed on/off state', (tester) async {
      const caps = AgentCapabilities(
        canPushToRepo: false,
        canCallGitHubApi: false,
        canCallTicketing: true,
        canAccessNetwork: true,
      );
      final overrides = await _baseOverrides(caps: caps);
      await _pumpScreen(tester, overrides: overrides);

      final switches = find.byType(CcSwitch).evaluate().toList();
      expect(switches.length, 5);
      expect((switches[1].widget as CcSwitch).value, isFalse);
      expect((switches[2].widget as CcSwitch).value, isFalse);
      expect((switches[3].widget as CcSwitch).value, isTrue);
      expect((switches[4].widget as CcSwitch).value, isTrue);
    });

    testWidgets('capability onChanged is null when sandboxing disabled', (tester) async {
      final overrides = await _baseOverrides(
        enabled: false,
        caps: const AgentCapabilities(),
      );
      await _pumpScreen(tester, overrides: overrides);

      final switches = find.byType(CcSwitch).evaluate().toList();
      expect(switches.length, 5);
      for (var i = 1; i <= 4; i++) {
        expect((switches[i].widget as CcSwitch).onChanged, isNull);
      }
    });

    testWidgets('capability onChanged is non-null when sandboxing enabled', (tester) async {
      final overrides = await _baseOverrides();
      await _pumpScreen(tester, overrides: overrides);

      final switches = find.byType(CcSwitch).evaluate().toList();
      expect(switches.length, 5);
      for (var i = 1; i <= 4; i++) {
        expect((switches[i].widget as CcSwitch).onChanged, isNotNull);
      }
    });
  });
}
