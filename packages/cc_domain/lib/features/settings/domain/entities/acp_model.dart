/// A model advertised by an ACP-compatible agent runner.
///
/// In a full ACP integration these come from the `availableModels` field of
/// the adapter's `session/new` response (Agent Client Protocol). Until the
/// ACP transport is wired we ship a curated list keyed by adapter id.
///
/// Model traits — [contextWindow] and the [thinkingLevels] vocabulary — drive
/// the agent form's auto-inference: picking a model pre-fills its context size
/// and offers that model's reasoning levels in the effort dropdown. They are
/// display/inference only; equality stays by [id].
class AcpModel {

  /// Reconstructs a model from its JSON shape (the inverse of [toJson]).
  factory AcpModel.fromJson(Map<String, dynamic> json) => AcpModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? json['id'] as String,
        description: json['description'] as String?,
        contextWindow: (json['context_window'] as num?)?.toInt(),
        thinkingLevels: (json['thinking_levels'] as List?)
            ?.map((e) => ThinkingLevel(
                  id: (e as Map)['id'] as String,
                  label: e['label'] as String? ?? e['id'] as String,
                ))
            .toList(),
        defaultThinkingLevel: json['default_thinking_level'] as String?,
      );
  /// Creates a new [AcpModel].
  const AcpModel({
    required this.id,
    required this.name,
    this.description,
    this.contextWindow,
    this.thinkingLevels,
    this.defaultThinkingLevel,
  }) : assert(
          thinkingLevels == null || defaultThinkingLevel != null,
          'defaultThinkingLevel is required when thinkingLevels is provided',
        );

  /// Unique model identifier (e.g. 'anthropic/claude-opus-4-7').
  final String id;
  /// Human-readable model name.
  final String name;
  /// Optional model description.
  final String? description;

  /// Context window in tokens, when vendor-documented. Null when unverified —
  /// the UI shows a placeholder and lets the user type a value.
  final int? contextWindow;

  /// The reasoning levels this model accepts (e.g. low/medium/high/xhigh).
  /// Null when the model exposes no reasoning control.
  final List<ThinkingLevel>? thinkingLevels;

  /// The level id to default to when the user has not chosen. Required when
  /// [thinkingLevels] is non-null.
  final String? defaultThinkingLevel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcpModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Serializes the model to the wire/JSON shape (snake_case). The trait
  /// fields are optional so older persisted shapes still round-trip.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (contextWindow != null) 'context_window': contextWindow,
        if (thinkingLevels != null)
          'thinking_levels':
              thinkingLevels!.map((l) => {'id': l.id, 'label': l.label}).toList(),
        if (defaultThinkingLevel != null)
          'default_thinking_level': defaultThinkingLevel,
      };
}

/// One reasoning level a model accepts (e.g. `low`, `xhigh`). Equality and
/// hashing are by [id]; [label] is the display string.
class ThinkingLevel {
  /// Creates a [ThinkingLevel].
  const ThinkingLevel({required this.id, required this.label});

  /// Stable level id passed to the CLI (e.g. `'xhigh'`).
  final String id;
  /// Human-readable label (e.g. `'Extra High'`).
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThinkingLevel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ThinkingLevel($id)';
}
