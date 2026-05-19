import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_change_type.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_delta.dart';

/// The result of pushing a Control Center ticket to a vendor: the vendor ids
/// the engine persists on the sync link so a later pull / webhook can match the
/// same ticket. Null fields mean "the vendor did not return one" (e.g. a status
/// transition that does not surface a URL).
class TicketPushOutcome {
  /// Creates a [TicketPushOutcome].
  const TicketPushOutcome({
    required this.externalId,
    this.externalKey,
    this.url,
  });

  /// Stable vendor id for the pushed ticket.
  final String externalId;

  /// Vendor-native human key (e.g. `ENG-123`).
  final String? externalKey;

  /// Web URL on the vendor, if known.
  final String? url;
}

/// The boundary between Control Center's (primary) ticket system and one
/// external vendor. CC tickets are the source of truth for agent work; a sync
/// adapter mirrors changes out to the vendor and pulls vendor changes back in.
///
/// Every vendor-specific concern — transport, auth, status vocabulary, field
/// shape — lives behind one adapter. The sync engine only ever sees this
/// interface plus the provider-neutral [TicketSyncDelta] / [Ticket].
abstract interface class TicketSyncAdapter {
  /// Stable vendor identifier (e.g. `linear`, `jira`, `github`). Matches the
  /// `vendor` column on sync configs / links and the `{vendor}` path segment of
  /// the inbound webhook route.
  String get vendorId;

  /// Network domains the adapter reaches, threaded into a sandboxed agent's
  /// allow-list as plain data (no import coupling to the sandbox layer).
  List<String> get allowedDomains;

  /// Pulls tickets changed on the vendor into provider-neutral deltas. Called
  /// by a poll loop or after a webhook signals a project changed. [since] bounds
  /// the window to changes after a timestamp when the vendor supports it.
  Future<List<TicketSyncDelta>> pullChanges({
    required String workspaceId,
    required String vendorProjectId,
    DateTime? since,
  });

  /// Pushes a Control Center ticket change to the vendor and returns the vendor
  /// ids to persist on the sync link (or null when the vendor has nothing to
  /// link, e.g. an unsupported change type the adapter chose to ignore).
  Future<TicketPushOutcome?> pushChange({
    required String workspaceId,
    required Ticket ticket,
    required TicketChangeType changeType,
    String? externalId,
    String vendorProjectId = '',
  });

  /// Resolves a vendor ticket URL to its stable vendor id, or null when the URL
  /// is not one this vendor recognizes. Used to link a worktree / ticket from a
  /// pasted link.
  Future<String?> resolveVendorUrl(String url);

  /// Maps a vendor-native state name to a normalized [TicketStatus].
  TicketStatus mapVendorStatus(String vendorStatus);

  /// Maps a normalized [TicketStatus] to the vendor-native state name the
  /// vendor expects on a transition.
  String mapCcStatus(TicketStatus ccStatus);
}
