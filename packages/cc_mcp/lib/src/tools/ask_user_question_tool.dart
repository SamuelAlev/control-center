import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// MCP tool that asks the user a question (with predefined choices and/or a
/// free-text answer) and blocks until the user answers via the inline form
/// rendered in the conversation.
class AskUserQuestionTool extends McpTool {
  /// Creates an [AskUserQuestionTool].
  AskUserQuestionTool({required AgentQuestionPort questionPort})
      : _questionPort = questionPort;

  final AgentQuestionPort _questionPort;

  @override
  String get name => 'ask_user_question';

  @override
  String get description =>
      'Ask the user a question and wait for their answer. Renders an '
      'interactive form (single/multi choice and/or free text) in the '
      'conversation and blocks until the user responds. Use when you need a '
      'decision or clarification before proceeding.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'channel_id': {
            'type': 'string',
            'description':
                'The conversation/channel to render the question in.',
          },
          'question': {
            'type': 'string',
            'description': 'The question to ask the user.',
          },
          'options': {
            'type': 'array',
            'description': 'Available choices for the user.',
            'items': {
              'type': 'object',
              'properties': {
                'label': {
                  'type': 'string',
                  'description': 'Display text for this option.',
                },
                'description': {
                  'type': 'string',
                  'description': 'What this option means.',
                },
              },
              'required': ['label'],
            },
          },
          'allow_freeform': {
            'type': 'boolean',
            'description':
                'Whether the user may also type a free-text answer. '
                'Defaults to false.',
          },
          'multi_select': {
            'type': 'boolean',
            'description':
                'Whether the user may pick more than one option. '
                'Defaults to false.',
          },
          'context': {
            'type': 'string',
            'description': 'Why you are asking this question.',
          },
        },
        'required': ['channel_id', 'question'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final question = arguments['question'];
    if (question is! String || question.isEmpty) {
      return CallResult.error('Missing or invalid argument: question');
    }
    final channelId = arguments['channel_id'];
    if (channelId is! String || channelId.isEmpty) {
      return CallResult.error('Missing or invalid argument: channel_id');
    }

    final options = <AgentQuestionOption>[];
    final rawOptions = arguments['options'];
    if (rawOptions is List) {
      for (final opt in rawOptions) {
        if (opt is Map) {
          final m = opt.cast<String, dynamic>();
          final label = m['label'];
          if (label is String && label.isNotEmpty) {
            options.add(AgentQuestionOption(
              label: label,
              description: m['description'] as String?,
              value: m['value'] as String?,
            ));
          }
        }
      }
    }

    final allowFreeText = arguments['allow_freeform'] == true;
    if (options.isEmpty && !allowFreeText) {
      return CallResult.error(
        'Provide at least one option, or set allow_freeform to true.',
      );
    }

    final answer = await _questionPort.ask(AgentQuestionRequest(
      conversationId: channelId,
      question: question,
      context: arguments['context'] as String?,
      options: options,
      allowFreeText: allowFreeText,
      multiSelect: arguments['multi_select'] == true,
    ));

    if (answer == null || answer.isEmpty) {
      return CallResult.error(
        'No answer received — the question was dismissed or timed out.',
      );
    }

    return CallResult.success(
      'The user answered your question "$question":\n'
      '${answer.toPromptString()}',
    );
  }
}
