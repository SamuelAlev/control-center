import 'package:control_center/core/domain/ports/agent_question_port.dart';
import 'package:control_center/features/mcp/application/tools/ask_user_question_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeQuestionPort implements AgentQuestionPort {
  AgentQuestionRequest? lastRequest;
  AgentQuestionAnswer? nextAnswer;
  int callCount = 0;

  @override
  Future<AgentQuestionAnswer?> ask(AgentQuestionRequest request) async {
    callCount++;
    lastRequest = request;
    return nextAnswer;
  }
}

void main() {
  group('AskUserQuestionTool', () {
    late _FakeQuestionPort port;
    late AskUserQuestionTool tool;

    setUp(() {
      port = _FakeQuestionPort();
      tool = AskUserQuestionTool(questionPort: port);
    });

    group('metadata', () {
      test('has correct name', () {
        expect(tool.name, 'ask_user_question');
      });

      test('has valid inputSchema', () {
        final schema = tool.inputSchema;
        expect(schema['type'], 'object');
        expect(
          schema['required'],
          containsAll(['channel_id', 'question']),
        );
        final props = schema['properties'] as Map<String, dynamic>;
        expect((props['channel_id'] as Map<String, dynamic>)['type'], 'string');
        expect((props['question'] as Map<String, dynamic>)['type'], 'string');
        expect((props['options'] as Map<String, dynamic>)['type'], 'array');
        expect((props['allow_freeform'] as Map<String, dynamic>)['type'], 'boolean');
        expect((props['multi_select'] as Map<String, dynamic>)['type'], 'boolean');
        expect((props['context'] as Map<String, dynamic>)['type'], 'string');
      });
    });

    group('argument validation', () {
      test('returns error when question is missing', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('question'));
      });

      test('returns error when question is empty', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'question': '',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('question'));
      });

      test('returns error when question is not a string', () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'question': 42,
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('question'));
      });

      test('returns error when channel_id is missing', () async {
        final result = await tool.call({
          'question': 'What do you think?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('channel_id'));
      });

      test('returns error when channel_id is empty', () async {
        final result = await tool.call({
          'channel_id': '',
          'question': 'What do you think?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('channel_id'));
      });

      test('returns error when channel_id is not a string', () async {
        final result = await tool.call({
          'channel_id': 99,
          'question': 'What do you think?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('channel_id'));
      });
    });

    group('options parsing', () {
      test('parses valid options with label only', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          selectedLabels: ['Yes'],
        );
        await tool.call({
          'channel_id': 'ch-1',
          'question': 'Proceed?',
          'options': [
            {'label': 'Yes'},
            {'label': 'No'},
          ],
        });

        final req = port.lastRequest!;
        expect(req.options.length, 2);
        expect(req.options[0].label, 'Yes');
        expect(req.options[0].description, isNull);
        expect(req.options[1].label, 'No');
      });

      test('parses options with label and description', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          selectedLabels: ['Yes'],
        );
        await tool.call({
          'channel_id': 'ch-1',
          'question': 'Proceed?',
          'options': [
            {
              'label': 'Yes',
              'description': 'Continue with the operation',
            },
          ],
        });

        expect(port.lastRequest!.options[0].label, 'Yes');
        expect(
          port.lastRequest!.options[0].description,
          'Continue with the operation',
        );
      });

      test('parses options with label, description, and value', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          selectedLabels: ['Yes'],
        );
        await tool.call({
          'channel_id': 'ch-1',
          'question': 'Proceed?',
          'options': [
            {
              'label': 'Yes',
              'description': 'Continue',
              'value': 'y',
            },
          ],
        });

        expect(port.lastRequest!.options[0].label, 'Yes');
        expect(port.lastRequest!.options[0].description, 'Continue');
        expect(port.lastRequest!.options[0].value, 'y');
      });

      test('skips options without a label field', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          selectedLabels: ['Yes'],
        );
        await tool.call({
          'channel_id': 'ch-1',
          'question': 'Proceed?',
          'options': [
            {'description': 'no label here'},
            {'label': 'Yes'},
          ],
        });

        expect(port.lastRequest!.options.length, 1);
        expect(port.lastRequest!.options[0].label, 'Yes');
      });

      test('skips options with empty label', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          selectedLabels: ['Yes'],
        );
        await tool.call({
          'channel_id': 'ch-1',
          'question': 'Proceed?',
          'options': [
            {'label': ''},
            {'label': 'Yes'},
          ],
        });

        expect(port.lastRequest!.options.length, 1);
        expect(port.lastRequest!.options[0].label, 'Yes');
      });

      test('skips non-Map entries in options list', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          selectedLabels: ['Yes'],
        );
        await tool.call({
          'channel_id': 'ch-1',
          'question': 'Proceed?',
          'options': [
            'not a map',
            42,
            {'label': 'Yes'},
          ],
        });

        expect(port.lastRequest!.options.length, 1);
        expect(port.lastRequest!.options[0].label, 'Yes');
      });

      test('treats missing options as empty list', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          freeText: 'my answer',
        );
        await tool.call({
          'channel_id': 'ch-1',
          'question': 'What?',
          'allow_freeform': true,
        });

        expect(port.lastRequest!.options, isEmpty);
      });
    });

    group('allow_freeform / options mutual exclusivity', () {
      test('returns error when no options and allow_freeform is false',
          () async {
        final result = await tool.call({
          'channel_id': 'ch-1',
          'question': 'What?',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('allow_freeform'));
      });

      test('succeeds with allow_freeform true and no options', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          freeText: 'something',
        );
        final result = await tool.call({
          'channel_id': 'ch-1',
          'question': 'What?',
          'allow_freeform': true,
        });

        expect(result.isError, isFalse);
        expect(port.lastRequest!.allowFreeText, isTrue);
      });
    });

    group('success path', () {
      test('returns success with selected labels', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          selectedLabels: ['Option A', 'Option B'],
        );

        final result = await tool.call({
          'channel_id': 'ch-1',
          'question': 'Which options?',
          'options': [
            {'label': 'Option A'},
            {'label': 'Option B'},
            {'label': 'Option C'},
          ],
        });

        expect(result.isError, isFalse);
        expect(result.content.first.text, contains('Option A'));
        expect(result.content.first.text, contains('Option B'));
        expect(result.content.first.text, isNot(contains('Option C')));
      });

      test('returns success with free text answer', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          freeText: 'Here is my detailed response.',
        );

        final result = await tool.call({
          'channel_id': 'ch-1',
          'question': 'What do you think?',
          'allow_freeform': true,
        });

        expect(result.isError, isFalse);
        expect(
          result.content.first.text,
          contains('Here is my detailed response.'),
        );
      });

      test('returns success with both selections and free text', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          selectedLabels: ['Option A'],
          freeText: 'Additional notes here.',
        );

        final result = await tool.call({
          'channel_id': 'ch-1',
          'question': 'Choose and explain',
          'options': [
            {'label': 'Option A'},
            {'label': 'Option B'},
          ],
        });

        expect(result.isError, isFalse);
        expect(result.content.first.text, contains('Option A'));
        expect(result.content.first.text, contains('Additional notes here.'));
      });
    });

    group('request forwarding', () {
      test('passes channel_id as conversationId', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          selectedLabels: ['Yes'],
        );
        await tool.call({
          'channel_id': 'my-channel',
          'question': 'Proceed?',
          'options': [
            {'label': 'Yes'},
          ],
        });

        expect(port.lastRequest!.conversationId, 'my-channel');
      });

      test('passes context through', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          selectedLabels: ['Yes'],
        );
        await tool.call({
          'channel_id': 'ch-1',
          'question': 'Proceed?',
          'context': 'We need this for the auth flow',
          'options': [
            {'label': 'Yes'},
          ],
        });

        expect(
          port.lastRequest!.context,
          'We need this for the auth flow',
        );
      });

      test('passes context as null when omitted', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          selectedLabels: ['Yes'],
        );
        await tool.call({
          'channel_id': 'ch-1',
          'question': 'Proceed?',
          'options': [
            {'label': 'Yes'},
          ],
        });

        expect(port.lastRequest!.context, isNull);
      });

      test('passes multi_select flag', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          selectedLabels: ['A', 'B'],
        );
        await tool.call({
          'channel_id': 'ch-1',
          'question': 'Select many',
          'multi_select': true,
          'options': [
            {'label': 'A'},
            {'label': 'B'},
          ],
        });

        expect(port.lastRequest!.multiSelect, isTrue);
      });

      test('defaults multi_select to false', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          selectedLabels: ['A'],
        );
        await tool.call({
          'channel_id': 'ch-1',
          'question': 'Select one',
          'options': [
            {'label': 'A'},
          ],
        });

        expect(port.lastRequest!.multiSelect, isFalse);
      });
    });

    group('answer handling', () {
      test('returns error when port returns null', () async {
        port.nextAnswer = null;

        final result = await tool.call({
          'channel_id': 'ch-1',
          'question': 'Proceed?',
          'options': [
            {'label': 'Yes'},
          ],
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('dismissed'));
      });

      test('returns error when answer is empty', () async {
        port.nextAnswer = const AgentQuestionAnswer();

        final result = await tool.call({
          'channel_id': 'ch-1',
          'question': 'Proceed?',
          'options': [
            {'label': 'Yes'},
          ],
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('No answer'));
      });

      test('returns error when freeText is whitespace only', () async {
        port.nextAnswer = const AgentQuestionAnswer(freeText: '   ');

        final result = await tool.call({
          'channel_id': 'ch-1',
          'question': 'What?',
          'allow_freeform': true,
        });

        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('No answer'));
      });

      test('handles empty answer with (no answer) fallback', () async {
        // This tests toPromptString edge case via the success path —
        // a non-empty answer that somehow yields (no answer) can't happen
        // because isEmpty catches that before we get to success.
        // But we test isEmpty guard here.
        const ans = AgentQuestionAnswer();
        expect(ans.isEmpty, isTrue);
        expect(ans.toPromptString(), '(no answer)');
      });
    });

    group('edge cases', () {
      test('works with options that have label as only property', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          selectedLabels: ['Simple'],
        );
        final result = await tool.call({
          'channel_id': 'ch-1',
          'question': 'Simple?',
          'options': [
            {'label': 'Simple'},
          ],
        });

        expect(result.isError, isFalse);
        expect(result.content.first.text, contains('Simple'));
      });

      test('question text included in success message', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          selectedLabels: ['Yes'],
        );
        final result = await tool.call({
          'channel_id': 'ch-1',
          'question': 'Are you sure?',
          'options': [
            {'label': 'Yes'},
          ],
        });

        expect(
          result.content.first.text,
          contains('"Are you sure?"'),
        );
      });

      test('passes empty options list when options is not a List', () async {
        port.nextAnswer = const AgentQuestionAnswer(
          freeText: 'answer',
        );
        await tool.call({
          'channel_id': 'ch-1',
          'question': 'What?',
          'options': 'not-a-list',
          'allow_freeform': true,
        });

        expect(port.lastRequest!.options, isEmpty);
      });
    });
  });
}
