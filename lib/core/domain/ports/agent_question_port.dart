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
    required this.conversationId,
    required this.question,
    this.context,
    this.options = const [],
    this.allowFreeText = false,
    this.multiSelect = false,
    this.askedByAgentId,
    this.askedByName,
  });

  /// Channel/conversation the question belongs to — the UI renders the form
  /// inline in this conversation.
  final String conversationId;

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
  });

  /// Builds an [AgentQuestionAnswer] from persisted JSON.
  factory AgentQuestionAnswer.fromJson(Map<String, dynamic> json) {
    final raw = json['selected'];
    return AgentQuestionAnswer(
      selectedLabels: raw is List
          ? raw.map((e) => '$e').toList(growable: false)
          : const [],
      freeText: json['freeText'] as String?,
    );
  }

  /// Labels (or values) of the chosen options, in selection order.
  final List<String> selectedLabels;

  /// Optional free-text answer the user typed.
  final String? freeText;

  /// Whether the user supplied nothing.
  bool get isEmpty =>
      selectedLabels.isEmpty &&
      (freeText == null || freeText!.trim().isEmpty);

  /// Serializes to JSON for message metadata.
  Map<String, dynamic> toJson() => {
        'selected': selectedLabels,
        if (freeText != null && freeText!.isNotEmpty) 'freeText': freeText,
      };

  /// A concise, agent-readable rendering of the answer.
  String toPromptString() {
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
