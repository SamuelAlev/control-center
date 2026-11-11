import 'dart:convert';

import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';

/// What a hidden value reads as in [EnvironmentDefinitionRecord.toRedactedJson].
///
/// A placeholder rather than an absence, so that a definition read this way
/// and saved back is refused by [environmentHoldsRedaction] instead of quietly
/// losing the values it never had.
const String kEnvironmentRedactedValue = '<redacted>';

/// Whether [json] holds a [kEnvironmentRedactedValue] anywhere.
bool environmentHoldsRedaction(Object? json) => switch (json) {
  final Map<Object?, Object?> map => map.values.any(environmentHoldsRedaction),
  final List<Object?> list => list.any(environmentHoldsRedaction),
  _ => json == kEnvironmentRedactedValue,
};

Object? _redactEnvValues(Object? json) => switch (json) {
  final Map<Object?, Object?> map => {
    for (final entry in map.entries)
      '${entry.key}': entry.key == 'env'
          ? _redactAll(entry.value)
          : _redactEnvValues(entry.value),
  },
  final List<Object?> list => [for (final item in list) _redactEnvValues(item)],
  _ => json,
};

Object? _redactAll(Object? json) => switch (json) {
  final Map<Object?, Object?> map => {
    for (final entry in map.entries) '${entry.key}': _redactAll(entry.value),
  },
  final List<Object?> list => [for (final item in list) _redactAll(item)],
  _ => kEnvironmentRedactedValue,
};

/// A stored environment definition.
class EnvironmentDefinitionRecord {
  /// Creates an [EnvironmentDefinitionRecord].
  EnvironmentDefinitionRecord({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.definitionJson,
    this.sourceRepoId,
    this.sourcePath,
    this.approvedBlobHash,
    this.overridesJson,
    this.createdBy,
    this.hostApprovedBy,
    this.runsOnHost = false,
    this.hostApproved = false,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (id.isEmpty || workspaceId.isEmpty) {
      throw ArgumentError('EnvironmentDefinitionRecord needs ids');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('EnvironmentDefinitionRecord needs a name');
    }
    if ((sourceRepoId == null) != (sourcePath == null)) {
      throw ArgumentError('An in-repo source needs a repo and a path');
    }
  }

  /// Definition id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Display name.
  final String name;

  /// The definition as JSON text. For an in-repo source this is the last
  /// APPROVED content, never the file's current state: what runs on the host
  /// changes only when an admin approves a new hash.
  final String definitionJson;

  /// The repo holding the in-repo definition, or null.
  final String? sourceRepoId;

  /// Its path in that repo.
  final String? sourcePath;

  /// The blob hash an admin approved.
  final String? approvedBlobHash;

  /// Workspace-side overrides, as JSON text.
  final String? overridesJson;

  /// Who wrote it.
  final String? createdBy;

  /// The user id of the server owner who saved this definition while it ran
  /// something on the host, or null: it runs nothing there, or no owner
  /// approved it. Only the server sets it, on save, and nothing it runs on
  /// the host starts unless this is the current server owner.
  final String? hostApprovedBy;

  /// Whether it runs anything on the server itself, as the server reported
  /// it with this record (`runs_on_host`). Derived per answer, never stored.
  final bool runsOnHost;

  /// Whether the CURRENT server owner approved what it runs on the server
  /// (`host_approved`), as the server reported it with this record. Derived
  /// per answer from [hostApprovedBy] and who owns the server now; never
  /// stored. Meaningful only with [runsOnHost].
  final bool hostApproved;

  /// Whether it runs on the server but no current owner approved it, so
  /// nothing it runs there starts until the owner saves it once.
  bool get awaitsHostApproval => runsOnHost && !hostApproved;

  /// When it was created.
  final DateTime createdAt;

  /// When it last changed.
  final DateTime updatedAt;

  /// Whether this tracks a file in a repo.
  bool get hasSource => sourceRepoId != null;

  /// The parsed definition, without overrides.
  ///
  /// Throws [EnvironmentDefinitionException] listing every issue by path, or
  /// a plain [FormatException] when the text is not JSON.
  EnvironmentDefinition get definition {
    final (:definition, :issues) = parseEnvironmentDefinition(
      jsonDecode(definitionJson),
    );
    if (definition == null) {
      throw EnvironmentDefinitionException(issues);
    }
    return definition;
  }

  /// Wire form.
  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'name': name,
    'definition': jsonDecode(definitionJson),
    if (sourceRepoId != null) 'source_repo_id': sourceRepoId,
    if (sourcePath != null) 'source_path': sourcePath,
    if (approvedBlobHash != null) 'approved_blob_hash': approvedBlobHash,
    if (overridesJson != null) 'overrides': jsonDecode(overridesJson!),
    if (createdBy != null) 'created_by': createdBy,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  /// Wire form for anyone but an admin.
  ///
  /// Definitions tend to carry database passwords and secret ids in `env` and
  /// `overrides`. A member needs what a definition starts, not those: names
  /// and structure stay, every value is [kEnvironmentRedactedValue].
  Map<String, dynamic> toRedactedJson() {
    final json = toJson();
    return {
      ...json,
      'definition': _redactEnvValues(json['definition']),
      if (json.containsKey('overrides'))
        'overrides': _redactAll(json['overrides']),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is EnvironmentDefinitionRecord &&
      other.id == id &&
      other.workspaceId == workspaceId &&
      other.name == name &&
      other.definitionJson == definitionJson &&
      other.sourceRepoId == sourceRepoId &&
      other.sourcePath == sourcePath &&
      other.approvedBlobHash == approvedBlobHash &&
      other.overridesJson == overridesJson &&
      other.hostApprovedBy == hostApprovedBy &&
      other.runsOnHost == runsOnHost &&
      other.hostApproved == hostApproved &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    name,
    definitionJson,
    sourceRepoId,
    sourcePath,
    approvedBlobHash,
    overridesJson,
    hostApprovedBy,
    runsOnHost,
    hostApproved,
    updatedAt,
  );
}

/// Applies [overrides] over [base], recursing into objects.
Map<String, dynamic> mergeEnvironmentOverrides(
  Map<String, dynamic> base,
  Map<String, dynamic> overrides,
) {
  final merged = Map<String, dynamic>.of(base);
  for (final entry in overrides.entries) {
    final existing = merged[entry.key];
    final value = entry.value;
    merged[entry.key] = existing is Map && value is Map
        ? mergeEnvironmentOverrides(
            Map<String, dynamic>.from(existing),
            Map<String, dynamic>.from(value),
          )
        : value;
  }
  return merged;
}
