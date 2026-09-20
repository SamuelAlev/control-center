import 'package:cc_data/cc_data.dart' show RemoteRigRepository, RigView;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/audio/audio_input_settings.dart';
import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
import 'package:control_center/features/rigs/presentation/rig_device_toolbar.dart';
import 'package:control_center/features/rigs/presentation/rig_panel.dart';
import 'package:control_center/features/rigs/presentation/rig_panel_chrome.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_audio_controls.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:record/record.dart';

class _StubChannel implements RemoteRpcChannelPort {
  @override
  Stream<Map<String, dynamic>> get incoming => const Stream.empty();

  @override
  Stream<RemoteChannelState> get state => const Stream.empty();

  @override
  bool get isOpen => false;

  @override
  Future<void> send(Map<String, dynamic> frame) async {}

  @override
  Future<void> close() async {}
}

class _RecordingRigRepository extends RemoteRigRepository {
  _RecordingRigRepository() : super(RemoteRpcClient(_StubChannel()));

  final List<(String, String)> unrestrictedRestarts = [];

  @override
  Future<RigView> restartUnrestricted(String workspaceId, String rigId) async {
    unrestrictedRestarts.add((workspaceId, rigId));
    return const RigView(
      id: 'rig-open-network',
      surface: 'computer',
      backendLabel: 'QEMU',
      phase: 'ready',
      accelerated: true,
      unrestrictedNetwork: true,
    );
  }
}

void main() {
  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: CcTheme(
      data: CcThemeData(
        tokens: DesignSystemTokens.light(),
        brightness: CcBrightness.light,
      ),
      child: Scaffold(body: child),
    ),
  );

  const rig = RigView(
    id: 'rig-1',
    surface: 'computer',
    backendLabel: 'QEMU',
    phase: 'ready',
    accelerated: true,
  );

  const lifecycleRig = RigView(
    id: 'rig-lifecycle',
    surface: 'computer',
    backendLabel: 'QEMU',
    phase: 'ready',
    accelerated: true,
    displayWidth: 640,
    displayHeight: 480,
  );

  const unrestrictedRig = RigView(
    id: 'rig-open-network',
    surface: 'computer',
    backendLabel: 'QEMU',
    phase: 'ready',
    accelerated: true,
    unrestrictedNetwork: true,
  );

  const iosRig = RigView(
    id: 'rig-ios',
    surface: 'ios',
    backendLabel: 'iOS Simulator',
    phase: 'ready',
    accelerated: true,
    egressEnforced: false,
    displayWidth: 390,
    displayHeight: 844,
  );

  testWidgets(
    'display size and media controls sit flush against the trailing edge',
    (tester) async {
      // Regression: a loose Flexible next to a Spacer split leftover slack
      // 1:1 and parked the size + buttons in the middle of a wide panel.
      tester.view.physicalSize = const Size(1200, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        app(
          RigHeader(
            rig: lifecycleRig,
            onStop: () {},
            onToggleAudio: () {},
            onToggleMicrophone: () {},
            onNetworkSecurity: () {},
          ),
        ),
      );

      expect(find.text('640×480'), findsOneWidget);
      final trailing = tester.getTopRight(
        find.byWidgetPredicate(
          (w) => w is CcIconButton && w.icon == AppIcons.power,
        ),
      );
      expect(trailing.dx, closeTo(1200 - AppSpacing.md, 0.5));
    },
  );

  testWidgets('computer header exposes independent output and input controls', (
    tester,
  ) async {
    var microphoneToggles = 0;
    await tester.pumpWidget(
      app(
        RigHeader(
          rig: rig,
          onToggleAudio: () {},
          onToggleMicrophone: () => microphoneToggles++,
        ),
      ),
    );

    expect(find.byIcon(AppIcons.volumeOff), findsOneWidget);
    expect(find.byIcon(AppIcons.micOff), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.micOff));
    expect(microphoneToggles, 1);
  });

  testWidgets('network bypass stays visible and names its control', (
    tester,
  ) async {
    var opens = 0;
    await tester.pumpWidget(
      app(RigHeader(rig: unrestrictedRig, onNetworkSecurity: () => opens++)),
    );

    expect(find.text('Network unrestricted'), findsOneWidget);
    expect(find.byIcon(AppIcons.shieldOff), findsOneWidget);
    await tester.tap(find.byIcon(AppIcons.shieldOff));
    expect(opens, 1);
  });

  testWidgets('network bypass requires confirmation before restart', (
    tester,
  ) async {
    final repository = _RecordingRigRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rigRepositoryProvider.overrideWithValue(repository)],
        child: app(
          const SizedBox(
            width: 640,
            height: 480,
            child: RigPanel(workspaceId: 'ws-1', rig: lifecycleRig),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(AppIcons.shield));
    await tester.pumpAndSettle();
    expect(find.text('Allow every network host?'), findsOneWidget);
    expect(repository.unrestrictedRestarts, isEmpty);

    await tester.tap(find.text('Restart unrestricted'));
    await tester.pumpAndSettle();
    expect(repository.unrestrictedRestarts, [('ws-1', 'rig-lifecycle')]);
  });

  testWidgets('iOS exposes input without desktop-only controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: app(
          const SizedBox(
            width: 640,
            height: 480,
            child: RigPanel(workspaceId: 'ws-1', rig: iosRig),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(AppIcons.shield), findsNothing);
    expect(find.byIcon(AppIcons.shieldOff), findsNothing);
    expect(find.byIcon(AppIcons.volumeOff), findsNothing);
    expect(find.byIcon(AppIcons.micOff), findsNothing);
    expect(find.byType(RigDeviceToolbar), findsOneWidget);
    expect(find.byIcon(AppIcons.house), findsOneWidget);
    expect(find.byIcon(AppIcons.rotateCw), findsOneWidget);
    expect(find.byIcon(AppIcons.rotateCcw), findsOneWidget);
    expect(find.byIcon(AppIcons.image), findsOneWidget);
  });

  testWidgets('tab media indicators mute output and suppress microphone', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        audioOutputDevicesProvider.overrideWith((ref) async => []),
        audioInputDevicesProvider.overrideWith((ref) async => []),
      ],
    );
    addTearDown(container.dispose);
    final key = Object();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: app(
          RigTabAudioIndicators(
            tabKey: key,
            color: const Color(0xff222222),
            supportsOutput: true,
            supportsMicrophone: true,
          ),
        ),
      ),
    );
    final notifier = container.read(rigTabAudioProvider(key).notifier);
    notifier
      ..setOutputPlaying(true)
      ..setMicrophoneEnabled(true);
    await tester.pump();

    expect(find.byIcon(AppIcons.volume2), findsOneWidget);
    expect(find.byIcon(AppIcons.mic), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.volume2));
    await tester.pump();
    expect(container.read(rigTabAudioProvider(key)).outputEnabled, isFalse);
    expect(find.byIcon(AppIcons.volume2), findsNothing);
    expect(find.byIcon(AppIcons.volumeOff), findsOneWidget);
    expect(find.byIcon(AppIcons.mic), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.mic));
    await tester.pump();
    expect(container.read(rigTabAudioProvider(key)).microphoneEnabled, isFalse);
    expect(find.byIcon(AppIcons.mic), findsNothing);
    expect(find.byIcon(AppIcons.micOff), findsOneWidget);
  });

  testWidgets('audio keeps playing while hidden rendering pauses', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final key = Object();
    final keepAlive = container.listen(rigTabAudioProvider(key), (_, _) {});
    addTearDown(keepAlive.close);
    final notifier = container.read(rigTabAudioProvider(key).notifier)
      ..setOutputEnabled(true);

    Widget panel({required bool paused}) => UncontrolledProviderScope(
      container: container,
      child: app(
        SizedBox(
          width: 640,
          height: 480,
          child: RigPanel(
            workspaceId: 'ws-1',
            rig: lifecycleRig,
            paused: paused,
            audioTabKey: key,
          ),
        ),
      ),
    );

    await tester.pumpWidget(panel(paused: false));
    await tester.pump();
    notifier.setOutputPlaying(true);

    await tester.pumpWidget(panel(paused: true));
    expect(tester.takeException(), isNull);
    expect(container.read(rigTabAudioProvider(key)).outputPlaying, isTrue);

    await tester.pumpWidget(panel(paused: false));
    await tester.pump();
    notifier.setOutputPlaying(true);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
    expect(container.read(rigTabAudioProvider(key)).outputPlaying, isTrue);
  });

  testWidgets('rig tab menu owns independent input and output devices', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        audioOutputDevicesProvider.overrideWith(
          (ref) async => const [AudioDevice('coreaudio/1', 'Studio monitors')],
        ),
        audioInputDevicesProvider.overrideWith(
          (ref) async => const [
            InputDevice(id: 'input-1', label: 'Studio microphone'),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    final key = Object();
    final keepAlive = container.listen(rigTabAudioProvider(key), (_, _) {});
    addTearDown(keepAlive.close);
    await container.read(audioOutputDevicesProvider.future);
    await container.read(audioInputDevicesProvider.future);
    late List<CcMenuItem> items;
    late List<CcMenuItem> unsupportedItems;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: app(
          Consumer(
            builder: (context, ref, _) {
              items = rigTabAudioMenuItems(
                context: context,
                ref: ref,
                tabKey: key,
                supportsOutput: true,
                supportsMicrophone: true,
              );
              unsupportedItems = rigTabAudioMenuItems(
                context: context,
                ref: ref,
                tabKey: key,
                supportsOutput: false,
                supportsMicrophone: false,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final output = items.firstWhere((item) => item.label == 'Audio output');
    final input = items.firstWhere((item) => item.label == 'Audio input');
    expect(items[0].enabled, isTrue);
    expect(items[1].enabled, isTrue);
    expect(output.children.first.label, 'System default');
    expect(input.children.first.label, 'System default');
    expect(output.children.first.selected, isTrue);
    expect(input.children.first.selected, isTrue);
    expect(output.children.last.label, 'Studio monitors');
    expect(input.children.last.label, 'Studio microphone');

    output.children.last.onSelected();
    input.children.last.onSelected();
    final state = container.read(rigTabAudioProvider(key));
    expect(state.outputDeviceName, 'coreaudio/1');
    expect(state.inputDeviceId, 'input-1');
    final otherKey = Object();
    final otherKeepAlive = container.listen(
      rigTabAudioProvider(otherKey),
      (_, _) {},
    );
    addTearDown(otherKeepAlive.close);
    final other = container.read(rigTabAudioProvider(otherKey));
    expect(other.outputDeviceName, isNull);
    expect(other.inputDeviceId, isNull);

    // Browser and mobile tabs still expose per-tab device choices, but do not
    // offer capture/playback toggles their current drivers cannot satisfy.
    expect(unsupportedItems[0].enabled, isFalse);
    expect(unsupportedItems[1].enabled, isFalse);
    expect(
      unsupportedItems.where((item) => item.label == 'Audio output'),
      hasLength(1),
    );
    expect(
      unsupportedItems.where((item) => item.label == 'Audio input'),
      hasLength(1),
    );
  });

  testWidgets('active microphone is visible without relying on color', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(RigHeader(rig: rig, microphoneOn: true, onToggleMicrophone: () {})),
    );

    expect(find.byIcon(AppIcons.mic), findsOneWidget);
    expect(find.byIcon(AppIcons.micOff), findsNothing);
  });
}
