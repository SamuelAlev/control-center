/// A single selectable option offered by an agent when it asks the user a
/// question (see [AgentQuestionPort]).
class AgentQuestionOption {
  /// Creates an [AgentQuestionOption].
  const AgentQuestionOption({
    required this.label,
    this.description,
    this.value,
  });

  /// Builds an [AgentQuestionOption] from persisted JSON.
  factory AgentQuestionOption.fromJson(Map<String, dynamic> json) =>
      AgentQuestionOption(
        label: (json['label'] as String?) ?? '',
        description: json['description'] as String?,
        value: json['value'] as String?,
      );

  /// Display text for this option.
  final String label;

  /// Optional explanation of what the option means.
  final String? description;

  /// Optional machine value returned instead of [label] when chosen.
  final String? value;

  /// The value an agent receives when this option is selected.
  String get effectiveValue => value ?? label;

  /// Serializes to JSON for message metadata.
  Map<String, dynamic> toJson() => {
    'label': label,
    if (description != null) 'description': description,
    if (value != null) 'value': value,
  };
}

/// A question an agent wants the user to answer before it continues.
class AgentQuestionRequest {
  /// Creates an [AgentQuestionRequest].
  const AgentQuestionRequest({
    required this.workspaceId,
    required this.spaceId,
    required this.question,
    this.context,
    this.options = const [],
    this.allowFreeText = false,
    this.multiSelect = false,
    this.askedByAgentId,
    this.askedByName,
  });

  /// Workspace owning [spaceId]. A space id is a uuid, not an access
  /// boundary: the workspace selects the database the question message is
  /// written into, so a foreign space id resolves to nothing.
  final String workspaceId;

  /// The space the question belongs to — the UI renders the form inline in
  /// its standing conversation.
  final String spaceId;

  /// The question text.
  final String question;

  /// Optional context explaining why the agent is asking.
  final String? context;

  /// Predefined choices. May be empty for a pure free-text question.
  final List<AgentQuestionOption> options;

  /// Whether the user may also type a free-text answer.
  final bool allowFreeText;

  /// Whether more than one option may be selected.
  final bool multiSelect;

  /// Agent id that asked (used as the message sender).
  final String? askedByAgentId;

  /// Display name of the asking agent.
  final String? askedByName;
}

/// The user's answer to an [AgentQuestionRequest].
class AgentQuestionAnswer {
  /// Creates an [AgentQuestionAnswer].
  const AgentQuestionAnswer({
    this.selectedLabels = const [],
    this.freeText,
    this.skipped = false,
  });

  /// Builds an [AgentQuestionAnswer] from persisted JSON.
  factory AgentQuestionAnswer.fromJson(Map<String, dynamic> json) {
    final raw = json['selected'];
    return AgentQuestionAnswer(
      selectedLabels: raw is List
          ? raw.map((e) => '$e').toList(growable: false)
          : const [],
      freeText: json['freeText'] as String?,
      skipped: json['skipped'] == true,
    );
  }

  /// Labels (or values) of the chosen options, in selection order.
  final List<String> selectedLabels;

  /// Optional free-text answer the user typed.
  final String? freeText;

  /// Whether the user skipped the question rather than answering.
  ///
  /// Distinct from [isEmpty]: skip is a deliberate "you pick" and the agent
  /// should proceed on a stated assumption, not treat it as a blank form.
  final bool skipped;

  /// Whether the user supplied nothing.
  bool get isEmpty =>
      !skipped &&
      selectedLabels.isEmpty &&
      (freeText == null || freeText!.trim().isEmpty);

  /// Serializes to JSON for message metadata.
  Map<String, dynamic> toJson() => {
    'selected': selectedLabels,
    if (freeText != null && freeText!.isNotEmpty) 'freeText': freeText,
    if (skipped) 'skipped': true,
  };

  /// A concise, agent-readable rendering of the answer.
  String toPromptString() {
    if (skipped) {
      return 'Skipped';
    }
    final parts = <String>[];
    if (selectedLabels.isNotEmpty) {
      parts.add('Selected: ${selectedLabels.join(', ')}');
    }
    final text = freeText?.trim();
    if (text != null && text.isNotEmpty) {
      parts.add('Additional input: $text');
    }
    return parts.isEmpty ? '(no answer)' : parts.join('\n');
  }
}

/// Reads the argument map both `ask_user` callers share: the harness tool and
/// the MCP tool. One parser so the two surfaces cannot disagree about what a
/// valid question is.
class AskUserArguments {
  const AskUserArguments._({
    this.error,
    this.question = '',
    this.context,
    this.options = const [],
    this.allowFreeText = false,
    this.multiSelect = false,
  });

  /// Parses [args]. [error] is set when the question cannot be asked; the
  /// other fields are meaningful only when [error] is null.
  factory AskUserArguments.parse(
    Map<String, dynamic> args, {
    int maxOptions = 8,
  }) {
    final question = (args['question'] as String?)?.trim() ?? '';
    if (question.isEmpty) {
      return const AskUserArguments._(
        error: 'ask_user requires a non-empty question.',
      );
    }

    final options = <AgentQuestionOption>[];
    final rawOptions = args['options'];
    if (rawOptions is List) {
      for (final raw in rawOptions.take(maxOptions)) {
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
      return const AskUserArguments._(
        error:
            'ask_user needs either options or allow_free_text; a question with '
            'neither cannot be answered.',
      );
    }

    final rawContext = args['context'];
    final context = rawContext is String ? rawContext.trim() : null;
    return AskUserArguments._(
      question: question,
      context: (context == null || context.isEmpty) ? null : context,
      options: options,
      allowFreeText: allowFreeText,
      multiSelect: args['multi_select'] as bool? ?? false,
    );
  }

  /// Why [parse] refused the arguments, or null when they are usable.
  final String? error;

  /// The question, as one sentence.
  final String question;

  /// Why the agent is asking, when it said.
  final String? context;

  /// Concrete choices. Empty for a free-text question.
  final List<AgentQuestionOption> options;

  /// Whether the user may type an answer.
  final bool allowFreeText;

  /// Whether more than one option may be selected.
  final bool multiSelect;
}

/// The text an agent should read back after [AgentQuestionPort.ask] returns.
class AskUserOutcome {
  /// Creates an [AskUserOutcome].
  const AskUserOutcome(this.text, {required this.isError});

  /// Maps [answer] onto the sentence the agent continues from.
  ///
  /// Null is a timeout. Skip is a deliberate "you pick" and is not an error —
  /// the agent should proceed, not ask again.
  factory AskUserOutcome.fromAnswer(AgentQuestionAnswer? answer) {
    if (answer == null) {
      return const AskUserOutcome(
        'No answer: the question timed out or was dismissed. Do not ask '
        'again. Choose the most reasonable option, state the assumption you '
        'are proceeding under, and continue.',
        isError: true,
      );
    }
    if (answer.skipped) {
      return const AskUserOutcome(
        'The user skipped this question. Choose the most reasonable option, '
        'state the assumption you are proceeding under, and continue. Do not '
        'ask again.',
        isError: false,
      );
    }
    if (answer.isEmpty) {
      return const AskUserOutcome(
        'The user submitted an empty answer. Proceed with your best judgment '
        'and say what you assumed.',
        isError: false,
      );
    }
    return AskUserOutcome(answer.toPromptString(), isError: false);
  }

  /// What the agent reads.
  final String text;

  /// Whether the turn should treat this as a tool error.
  final bool isError;
}

/// Surfaces an agent's question to the user as an interactive form in the
/// conversation and blocks until the user answers.
///
/// Mirrors `ConfirmationPort` but carries richer payloads (multiple choices +
/// optional free text). Implemented in-process so the asking agent — blocked
/// in its MCP tool call or PTY relay — receives the answer and continues.
abstract interface class AgentQuestionPort {
  /// Surfaces [request] and resolves once the user submits the form. Returns
  /// `null` if the question is dismissed or times out.
  Future<AgentQuestionAnswer?> ask(AgentQuestionRequest request);
}
