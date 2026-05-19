import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig_action_log_entry.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Rows ↔ entities for the rig tables.
class RigMapper {
  /// Creates a [RigMapper].
  const RigMapper();

  /// Row → entity.
  ///
  /// Tolerant of rows written by a newer build: an unknown surface or backend
  /// resolves to a sane value rather than throwing, because a row we cannot
  /// fully understand must still be closable. The phase is the one field where
  /// an unknown value becomes [RigFailed] — a machine whose state we cannot
  /// read is not one we should report as running.
  Rig rigFromRow(RigSessionsTableData row) => Rig(
    id: row.id,
    workspaceId: row.workspaceId,
    surface: RigSurface.fromWire(row.surface) ?? RigSurface.computer,
    backend:
        EnclosureBackend.fromWire(row.backend) ?? EnclosureBackend.qemuHvf,
    status: RigStatus.fromStorage(
      phase: row.phase,
      detail: row.statusDetail,
      closeReason: row.closeReason,
    ),
    spec: _specFromJson(row.specJson, row.surface),
    display: row.displayWidth != null && row.displayHeight != null
        ? RigDisplaySize(row.displayWidth!, row.displayHeight!)
        : null,
    createdBy: Principal.tryParse(row.createdBy) ?? UserPrincipal(row.createdBy),
    conversationId: row.conversationId,
    agentId: row.agentId,
    workerId: row.workerId,
    controller: Principal.tryParse(row.controller),
    controlHeldSince: row.controlHeldSince,
    createdAt: row.createdAt,
    readyAt: row.readyAt,
    lastActivityAt: row.lastActivityAt,
    closedAt: row.closedAt,
    currentUrl: row.currentUrl,
  );

  /// Entity → companion.
  RigSessionsTableCompanion rigToCompanion(Rig rig) =>
      RigSessionsTableCompanion.insert(
        id: rig.id,
        workspaceId: rig.workspaceId,
        surface: rig.surface.wire,
        backend: rig.backend.wire,
        phase: Value(rig.status.phase.wire),
        statusDetail: Value(rig.status.detail),
        closeReason: Value(rig.status.closeReason?.wire),
        specJson: Value(jsonEncode(rig.spec.toJson())),
        displayWidth: Value(rig.display?.width),
        displayHeight: Value(rig.display?.height),
        conversationId: Value(rig.conversationId),
        agentId: Value(rig.agentId),
        workerId: Value(rig.workerId),
        createdBy: rig.createdBy.wire,
        controller: Value(rig.controller?.wire),
        controlHeldSince: Value(rig.controlHeldSince),
        createdAt: Value(rig.createdAt),
        readyAt: Value(rig.readyAt),
        lastActivityAt: Value(rig.lastActivityAt),
        closedAt: Value(rig.closedAt),
        currentUrl: Value(rig.currentUrl),
      );

  /// Row → action-log entity.
  RigActionLogEntry actionFromRow(RigActionLogTableData row) =>
      RigActionLogEntry(
        id: row.id,
        workspaceId: row.workspaceId,
        rigId: row.rigId,
        seq: row.seq,
        verb: row.verb,
        args: _decodeMap(row.argsJson),
        summary: row.summary,
        actor: Principal.tryParse(row.actor) ?? UserPrincipal(row.actor),
        isTakeOver: row.isTakeOver,
        isError: row.isError,
        resultText: row.resultText,
        imageHash: row.imageHash,
        durationMs: row.durationMs,
        createdAt: row.createdAt,
      );

  /// Action-log entity → companion.
  RigActionLogTableCompanion actionToCompanion(RigActionLogEntry entry) =>
      RigActionLogTableCompanion.insert(
        id: entry.id,
        workspaceId: entry.workspaceId,
        rigId: entry.rigId,
        seq: entry.seq,
        verb: entry.verb,
        argsJson: Value(jsonEncode(entry.args)),
        summary: Value(entry.summary),
        actor: entry.actor.wire,
        isTakeOver: Value(entry.isTakeOver),
        isError: Value(entry.isError),
        resultText: Value(entry.resultText),
        imageHash: Value(entry.imageHash),
        durationMs: Value(entry.durationMs),
        createdAt: Value(entry.createdAt),
      );

  /// Reads the stored spec, falling back to a minimal spec for the row's
  /// surface when the JSON is unreadable.
  ///
  /// A spec that fails to parse must not make the session unreadable: the row
  /// still names a machine that may be running, and closing it needs the id,
  /// not the spec.
  RigSpec _specFromJson(String raw, String surfaceWire) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> && decoded.isNotEmpty) {
        return RigSpec.fromJson(decoded);
      }
    } on Object {
      // Fall through to the default below.
    }
    return RigSpec(
      surface: RigSurface.fromWire(surfaceWire) ?? RigSurface.computer,
    );
  }

  Map<String, dynamic> _decodeMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on Object {
      // A malformed args blob is worth nothing but must not break the feed.
    }
    return const {};
  }
}
