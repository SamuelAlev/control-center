import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_mcp/src/mcp_scoped_tool.dart';

/// Asks the operator a structured question and blocks until they answer.
///
/// This is the MCP half of `ask_user`. The built-in harness has its own tool
/// of the same name; Claude Code and Pi never see that one — they only see
/// what `tools/list` advertises. A prompt that says "call `ask_user`" against
/// a catalogue that does not contain it is how a run announces the tool is
/// missing and then guesses. Both halves call the same [AgentQuestionPort],
/// so the form renders in the run's space and the answer completes the same
/// in-process waiter.
class AskUserTool extends McpScopedTool {
  /// Creates an [AskUserTool] that blocks on [port].
  AskUserTool({required this.port, this.maxOptions = 8});

  /// Where the question is asked. The run waits on this port's answer.
  final AgentQuestionPort port;

  /// Cap on how many options are shown. Matches the harness tool.
  final int maxOptions;

  @override
  String get name => 'ask_user';

  @override
  String get resultNote =>
      '{selected: string[], text: string | null, skipped: boolean}.';

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

  /// What a code mode script's `await tools.ask_user(...)` resolves to.
  @override
  Map<String, dynamic> get outputSchema => const {
    'type': 'object',
    'properties': {
      'selected': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'The labels of the options the person picked.',
      },
      'text': {
        'type': ['string', 'null'],
        'description': 'What the person typed, or null.',
      },
      'skipped': {
        'type': 'boolean',
        'description': 'Whether the person left the choice to you.',
      },
    },
    'required': ['selected', 'text', 'skipped'],
  };

  /// The call is the person's time: a script's deadline is held while the
  /// form is open.
  @override
  bool get waitsOnPerson => true;

  /// The MCP client giving up (its own request timeout, or the run being
  /// stopped) closes the form, so it does not wait out the server timeout
  /// offering an answer the agent will never read. A question a script asked
  /// carries the script's origin, so the form can say so.
  @override
  Future<CallResult> runScoped(
    Map<String, dynamic> arguments,
    McpCallContext context, {
    Future<void>? abandoned,
  }) async {
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
          origin: context.origin,
        ),
        abandoned: abandoned,
      );
    } on ArgumentError catch (e) {
      return CallResult.error('${e.message}');
    }

    final outcome = AskUserOutcome.fromAnswer(answer);
    if (outcome.isError || answer == null) {
      return CallResult.error(outcome.text);
    }
    return CallResult.success(
      outcome.text,
      structured: {
        'selected': answer.selectedLabels,
        'text': answer.freeText,
        'skipped': answer.skipped,
      },
    );
  }
}
