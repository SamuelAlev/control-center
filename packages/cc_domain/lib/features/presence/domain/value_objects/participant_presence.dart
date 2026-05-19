import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/presence/domain/value_objects/presence_locus.dart';

/// Cadence constants for the ephemeral presence lane — named in ONE place per
/// the PRD 16 clarification, not magic numbers scattered across surfaces.
final class PresenceCadence {
  PresenceCadence._();

  /// Status/locus updates are re-sent this often even without changes.
  static const Duration heartbeat = Duration(seconds: 10);

  /// An entry expires after three missed heartbeats.
  static const Duration expiry = Duration(seconds: 30);

  /// How often the hub sweeps for expired entries.
  static const Duration sweepInterval = Duration(seconds: 5);

  /// Max roster fan-out rate for desktop/web consumers.
  static const Duration fullTierMinInterval = Duration(milliseconds: 100);

  /// Max roster fan-out rate for the phone tier (coalesced summaries so
  /// cursor-cadence presence can never melt the PWA).
  static const Duration summaryTierMinInterval = Duration(milliseconds: 500);

  /// Idle threshold: no input activity for this long flips online → idle.
  static const Duration idleAfter = Duration(minutes: 5);
}

/// Availability of a participant on the presence lane.
enum PresenceAvailability {
  /// Actively present.
  online,

  /// Connected but inactive.
  idle;

  /// Parses a wire name, defaulting to [online].
  static PresenceAvailability fromWire(String? value) =>
      value == 'idle' ? PresenceAvailability.idle : PresenceAvailability.online;
}

/// Live state of an agent participant (synthesized server-side; agents have
/// no client of their own).
class AgentLiveStatus {
  /// Creates an [AgentLiveStatus].
  const AgentLiveStatus({required this.state, this.costUsd});

  /// Parses from wire.
  factory AgentLiveStatus.fromWire(Map<String, dynamic> wire) =>
      AgentLiveStatus(
        state: AgentLiveState.fromWire(wire['s'] as String?),
        costUsd: (wire['c'] as num?)?.toDouble(),
      );

  /// What the agent is doing right now.
  final AgentLiveState state;

  /// Running cost of the current run, when known.
  final double? costUsd;

  /// Serializes to wire.
  Map<String, dynamic> toWire() => {'s': state.wire, 'c': ?costUsd};
}

/// The agent-participant states the roster renders (icon + label, never
/// color-alone).
enum AgentLiveState {
  /// Reasoning (no tool running).
  thinking('thinking'),

  /// Executing (tools/edits in flight).
  running('running'),

  /// Waiting on a fail-closed approval gate.
  blockedOnApproval('blocked'),

  /// Finished its latest run just now.
  done('done');

  const AgentLiveState(this.wire);

  /// Wire name.
  final String wire;

  /// Parses a wire name, defaulting to [running].
  static AgentLiveState fromWire(String? value) => AgentLiveState.values
      .firstWhere((s) => s.wire == value, orElse: () => AgentLiveState.running);
}

/// A soft-claim on a shared mutable entity ("agent is editing this ticket",
/// "Sam is editing the worktree") — conflict *visibility*, not a lock
/// (PRD 16 §14). Ephemeral: claims ride presence and die with it.
class SoftClaim {
  /// Creates a [SoftClaim].
  const SoftClaim({required this.entityType, required this.entityId});

  /// Parses from wire.
  factory SoftClaim.fromWire(Map<String, dynamic> wire) => SoftClaim(
    entityType: wire['t'] as String? ?? '',
    entityId: wire['id'] as String? ?? '',
  );

  /// Entity kind: `ticket` | `note` | `worktree` | `plan`.
  final String entityType;

  /// The claimed entity id (for `worktree`: the conversation/space id).
  final String entityId;

  /// Serializes to wire.
  Map<String, dynamic> toWire() => {'t': entityType, 'id': entityId};

  @override
  bool operator ==(Object other) =>
      other is SoftClaim &&
      other.entityType == entityType &&
      other.entityId == entityId;

  @override
  int get hashCode => Object.hash(entityType, entityId);
}

/// One participant's ephemeral presence — human or agent, on the SAME lane
/// and roster (PRD 16 §1/§2). Never persisted (the awareness rule): it lives
/// in the server's in-memory hub, expires ~30s after the last update and is
/// broadcast to workspace members only.
class ParticipantPresence {
  /// Creates a [ParticipantPresence].
  ParticipantPresence({
    required this.principal,
    required this.displayName,
    required this.availability,
    this.locus,
    this.typingInSpaceId,
    this.agent,
    this.spotlightSpaceId,
    this.claims = const [],
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Parses from wire; throws [FormatException] on a principal-less entry.
  factory ParticipantPresence.fromWire(Map<String, dynamic> wire) {
    final principal = Principal.tryParse(wire['p'] as String? ?? '');
    if (principal == null) {
      throw const FormatException('presence entry has no principal');
    }
    return ParticipantPresence(
      principal: principal,
      displayName: wire['n'] as String? ?? principal.id,
      availability: PresenceAvailability.fromWire(wire['a'] as String?),
      locus: wire['l'] is Map
          ? PresenceLocus.fromWire((wire['l'] as Map).cast<String, dynamic>())
          : null,
      typingInSpaceId: wire['ty'] as String?,
      agent: wire['ag'] is Map
          ? AgentLiveStatus.fromWire(
              (wire['ag'] as Map).cast<String, dynamic>(),
            )
          : null,
      spotlightSpaceId: wire['sp'] as String?,
      claims: wire['cl'] is List
          ? [
              for (final c in wire['cl'] as List)
                if (c is Map) SoftClaim.fromWire(c.cast<String, dynamic>()),
            ]
          : const [],
      updatedAt: DateTime.tryParse(wire['u'] as String? ?? ''),
    );
  }

  /// Who this is — humans and agents are co-equal principals here.
  final Principal principal;

  /// Display name for the roster (denormalized so the roster needs no join).
  final String displayName;

  /// Online / idle.
  final PresenceAvailability availability;

  /// What they are looking at / editing, when shared.
  final PresenceLocus? locus;

  /// The space they are typing in right now, when any.
  final String? typingInSpaceId;

  /// Live agent state (null for humans).
  final AgentLiveStatus? agent;

  /// The space this participant is presenting (spotlight, PRD 16 §5).
  final String? spotlightSpaceId;

  /// Soft-claims this participant currently holds.
  final List<SoftClaim> claims;

  /// Server receipt time of the latest update (drives expiry).
  final DateTime updatedAt;

  /// Whether this participant is an agent.
  bool get isAgent => principal.isAgent;

  /// Serializes to wire.
  Map<String, dynamic> toWire() => {
    'p': principal.wire,
    'n': displayName,
    'a': availability.name,
    'l': ?locus?.toWire(),
    'ty': ?typingInSpaceId,
    'ag': ?agent?.toWire(),
    'sp': ?spotlightSpaceId,
    if (claims.isNotEmpty) 'cl': [for (final c in claims) c.toWire()],
    'u': updatedAt.toIso8601String(),
  };
}
