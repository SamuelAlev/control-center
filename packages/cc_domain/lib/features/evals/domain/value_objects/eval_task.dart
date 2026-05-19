import 'dart:convert';

/// The task an eval suite runs against a fixture (PRD 21 §5).
class EvalTask {
  /// Creates an [EvalTask].
  const EvalTask({
    required this.prompt,
    this.agentId,
    this.mode = 'chat',
    this.setup = const {},
  });

  /// Parses from a suite's `taskJson`.
  factory EvalTask.fromJson(Map<String, dynamic> json) => EvalTask(
    prompt: json['prompt'] as String? ?? '',
    agentId: json['agentId'] as String?,
    mode: json['mode'] as String? ?? 'chat',
    setup: (json['setup'] as Map?)?.cast<String, dynamic>() ?? const {},
  );

  /// Parses from a JSON string.
  factory EvalTask.fromJsonString(String source) => EvalTask.fromJson(
    source.trim().isEmpty
        ? const {}
        : jsonDecode(source) as Map<String, dynamic>,
  );

  /// The task prompt the agent runs.
  final String prompt;

  /// The target agent id (or null to use the suite's default agent).
  final String? agentId;

  /// The conversation mode.
  final String mode;

  /// Opaque per-task setup (e.g. seeded bug ids, expected-signal config).
  final Map<String, dynamic> setup;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    if (agentId != null) 'agentId': agentId,
    'mode': mode,
    if (setup.isNotEmpty) 'setup': setup,
  };

  /// Serializes to a JSON string.
  String toJsonString() => jsonEncode(toJson());
}
