import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:drift/drift.dart';

/// Maps between [TicketLink] domain entities and their Drift rows. Rows with an
/// unrecognized `type` are skipped by the repository (see [fromRowOrNull]).
class TicketLinkMapper {
  /// Creates a [TicketLinkMapper].
  const TicketLinkMapper();

  /// Companion writing every column.
  TicketLinksTableCompanion toCompanion(TicketLink l) {
    return TicketLinksTableCompanion(
      id: Value(l.id),
      workspaceId: Value(l.workspaceId),
      sourceTicketId: Value(l.sourceTicketId),
      targetTicketId: Value(l.targetTicketId),
      type: Value(l.type.toStorageString()),
      createdAt: Value(l.createdAt),
    );
  }

  /// Builds a domain [TicketLink] from a row, or null when the stored `type`
  /// is not recognized (defensive against forward-incompatible rows).
  TicketLink? fromRowOrNull(TicketLinksTableData row) {
    final type = TicketLinkType.fromStorage(row.type);
    if (type == null) {
      return null;
    }
    return TicketLink(
      id: row.id,
      workspaceId: row.workspaceId,
      sourceTicketId: row.sourceTicketId,
      targetTicketId: row.targetTicketId,
      type: type,
      createdAt: row.createdAt,
    );
  }
}
