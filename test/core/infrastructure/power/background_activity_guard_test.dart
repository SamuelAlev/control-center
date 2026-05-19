import 'package:control_center/core/infrastructure/power/background_activity_guard.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NoopBackgroundActivityGuard', () {
    test('begin/end complete without doing anything', () async {
      const guard = NoopBackgroundActivityGuard();
      await expectLater(guard.begin('whatever'), completes);
      await expectLater(guard.end(), completes);
    });
  });

  group('MacosBackgroundActivityGuard', () {
    const channel = MethodChannel('test/power');
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    void record() {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
    }

    setUp(calls.clear);
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('begin invokes beginBackgroundActivity with the reason', () async {
      record();
      await const MacosBackgroundActivityGuard(channel)
          .begin('Recording a meeting');
      expect(calls.single.method, 'beginBackgroundActivity');
      expect(
        (calls.single.arguments as Map)['reason'],
        'Recording a meeting',
      );
    });

    test('end invokes endBackgroundActivity', () async {
      record();
      await const MacosBackgroundActivityGuard(channel).end();
      expect(calls.single.method, 'endBackgroundActivity');
    });

    test('a missing native handler is swallowed (older build)', () async {
      // No mock handler registered → MissingPluginException, must not throw.
      const guard = MacosBackgroundActivityGuard(channel);
      await expectLater(guard.begin('x'), completes);
      await expectLater(guard.end(), completes);
    });

    test('a native PlatformException is swallowed', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'boom', message: 'no nap for you');
      });
      const guard = MacosBackgroundActivityGuard(channel);
      await expectLater(guard.begin('x'), completes);
      await expectLater(guard.end(), completes);
    });
  });
}
