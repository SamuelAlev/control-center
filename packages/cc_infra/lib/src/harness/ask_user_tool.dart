/// @docImport 'package:cc_domain/core/domain/ports/confirmation_port.dart';
library;

import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/code_mode/run_script_origins.dart';

/// Asks the human a structured question and blocks until they answer.
///
/// Keeps the run alive across a real fork (vs guessing or ending the turn).
/// Distinct from [ConfirmationPort] ("may I?") — this asks the human to choose.
/// Listed as an interaction tool so dispatch does not wrap it in a second
/// approval dialog.
///
/// A script can ask too (`await tools.ask_user(...)` in `repl`). The answer
/// then also comes back as `{selected, text, skipped}` ([outputSchema]), and
/// the request carries the script's origin so the form can say who asked.
class AskUserTool extends HarnessTool {
  /// Creates an [AskUserTool] for the run's workspace and conversation.
  AskUserTool({
    required this._port,
    required this._workspaceId,
    required this._spaceId,
    required this._conversationId,
    this._askedByAgentId,
    this._askedByName,
    this._runId,
    this._scriptOrigins,
    this._maxOptions = 8,
  });

  final AgentQuestionPort _port;
  final String _workspaceId;
  final String _spaceId;
  final String _conversationId;
  final String? _askedByAgentId;
  final String? _askedByName;
  final String? _runId;

  /// The scripts running in this run, which name the execution in the origin
  /// of a question a script asks. Without it a script's question carries no
  /// origin.
  final RunScriptOrigins? _scriptOrigins;
  final int _maxOptions;

  @override
  String get name => 'ask_user';

  @override
  String get resultNote =>
      '{selected: string[], text: string | null, skipped: boolean}.';

  @override
  String get description => kAskUserToolDescription;

  /// Read tier: asking a question mutates nothing. The tool gathers the human's
  /// own input, so it is never itself approval-gated.
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  /// Two concurrent questions would race for one human's attention and render
  /// as two competing forms, so this never joins a parallel batch.
  @override
  bool get parallelSafe => false;

  /// The whole call is a wait on a person: a script's clock stops while the
  /// form is open, and a script's questions take the serial lane, one form at
  /// a time in call order.
  @override
  bool get waitsOnPerson => true;

  /// What a script's `await tools.ask_user(...)` resolves to. A question that
  /// times out or is dismissed rejects instead.
  @override
  Map<String, dynamic> get outputSchema => const {
    'type': 'object',
    'properties': {
      'selected': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'The chosen options, in the order they were picked.',
      },
      'text': {
        'type': ['string', 'null'],
        'description': 'What the person typed, or null.',
      },
      'skipped': {
        'type': 'boolean',
        'description':
            'Whether the person skipped the question: proceed on a stated '
            'assumption.',
      },
    },
    'required': ['selected', 'text', 'skipped'],
  };

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
    final parsed = AskUserArguments.parse(args, maxOptions: _maxOptions);
    final error = parsed.error;
    if (error != null) {
      return HarnessToolResult.error(error);
    }

    final AgentQuestionAnswer? answer;
    try {
      answer = await _port.ask(
        AgentQuestionRequest(
          workspaceId: _workspaceId,
          spaceId: _spaceId,
          conversationId: _conversationId,
          question: parsed.question,
          context: parsed.context,
          options: parsed.options,
          allowFreeText: parsed.allowFreeText,
          multiSelect: parsed.multiSelect,
          askedByAgentId: _askedByAgentId,
          askedByName: _askedByName,
          runId: _runId,
          origin: _originFor(context),
        ),
        // A stopped run leaves nobody to read the answer; close the form.
        abandoned: context.cancel?.whenCancelled,
      );
    } on ArgumentError catch (e) {
      return HarnessToolResult.error('${e.message}');
    }

    final outcome = AskUserOutcome.fromAnswer(answer);
    if (outcome.isError || answer == null) {
      return HarnessToolResult.error(outcome.text);
    }
    final text = answer.freeText?.trim();
    return HarnessToolResult.success(
      outcome.text,
      structured: {
        'selected': answer.selectedLabels,
        'text': text == null || text.isEmpty ? null : text,
        'skipped': answer.skipped,
      },
    );
  }

  /// The script that asked, when a script asked: the form then says so and
  /// links to the script's transcript row.
  ScriptCallOrigin? _originFor(HarnessToolContext context) {
    final parent = context.parentToolCallId;
    if (parent == null || parent.isEmpty) {
      return null;
    }
    return _scriptOrigins?.originOf(parent);
  }
}
