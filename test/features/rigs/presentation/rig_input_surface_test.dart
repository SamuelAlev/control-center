import 'package:cc_data/cc_data.dart' show RemoteRigRepository, RigView;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/features/rigs/presentation/rig_input_surface.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  const rig = RigView(
    id: 'ios-1',
    surface: 'ios',
    backendLabel: 'iOS Simulator',
    phase: 'ready',
    accelerated: true,
    egressEnforced: false,
    displayWidth: 100,
    displayHeight: 200,
  );

  Future<_RecordingRepository> pump(WidgetTester tester) async {
    final repository = _RecordingRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rigRepositoryProvider.overrideWithValue(repository)],
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 200,
              height: 400,
              child: RigInputSurface(
                workspaceId: 'ws-1',
                rig: rig,
                enabled: true,
                active: true,
                child: ColoredBox(color: Color(0xff000000)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return repository;
  }

  testWidgets('iOS sends one tap in simulator points and no mouse verbs', (
    tester,
  ) async {
    final repository = await pump(tester);
    final center = tester.getCenter(find.byType(RigInputSurface));

    await tester.tapAt(center);
    await tester.pumpAndSettle();

    expect(repository.actions, [
      {
        'action': 'tap',
        'coordinate': [50, 100],
      },
    ]);
  });

  testWidgets('iOS converts a drag to one swipe and ignores hover', (
    tester,
  ) async {
    final repository = await pump(tester);
    final rect = tester.getRect(find.byType(RigInputSurface));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: rect.center);
    await mouse.moveTo(rect.topLeft + const Offset(30, 60));
    await tester.pump();
    expect(repository.actions, isEmpty);

    await tester.timedDragFrom(
      rect.topLeft + const Offset(20, 40),
      const Offset(160, 320),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();

    expect(repository.actions, hasLength(1));
    expect(repository.actions.single['action'], 'swipe');
    expect(repository.actions.single['from'], [10, 20]);
    expect(repository.actions.single['to'], [90, 180]);
    expect(repository.actions.single.containsKey('duration_ms'), isTrue);
  });

  testWidgets('a cancelled iOS press sends no partial gesture', (tester) async {
    final repository = await pump(tester);
    final center = tester.getCenter(find.byType(RigInputSurface));
    final pointer = TestPointer(7, PointerDeviceKind.touch);

    await tester.sendEventToBinding(pointer.down(center));
    await tester.sendEventToBinding(pointer.cancel());
    await tester.pumpAndSettle();

    expect(repository.actions, isEmpty);
  });
}
