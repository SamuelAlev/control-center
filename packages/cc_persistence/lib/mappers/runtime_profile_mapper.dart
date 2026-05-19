import 'dart:convert';

import 'package:cc_domain/features/governance/domain/entities/runtime_profile.dart';
import 'package:cc_domain/features/governance/domain/value_objects/protocol_family.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between [RuntimeProfile] domain entities and `runtime_profiles` rows.
class RuntimeProfileMapper {
  /// Creates a [RuntimeProfileMapper].
  const RuntimeProfileMapper();

  /// To domain.
  RuntimeProfile toDomain(RuntimeProfilesTableData row) => RuntimeProfile(
    id: row.id,
    workspaceId: row.workspaceId,
    name: row.name,
    protocolFamily: ProtocolFamily.fromStorage(row.protocolFamily),
    command: row.command,
    fixedArgs: _decodeArgs(row.fixedArgsJson),
    description: row.description,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  /// To domain list.
  List<RuntimeProfile> toDomainList(List<RuntimeProfilesTableData> rows) =>
      rows.map(toDomain).toList(growable: false);

  /// To companion.
  RuntimeProfilesTableCompanion toCompanion(RuntimeProfile p) =>
      RuntimeProfilesTableCompanion(
        id: Value(p.id),
        workspaceId: Value(p.workspaceId),
        name: Value(p.name),
        protocolFamily: Value(p.protocolFamily.name),
        command: Value(p.command),
        fixedArgsJson: Value(jsonEncode(p.fixedArgs)),
        description: Value(p.description),
        createdAt: Value(p.createdAt),
        updatedAt: Value(p.updatedAt),
      );

  static List<String> _decodeArgs(String raw) {
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
