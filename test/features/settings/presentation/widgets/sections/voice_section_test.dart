import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/audio/audio_input_settings.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/voice_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

import '../../../../../helpers/test_wrap.dart';

/// A test notifier for [voiceModelStateProvider] that does not call _probe()
/// (which hits the filesystem) and allows setting arbitrary initial state.
class _TestVoiceModelStateNotifier extends VoiceModelStateNotifier {
  _TestVoiceModelStateNotifier(this._initial);

  final VoiceModelState _initial;

  @override
  VoiceModelState build() => _initial;

  /// Number of times [installIfNeeded] was called.
  int installCallCount = 0;

  /// Number of times [cancel] was called.
  int cancelCallCount = 0;

  /// Number of times [uninstall] was called.
  int uninstallCallCount = 0;

  @override
  Future<void> installIfNeeded() async {
    installCallCount++;
  }

  @override
  void cancel() {
    cancelCallCount++;
  }

  @override
  Future<void> uninstall() async {
    uninstallCallCount++;
  }
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
    late _TestVoiceModelStateNotifier testNotifier;

    Widget voiceSectionWithState(VoiceModelState state) {
      testNotifier = _TestVoiceModelStateNotifier(state);
      return ProviderScope(
        overrides: [
          voiceModelStateProvider.overrideWith(() => testNotifier),
          audioInputDevicesProvider
              .overrideWith((ref) => Future.value(<InputDevice>[])),
          audioInputDeviceProvider.overrideWith(
            () => _TestAudioInputDeviceNotifier(null),
          ),
        ],
        child: testWrap(const VoiceSection()),
      );
    }

    group('rendering', () {
      testWidgets('shows section label', (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(status: VoiceModelStatus.unknown),
        ));
        expect(find.text('VOICE TRANSCRIPTION'), findsOneWidget);
      });

      testWidgets('unknown status shows checking subtitle and Install button',
          (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(status: VoiceModelStatus.unknown),
        ));

        expect(find.text('Checking…'), findsOneWidget);
        expect(find.text('Install'), findsOneWidget);
      });

      testWidgets('notInstalled status shows not-installed message and Install',
          (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(status: VoiceModelStatus.notInstalled),
        ));

        expect(
          find.text(
            'Not installed. Downloads ~200 MB once; runs fully on-device.',
          ),
          findsOneWidget,
        );
        expect(find.text('Install'), findsOneWidget);
      });

      testWidgets('installed status shows installed message with Remove+Redownload',
          (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(status: VoiceModelStatus.installed),
        ));

        expect(
          find.text(
            'Installed. Powers meeting transcription and the composer mic button.',
          ),
          findsOneWidget,
        );
        expect(find.text('Remove'), findsOneWidget);
        expect(find.text('Redownload'), findsOneWidget);
      });

      testWidgets('error status shows error message in destructive style',
          (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(
            status: VoiceModelStatus.error,
            error: 'test error',
          ),
        ));

        expect(
          find.text('Install failed: test error'),
          findsOneWidget,
        );

        // Check destructive styling applied
        final text =
            tester.widget<Text>(find.text('Install failed: test error'));
        expect(text.style!.color, isNotNull);
      });

      testWidgets('error status with null error falls back to literal string',
          (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(status: VoiceModelStatus.error),
        ));

        expect(
          find.text('Install failed: unknown error'),
          findsOneWidget,
        );
      });

      testWidgets('downloading phase shows download subtitle and Cancel button',
          (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(
            status: VoiceModelStatus.downloading,
            progress: 0.45,
            phase: 'downloading',
          ),
        ));

        expect(find.text('Downloading model… 45%'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('extracting phase shows extract subtitle',
          (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(
            status: VoiceModelStatus.downloading,
            progress: 0.9,
            phase: 'extracting',
          ),
        ));

        expect(find.text('Extracting model… 90%'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });
    });

    group('bundled models', () {
      testWidgets('Silero VAD row shows an Included badge, no install',
          (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(status: VoiceModelStatus.installed),
        ));

        // The bundled VAD model surfaces as "Included".
        expect(find.text('Included'), findsOneWidget);
        // The bundled row renders its description, not a download state.
        expect(
          find.text(
            'A learned voice-activity model that skips silence so the '
            'transcriber decodes only speech. Falls back to an energy '
            'threshold when not installed.',
          ),
          findsOneWidget,
        );
      });
    });

    group('progress bar', () {
      testWidgets('shows indeterminate progress when progress is 0',
          (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(
            status: VoiceModelStatus.downloading,
            progress: 0,
          ),
        ));

        // Indeterminate = a CcProgressBar with no value (lib: const CcProgressBar()).
        expect(find.byType(CcProgressBar), findsOneWidget);
        expect(
          tester.widget<CcProgressBar>(find.byType(CcProgressBar)).value,
          isNull,
        );
      });

      testWidgets('shows determinate progress when progress > 0',
          (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(
            status: VoiceModelStatus.downloading,
            progress: 0.3,
          ),
        ));

        // Determinate = a CcProgressBar carrying the fractional value.
        expect(find.byType(CcProgressBar), findsOneWidget);
        expect(
          tester.widget<CcProgressBar>(find.byType(CcProgressBar)).value,
          isNotNull,
        );
      });

      testWidgets('no progress bar when not downloading', (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(status: VoiceModelStatus.notInstalled),
        ));

        expect(find.byType(CcProgressBar), findsNothing);
      });

      testWidgets('no progress bar when installed', (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(status: VoiceModelStatus.installed),
        ));

        expect(find.byType(CcProgressBar), findsNothing);
      });
    });

    group('state interactions', () {
      testWidgets('tapping Install calls installIfNeeded', (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(status: VoiceModelStatus.notInstalled),
        ));

        await tester.tap(find.text('Install'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(testNotifier.installCallCount, 1);
      });

      testWidgets('tapping Cancel calls cancel', (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(
            status: VoiceModelStatus.downloading,
            progress: 0.3,
          ),
        ));

        await tester.tap(find.text('Cancel'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(testNotifier.cancelCallCount, 1);
      });

      testWidgets('tapping Cancel when extracting calls cancel', (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(
            status: VoiceModelStatus.downloading,
            progress: 0.8,
            phase: 'extracting',
          ),
        ));

        await tester.tap(find.text('Cancel'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(testNotifier.cancelCallCount, 1);
      });

      testWidgets('Install button visible from error state', (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(status: VoiceModelStatus.error),
        ));

        expect(find.text('Install'), findsOneWidget);
      });

      testWidgets('Install button visible from unknown state', (tester) async {
        await tester.pumpWidget(voiceSectionWithState(
          const VoiceModelState(status: VoiceModelStatus.unknown),
        ));

        expect(find.text('Install'), findsOneWidget);
      });
    });

    group('AudioInputRow', () {
      Widget voiceSectionWithDevices(List<InputDevice> devices,
          {String? selectedId}) {
        testNotifier = _TestVoiceModelStateNotifier(
          const VoiceModelState(status: VoiceModelStatus.notInstalled),
        );
        return ProviderScope(
          overrides: [
            voiceModelStateProvider.overrideWith(() => testNotifier),
            audioInputDevicesProvider
                .overrideWith((ref) => Future.value(devices)),
            audioInputDeviceProvider.overrideWith(
              () => _TestAudioInputDeviceNotifier(selectedId),
            ),
          ],
          child: testWrap(const VoiceSection()),
        );
      }

      testWidgets('shows Audio input label', (tester) async {
        await tester.pumpWidget(voiceSectionWithDevices([]));
        await tester.pump();
        expect(find.text('Audio input'), findsOneWidget);
      });

      testWidgets('shows detecting message while loading',
          (tester) async {
        // Override with a never-completing future to test loading state.
        testNotifier = _TestVoiceModelStateNotifier(
          const VoiceModelState(status: VoiceModelStatus.notInstalled),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              voiceModelStateProvider.overrideWith(() => testNotifier),
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
            child: testWrap(const VoiceSection()),
          ),
        );


        expect(find.text('Detecting input devices…'), findsOneWidget);

        // Advance the clock past the 30s delay to clear the pending timer.
        await tester.pump(const Duration(seconds: 31));
      });

      testWidgets('shows no devices message when list is empty',
          (tester) async {
        await tester.pumpWidget(voiceSectionWithDevices([]));
        await tester.pump();

        expect(
          find.text(
            'No input devices detected — using system default.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('shows system default when selected device not in list',
          (tester) async {
        const device = InputDevice(
          id: 'dev-1',
          label: 'Microphone',
        );
        await tester.pumpWidget(voiceSectionWithDevices([device],
            selectedId: 'dev-unknown'));
        await tester.pump();

        expect(
          find.text('Using the system default microphone.'),
          findsOneWidget,
        );
      });

      testWidgets('shows recording from device when device selected',
          (tester) async {
        const device = InputDevice(
          id: 'dev-1',
          label: 'USB Mic',
        );
        await tester.pumpWidget(voiceSectionWithDevices([device],
            selectedId: 'dev-1'));
        await tester.pump();

        expect(
          find.text('Recording from USB Mic.'),
          findsOneWidget,
        );
      });

      testWidgets('shows Refresh button', (tester) async {
        await tester.pumpWidget(voiceSectionWithDevices([]));
        await tester.pump();
        expect(find.text('Refresh'), findsOneWidget);
      });

      testWidgets('shows Test button', (tester) async {
        await tester.pumpWidget(voiceSectionWithDevices([]));
        await tester.pump();
        expect(find.text('Test'), findsOneWidget);
      });
    });
  });
}
