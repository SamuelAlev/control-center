import 'package:control_center/core/infrastructure/audio/audio_input_settings.dart';
import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/user/audio_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:record/record.dart';

import '../../../../../helpers/test_wrap.dart';

/// Pins the stored output-device selection for a provider container.
class _FixedOutputDeviceNotifier extends AudioOutputDeviceNotifier {
  _FixedOutputDeviceNotifier(this._name);

  final String? _name;

  @override
  String? build() => _name;
}

/// Pins the stored input-device selection for a provider container.
class _FixedInputDeviceNotifier extends AudioInputDeviceNotifier {
  _FixedInputDeviceNotifier(this._id);

  final String? _id;

  @override
  String? build() => _id;
}

Widget _wrap({required List<AudioDevice> devices, String? selected}) {
  return testWrap(
    ProviderScope(
      overrides: [
        audioOutputDevicesProvider.overrideWith((ref) async => devices),
        audioOutputDeviceProvider.overrideWith(
          () => _FixedOutputDeviceNotifier(selected),
        ),
        audioInputDevicesProvider.overrideWith(
          (ref) async => const <InputDevice>[],
        ),
        audioInputDeviceProvider.overrideWith(
          () => _FixedInputDeviceNotifier(null),
        ),
      ],
      child: const AudioDevicesSection(),
    ),
  );
}

const _kDevices = [
  AudioDevice('coreaudio/1', 'Studio monitors'),
  AudioDevice('coreaudio/2', 'MacBook speakers'),
];

void main() {
  group('AudioDevicesSection', () {
    testWidgets('shows the selected device with test and refresh actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(devices: _kDevices, selected: 'coreaudio/1'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('AUDIO DEVICES'), findsOneWidget);
      expect(find.text('Output device'), findsOneWidget);
      // The device name shows twice: the row subtitle and the select's value.
      expect(find.text('Studio monitors'), findsNWidgets(2));
      // Both the input and the output row carry test and refresh actions.
      expect(find.text('Test'), findsNWidgets(2));
      expect(find.text('Refresh'), findsNWidgets(2));
    });

    testWidgets('no selection shows the system-default hint', (tester) async {
      await tester.pumpWidget(_wrap(devices: _kDevices, selected: null));
      await tester.pump();
      await tester.pump();

      // One "System default" per row (input select + output select).
      expect(find.text('System default'), findsNWidgets(2));
      expect(
        find.text('All app sound plays through the system default output.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'a stored device that no longer exists is called out, not silently swapped',
      (tester) async {
        await tester.pumpWidget(
          _wrap(devices: _kDevices, selected: 'coreaudio/unplugged'),
        );
        await tester.pump();
        await tester.pump();

        expect(
          find.text(
            'The selected output device is no longer connected — the system '
            'default is used until you pick another.',
          ),
          findsOneWidget,
        );
        // The picker falls back to the default entry rather than showing a
        // value that is not in the list.
        expect(find.text('System default'), findsNWidgets(2));
      },
    );
  });
}
