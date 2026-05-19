import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/ports/remote_ticket.dart';
import 'package:control_center/features/ticketing/domain/ports/ticket_provider_port.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:uuid/uuid.dart';

/// Pulls tickets from the active remote provider into the local mirror,
/// touching only the mirror columns so the Control-Center orchestration overlay
/// (assignment / channel / pipeline coupling) survives every refresh.
/// A no-op for the local provider, whose rows are already the source of truth.
class TicketSyncService {
  /// Creates a [TicketSyncService].
  TicketSyncService({required this.port, required this.repository});

  /// Active provider.
  final TicketProviderPort port;

  /// Local mirror store.
  final TicketRepository repository;

  static const _uuid = Uuid();

  /// Pulls and mirrors the tickets visible to the current user for
  /// [workspaceId]. Safe to call on every screen open.
  Future<void> sync(String workspaceId) async {
    if (!port.capabilities.supportsRemoteSync) return;
    try {
      final remotes = await port.list();
      for (final remote in remotes) {
        await repository.upsertMirror(_toTicket(remote, workspaceId));
      }
    } on Object catch (e, st) {
      AppLog.e('TicketSyncService', 'sync failed', e, st);
    }
  }

  Ticket _toTicket(RemoteTicket r, String workspaceId) {
    final now = DateTime.now();
    return Ticket(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      provider: port.provider,
      externalKey: r.externalKey ?? r.externalId,
      url: r.url,
      title: r.title,
      description: r.description,
      priority: r.priority,
      labels: r.labels,
      status: r.status,
      rawStatus: r.rawStatus,
      createdAt: r.createdAt ?? now,
      updatedAt: r.updatedAt ?? now,
    );
  }
}
