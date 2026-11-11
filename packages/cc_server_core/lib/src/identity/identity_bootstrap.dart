import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/value_objects/username.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:uuid/uuid.dart';

/// First-boot identity: creates the install owner locally (no cloud account).
///
/// Idempotent; subsequent boots reuse the recorded owner. Pairing/devices come
/// later.
class IdentityBootstrap {
  /// Creates an [IdentityBootstrap] over the global database [_global] and the
  /// per-workspace databases [_workspaces].
  IdentityBootstrap({
    required this._global,
    required this._workspaces,
    Map<String, String> environment = const {},
    this._eventBus,
    this._log,
  }) : _env = environment;

  final GlobalDatabase _global;
  final WorkspaceDatabaseManager _workspaces;
  final Map<String, String> _env;
  final DomainEventBus? _eventBus;
  final void Function(String message)? _log;
  static const _uuid = Uuid();

  /// Runs the bootstrap; returns the owner's user id.
  Future<String> run() async {
    final ownerId = await _ensureOwner();
    await _ensureOwnerMemberships();
    return ownerId;
  }

  /// Returns the server owner: the user id recorded in `server_meta`
  /// ([GlobalDatabase.serverOwnerKey]).
  ///
  /// Nothing that reaches the server over the network decides who that is.
  /// With no record the owner is minted here, before any listener opens, and
  /// recorded. Existing accounts never become the owner by being there: a data
  /// dir that has accounts but no record gets a freshly minted owner too, so
  /// ownership never falls to whichever account exists or signs in next.
  Future<String> _ensureOwner() async {
    final meta = _global.workspaceRouteDao;
    final recorded = await meta.meta(GlobalDatabase.serverOwnerKey);
    if (recorded != null) {
      return recorded;
    }
    // The OS account name is the only hint taken from the environment: it is
    // a suggestion, not configuration. The person confirms or changes their
    // username and name in onboarding's first step, and later under You →
    // Profile.
    final suggested = Username.fromFreeText(
      _env['USER'] ?? _env['USERNAME'] ?? '',
      fallback: 'owner',
    );
    final owner = await DaoUserRepository(_global.userDao).insertWithFreeHandle(
      User(
        id: _uuid.v4(),
        handle: suggested.value,
        displayName: suggested.value,
        createdAt: DateTime.now(),
      ),
    );
    await meta.setMeta(GlobalDatabase.serverOwnerKey, owner.id);
    _log?.call('identity: minted owner "${owner.handle}" (${owner.id})');
    return owner.id;
  }

  /// Gives every workspace's recorded owner an owner membership in that
  /// workspace when the row is missing. A workspace without a recorded owner
  /// is left alone: nobody is granted it.
  Future<void> _ensureOwnerMemberships() async {
    final rows = await _global.select(_global.workspacesTable).get();
    for (final ws in rows) {
      final ownerUserId = ws.ownerUserId;
      if (ownerUserId == null) {
        continue;
      }
      final db = _workspaces.of(ws.id);
      final member = await db.workspaceMemberDao.getMember(ws.id, ownerUserId);
      if (member == null) {
        final joinedAt = DateTime.now();
        await db.workspaceMemberDao.upsert(
          WorkspaceMembersTableCompanion(
            id: Value(_uuid.v4()),
            workspaceId: Value(ws.id),
            userId: Value(ownerUserId),
            role: Value(WorkspaceRole.owner.wireName),
            joinedAt: Value(joinedAt),
          ),
        );
        // Announced like any other membership write. Inert on a normal boot
        // (this runs before the RPC surface accepts connections), but the
        // bootstrap is idempotent and also runs from `pair_device`, so the
        // row must never appear without its event.
        _eventBus?.publish(
          WorkspaceMemberAdded(
            workspaceId: ws.id,
            userId: ownerUserId,
            role: WorkspaceRole.owner,
            occurredAt: joinedAt,
          ),
        );
      }
    }
  }
}
