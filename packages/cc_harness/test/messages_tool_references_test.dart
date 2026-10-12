import 'dart:convert';

import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:test/test.dart';

const _reference = ToolOutputReference(
  handle: 'h-1',
  toolName: 'bash',
  byteLength: 40000,
  charLength: 39000,
);

void main() {
  group('HarnessToolResultBlock tool references', () {
    test('defaults to no references and no output handle', () {
      const block = HarnessToolResultBlock(toolUseId: 't1', content: 'ok');
      expect(block.toolReferences, isEmpty);
      expect(block.outputReference, isNull);
      expect(block.portableContent, 'ok');
    });

    test('portableContent names the activated tools', () {
      const block = HarnessToolResultBlock(
        toolUseId: 't1',
        content: 'found 2 tools',
        toolReferences: ['read_file', 'write_file'],
      );
      expect(
        block.portableContent,
        'found 2 tools\n\nActivated tools: read_file, write_file.',
      );
    });

    test('portableContent carries a reference-only activation', () {
      const block = HarnessToolResultBlock(
        toolUseId: 't1',
        content: '',
        toolReferences: ['read_file'],
      );
      expect(block.portableContent, 'Activated tools: read_file.');
    });

    test('round-trips references and the output handle through JSON', () {
      const block = HarnessToolResultBlock(
        toolUseId: 't1',
        content: 'head…[output omitted]',
        toolReferences: ['read_file'],
        outputReference: _reference,
      );
      final json = block.toJson();
      expect(json['output_reference'], _reference.toJson());
      expect(json['tool_references'], ['read_file']);

      final restored = HarnessContentBlock.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );
      expect(restored, block);
      final restoredBlock = restored as HarnessToolResultBlock;
      expect(restoredBlock.outputReference, _reference);
      expect(restoredBlock.toolReferences, ['read_file']);
    });

    test('a transcript written before references still loads', () {
      final restored = HarnessContentBlock.fromJson({
        'type': 'tool_result',
        'tool_use_id': 't1',
        'content': 'ok',
      });
      final block = restored as HarnessToolResultBlock;
      expect(block.outputReference, isNull);
      expect(block.toolReferences, isEmpty);
    });

    test('a non-map output_reference is ignored rather than fatal', () {
      final restored = HarnessContentBlock.fromJson({
        'type': 'tool_result',
        'tool_use_id': 't1',
        'content': 'ok',
        'output_reference': 'not-a-map',
      });
      expect((restored as HarnessToolResultBlock).outputReference, isNull);
    });

    test('equality and hashCode include the new fields', () {
      const base = HarnessToolResultBlock(toolUseId: 't1', content: 'ok');
      const withReference = HarnessToolResultBlock(
        toolUseId: 't1',
        content: 'ok',
        outputReference: _reference,
      );
      const withToolReferences = HarnessToolResultBlock(
        toolUseId: 't1',
        content: 'ok',
        toolReferences: ['read_file'],
      );
      expect(base == withReference, isFalse);
      expect(base == withToolReferences, isFalse);
      expect(
        withToolReferences.hashCode == base.hashCode,
        isFalse,
        reason: 'a replay diff must see an added activation',
      );
      expect(
        const HarnessToolResultBlock(
          toolUseId: 't1',
          content: 'ok',
          toolReferences: ['read_file'],
        ),
        withToolReferences,
      );
    });

    test('copyWith attaches a handle and references', () {
      const base = HarnessToolResultBlock(toolUseId: 't1', content: 'ok');
      final next = base.copyWith(
        content: 'ok…[output omitted]',
        outputReference: _reference,
        toolReferences: const ['read_file'],
      );
      expect(next.toolUseId, 't1');
      expect(next.content, 'ok…[output omitted]');
      expect(next.outputReference, _reference);
      expect(next.toolReferences, ['read_file']);
      // The original is untouched.
      expect(base.outputReference, isNull);
      expect(base.toolReferences, isEmpty);
    });
  });

  group('HarnessMessage activation metadata', () {
    test('is absent by default and serialized only when set', () {
      final plain = HarnessMessage.user('hi');
      expect(plain.activatedToolNames, isEmpty);
      expect(plain.toJson().containsKey('activated_tool_names'), isFalse);
    });

    test('round-trips through JSON on the message and its factories', () {
      final message = HarnessMessage.toolResults(
        const [HarnessToolResultBlock(toolUseId: 't1', content: 'ok')],
        activatedToolNames: const ['write_file', 'deploy'],
      );
      final json = jsonDecode(jsonEncode(message.toJson()));
      final restored = HarnessMessage.fromJson(json as Map<String, dynamic>);
      expect(restored.activatedToolNames, ['write_file', 'deploy']);
      expect(restored, message);
    });

    test('tolerates a transcript written before the metadata existed', () {
      final restored = HarnessMessage.fromJson({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': 'hi'},
        ],
      });
      expect(restored.activatedToolNames, isEmpty);
      final junk = HarnessMessage.fromJson({
        'role': 'user',
        'content': const [],
        'activated_tool_names': ['ok', 42, null],
      });
      expect(junk.activatedToolNames, ['ok']);
    });

    test('equality treats the metadata as a set and includes it', () {
      const a = HarnessMessage(
        role: HarnessRole.user,
        content: [HarnessTextBlock('x')],
        activatedToolNames: ['b', 'a'],
      );
      const b = HarnessMessage(
        role: HarnessRole.user,
        content: [HarnessTextBlock('x')],
        activatedToolNames: ['a', 'b'],
      );
      expect(a, b, reason: 'the same activation in another order');
      expect(a.hashCode, b.hashCode);

      const without = HarnessMessage(
        role: HarnessRole.user,
        content: [HarnessTextBlock('x')],
      );
      expect(
        a == without,
        isFalse,
        reason: 'a fold that drops the activation changed the history',
      );
      expect(
        a ==
            const HarnessMessage(
              role: HarnessRole.user,
              content: [HarnessTextBlock('x')],
              activatedToolNames: ['a'],
            ),
        isFalse,
        reason: 'a dropped NAME must be visible to the diff',
      );
    });

    test('copyWith replaces the metadata or leaves it alone', () {
      const base = HarnessMessage(
        role: HarnessRole.user,
        content: [HarnessTextBlock('x')],
        activatedToolNames: ['a'],
      );
      final carried = base.copyWith(
        content: const [HarnessTextBlock('summary')],
        activatedToolNames: const ['a', 'b'],
      );
      expect(carried.textContent, 'summary');
      expect(carried.activatedToolNames, ['a', 'b']);
      expect(base.copyWith().activatedToolNames, ['a']);
    });
  });
}
