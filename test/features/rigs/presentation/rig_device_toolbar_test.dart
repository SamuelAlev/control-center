import 'package:cc_data/cc_data.dart' show RemoteRigRepository, RigView;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/rig_device_toolbar.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

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

class _RecordingRepository extends RemoteRigRepository {
  _RecordingRepository() : super(RemoteRpcClient(_StubChannel()));

  final actions = <Map<String, dynamic>>[];

  @override
  Future<
    ({String text, bool isError, String? imageBase64, String? imageMediaType})
  >
  act({
    required String workspaceId,
    required String rigId,
    required Map<String, dynamic> action,
  }) async {
    actions.add(Map<String, dynamic>.from(action));
    return (
      text: 'ok',
      isError: false,
      imageBase64: null,
      imageMediaType: null,
    );
  }
}

Finder _button(String tooltip) =>
    find.byWidgetPredicate((w) => w is CcIconButton && w.tooltip == tooltip);

void main() {
  const android = RigView(
    id: 'android-1',
    surface: 'mobile',
    backendLabel: 'Android emulator',
    phase: 'ready',
    accelerated: true,
    egressEnforced: false,
    displayWidth: 1080,
    displayHeight: 1920,
  );

  const ios = RigView(
    id: 'ios-1',
    surface: 'ios',
    backendLabel: 'iOS Simulator',
    phase: 'ready',
    accelerated: true,
    egressEnforced: false,
    displayWidth: 390,
    displayHeight: 844,
  );

  Future<_RecordingRepository> pump(
    WidgetTester tester,
    RigView rig, {
    TextDirection? textDirection,
  }) async {
    final repository = _RecordingRepository();
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [rigRepositoryProvider.overrideWithValue(repository)],
          child: RigDeviceToolbar(workspaceId: 'ws-1', rig: rig),
        ),
        textDirection: textDirection,
      ),
    );
    return repository;
  }

  testWidgets('Android sends rotate, home key, and a full-resolution still', (
    tester,
  ) async {
    final repository = await pump(tester, android);

    await tester.tap(_button('Rotate counterclockwise'));
    await tester.pumpAndSettle();
    await tester.tap(_button('Rotate clockwise'));
    await tester.pumpAndSettle();
    await tester.tap(_button('Home'));
    await tester.pumpAndSettle();
    await tester.tap(_button('Take a screenshot'));
    await tester.pumpAndSettle();

    expect(repository.actions, [
      {'action': 'rotate', 'direction': 'counterclockwise'},
      {'action': 'rotate', 'direction': 'clockwise'},
      {'action': 'key', 'key': 'home'},
      {'action': 'screenshot', 'full_resolution': true},
    ]);
  });

  testWidgets('iOS home is the simulator Home button, not a key', (
    tester,
  ) async {
    final repository = await pump(tester, ios);

    await tester.tap(_button('Home'));
    await tester.pumpAndSettle();

    expect(repository.actions, [
      {'action': 'home'},
    ]);
  });

  testWidgets('an agent in control keeps rotate and home off', (tester) async {
    final repository = await pump(
      tester,
      const RigView(
        id: 'ios-1',
        surface: 'ios',
        backendLabel: 'iOS Simulator',
        phase: 'ready',
        accelerated: true,
        egressEnforced: false,
        controller: 'agent:bot-1',
      ),
    );

    expect(tester.widget<CcIconButton>(_button('Home')).onPressed, isNull);
    expect(
      tester.widget<CcIconButton>(_button('Rotate clockwise')).onPressed,
      isNull,
    );
    expect(
      tester.widget<CcIconButton>(_button('Take a screenshot')).onPressed,
      isNotNull,
    );

    await tester.tap(_button('Home'));
    await tester.tap(_button('Take a screenshot'));
    await tester.pumpAndSettle();

    expect(repository.actions, [
      {'action': 'screenshot', 'full_resolution': true},
    ]);
  });

  testWidgets('chrome stays present under RTL', (tester) async {
    await pump(tester, android, textDirection: TextDirection.rtl);
    expect(_button('Home'), findsOneWidget);
    expect(_button('Rotate clockwise'), findsOneWidget);
    expect(_button('Take a screenshot'), findsOneWidget);
  });
}
