// Named JSON factories read best next to the fields they map.
// ignore_for_file: sort_constructors_first

import 'dart:convert';

import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';

/// Type of a playbook parameter (PRD 17 clarifications: "typed and dumb").
enum PlaybookParamType {
  /// Free-form text.
  string,

  /// One of a fixed set of choices.
  enumeration,

  /// A repo reference (repo id).
  repoRef,

  /// An agent reference (agent id).
  agentRef;

  /// Parses a stored name, defaulting to [string].
  static PlaybookParamType fromName(String? name) =>
      PlaybookParamType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => PlaybookParamType.string,
      );
}

/// One typed playbook parameter.
///
/// Substitution is explicit `{{name}}` placeholders in node titles,
/// descriptions, the goal, and prompt fields. No expression language, no
/// conditionals — a playbook that needs logic is a pipeline.
class PlaybookParam {
  /// Creates a parameter. [name] must be non-empty.
  PlaybookParam({
    required this.name,
    this.type = PlaybookParamType.string,
    this.description = '',
    this.required = true,
    this.defaultValue,
    this.choices = const [],
  }) {
    if (name.isEmpty) {
      throw ArgumentError('PlaybookParam requires a non-empty name.');
    }
  }

  /// Placeholder name (`{{name}}`).
  final String name;

  /// Parameter type.
  final PlaybookParamType type;

  /// What the parameter means.
  final String description;

  /// Whether instantiation must supply it (when false, [defaultValue] or
  /// empty is used).
  final bool required;

  /// Default when not supplied (optional params only).
  final String? defaultValue;

  /// Allowed values for [PlaybookParamType.enumeration].
  final List<String> choices;

  /// Builds from JSON.
  factory PlaybookParam.fromJson(Map<String, dynamic> json) => PlaybookParam(
    name: json['name'] as String? ?? '',
    type: PlaybookParamType.fromName(json['type'] as String?),
    description: json['description'] as String? ?? '',
    required: json['required'] != false,
    defaultValue: json['default'] as String?,
    choices:
        (json['choices'] as List?)?.whereType<String>().toList() ?? const [],
  );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'description': description,
    'required': required,
    if (defaultValue != null) 'default': defaultValue,
    if (choices.isNotEmpty) 'choices': choices,
  };
}

/// A named, versioned, parameterized plan template (PRD 17 §10).
class Playbook {
  /// Creates a playbook. [id]/[workspaceId]/[name] must be non-empty;
  /// [version] must be >= 1.
  Playbook({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.description = '',
    this.params = const [],
    required this.sourceProposal,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (id.isEmpty || workspaceId.isEmpty || name.isEmpty) {
      throw ArgumentError(
        'Playbook requires non-empty id, workspaceId, and name.',
      );
    }
    if (version < 1) {
      throw ArgumentError.value(version, 'version', 'must be >= 1');
    }
  }

  /// Unique id (UUID v4).
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Display name (unique per workspace).
  final String name;

  /// What the playbook does / when to use it.
  final String description;

  /// Typed parameters.
  final List<PlaybookParam> params;

  /// The stored proposal template, with `{{param}}` placeholders.
  final OrchestrationProposal sourceProposal;

  /// Monotonic version, bumped on each save-over.
  final int version;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last mutation time.
  final DateTime updatedAt;

  /// Serializes [params] to the `paramsSchemaJson` column payload.
  String paramsToJsonString() =>
      jsonEncode(params.map((p) => p.toJson()).toList());

  /// Parses a `paramsSchemaJson` column payload.
  static List<PlaybookParam> paramsFromJsonString(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map>()
          .map((m) => PlaybookParam.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Returns a copy with replaced fields.
  Playbook copyWith({
    String? name,
    String? description,
    List<PlaybookParam>? params,
    OrchestrationProposal? sourceProposal,
    int? version,
    DateTime? updatedAt,
  }) => Playbook(
    id: id,
    workspaceId: workspaceId,
    name: name ?? this.name,
    description: description ?? this.description,
    params: params ?? this.params,
    sourceProposal: sourceProposal ?? this.sourceProposal,
    version: version ?? this.version,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Playbook &&
      other.id == id &&
      other.version == version &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, version, updatedAt);
}
