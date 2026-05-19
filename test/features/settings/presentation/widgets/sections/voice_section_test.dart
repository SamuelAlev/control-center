import 'dart:async';

import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/audio/audio_input_settings.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_control.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/voice_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/user/audio_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

import '../../../../../helpers/test_wrap.dart';

/// A test [SelectableModelControl] that streams a fixed snapshot and counts
/// mutator calls, without touching any RPC client.
class _TestVoiceModelControl implements SelectableModelControl {
  _TestVoiceModelControl(this._initial);

  final ModelStatusSnapshot _initial;
  final StreamController<ModelStatusSnapshot> _controller =
      StreamController<ModelStatusSnapshot>.broadcast();

  /// Number of times [install] was called.
  int installCallCount = 0;

  /// Number of times [cancel] was called.
  int cancelCallCount = 0;

  /// Number of times [uninstall] was called.
  int uninstallCallCount = 0;

  @override
  Future<ModelStatusSnapshot> status() async => _initial;

  @override
  Stream<ModelStatusSnapshot> watch() async* {
    // Yield on SUBSCRIBE, not on construction — a broadcast stream drops
    // events emitted before a listener attaches and the listener (the
    // section's StreamProvider) subscribes asynchronously after the widget
    // builds, racing a construction-time `add()`.
    yield _initial;
    yield* _controller.stream;
  }

  /// Closes the broadcast controller so no sink leaks across tests.
  void dispose() => _controller.close();

  @override
  Future<void> install() async {
    installCallCount++;
  }

  @override
  Future<void> cancel() async {
    cancelCallCount++;
  }

  @override
  Future<void> uninstall() async {
    uninstallCallCount++;
  }

  @override
  Future<ModelCatalog> catalog() async =>
      const ModelCatalog(selectedId: '', models: []);

  @override
  Future<ModelStatusSnapshot> select(String modelId) async =>
      const ModelStatusSnapshot(status: ModelLifecycleStatus.unknown);
}

/// Test notifier for [audioInputDeviceProvider].
class _TestAudioInputDeviceNotifier extends AudioInputDeviceNotifier {
  _TestAudioInputDeviceNotifier(this._id);

  final String? _id;

  @override
  String? build() => _id;

  @override
  Future<void> setDeviceId(String? id) async {
    state = id;
  }
}

void main() {
  group('VoiceSection', () {
    late _TestVoiceModelControl testControl;

    Widget voiceSectionWithStatus(ModelStatusSnapshot status) {
      testControl = _TestVoiceModelControl(status);
      addTearDown(testControl.dispose);
      return ProviderScope(
        overrides: [
          voiceModelControlProvider.overrideWithValue(testControl),
          voiceModelCatalogProvider.overrideWith(
            (ref) =>
                Future.value(const ModelCatalog(selectedId: '', models: [])),
          ),
          audioInputDevicesProvider.overrideWith(
            (ref) => Future.value(<InputDevice>[]),
          ),
          audioInputDeviceProvider.overrideWith(
            () => _TestAudioInputDeviceNotifier(null),
          ),
        ],
        child: testWrap(const VoiceSection()),
      );
    }

    group('rendering', () {
      testWidgets('shows section label', (tester) async {
        await tester.pumpWidget(
          voiceSectionWithStatus(
            const ModelStatusSnapshot(status: ModelLifecycleStatus.unknown),
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(find.text('VOICE TRANSCRIPTION'), findsOneWidget);
      });

      testWidgets('unknown status shows checking subtitle and Install button', (
        tester,
      ) async {
        await tester.pumpWidget(
          voiceSectionWithStatus(
            const ModelStatusSnapshot(status: ModelLifecycleStatus.unknown),
          ),
        );
        await tester.pump();
        await tester.pump();

        // At least the status subtitle; the ASR model picker's hint also reads
        // "Checking…" while its catalog future is still loading.
        expect(find.text('Checking…'), findsAtLeastNWidgets(1));
        expect(find.text('Install'), findsOneWidget);
      });

      testWidgets(
        'notInstalled status shows not-installed message and Install',
        (tester) async {
          await tester.pumpWidget(
            voiceSectionWithStatus(
              const ModelStatusSnapshot(
                status: ModelLifecycleStatus.notInstalled,
              ),
            ),
          );
          await tester.pump();
          await tester.pump();

          expect(
            find.text(
              'Not installed. Downloads ~200 MB once; runs fully on-device.',
            ),
            findsOneWidget,
          );
          expect(find.text('Install'), findsOneWidget);
        },
      );

      testWidgets(
        'installed status shows installed message with Remove+Redownload',
        (tester) async {
          await tester.pumpWidget(
            voiceSectionWithStatus(
              const ModelStatusSnapshot(status: ModelLifecycleStatus.installed),
            ),
          );
          await tester.pump();
          await tester.pump();

          expect(
            find.text(
              'Installed. Powers meeting transcription and the composer mic button.',
            ),
            findsOneWidget,
          );
          expect(find.text('Remove'), findsOneWidget);
          expect(find.text('Redownload'), findsOneWidget);
        },
      );

      testWidgets('error status shows error message in destructive style', (
        tester,
      ) async {
        await tester.pumpWidget(
          voiceSectionWithStatus(
            const ModelStatusSnapshot(
              status: ModelLifecycleStatus.error,
              error: 'test error',
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Install failed: test error'), findsOneWidget);

        // Check destructive styling applied
        final text = tester.widget<Text>(
          find.text('Install failed: test error'),
        );
        expect(text.style!.color, isNotNull);
      });

      testWidgets('error status with null error falls back to literal string', (
        tester,
      ) async {
        await tester.pumpWidget(
          voiceSectionWithStatus(
            const ModelStatusSnapshot(status: ModelLifecycleStatus.error),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Install failed: unknown error'), findsOneWidget);
      });

      testWidgets(
        'downloading phase shows download subtitle and Cancel button',
        (tester) async {
          await tester.pumpWidget(
            voiceSectionWithStatus(
              const ModelStatusSnapshot(
                status: ModelLifecycleStatus.downloading,
                progress: 0.45,
                phase: 'downloading',
              ),
            ),
          );
          await tester.pump();
          await tester.pump();

          expect(find.text('Downloading model… 45%'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);
        },
      );

      testWidgets('extracting phase shows extract subtitle', (tester) async {
        await tester.pumpWidget(
          voiceSectionWithStatus(
            const ModelStatusSnapshot(
              status: ModelLifecycleStatus.downloading,
              progress: 0.9,
              phase: 'extracting',
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Extracting model… 90%'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });
    });

    group('progress bar', () {
      testWidgets('shows indeterminate progress when progress is 0', (
        tester,
      ) async {
        await tester.pumpWidget(
          voiceSectionWithStatus(
            const ModelStatusSnapshot(
              status: ModelLifecycleStatus.downloading,
              progress: 0,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        // Indeterminate = a CcProgressBar with no value (lib: const CcProgressBar()).
        expect(find.byType(CcProgressBar), findsOneWidget);
        expect(
          tester.widget<CcProgressBar>(find.byType(CcProgressBar)).value,
          isNull,
        );
      });

      testWidgets('shows determinate progress when progress > 0', (
        tester,
      ) async {
        await tester.pumpWidget(
          voiceSectionWithStatus(
            const ModelStatusSnapshot(
              status: ModelLifecycleStatus.downloading,
              progress: 0.3,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        // Determinate = a CcProgressBar carrying the fractional value.
        expect(find.byType(CcProgressBar), findsOneWidget);
        expect(
          tester.widget<CcProgressBar>(find.byType(CcProgressBar)).value,
          isNotNull,
        );
      });

      testWidgets('no progress bar when not downloading', (tester) async {
        await tester.pumpWidget(
          voiceSectionWithStatus(
            const ModelStatusSnapshot(
              status: ModelLifecycleStatus.notInstalled,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(CcProgressBar), findsNothing);
      });

      testWidgets('no progress bar when installed', (tester) async {
        await tester.pumpWidget(
          voiceSectionWithStatus(
            const ModelStatusSnapshot(status: ModelLifecycleStatus.installed),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(CcProgressBar), findsNothing);
      });
    });

    group('state interactions', () {
      testWidgets('tapping Install calls install', (tester) async {
        await tester.pumpWidget(
          voiceSectionWithStatus(
            const ModelStatusSnapshot(
              status: ModelLifecycleStatus.notInstalled,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        await tester.tap(find.text('Install'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(testControl.installCallCount, 1);
      });

      testWidgets('tapping Cancel calls cancel', (tester) async {
        await tester.pumpWidget(
          voiceSectionWithStatus(
            const ModelStatusSnapshot(
              status: ModelLifecycleStatus.downloading,
              progress: 0.3,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        await tester.tap(find.text('Cancel'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(testControl.cancelCallCount, 1);
      });

      testWidgets('tapping Cancel when extracting calls cancel', (
        tester,
      ) async {
        await tester.pumpWidget(
          voiceSectionWithStatus(
            const ModelStatusSnapshot(
              status: ModelLifecycleStatus.downloading,
              progress: 0.8,
              phase: 'extracting',
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        await tester.tap(find.text('Cancel'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(testControl.cancelCallCount, 1);
      });

      testWidgets('Install button visible from error state', (tester) async {
        await tester.pumpWidget(
          voiceSectionWithStatus(
            const ModelStatusSnapshot(status: ModelLifecycleStatus.error),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Install'), findsOneWidget);
      });

      testWidgets('Install button visible from unknown state', (tester) async {
        await tester.pumpWidget(
          voiceSectionWithStatus(
            const ModelStatusSnapshot(status: ModelLifecycleStatus.unknown),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Install'), findsOneWidget);
      });
    });

    group('AudioInputRow', () {
      // The row lives on You → Voice input now (the server voice page is
      // models-only), so its group mounts the section that hosts it there.
      Widget audioSectionWithDevices(
        List<InputDevice> devices, {
        String? selectedId,
      }) {
        return ProviderScope(
          overrides: [
            audioInputDevicesProvider.overrideWith(
              (ref) => Future.value(devices),
            ),
            audioInputDeviceProvider.overrideWith(
              () => _TestAudioInputDeviceNotifier(selectedId),
            ),
          ],
          child: testWrap(const AudioInputSection()),
        );
      }

      testWidgets('shows Audio input label', (tester) async {
        await tester.pumpWidget(audioSectionWithDevices([]));
        await tester.pump();
        await tester.pump();
        expect(find.text('Audio input'), findsOneWidget);
      });

      testWidgets('shows detecting message while loading', (tester) async {
        // Override with a never-completing future to test loading state.
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              audioInputDevicesProvider.overrideWith(
                (ref) => Future.delayed(
                  const Duration(seconds: 30),
                  () => <InputDevice>[],
                ),
              ),
              audioInputDeviceProvider.overrideWith(
                () => _TestAudioInputDeviceNotifier(null),
              ),
            ],
            child: testWrap(const AudioInputSection()),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Detecting input devices…'), findsOneWidget);

        // Advance the clock past the 30s delay to clear the pending timer.
        await tester.pump(const Duration(seconds: 31));
      });

      testWidgets('shows no devices message when list is empty', (
        tester,
      ) async {
        await tester.pumpWidget(audioSectionWithDevices([]));
        await tester.pump();
        await tester.pump();

        expect(
          find.text('No input devices detected — using system default.'),
          findsOneWidget,
        );
      });

      testWidgets('shows system default when selected device not in list', (
        tester,
      ) async {
        const device = InputDevice(id: 'dev-1', label: 'Microphone');
        await tester.pumpWidget(
          audioSectionWithDevices([device], selectedId: 'dev-unknown'),
        );
        await tester.pump();
        await tester.pump();

        expect(
          find.text('Using the system default microphone.'),
          findsOneWidget,
        );
      });

      testWidgets('shows recording from device when device selected', (
        tester,
      ) async {
        const device = InputDevice(id: 'dev-1', label: 'USB Mic');
        await tester.pumpWidget(
          audioSectionWithDevices([device], selectedId: 'dev-1'),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Recording from USB Mic.'), findsOneWidget);
      });

      testWidgets('shows Refresh button', (tester) async {
        await tester.pumpWidget(audioSectionWithDevices([]));
        await tester.pump();
        await tester.pump();
        expect(find.text('Refresh'), findsOneWidget);
      });

      testWidgets('shows Test button', (tester) async {
        await tester.pumpWidget(audioSectionWithDevices([]));
        await tester.pump();
        await tester.pump();
        expect(find.text('Test'), findsOneWidget);
      });
    });
  });
}
