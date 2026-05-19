import 'dart:async';

import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/audio/audio_input_settings.dart';
import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_control.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_model_steps.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/voice_section_extras.dart'
    show VoiceModelPicker;
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [ModelControl] that reports whatever the test sets and records the calls
/// the footer buttons make.
class _FakeVoiceControl implements ModelControl {
  _FakeVoiceControl(this.snapshot);

  final ModelStatusSnapshot snapshot;
  int installs = 0;
  int cancels = 0;

  @override
  Future<ModelStatusSnapshot> status() async => snapshot;

  @override
  Stream<ModelStatusSnapshot> watch() => Stream.value(snapshot);

  @override
  Future<void> install() async => installs++;

  @override
  Future<void> cancel() async => cancels++;

  @override
  Future<void> uninstall() async {}
}

void main() {
  // The server force-installs the SELECTED voice model at boot, so this step is
  // routinely reached while a ~600 MB transfer is still running. Every state it
  // can land in therefore has to offer a way forward — a step whose only
  // buttons are Back and Cancel strands whoever is on a slow link.

  late _FakeVoiceControl control;

  Widget wrap(ModelStatusSnapshot snapshot) {
    control = _FakeVoiceControl(snapshot);
    return ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(AppPreferences.inMemory({})),
        voiceModelControlProvider.overrideWithValue(control),
        voiceModelStatusSnapshotProvider.overrideWith(
          (ref) => Stream.value(snapshot),
        ),
        voiceModelCatalogProvider.overrideWith(
          (ref) async => const ModelCatalog(
            selectedId: 'parakeet',
            models: [
              ModelChoice(id: 'parakeet', displayName: 'Parakeet TDT v3'),
              ModelChoice(id: 'whisper', displayName: 'Whisper base.en'),
            ],
          ),
        ),
        audioInputDevicesProvider.overrideWith((ref) async => []),
        audioOutputDevicesProvider.overrideWith((ref) async => []),
      ],
      child: CcTheme(
        data: CcThemeData.light(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcToastScope(
            child: Scaffold(
              body: OnboardingVoiceStep(onBack: () {}, onFinish: () {}),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pump(WidgetTester tester, ModelStatusSnapshot snapshot) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(wrap(snapshot));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('a download in flight shows progress AND a way forward', (
    tester,
  ) async {
    await pump(
      tester,
      const ModelStatusSnapshot(
        status: ModelLifecycleStatus.downloading,
        progress: 0.4,
        phase: 'downloading',
      ),
    );

    expect(find.text('Downloading model… 40%'), findsOneWidget);
    expect(find.byType(CcProgressBar), findsOneWidget);
    // The regression this guards: Cancel used to be the ONLY footer action.
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('the model picker stays usable while downloading', (
    tester,
  ) async {
    await pump(
      tester,
      const ModelStatusSnapshot(
        status: ModelLifecycleStatus.downloading,
        progress: 0.4,
        phase: 'downloading',
      ),
    );

    // Scoped to the picker: the audio input/output rows render their own
    // CcSelect<String>, so a bare byType finder matches three.
    final select = tester.widget<CcSelect<String>>(
      find.descendant(
        of: find.byType(VoiceModelPicker),
        matching: find.byType(CcSelect<String>),
      ),
    );
    expect(
      select.enabled,
      isTrue,
      reason: 'a boot download must not lock the user out of choosing a model',
    );
  });

  testWidgets('an installed model offers only the finish action', (
    tester,
  ) async {
    await pump(
      tester,
      const ModelStatusSnapshot(
        status: ModelLifecycleStatus.installed,
        progress: 1,
        phase: 'ready',
      ),
    );

    expect(find.text('Finish'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Download'), findsNothing);
  });

  testWidgets('a failed download offers a retry and shows the reason', (
    tester,
  ) async {
    await pump(
      tester,
      const ModelStatusSnapshot(
        status: ModelLifecycleStatus.error,
        error: 'connection closed before full header was received',
      ),
    );

    expect(
      find.text('connection closed before full header was received'),
      findsOneWidget,
    );
    expect(find.text('Download'), findsOneWidget);

    await tester.tap(find.text('Download'));
    await tester.pump();
    expect(control.installs, 1);
  });

  testWidgets('a model never installed offers download or skip', (
    tester,
  ) async {
    await pump(
      tester,
      const ModelStatusSnapshot(status: ModelLifecycleStatus.notInstalled),
    );

    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
  });
}
