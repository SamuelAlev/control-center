import 'package:cc_harness/loop.dart';
import 'package:test/test.dart';

class _RecordingHooks implements AgentLoopHooks {
  final calls = <String>[];
  bool allow = true;

  @override
  bool get interceptsTools => true;

  @override
  Future<void> onSessionStart() async => calls.add('start');

  @override
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args) async {
    calls.add('pre:$toolName');
    return allow;
  }

  @override
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  }) async => calls.add('post:$toolName:$isError');
}

void main() {
  group('NestedRunHooks', () {
    test('forwards the tool gate and observation to the parent', () async {
      final parent = _RecordingHooks()..allow = false;
      final nested = NestedRunHooks(parent);
      expect(nested.interceptsTools, isTrue);
      expect(await nested.preToolUse('bash', const {'command': 'rm'}), isFalse);
      await nested.postToolUse('bash', 'out', isError: true);
      expect(parent.calls, ['pre:bash', 'post:bash:true']);
    });

    test('does not re-fire the session-start hook', () async {
      final parent = _RecordingHooks();
      await NestedRunHooks(parent).onSessionStart();
      expect(parent.calls, isEmpty);
    });
  });

  group('SteeringQueue.nestedView', () {
    test('surfaces each message once without consuming it', () {
      final parent = SteeringQueue();
      final delivered = <String>[];
      parent.onDrained = (m) => delivered.add(m.content);
      final view = parent.nestedView();

      parent
        ..pushSteering('focus on tests')
        ..pushAside('fyi');
      expect(view.hasSteering, isTrue);
      expect(
        [for (final m in view.drainSteering()) m.content],
        ['focus on tests'],
      );
      expect([for (final m in view.drainAside()) m.content], ['fyi']);
      // Seen once: a second drain of the view is empty...
      expect(view.drainSteering(), isEmpty);
      expect(view.hasSteering, isFalse);
      expect(view.isEmpty, isTrue);
      // ...and nothing was consumed or reported delivered on the parent.
      expect(delivered, isEmpty);
      expect(parent.hasSteering, isTrue);
      expect(
        [for (final m in parent.drainSteering()) m.content],
        ['focus on tests'],
      );
      expect(delivered, ['focus on tests']);
    });

    test('never surfaces follow-ups; they stay with the parent', () {
      final parent = SteeringQueue()..pushFollowUp('then do X');
      final view = parent.nestedView();
      expect(view.hasFollowUp, isFalse);
      expect(view.drainFollowUp(), isEmpty);
      expect(parent.drainFollowUp().single.content, 'then do X');
    });

    test('a message enqueued through the view lands on the parent', () {
      final parent = SteeringQueue();
      parent.nestedView().pushSteering('from child side');
      expect(parent.drainSteering().single.content, 'from child side');
    });
  });
}
