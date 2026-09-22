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
      'Ask the operator a structured question. This is the ONLY way to ask '
      'them anything: it renders a form in the conversation and the run waits '
      'for the answer. Never write a question as a chat message — that ends '
      'the turn and they have to re-prompt. Use it when the answer changes '
      'what you build and you cannot settle it from the code, the request, or '
      'a sensible default (a preference between real alternatives, a missing '
      'requirement, an ambiguity whose readings lead to different work). Do '
      'NOT use it to report progress, to ask permission (the approval gate '
      'handles that), or to confirm something you can verify yourself. Offer '
      'concrete {label, description?} options when you can; set '
      'allow_free_text when the list may not cover the answer; set '
      'multi_select when several options may apply. '
      'workspace_id, space_id and agent_id are filled from the session; a '
      'value you pass for them is ignored.';

  /// The question renders in the space the human is watching, and the message
  /// is sent as the agent that asked. A model-supplied id would put the form
  /// somewhere else, or attribute it to someone else, and the call would wait
  /// out its timeout with nobody looking at it.
  @override
  Set<String> get forcedScopeKeys => const {'space_id', 'agent_id'};

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
  Future<CallResult> run(Map<String, dynamic> arguments) async {
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

    final parsed = AskUserArguments.parse(arguments, maxOptions: maxOptions);
    final error = parsed.error;
    if (error != null) {
      return CallResult.error(error);
    }

    final rawAgent = arguments['agent_id'];
    final answer = await port.ask(
      AgentQuestionRequest(
        workspaceId: workspaceId!,
        spaceId: spaceId!,
        question: parsed.question,
        context: parsed.context,
        options: parsed.options,
        allowFreeText: parsed.allowFreeText,
        multiSelect: parsed.multiSelect,
        askedByAgentId: rawAgent is String && rawAgent.isNotEmpty
            ? rawAgent
            : null,
      ),
    );

    final outcome = AskUserOutcome.fromAnswer(answer);
    return outcome.isError
        ? CallResult.error(outcome.text)
        : CallResult.success(outcome.text);
  }
}
