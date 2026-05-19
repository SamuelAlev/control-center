import 'package:collection/collection.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';

/// A policy rule governing agent access or behavior within a memory domain.
class MemoryPolicy {
  /// Creates a new [MemoryPolicy].
  MemoryPolicy({
    required this.id,
    required this.workspaceId,
    required this.domain,
    required this.rule,
    this.sourceFactIds = const [],
    this.requiredRole,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(workspaceId.isNotEmpty, 'MemoryPolicy workspaceId must not be empty'),
       assert(rule.isNotEmpty, 'MemoryPolicy rule must not be empty');

  /// Unique identifier.
  final String id;
  /// Workspace this policy belongs to.
  final String workspaceId;
  /// Memory domain scoped by this policy.
  final String domain;
  /// Policy rule text.
  final String rule;
  /// Facts that sourced this policy, if any.
  final List<String> sourceFactIds;
  /// Role required for this policy to apply, if any.
  final AgentRole? requiredRole;
  /// Whether this policy is active.
  final bool active;
  /// When the policy was created.
  final DateTime createdAt;
  /// When the policy was last updated.
  final DateTime updatedAt;

  /// Structural equality check.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryPolicy &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          domain == other.domain &&
          rule == other.rule &&
          const ListEquality<String>().equals(sourceFactIds, other.sourceFactIds) &&
          requiredRole == other.requiredRole &&
          active == other.active;

  /// Hash code based on all fields.
  @override
  int get hashCode => Object.hash(
    id, workspaceId, domain, rule,
    Object.hashAll(sourceFactIds),
    requiredRole, active,
  );

  /// Returns a copy with optional field overrides.
  MemoryPolicy copyWith({
    String? id,
    String? workspaceId,
    String? domain,
    String? rule,
    List<String>? sourceFactIds,
    AgentRole? requiredRole,
    bool clearRequiredRole = false,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemoryPolicy(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      domain: domain ?? this.domain,
      rule: rule ?? this.rule,
      sourceFactIds: sourceFactIds ?? this.sourceFactIds,
      requiredRole: clearRequiredRole ? null : (requiredRole ?? this.requiredRole),
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
