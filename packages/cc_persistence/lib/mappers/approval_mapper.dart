import 'dart:convert';

import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/entities/approval_comment.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_kind.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_status.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between [Approval] / [ApprovalComment] domain entities and their table
/// rows.
class ApprovalMapper {
  /// Creates an [ApprovalMapper].
  const ApprovalMapper();

  /// Approval to domain.
  Approval toDomain(ApprovalsTableData row) => Approval(
    id: row.id,
    workspaceId: row.workspaceId,
    title: row.title,
    description: row.description,
    kind: ApprovalKind.fromStorage(row.kind),
    status: ApprovalStatus.fromStorage(row.status),
    requestedByActorType: row.requestedByActorType,
    requestedById: row.requestedById,
    linkedTicketIds: _decodeIds(row.linkedTicketIds),
    linkedEntityType: row.linkedEntityType,
    linkedEntityId: row.linkedEntityId,
    decidedByActorType: row.decidedByActorType,
    decidedById: row.decidedById,
    decisionReason: row.decisionReason,
    createdAt: row.createdAt,
    decidedAt: row.decidedAt,
    updatedAt: row.updatedAt,
  );

  /// Approval list to domain.
  List<Approval> toDomainList(List<ApprovalsTableData> rows) =>
      rows.map(toDomain).toList(growable: false);

  /// Approval to companion.
  ApprovalsTableCompanion toCompanion(Approval a) => ApprovalsTableCompanion(
    id: Value(a.id),
    workspaceId: Value(a.workspaceId),
    title: Value(a.title),
    description: Value(a.description),
    kind: Value(a.kind.storage),
    status: Value(a.status.storage),
    requestedByActorType: Value(a.requestedByActorType),
    requestedById: Value(a.requestedById),
    linkedTicketIds: Value(jsonEncode(a.linkedTicketIds)),
    linkedEntityType: Value(a.linkedEntityType),
    linkedEntityId: Value(a.linkedEntityId),
    decidedByActorType: Value(a.decidedByActorType),
    decidedById: Value(a.decidedById),
    decisionReason: Value(a.decisionReason),
    createdAt: Value(a.createdAt),
    decidedAt: Value(a.decidedAt),
    updatedAt: Value(a.updatedAt),
  );

  /// Comment to domain.
  ApprovalComment commentToDomain(ApprovalCommentsTableData row) =>
      ApprovalComment(
        id: row.id,
        approvalId: row.approvalId,
        workspaceId: row.workspaceId,
        authorType: row.authorType,
        authorId: row.authorId,
        body: row.body,
        createdAt: row.createdAt,
      );

  /// Comment list to domain.
  List<ApprovalComment> commentsToDomain(
    List<ApprovalCommentsTableData> rows,
  ) => rows.map(commentToDomain).toList(growable: false);

  /// Comment to companion.
  ApprovalCommentsTableCompanion commentToCompanion(ApprovalComment c) =>
      ApprovalCommentsTableCompanion(
        id: Value(c.id),
        approvalId: Value(c.approvalId),
        workspaceId: Value(c.workspaceId),
        authorType: Value(c.authorType),
        authorId: Value(c.authorId),
        body: Value(c.body),
        createdAt: Value(c.createdAt),
      );

  static List<String> _decodeIds(String raw) {
    if (raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList(growable: false);
      }
    } catch (_) {}
    return const [];
  }
}
