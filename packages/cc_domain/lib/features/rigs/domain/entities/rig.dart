import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';

/// A live (or recently-closed) enclosure session.
///
/// Workspace-scoped like everything else: `workspaceId` is non-null and is
/// what picks the database file. A rig with no workspace has nowhere to be
/// written and nobody who is allowed to watch it.
class Rig {
  /// Creates a [Rig].
  Rig({
    required this.id,
    required this.workspaceId,
    required this.surface,
    required this.backend,
    required this.status,
    required this.spec,
    required this.createdBy,
    required this.createdAt,
    required this.lastActivityAt,
    this.display,
    this.conversationId,
    this.agentId,
    this.workerId,
    this.controller,
    this.controlHeldSince,
    this.readyAt,
    this.closedAt,
    this.currentUrl,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (workspaceId.isEmpty) {
      throw ArgumentError.value(
        workspaceId,
        'workspaceId',
        'A rig must belong to exactly one workspace',
      );
    }
  }

  /// Opaque session id.
  final String id;

  /// The owning workspace. Non-null by construction.
  final String workspaceId;

  /// Which machine this is.
  final RigSurface surface;

  /// The hypervisor stack behind it.
  final EnclosureBackend backend;

  /// Current status.
  final RigStatus status;

  /// What it was asked for.
  final RigSpec spec;

  /// The display the guest is currently in, once it has one.
  final RigDisplaySize? display;

  /// Who opened it.
  final Principal createdBy;

  /// The conversation it belongs to, when opened from one.
  final String? conversationId;

  /// The agent driving it, when an agent opened it.
  final String? agentId;

  /// The fleet worker hosting it, when it is not local.
  final String? workerId;

  /// Who currently holds exclusive input control, or null when the agent that
  /// owns the rig is free to drive it.
  ///
  /// This is the take-over lock. It is a single slot on purpose: two actors
  /// typing into one machine produces input nobody meant.
  final Principal? controller;

  /// When [controller] took control.
  final DateTime? controlHeldSince;

  /// When it was created.
  final DateTime createdAt;

  /// When it first became reachable.
  final DateTime? readyAt;

  /// Last action of any kind — what the idle reaper measures.
  final DateTime lastActivityAt;

  /// When it closed.
  final DateTime? closedAt;

  /// The URL a browser rig's page is currently on, tracked from the page's
  /// own navigation events and persisted so watchers (the address bar) see
  /// navigations — whoever initiated them — without polling.
  ///
  /// Null on the computer and mobile surfaces, and on a browser rig until its
  /// first navigation lands.
  final String? currentUrl;

  /// Whether a human has taken over.
  bool get isHumanControlled => controller?.isUser ?? false;

  /// Whether the owning agent may send input right now.
  ///
  /// False while a human holds control: the agent keeps observing (screenshots
  /// and extractions stay allowed) but cannot type or click. Mutual exclusion
  /// is enforced server-side at the act chokepoint, never by asking nicely in
  /// a prompt.
  bool get agentMayAct => controller == null || controller!.isAgent;

  /// When the hard TTL expires.
  DateTime get expiresAt => createdAt.add(spec.ttl);

  /// Whether the hard TTL has passed as of [now].
  bool isExpired(DateTime now) => now.isAfter(expiresAt);

  /// Whether it has been idle past its idle timeout as of [now].
  bool isIdle(DateTime now) =>
      now.difference(lastActivityAt) > spec.idleTimeout;

  /// Returns a copy with selected fields replaced.
  ///
  /// **Nullable fields take a `clearX` flag** rather than relying on `null` to
  /// mean "clear": in a `copyWith`, `null` is indistinguishable from "not
  /// supplied", so without these there was no way to unset `display`,
  /// `readyAt`, `closedAt`, `currentUrl` or `workerId` at all — a rig handed
  /// back by a worker kept naming that worker forever, and a browser rig that
  /// navigated to `about:blank` kept its last real URL.
  ///
  /// `controller` keeps its dedicated [releaseControl] because clearing the
  /// take-over lock is a state transition with its own rules, not a field
  /// edit.
  Rig copyWith({
    RigStatus? status,
    RigDisplaySize? display,
    Principal? controller,
    DateTime? controlHeldSince,
    DateTime? readyAt,
    DateTime? lastActivityAt,
    DateTime? closedAt,
    String? workerId,
    String? currentUrl,
    bool clearDisplay = false,
    bool clearControlHeldSince = false,
    bool clearReadyAt = false,
    bool clearClosedAt = false,
    bool clearWorkerId = false,
    bool clearCurrentUrl = false,
  }) => Rig(
    id: id,
    workspaceId: workspaceId,
    surface: surface,
    backend: backend,
    status: status ?? this.status,
    spec: spec,
    display: clearDisplay ? null : (display ?? this.display),
    createdBy: createdBy,
    conversationId: conversationId,
    agentId: agentId,
    workerId: clearWorkerId ? null : (workerId ?? this.workerId),
    controller: controller ?? this.controller,
    controlHeldSince: clearControlHeldSince
        ? null
        : (controlHeldSince ?? this.controlHeldSince),
    createdAt: createdAt,
    readyAt: clearReadyAt ? null : (readyAt ?? this.readyAt),
    lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    closedAt: clearClosedAt ? null : (closedAt ?? this.closedAt),
    currentUrl: clearCurrentUrl ? null : (currentUrl ?? this.currentUrl),
  );

  /// Returns a copy with the take-over lock cleared.
  Rig releaseControl() => Rig(
    id: id,
    workspaceId: workspaceId,
    surface: surface,
    backend: backend,
    status: status,
    spec: spec,
    display: display,
    createdBy: createdBy,
    conversationId: conversationId,
    agentId: agentId,
    workerId: workerId,
    createdAt: createdAt,
    readyAt: readyAt,
    lastActivityAt: lastActivityAt,
    closedAt: closedAt,
    currentUrl: currentUrl,
  );

  /// FULL structural equality.
  ///
  /// Deliberately not a subset. The watch stream is de-duplicated with
  /// `distinctUntilChanged`, so any field left out of this comparison is a
  /// field whose change never reaches a viewer: a `workerId`-only update — the
  /// row saying which machine in the fleet took the job — compared EQUAL and
  /// was dropped, and so did every `readyAt`/`closedAt`/`controlHeldSince`
  /// transition that did not also move the status.
  ///
  /// Immutable fields (`id`, `createdAt`, `spec`, …) cost one comparison each
  /// and remove the question of which subset was intended.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rig &&
          runtimeType == other.runtimeType &&
          other.id == id &&
          other.workspaceId == workspaceId &&
          other.surface == surface &&
          other.backend == backend &&
          other.status == status &&
          other.spec == spec &&
          other.display == display &&
          other.createdBy == createdBy &&
          other.conversationId == conversationId &&
          other.agentId == agentId &&
          other.workerId == workerId &&
          other.controller == controller &&
          other.controlHeldSince == controlHeldSince &&
          other.createdAt == createdAt &&
          other.readyAt == readyAt &&
          other.lastActivityAt == lastActivityAt &&
          other.closedAt == closedAt &&
          other.currentUrl == currentUrl;

  @override
  int get hashCode => Object.hashAll([
    id,
    workspaceId,
    surface,
    backend,
    status,
    spec,
    display,
    createdBy,
    conversationId,
    agentId,
    workerId,
    controller,
    controlHeldSince,
    createdAt,
    readyAt,
    lastActivityAt,
    closedAt,
    currentUrl,
  ]);
}
