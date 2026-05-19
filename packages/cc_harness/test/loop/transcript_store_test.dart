import 'dart:convert';

import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:test/test.dart';

HarnessMessage user(String text) => HarnessMessage.user(text);
HarnessMessage assistant(String text) => HarnessMessage.assistant(text);
HarnessMessage toolResult(String id, String content) =>
    HarnessMessage.toolResults([
      HarnessToolResultBlock(toolUseId: id, content: content),
    ]);

void main() {
  group('HarnessTranscript round trip', () {
    test('survives json, keeping roles and text', () {
      final original = HarnessTranscript(
        messages: [user('do the thing'), assistant('doing it')],
        checkpoints: const {'before-refactor': 1},
        turns: 4,
      );
      final restored = HarnessTranscript.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.messages, hasLength(2));
      expect(restored.messages.first.role, HarnessRole.user);
      expect(restored.messages.first.textContent, 'do the thing');
      expect(restored.messages.last.role, HarnessRole.assistant);
      expect(restored.checkpoints, {'before-refactor': 1});
      expect(restored.turns, 4);
    });

    test('carries tool results, not just text', () {
      // The whole difference between a resume and a re-tell: the model sees
      // what its tools actually returned, rather than a summary of them.
      final original = HarnessTranscript(
        messages: [
          assistant('reading'),
          toolResult('call_1', 'file contents here'),
        ],
      );
      final restored = HarnessTranscript.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      final block = restored.messages.last.content.single;
      expect(block, isA<HarnessToolResultBlock>());
      expect((block as HarnessToolResultBlock).toolUseId, 'call_1');
      expect(block.content, 'file contents here');
    });

    test('drops a checkpoint pointing past the restored history', () {
      // Clamping would silently retarget the rewind at whatever happens to be
      // last, which is exactly the failure a label exists to prevent.
      final restored = HarnessTranscript.fromJson({
        'messages': [user('a').toJson()],
        'checkpoints': {'ok': 1, 'stale': 9, 'negative': -1},
      });
      expect(restored.checkpoints, {'ok': 1});
    });

    test('a corrupt record yields an empty transcript, not an exception', () {
      final restored = HarnessTranscript.fromJson({'messages': 'not a list'});
      expect(restored.messages, isEmpty);
      expect(restored.checkpoints, isEmpty);
    });
  });

  group('trimTranscriptForResume', () {
    test('keeps a short transcript untouched', () {
      final t = HarnessTranscript(
        messages: [for (var i = 0; i < 10; i++) user('$i')],
      );
      expect(identical(trimTranscriptForResume(t), t), isTrue);
    });

    test('keeps the newest messages', () {
      final t = HarnessTranscript(
        messages: [for (var i = 0; i < 20; i++) user('$i')],
      );
      final trimmed = trimTranscriptForResume(t, maxMessages: 5);
      expect(trimmed.messages, hasLength(5));
      expect(trimmed.messages.first.textContent, '15');
      expect(trimmed.messages.last.textContent, '19');
    });

    test('never starts on an orphaned tool result', () {
      // A tool_result whose tool_use was trimmed away is a message no provider
      // will accept — a transcript that cannot be sent is worse than a short
      // one.
      final t = HarnessTranscript(
        messages: [
          user('0'),
          assistant('1'),
          toolResult('a', 'r1'),
          toolResult('b', 'r2'),
          user('4'),
        ],
      );
      final trimmed = trimTranscriptForResume(t, maxMessages: 3);
      expect(trimmed.messages.first.role, isNot(HarnessRole.tool));
      expect(trimmed.messages.map((m) => m.textContent), contains('4'));
    });

    test('remaps checkpoints that survive and drops those that do not', () {
      final t = HarnessTranscript(
        messages: [for (var i = 0; i < 20; i++) user('$i')],
        checkpoints: const {'early': 2, 'late': 18},
      );
      final trimmed = trimTranscriptForResume(t, maxMessages: 5);
      expect(trimmed.checkpoints.containsKey('early'), isFalse);
      expect(trimmed.checkpoints['late'], 3);
    });
  });

  group('InMemoryHarnessTranscriptStore', () {
    test('saves, loads and clears by key', () async {
      final store = InMemoryHarnessTranscriptStore();
      expect(await store.load('conv1'), isNull);

      await store.save(
        'conv1',
        HarnessTranscript(messages: [user('hello')]),
      );
      expect((await store.load('conv1'))!.messages.single.textContent, 'hello');
      expect(await store.load('conv2'), isNull);

      await store.clear('conv1');
      expect(await store.load('conv1'), isNull);
    });
  });

  group('NoopHarnessTranscriptStore', () {
    test('remembers nothing, so the loop never branches on null', () async {
      const store = NoopHarnessTranscriptStore();
      await store.save('k', HarnessTranscript(messages: [user('x')]));
      expect(await store.load('k'), isNull);
    });
  });
}
