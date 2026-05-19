import 'package:cc_domain/features/dispatch/domain/advisor/advisor_advice.dart';
import 'package:cc_domain/features/dispatch/domain/advisor/advisor_runtime.dart';
import 'package:cc_domain/features/dispatch/domain/advisor/secret_obfuscator.dart';
import 'package:cc_domain/features/dispatch/domain/steering/steering_queue.dart';
import 'package:flutter_test/flutter_test.dart';

class _ScriptedResponder implements AdvisorResponder {
  _ScriptedResponder(this.script);
  final List<Object?> script; // AdvisorAdvice | Exception | null
  final List<String> seen = [];
  int _i = 0;

  @override
  Future<AdvisorAdvice?> review(String deltaTranscript) async {
    seen.add(deltaTranscript);
    final next = _i < script.length ? script[_i++] : null;
    if (next is Exception) {
      throw next;
    }
    return next as AdvisorAdvice?;
  }
}

AdvisorTranscriptMessage _msg(String role, String content, {bool pinned = false}) =>
    AdvisorTranscriptMessage(role: role, content: content, pinned: pinned);

void main() {
  group('secret obfuscation', () {
    test('redacts common credential shapes', () {
      expect(obfuscateSecrets('key sk-abcdefghijklmnopqrstuvwx'),
          contains(kRedactedToken));
      expect(obfuscateSecrets('ghp_0123456789abcdefghijklmnopqrstuvwx'),
          contains(kRedactedToken));
      expect(obfuscateSecrets('token = supersecretvalue123'),
          contains(kRedactedToken));
      expect(
        obfuscateSecrets('AKIAIOSFODNN7EXAMPLE used'),
        contains(kRedactedToken),
      );
    });

    test('leaves ordinary prose untouched', () {
      const prose = 'The agent edited main.dart and ran the tests.';
      expect(obfuscateSecrets(prose), prose);
    });
  });

  group('AdvisorRuntime', () {
    test('enqueues a concern as an interrupting steering message', () async {
      final queue = SteeringQueue();
      final runtime = AdvisorRuntime(
        responder: _ScriptedResponder([
          const AdvisorAdvice(
            severity: AdvisorSeverity.concern,
            message: 'This deletes data.',
          ),
        ]),
        queue: queue,
      );
      await runtime.observe([_msg('assistant', 'rm -rf /tmp/x')]);
      expect(queue.hasSteering, isTrue);
      expect(queue.hasAside, isFalse);
      expect(queue.drainSteering().single.content, contains('advisor:concern'));
    });

    test('enqueues a nit as a passive aside', () async {
      final queue = SteeringQueue();
      final runtime = AdvisorRuntime(
        responder: _ScriptedResponder([
          const AdvisorAdvice(severity: AdvisorSeverity.nit, message: 'Typo.'),
        ]),
        queue: queue,
      );
      await runtime.observe([_msg('assistant', 'hello')]);
      expect(queue.hasAside, isTrue);
      expect(queue.hasSteering, isFalse);
    });

    test('only sends NEW messages since the last cursor', () async {
      final queue = SteeringQueue();
      final responder = _ScriptedResponder([null, null]);
      final runtime = AdvisorRuntime(responder: responder, queue: queue);

      await runtime.observe([_msg('assistant', 'first')]);
      await runtime.observe([_msg('assistant', 'first'), _msg('assistant', 'second')]);

      expect(responder.seen[0], contains('first'));
      expect(responder.seen[1], contains('second'));
      expect(responder.seen[1], isNot(contains('first')));
    });

    test('dedups re-injected pinned prompts across turns', () async {
      final queue = SteeringQueue();
      final responder = _ScriptedResponder([null, null]);
      final runtime = AdvisorRuntime(responder: responder, queue: queue);

      await runtime.observe([_msg('plan', 'THE PLAN', pinned: true)]);
      // Same pinned plan re-injected plus a new line.
      await runtime.observe([
        _msg('plan', 'THE PLAN', pinned: true),
        _msg('assistant', 'did the thing'),
      ]);

      expect(responder.seen[1], isNot(contains('THE PLAN')));
      expect(responder.seen[1], contains('did the thing'));
    });

    test('backs off after the configured consecutive failures', () async {
      final queue = SteeringQueue();
      final runtime = AdvisorRuntime(
        responder: _ScriptedResponder([
          Exception('boom1'),
          Exception('boom2'),
        ]),
        queue: queue,
        maxConsecutiveFailures: 2,
      );
      // observe() takes the cumulative transcript and reviews the delta since
      // the last cursor, so each turn appends a new message.
      final a = _msg('assistant', 'a');
      final b = _msg('assistant', 'b');
      final c = _msg('assistant', 'c');
      await runtime.observe([a]);
      expect(runtime.isDisabled, isFalse);
      await runtime.observe([a, b]);
      expect(runtime.isDisabled, isTrue);
      // Disabled: a further observe is a no-op and never calls the responder.
      final advice = await runtime.observe([a, b, c]);
      expect(advice, isNull);
    });

    test('obfuscates secrets before the advisor sees the transcript', () async {
      final queue = SteeringQueue();
      final responder = _ScriptedResponder([null]);
      final runtime = AdvisorRuntime(responder: responder, queue: queue);
      await runtime.observe([
        _msg('assistant', 'export TOKEN=ghp_0123456789abcdefghijklmnopqrstuvwx'),
      ]);
      expect(responder.seen.single, contains(kRedactedToken));
      expect(responder.seen.single, isNot(contains('ghp_0123456789')));
    });
  });
}
