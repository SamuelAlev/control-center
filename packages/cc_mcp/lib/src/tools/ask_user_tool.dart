import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// Asks the operator a structured question and blocks until they answer.
///
/// This is the MCP half of `ask_user`. The built-in harness has its own tool
/// of the same name; Claude Code and Pi never see that one — they only see
/// what `tools/list` advertises. A prompt that says "call `ask_user`" against
/// a catalogue that does not contain it is how a run announces the tool is
/// missing and then guesses. Both halves call the same [AgentQuestionPort],
/// so the form renders in the run's space and the answer completes the same
/// in-process waiter.
class AskUserTool extends McpTool {
  /// Creates an [AskUserTool] that blocks on [port].
  AskUserTool({required this.port, this.maxOptions = 8});

  /// Where the question is asked. The run waits on this port's answer.
  final AgentQuestionPort port;

  /// Cap on how many options are shown. Matches the harness tool.
  final int maxOptions;

  @override
  String get name => 'ask_user';

  @override
  String get description =>
      '$kAskUserToolDescription '
      'workspace_id, space_id, conversation_id and agent_id are filled '
      'from the session; values you pass for them are ignored.';

  /// The question renders in the run's conversation and is sent as the
  /// asking agent. A model-supplied destination would strand the form.
  @override
  Set<String> get forcedScopeKeys => const {
    'space_id',
    'conversation_id',
    'agent_id',
  };

  @override
  Set<String> get requiredScopeKeys => const {
    'workspace_id',
    'space_id',
    'conversation_id',
  };

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the space belongs to.',
      },
      'space_id': {
        'type': 'string',
        'description':
            'The space the form renders in. Filled from the session.',
      },
      'conversation_id': {
        'type': 'string',
        'description':
            'The conversation the form renders in. Filled from the session.',
      },
      'agent_id': {
        'type': 'string',
        'description': 'The asking agent. Filled from the session.',
      },
      'question': {
        'type': 'string',
        'description': 'The question, as one clear sentence.',
      },
      'context': {
        'type': 'string',
        'description':
            'Optional: why you are asking and what hangs on the answer.',
      },
      'options': {
        'type': 'array',
        'description':
            'Concrete choices. Each is {label, description?}. Omit for a pure '
            'free-text question. At most $maxOptions are shown.',
        'items': {
          'type': 'object',
          'properties': {
            'label': {'type': 'string'},
            'description': {'type': 'string'},
          },
          'required': ['label'],
        },
      },
      'allow_free_text': {
        'type': 'boolean',
        'description':
            'Let the user type an answer instead of picking. Default true '
            'when no options are given, false otherwise.',
      },
      'multi_select': {
        'type': 'boolean',
        'description': 'Let the user pick more than one option.',
      },
    },
    'required': ['workspace_id', 'question'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) =>
      _ask(arguments, null);

  /// The MCP client giving up (its own request timeout, or the run being
  /// stopped) closes the form, so it does not wait out the server timeout
  /// offering an answer the agent will never read.
  @override
  Future<CallResult> runUntilAbandoned(
    Map<String, dynamic> arguments,
    Future<void> abandoned,
  ) => _ask(arguments, abandoned);

  Future<CallResult> _ask(
    Map<String, dynamic> arguments,
    Future<void>? abandoned,
  ) async {
    final (workspaceId, workspaceErr) = McpTool.requireString(
      arguments,
      'workspace_id',
    );
    if (workspaceErr != null) {
      return workspaceErr;
    }
    final (spaceId, spaceErr) = McpTool.requireString(arguments, 'space_id');
    if (spaceErr != null) {
      return spaceErr;
    }

    final (conversationId, conversationErr) = McpTool.requireString(
      arguments,
      'conversation_id',
    );
    if (conversationErr != null) {
      return conversationErr;
    }
    final parsed = AskUserArguments.parse(arguments, maxOptions: maxOptions);
    final error = parsed.error;
    if (error != null) {
      return CallResult.error(error);
    }

    final rawAgent = arguments['agent_id'];
    final AgentQuestionAnswer? answer;
    try {
      answer = await port.ask(
        AgentQuestionRequest(
          workspaceId: workspaceId!,
          spaceId: spaceId!,
          question: parsed.question,
          conversationId: conversationId!,
          context: parsed.context,
          options: parsed.options,
          allowFreeText: parsed.allowFreeText,
          multiSelect: parsed.multiSelect,
          askedByAgentId: rawAgent is String && rawAgent.isNotEmpty
              ? rawAgent
              : null,
        ),
        abandoned: abandoned,
      );
    } on ArgumentError catch (e) {
      return CallResult.error('${e.message}');
    }

    final outcome = AskUserOutcome.fromAnswer(answer);
    return outcome.isError
        ? CallResult.error(outcome.text)
        : CallResult.success(outcome.text);
  }
}
