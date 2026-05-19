import 'package:collection/collection.dart';

/// Whether a policy statement grants or denies the matched action.
enum PolicyEffect {
  /// The action is permitted.
  allow,

  /// The action is forbidden.
  deny;

  /// Parses an effect string; defaults to [deny] for unknown values (fail
  /// closed).
  static PolicyEffect fromRaw(String? raw) =>
      raw == 'allow' ? PolicyEffect.allow : PolicyEffect.deny;

  /// The wire string.
  String get id => name;
}

/// The scope a set of policy statements applies at. Higher-precedence layers
/// are evaluated *last* so their statements win under last-match-wins.
enum PolicyLayer {
  /// Global / installation defaults (lowest precedence).
  global,

  /// User-level policy.
  user,

  /// Workspace-level policy (highest precedence).
  workspace;

  /// Evaluation order, lowest → highest precedence.
  static const List<PolicyLayer> precedence = [global, user, workspace];
}

/// A single allow/deny rule. [action] and [resource] are glob patterns
/// (`*` = any run, `?` = any single char).
class PolicyStatement {
  /// Creates a [PolicyStatement].
  const PolicyStatement({
    required this.action,
    required this.resource,
    required this.effect,
    this.layer = PolicyLayer.workspace,
  });

  /// Convenience: an `allow provider.use <resource>` statement.
  const PolicyStatement.allowProvider(
    this.resource, {
    this.layer = PolicyLayer.workspace,
  }) : action = 'provider.use',
       effect = PolicyEffect.allow;

  /// Convenience: a `deny provider.use <resource>` statement.
  const PolicyStatement.denyProvider(
    this.resource, {
    this.layer = PolicyLayer.workspace,
  }) : action = 'provider.use',
       effect = PolicyEffect.deny;

  /// Action glob (e.g. `provider.use`, `provider.*`).
  final String action;

  /// Resource glob (e.g. `anthropic`, `*-cn`, `*`).
  final String resource;

  /// Grant or deny.
  final PolicyEffect effect;

  /// The layer this statement belongs to (drives precedence ordering).
  final PolicyLayer layer;

  /// JSON round-trip (for persistence).
  Map<String, dynamic> toJson() => {
    'action': action,
    'resource': resource,
    'effect': effect.id,
    'layer': layer.name,
  };

  /// Reconstructs from JSON.
  static PolicyStatement fromJson(Map<String, dynamic> json) => PolicyStatement(
    action: json['action'] as String? ?? 'provider.use',
    resource: json['resource'] as String? ?? '*',
    effect: PolicyEffect.fromRaw(json['effect'] as String?),
    layer: PolicyLayer.values.firstWhere(
      (l) => l.name == json['layer'],
      orElse: () => PolicyLayer.workspace,
    ),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolicyStatement &&
          action == other.action &&
          resource == other.resource &&
          effect == other.effect &&
          layer == other.layer;

  @override
  int get hashCode => Object.hash(action, resource, effect, layer);

  @override
  String toString() => '${effect.id} $action $resource (${layer.name})';
}

/// An ordered set of policy statements, lowest precedence first.
class PolicyDocument {
  /// Creates a [PolicyDocument] from statements (order is preserved within a
  /// layer; layers are sorted by precedence).
  PolicyDocument(Iterable<PolicyStatement> statements)
    : statements = List.unmodifiable(
        statements.toList()..sort(
          (a, b) =>
              PolicyLayer.precedence.indexOf(a.layer) -
              PolicyLayer.precedence.indexOf(b.layer),
        ),
      );

  /// An empty document.
  static final PolicyDocument empty = PolicyDocument(const []);

  /// The statements, ordered lowest → highest precedence.
  final List<PolicyStatement> statements;

  /// Whether the document has any statements.
  bool get isEmpty => statements.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolicyDocument &&
          const ListEquality<PolicyStatement>().equals(
            statements,
            other.statements,
          );

  @override
  int get hashCode => const ListEquality<PolicyStatement>().hash(statements);
}
