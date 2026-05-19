import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// MCP tool that asks the user to approve or reject a significant action,
/// rendered as an inline Approve/Reject form in the conversation. Blocks until
/// the user decides.
class RequestConfirmationTool extends McpTool {
  /// Creates a [RequestConfirmationTool].
  RequestConfirmationTool({required AgentQuestionPort questionPort})
      : _questionPort = questionPort;

  final AgentQuestionPort _questionPort;

  /// Label for the approve choice.
  static const String approveLabel = 'Approve';

  /// Label for the reject choice.
  static const String rejectLabel = 'Reject';

  @override
  String get name => 'request_confirmation';

  @override
  String get description =>
      'Request user confirmation before proceeding with a potentially '
      'destructive or significant action. Renders an Approve/Reject form in '
      'the conversation and blocks until the user decides.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'channel_id': {
            'type': 'string',
            'description':
                'The conversation/channel to render the confirmation in.',
          },
          'title': {
            'type': 'string',
            'description': 'Short headline for the action.',
          },
          'description': {
            'type': 'string',
            'description': 'What will happen if confirmed.',
          },
          'severity': {
            'type': 'string',
            'enum': ['info', 'warning', 'destructive'],
            'description': 'How significant this action is.',
          },
          'command': {
            'type': 'string',
            'description': 'The command or action that will be executed.',
          },
        },
        'required': ['channel_id', 'title', 'description'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final channelId = arguments['channel_id'];
    if (channelId is! String || channelId.isEmpty) {
      return CallResult.error('Missing or invalid argument: channel_id');
    }
    final title = arguments['title'];
    final description = arguments['description'];
    if (title is! String || description is! String) {
      return CallResult.error('Title and description are required');
    }

    final severity = arguments['severity'] as String? ?? 'warning';
    final command = arguments['command'] as String?;

    final contextBuf = StringBuffer(description);
    if (command != null && command.isNotEmpty) {
      contextBuf.write('\n\nCommand: $command');
    }
    contextBuf.write('\n\nSeverity: $severity');

    final answer = await _questionPort.ask(AgentQuestionRequest(
      conversationId: channelId,
      question: title,
      context: contextBuf.toString(),
      options: const [
        AgentQuestionOption(label: approveLabel),
        AgentQuestionOption(label: rejectLabel),
      ],
    ));

    if (answer == null || answer.isEmpty) {
      return CallResult.error(
        'No decision received — the confirmation was dismissed or timed out.',
      );
    }

    final approved = answer.selectedLabels.contains(approveLabel);
    return CallResult.success(
      approved
          ? 'The user APPROVED: $title'
          : 'The user REJECTED: $title',
    );
  }
}
