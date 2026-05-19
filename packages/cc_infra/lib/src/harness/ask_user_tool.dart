import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_harness/tools.dart';

/// Asks the human a structured question and blocks until they answer.
///
/// The gap this fills: an agent that hits a genuine fork — which of three
/// libraries, which of two migration strategies — has exactly two bad options
/// without it. It can guess, and be wrong halfway through the work; or it can
/// stop and write a paragraph asking, which ends the turn and makes the human
/// re-prompt to continue. This keeps the run alive across the question.
///
/// Distinct from the approval gate (`ConfirmationPort`): that one asks "may I
/// do this?" about an action the agent already chose. This asks the human to
/// make the choice.
///
/// **The tool IS the user interaction**, so the dispatch layer must not wrap it
/// in a second approval prompt — a confirmation dialog in front of a question
/// dialog. `SandboxDispatchDeps` lists it in its interaction-tool set for
/// exactly that reason.
class AskUserTool extends HarnessTool {
  /// Creates an [AskUserTool] that renders into [spaceId] of [workspaceId].
  AskUserTool({
    required AgentQuestionPort port,
    required String workspaceId,
    required String spaceId,
    String? askedByAgentId,
    String? askedByName,
    int maxOptions = 8,
  }) : _port = port,
       _workspaceId = workspaceId,
       _spaceId = spaceId,
       _askedByAgentId = askedByAgentId,
       _askedByName = askedByName,
       _maxOptions = maxOptions;

  final AgentQuestionPort _port;
  final String _workspaceId;
  final String _spaceId;
  final String? _askedByAgentId;
  final String? _askedByName;
  final int _maxOptions;

  @override
  String get name => 'ask_user';

  @override
  String get description =>
      'Ask the user a question and wait for their answer. Use ONLY when the '
      'answer changes what you build and you cannot settle it from the code, '
      'the request, or a sensible default — a preference between real '
      'alternatives, a missing requirement, an ambiguity where the readings '
      'lead to materially different work. Do NOT use it to report progress, '
      'to ask permission for an action (that is handled separately), or to '
      'confirm something you can verify yourself. Offer concrete options when '
      'you can; set allow_free_text when the list may not cover the answer.';

  /// Read tier: asking a question mutates nothing. The tool gathers the human's
  /// own input, so it is never itself approval-gated.
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  /// Two concurrent questions would race for one human's attention and render
  /// as two competing forms, so this never joins a parallel batch.
  @override
  bool get parallelSafe => false;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
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
            'free-text question. At most $_maxOptions are shown.',
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
    'required': ['question'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final question = (args['question'] as String?)?.trim() ?? '';
    if (question.isEmpty) {
      return HarnessToolResult.error('ask_user requires a non-empty question.');
    }

    final options = <AgentQuestionOption>[];
    final rawOptions = args['options'];
    if (rawOptions is List) {
      for (final raw in rawOptions.take(_maxOptions)) {
        if (raw is! Map) {
          continue;
        }
        final label = (raw['label'] as String?)?.trim();
        if (label == null || label.isEmpty) {
          continue;
        }
        final description = (raw['description'] as String?)?.trim();
        options.add(
          AgentQuestionOption(
            label: label,
            description: (description?.isEmpty ?? true) ? null : description,
          ),
        );
      }
    }

    // A question with no options and no free-text field is unanswerable, so
    // free text defaults ON when nothing was offered to pick from.
    final allowFreeText = args['allow_free_text'] as bool? ?? options.isEmpty;
    if (options.isEmpty && !allowFreeText) {
      return HarnessToolResult.error(
        'ask_user needs either options or allow_free_text; a question with '
        'neither cannot be answered.',
      );
    }

    final answer = await _port.ask(
      AgentQuestionRequest(
        workspaceId: _workspaceId,
        spaceId: _spaceId,
        question: question,
        context: (args['context'] as String?)?.trim(),
        options: options,
        allowFreeText: allowFreeText,
        multiSelect: args['multi_select'] as bool? ?? false,
        askedByAgentId: _askedByAgentId,
        askedByName: _askedByName,
      ),
    );

    // Null is a dismissal or a timeout. Say which state we are in rather than
    // returning an empty answer the model would read as "the user said
    // nothing" — the correct next move (proceed on a stated assumption) is
    // different from the one for a deliberate empty answer.
    if (answer == null) {
      return HarnessToolResult.error(
        'No answer: the question timed out or was dismissed. Do not ask '
        'again. Choose the most reasonable option, state the assumption you '
        'are proceeding under, and continue.',
      );
    }
    if (answer.isEmpty) {
      return HarnessToolResult.success(
        'The user submitted an empty answer. Proceed with your best judgment '
        'and say what you assumed.',
      );
    }
    return HarnessToolResult.success(answer.toPromptString());
  }
}
