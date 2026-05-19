import 'dart:convert';

import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/user_activity_entry.dart';
import 'package:cc_domain/core/domain/entities/workspace_invite.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';

/// Maps identity/membership database rows to domain entities.
class IdentityMapper {
  /// Creates an [IdentityMapper].
  const IdentityMapper();

  /// Converts a database user row to a domain [User].
  User userToDomain(UsersTableData row) => User(
    id: row.id,
    handle: row.handle,
    displayName: row.displayName,
    email: row.email,
    avatarRef: row.avatarRef,
    gitAuthorName: row.gitAuthorName,
    gitAuthorEmail: row.gitAuthorEmail,
    createdAt: row.createdAt,
  );

  /// Converts a database membership row to a domain [WorkspaceMember].
  /// Unknown role values map to the least privilege (guest), never more.
  WorkspaceMember memberToDomain(WorkspaceMembersTableData row) =>
      WorkspaceMember(
        id: row.id,
        workspaceId: row.workspaceId,
        userId: row.userId,
        role: WorkspaceRole.fromWire(row.role) ?? WorkspaceRole.guest,
        invitedBy: row.invitedBy,
        joinedAt: row.joinedAt,
      );

  /// Converts a database invite row to a domain [WorkspaceInvite].
  WorkspaceInvite inviteToDomain(WorkspaceInvitesTableData row) =>
      WorkspaceInvite(
        id: row.id,
        workspaceId: row.workspaceId,
        codeHash: row.codeHash,
        role: WorkspaceRole.fromWire(row.role) ?? WorkspaceRole.guest,
        repoGrants: decodeRepoGrants(row.repoGrantsJson),
        createdBy: row.createdBy,
        createdAt: row.createdAt,
        expiresAt: row.expiresAt,
        usedAt: row.usedAt,
        usedBy: row.usedBy,
        revokedAt: row.revokedAt,
      );

  /// Converts a database activity row to a domain [UserActivityEntry].
  UserActivityEntry activityToDomain(UserActivityTableData row) =>
      UserActivityEntry(
        id: row.id,
        workspaceId: row.workspaceId,
        userId: row.userId,
        action: row.action,
        targetType: row.targetType,
        targetId: row.targetId,
        deviceId: row.deviceId,
        ip: row.ip,
        countryCode: row.countryCode,
        createdAt: row.createdAt,
      );

  /// Decodes a `{repoId: level}` JSON object; unknown levels are dropped
  /// (fail closed — an unparseable grant grants nothing).
  static Map<String, RepoGrantLevel> decodeRepoGrants(String json) {
    try {
      final raw = jsonDecode(json);
      if (raw is! Map) {
        return const {};
      }
      return {
        for (final entry in raw.entries)
          if (entry.value is String &&
              RepoGrantLevel.fromWire(entry.value as String) != null)
            entry.key as String: RepoGrantLevel.fromWire(
              entry.value as String,
            )!,
      };
    } catch (_) {
      return const {};
    }
  }

  /// Encodes a `{repoId: level}` map to its JSON column form.
  static String encodeRepoGrants(Map<String, RepoGrantLevel> grants) =>
      jsonEncode({
        for (final entry in grants.entries) entry.key: entry.value.wireName,
      });
}
