import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';

/// Which machine a spec asks for: one per key, so a second open with the same
/// key joins the first machine instead of booting another.
///
/// The parts are what make two machines different things to a caller:
///
/// - the owner (the space, held in `conversationId`);
/// - the surface;
/// - exec or not: an exec rig and a `computer_use` rig share the `computer`
///   surface, but the exec image is a shell with no display server;
/// - the browser engine, on the browser surface only: asking whether a page
///   works in Firefox must never be answered by Chromium;
/// - the slot: null is the owner's default machine, a named slot (or an
///   environment's id) is a deliberate second one.
///
/// A spec with no owner has no key: it never shares.
class RigSlotKey {
  /// Creates a [RigSlotKey]. Prefer [RigSlotKey.of].
  const RigSlotKey({
    required this.workspaceId,
    required this.ownerId,
    required this.surface,
    required this.isExec,
    required this.engine,
    required this.slotId,
  });

  /// The key of [spec] in [workspaceId], or null when it has no owner.
  static RigSlotKey? of(String workspaceId, RigSpec spec) {
    final owner = spec.conversationId;
    if (owner == null) {
      return null;
    }
    return RigSlotKey(
      workspaceId: workspaceId,
      ownerId: owner,
      surface: spec.surface,
      isExec: spec.isExec,
      engine: spec.surface == RigSurface.browser
          ? spec.browserEngine.wire
          : null,
      slotId: spec.slotId,
    );
  }

  /// The key of the slot [rig] fills, read from the row rather than its spec
  /// so a row whose stored spec could not be parsed still has its owner.
  static RigSlotKey? ofRig(Rig rig) {
    final owner = rig.conversationId;
    if (owner == null) {
      return null;
    }
    return RigSlotKey(
      workspaceId: rig.workspaceId,
      ownerId: owner,
      surface: rig.surface,
      isExec: rig.spec.isExec,
      engine: rig.surface == RigSurface.browser
          ? rig.spec.browserEngine.wire
          : null,
      slotId: rig.spec.slotId,
    );
  }

  /// The workspace.
  final String workspaceId;

  /// The space the machine belongs to.
  final String ownerId;

  /// The surface.
  final RigSurface surface;

  /// Whether it is an exec (terminal) machine.
  final bool isExec;

  /// The browser engine's wire name, or null off the browser surface.
  final String? engine;

  /// The slot, or null for the owner's default machine.
  final String? slotId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RigSlotKey &&
          other.workspaceId == workspaceId &&
          other.ownerId == ownerId &&
          other.surface == surface &&
          other.isExec == isExec &&
          other.engine == engine &&
          other.slotId == slotId;

  @override
  int get hashCode =>
      Object.hash(workspaceId, ownerId, surface, isExec, engine, slotId);

  @override
  String toString() =>
      '$workspaceId/$ownerId/${surface.wire}/$isExec/${engine ?? ''}/'
      '${slotId ?? ''}';
}
