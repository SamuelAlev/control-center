import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_mcp/src/tools/request_confirmation_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAgentQuestionPort implements AgentQuestionPort {
  final _answers = <String, AgentQuestionAnswer?>{};
  final _requests = <AgentQuestionRequest>[];
  int _callCount = 0;

  AgentQuestionRequest get lastRequest => _requests.last;
  int get callCount => _callCount;

  void enqueue(AgentQuestionAnswer? answer) {
    _answers['$_callCount'] = answer;
    _callCount++;
  }

  @override
  Future<AgentQuestionAnswer?> ask(AgentQuestionRequest request) async {
    _requests.add(request);
    final answer = _answers['${_requests.length - 1}'];
    return answer;
  }
}

void main() {
  group('RequestConfirmationTool', () {
    late _FakeAgentQuestionPort fakePort;
    late RequestConfirmationTool tool;

    setUp(() {
      fakePort = _FakeAgentQuestionPort();
      tool = RequestConfirmationTool(questionPort: fakePort);
    });

    test('name is request_confirmation', () {
      expect(tool.name, 'request_confirmation');
    });

    test('returns error for missing channel_id', () async {
      final result = await tool.run({
        'title': 'Delete',
        'description': 'Delete everything',
      });
      expect(result.isError, isTrue);
    });

    test('returns error for empty channel_id', () async {
      final result = await tool.run({
        'channel_id': '',
        'title': 'Delete',
        'description': 'Delete everything',
      });
      expect(result.isError, isTrue);
    });

    test('returns error when title is missing', () async {
      final result = await tool.run({
        'channel_id': 'ch-1',
        'description': 'Desc',
      });
      expect(result.isError, isTrue);
    });

    test('returns error when description is missing', () async {
      final result = await tool.run({
        'channel_id': 'ch-1',
        'title': 'Title',
      });
      expect(result.isError, isTrue);
    });

    test('returns APPROVED when user approves', () async {
      fakePort.enqueue(const AgentQuestionAnswer(
        selectedLabels: [RequestConfirmationTool.approveLabel],
      ));

      final result = await tool.run({
        'channel_id': 'ch-1',
        'title': 'Delete repository',
        'description': 'This will permanently remove the repo.',
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('APPROVED'));
      expect(result.content.first.text, contains('Delete repository'));
    });

    test('returns REJECTED when user rejects', () async {
      fakePort.enqueue(const AgentQuestionAnswer(
        selectedLabels: [RequestConfirmationTool.rejectLabel],
      ));

      final result = await tool.run({
        'channel_id': 'ch-1',
        'title': 'Delete repository',
        'description': 'This will permanently remove the repo.',
      });

      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('REJECTED'));
    });

    test('returns error when answer is null (dismissed)', () async {
      fakePort.enqueue(null);

      final result = await tool.run({
        'channel_id': 'ch-1',
        'title': 'Delete repository',
        'description': 'This will permanently remove the repo.',
      });

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('dismissed'));
    });

    test('returns error when empty labels (no selection)', () async {
      fakePort.enqueue(const AgentQuestionAnswer(selectedLabels: []));

      final result = await tool.run({
        'channel_id': 'ch-1',
        'title': 'Delete repository',
        'description': 'This will permanently remove the repo.',
      });

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('dismissed'));
    });

    test('passes correct request to port', () async {
      fakePort.enqueue(const AgentQuestionAnswer(
        selectedLabels: [RequestConfirmationTool.approveLabel],
      ));

      await tool.run({
        'channel_id': 'ch-1',
        'title': 'Deploy to prod',
        'description': 'Push new version to production.',
        'severity': 'destructive',
        'command': 'deploy --prod',
      });

      final req = fakePort.lastRequest;
      expect(req.conversationId, 'ch-1');
      expect(req.question, 'Deploy to prod');
      expect(req.context, contains('Push new version'));
      expect(req.context, contains('deploy --prod'));
      expect(req.context, contains('destructive'));
      expect(req.options.length, 2);
      expect(req.options[0].label, RequestConfirmationTool.approveLabel);
      expect(req.options[1].label, RequestConfirmationTool.rejectLabel);
    });

    test('defaults severity to warning when omitted', () async {
      fakePort.enqueue(const AgentQuestionAnswer(
        selectedLabels: [RequestConfirmationTool.approveLabel],
      ));

      await tool.run({
        'channel_id': 'ch-1',
        'title': 'Test',
        'description': 'Desc',
      });

      expect(fakePort.lastRequest.context, contains('warning'));
    });
  });
}
