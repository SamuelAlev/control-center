import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/sandbox_preferences.dart';
import 'package:control_center/features/sandboxing/presentation/onboarding_step_sandbox.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_wrap.dart';

final _l10n = AppLocalizationsEn();

SandboxDetectionResult _detection(
  String platform,
  SandboxBackendCapabilities native,
) => SandboxDetectionResult(
  platform: platform,
  recommendation: native.available
      ? SandboxBackend.native
      : SandboxBackend.none,
  capabilities: {SandboxBackend.native: native},
);

/// What the probe reports on Windows: no native sandbox, nothing to install.
final _windows = _detection(
  'Windows (x86_64)',
  const SandboxBackendCapabilities(
    backend: SandboxBackend.native,
    available: false,
    note: 'Native sandbox is not yet supported on this platform.',
  ),
);

/// Linux without bubblewrap: the sandbox is one install away.
final _linuxMissingTools = _detection(
  'Linux (x86_64)',
  const SandboxBackendCapabilities(
    backend: SandboxBackend.native,
    available: false,
    requiresInstall: true,
    installHint: 'Install missing tools: bubblewrap',
    note: 'Linux bubblewrap — namespace isolation, no kernel boundary.',
  ),
);

final _linuxReady = _detection(
  'Linux (x86_64)',
  const SandboxBackendCapabilities(
    backend: SandboxBackend.native,
    available: true,
  ),
);

void main() {
  late AppPreferences prefs;
  late int continued;

  setUp(() {
    prefs = AppPreferences.inMemory();
    continued = 0;
  });

  Future<void> pumpStep(
    WidgetTester tester,
    Future<SandboxDetectionResult> Function() detect,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          sandboxDetectionProvider.overrideWith((ref) => detect()),
        ],
        child: testWrap(
          OnboardingStepSandbox(onBack: () {}, onContinue: () => continued++),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a platform with no native sandbox continues without one, writing no opt-out',
    (tester) async {
      await pumpStep(tester, () async => _windows);

      expect(
        find.text(_l10n.nativeSandboxUnsupported('Windows (x86_64)')),
        findsOneWidget,
      );
      // Nothing to install, so nothing claims an install is needed, and the
      // probe's note would only repeat the subtitle.
      expect(find.text(_l10n.nativeSandboxNeedsInstall), findsNothing);
      expect(
        find.text('Native sandbox is not yet supported on this platform.'),
        findsNothing,
      );
      // Nothing to opt out of either.
      expect(find.text(_l10n.skipSandboxing), findsNothing);

      await tester.tap(find.text(_l10n.continueWithoutSandbox));
      await tester.pumpAndSettle();

      expect(continued, 1);
      final sandbox = SandboxPreferences(prefs);
      expect(sandbox.isEnabled, isTrue);
      expect(sandbox.backend, isNull);
    },
  );

  testWidgets('missing tools can be installed and checked for again', (
    tester,
  ) async {
    var probes = 0;
    await pumpStep(tester, () async {
      probes++;
      return probes == 1 ? _linuxMissingTools : _linuxReady;
    });

    expect(find.text(_l10n.nativeSandboxNeedsInstall), findsOneWidget);
    expect(find.text('Install missing tools: bubblewrap'), findsOneWidget);
    expect(find.text(_l10n.useSandbox), findsNothing);

    await tester.tap(find.text(_l10n.sandboxCheckAgain));
    await tester.pumpAndSettle();

    expect(probes, 2);
    expect(find.text(_l10n.useSandbox), findsOneWidget);
    expect(continued, 0);
  });

  testWidgets('missing tools can also be skipped, accepting the risk', (
    tester,
  ) async {
    await pumpStep(tester, () async => _linuxMissingTools);

    await tester.tap(find.text(_l10n.skipSandboxing));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.skipAcceptRisk));
    await tester.pumpAndSettle();

    expect(continued, 1);
    expect(SandboxPreferences(prefs).isEnabled, isFalse);
  });

  testWidgets('an available sandbox is pinned when used', (tester) async {
    await pumpStep(tester, () async => _linuxReady);

    await tester.tap(find.text(_l10n.useSandbox));
    await tester.pumpAndSettle();

    expect(continued, 1);
    expect(SandboxPreferences(prefs).backend, SandboxBackend.native);
  });
}
