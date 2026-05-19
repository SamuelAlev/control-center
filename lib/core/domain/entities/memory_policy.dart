import 'package:collection/collection.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';

class MemoryPolicy {
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

  final String id;
  final String workspaceId;
  final String domain;
  final String rule;
  final List<String> sourceFactIds;
  final AgentRole? requiredRole;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

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

  @override
  int get hashCode => Object.hash(
    id, workspaceId, domain, rule,
    Object.hashAll(sourceFactIds),
    requiredRole, active,
  );

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
