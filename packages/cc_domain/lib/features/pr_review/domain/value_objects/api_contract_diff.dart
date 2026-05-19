// Swagger-style API-contract diff (PRD 18 §5). CC owns a STABLE `changesJson`
// schema so the underlying diff engine (a pinned `oasdiff` binary, or our own
// pure-Dart differ) can be swapped without touching the UI or the gate.
//
// ignore_for_file: sort_constructors_first

import 'package:collection/collection.dart';

/// What changed in an API contract. Grouped so the UI can render add/modify/
/// remove sections per endpoint and per schema.
enum ApiChangeKind {
  /// A new endpoint (path + method) was added.
  endpointAdded,

  /// An endpoint was removed.
  endpointRemoved,

  /// An endpoint's definition changed (params/responses/etc.).
  endpointModified,

  /// A parameter was added to an endpoint.
  paramAdded,

  /// A parameter was removed from an endpoint.
  paramRemoved,

  /// A parameter's type/required-ness changed.
  paramModified,

  /// A schema/component was added.
  schemaAdded,

  /// A schema/component was removed.
  schemaRemoved,

  /// A schema/component's shape changed.
  schemaModified,

  /// A response definition changed.
  responseChanged;

  /// The stable wire/storage name.
  String get wireName => name;

  /// Parses a stored/wire name, defaulting to [endpointModified].
  static ApiChangeKind fromName(String? name) =>
      ApiChangeKind.values.firstWhere(
        (k) => k.name == name,
        orElse: () => ApiChangeKind.endpointModified,
      );
}

/// The severity/client-impact of an API change (oasdiff taxonomy, simplified).
enum ApiChangeSeverity {
  /// Breaks existing clients (removed endpoint/param, tightened type, new
  /// required param). Renders a "breaking" badge.
  breaking,

  /// Safe, additive change (new optional param, new endpoint).
  nonBreaking,

  /// Informational only (description/example change).
  info;

  /// The stable wire/storage name.
  String get wireName => name;

  /// Parses a stored/wire name, defaulting to [info].
  static ApiChangeSeverity fromName(String? name) => ApiChangeSeverity.values
      .firstWhere((s) => s.name == name, orElse: () => ApiChangeSeverity.info);
}

/// Per-change gate state (PRD 18 §5): a reviewer approves or rejects each
/// change; a rejected breaking change blocks the merge gate.
enum ApiChangeDecision {
  /// Not yet reviewed.
  pending,

  /// Reviewer approved this change.
  approved,

  /// Reviewer rejected this change — blocks the merge gate.
  rejected;

  /// The stable wire/storage name.
  String get wireName => name;

  /// Parses a stored/wire name, defaulting to [pending].
  static ApiChangeDecision fromName(String? name) =>
      ApiChangeDecision.values.firstWhere(
        (d) => d.name == name,
        orElse: () => ApiChangeDecision.pending,
      );
}

/// A single classified change in an API contract.
class ApiContractChange {
  /// Creates an [ApiContractChange].
  const ApiContractChange({
    required this.id,
    required this.kind,
    required this.severity,
    required this.path,
    this.method,
    this.detail = '',
    this.decision = ApiChangeDecision.pending,
  });

  /// Stable id for this change within its diff (so a decision survives a
  /// re-diff of unchanged changes).
  final String id;

  /// What kind of change this is.
  final ApiChangeKind kind;

  /// The change's severity / client impact.
  final ApiChangeSeverity severity;

  /// The endpoint path or schema/component name this change applies to.
  final String path;

  /// HTTP method for endpoint changes (`GET`/`POST`/…), null for schema
  /// changes.
  final String? method;

  /// Human-readable description of the change.
  final String detail;

  /// Per-change approve/reject decision.
  final ApiChangeDecision decision;

  /// Whether this change breaks existing clients.
  bool get isBreaking => severity == ApiChangeSeverity.breaking;

  /// Whether this change currently blocks the merge gate (a rejected change,
  /// or an unresolved breaking change).
  bool get blocksGate =>
      decision == ApiChangeDecision.rejected ||
      (isBreaking && decision == ApiChangeDecision.pending);

  /// Builds from JSON.
  factory ApiContractChange.fromJson(Map<String, dynamic> json) =>
      ApiContractChange(
        id: json['id'] as String? ?? '',
        kind: ApiChangeKind.fromName(json['kind'] as String?),
        severity: ApiChangeSeverity.fromName(json['severity'] as String?),
        path: json['path'] as String? ?? '',
        method: json['method'] as String?,
        detail: json['detail'] as String? ?? '',
        decision: ApiChangeDecision.fromName(json['decision'] as String?),
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.wireName,
    'severity': severity.wireName,
    'path': path,
    if (method != null) 'method': method,
    if (detail.isNotEmpty) 'detail': detail,
    'decision': decision.wireName,
  };

  /// Returns a copy with a new [decision].
  ApiContractChange withDecision(ApiChangeDecision decision) =>
      ApiContractChange(
        id: id,
        kind: kind,
        severity: severity,
        path: path,
        method: method,
        detail: detail,
        decision: decision,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiContractChange &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          kind == other.kind &&
          severity == other.severity &&
          path == other.path &&
          method == other.method &&
          detail == other.detail &&
          decision == other.decision;

  @override
  int get hashCode =>
      Object.hash(id, kind, severity, path, method, detail, decision);
}

/// A before/after diff of one API contract spec (PRD 18 §5), persisted in
/// `api_contract_snapshots`.
class ApiContractDiff {
  /// Creates an [ApiContractDiff].
  const ApiContractDiff({
    required this.id,
    required this.workspaceId,
    required this.repoId,
    required this.prExternalId,
    required this.specPath,
    required this.changes,
    this.headSha,
    this.derived = false,
  });

  /// Row id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// Owning repo.
  final String repoId;

  /// The PR (channel node) this diff belongs to.
  final String prExternalId;

  /// Repository-relative path of the spec file that changed.
  final String specPath;

  /// The classified changes.
  final List<ApiContractChange> changes;

  /// Head SHA this diff was computed against.
  final String? headSha;

  /// Whether this contract was *derived* from handler code rather than an
  /// explicit spec. Derived contracts are advisory-only and NEVER gate a merge
  /// (PRD 18 adversarial notes).
  final bool derived;

  /// Whether any change breaks existing clients.
  bool get hasBreaking => changes.any((c) => c.isBreaking);

  /// Whether this diff currently blocks the merge gate. Derived contracts never
  /// gate.
  bool get blocksGate => !derived && changes.any((c) => c.blocksGate);

  /// Count of breaking changes.
  int get breakingCount => changes.where((c) => c.isBreaking).length;

  /// Builds from JSON.
  factory ApiContractDiff.fromJson(Map<String, dynamic> json) =>
      ApiContractDiff(
        id: json['id'] as String? ?? '',
        workspaceId: json['workspaceId'] as String? ?? '',
        repoId: json['repoId'] as String? ?? '',
        prExternalId: json['prExternalId'] as String? ?? '',
        specPath: json['specPath'] as String? ?? '',
        changes: (json['changes'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => ApiContractChange.fromJson(m.cast<String, dynamic>()))
            .toList(),
        headSha: json['headSha'] as String?,
        derived: json['derived'] as bool? ?? false,
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'repoId': repoId,
    'prExternalId': prExternalId,
    'specPath': specPath,
    'changes': changes.map((c) => c.toJson()).toList(),
    if (headSha != null) 'headSha': headSha,
    'derived': derived,
  };

  /// Returns a copy with the change matching [changeId] set to [decision].
  ApiContractDiff withChangeDecision(
    String changeId,
    ApiChangeDecision decision,
  ) => ApiContractDiff(
    id: id,
    workspaceId: workspaceId,
    repoId: repoId,
    prExternalId: prExternalId,
    specPath: specPath,
    changes: [
      for (final c in changes)
        if (c.id == changeId) c.withDecision(decision) else c,
    ],
    headSha: headSha,
    derived: derived,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiContractDiff &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          repoId == other.repoId &&
          prExternalId == other.prExternalId &&
          specPath == other.specPath &&
          const ListEquality<ApiContractChange>().equals(
            changes,
            other.changes,
          ) &&
          headSha == other.headSha &&
          derived == other.derived;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    repoId,
    prExternalId,
    specPath,
    Object.hashAll(changes),
    headSha,
    derived,
  );
}
