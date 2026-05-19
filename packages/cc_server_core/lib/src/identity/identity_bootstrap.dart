import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:uuid/uuid.dart';

/// First-boot identity bootstrap: no central auth, no cloud account, ever.
///
/// Idempotent — runs at every server start, before the RPC surface accepts
/// connections:
///
/// 1. **First user is admin.** With zero users, mints the owner from the OS
///    account name, so a solo install never sees a login screen. Their name
///    and email are edited in Settings, not configured at boot.
/// 2. **Ownership backfill.** Every workspace missing `ownerUserId` gets the
///    owner, plus an `owner`-role membership row.
/// 3. **Device binding.** Paired devices missing `userId` are bound to the
///    owner (they were paired before identity existed).
/// 4. **Sentinel adoption.** Rows that attribute a human action to the literal
///    `'user'` placeholder — or to an id no user owns — are re-attributed to the
///    owner: space participants, human space messages, ticket assignees /
///    collaborators and approval actors.
///
/// Identity spans both halves of the split database, which is what makes this
/// class worth reading: `users` and `paired_devices` are global (one human is one
/// user across every workspace and a paired device outlives any workspace),
/// while memberships and every attributed row live inside a workspace's own
/// file. Step 4 therefore reads the user set from `global.db` once and then
/// visits each workspace database in turn.
class IdentityBootstrap {
  /// Creates an [IdentityBootstrap] over the global database [global] and the
  /// per-workspace databases [workspaces].
  IdentityBootstrap({
    required GlobalDatabase global,
    required WorkspaceDatabaseManager workspaces,
    Map<String, String> environment = const {},
    DomainEventBus? eventBus,
    void Function(String message)? log,
  }) : _global = global,
       _workspaces = workspaces,
       _env = environment,
       _eventBus = eventBus,
       _log = log;

  final GlobalDatabase _global;
  final WorkspaceDatabaseManager _workspaces;
  final Map<String, String> _env;
  final DomainEventBus? _eventBus;
  final void Function(String message)? _log;
  static const _uuid = Uuid();

  /// Runs the bootstrap; returns the owner's user id.
  Future<String> run() async {
    final ownerId = await _ensureOwner();
    await _backfillWorkspaceOwnership(ownerId);
    await _bindOrphanDevices(ownerId);
    await _adoptSentinels(ownerId);
    return ownerId;
  }

  /// Mints the owner when no users exist; otherwise returns the earliest
  /// user (the bootstrap owner).
  Future<String> _ensureOwner() async {
    final users = await _global.userDao.getAll();
    if (users.isNotEmpty) {
      return users.first.id;
    }
    // The OS account name is the only hint taken from the environment: it is
    // a display default, not configuration. Name and email are edited in
    // Settings → You → Profile & identity, which is where a person looking at
    // them would change them.
    final handle = _sanitizeHandle(_env['USER'] ?? _env['USERNAME'] ?? 'owner');
    final displayName = handle;
    final id = _uuid.v4();
    await _global.userDao.upsert(
      UsersTableCompanion(
        id: Value(id),
        handle: Value(handle),
        displayName: Value(displayName),
        email: const Value(null),
        createdAt: Value(DateTime.now()),
      ),
    );
    _log?.call('identity: minted owner "$handle" ($id)');
    return id;
  }

  Future<void> _backfillWorkspaceOwnership(String ownerId) async {
    final rows = await _global.select(_global.workspacesTable).get();
    for (final ws in rows) {
      if (ws.ownerUserId == null) {
        await (_global.update(_global.workspacesTable)
              ..where((t) => t.id.equals(ws.id)))
            .write(WorkspacesTableCompanion(ownerUserId: Value(ownerId)));
      }
      final ownerUserId = ws.ownerUserId ?? ownerId;
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

  Future<void> _bindOrphanDevices(String ownerId) async {
    final devices = await _global.pairedDeviceDao.getAll();
    for (final device in devices) {
      if (device.userId == null) {
        await _global.pairedDeviceDao.setUserId(device.id, ownerId);
      }
    }
  }

  /// Re-attributes placeholder human actors to [ownerId], in every workspace.
  ///
  /// The one genuinely cross-database question here is "does this sender id
  /// belong to a real user?" — `users` is global, the messages are not and
  /// SQLite cannot join across files. The user id set is small and bounded by
  /// the number of humans on the install, so it is read once and inlined into
  /// each workspace's statement.
  Future<void> _adoptSentinels(String ownerId) async {
    final users = await _global.userDao.getAll();
    final knownUserIds = {for (final u in users) u.id, ownerId};
    final idList = knownUserIds.map((_) => '?').join(', ');

    // CROSS-WORKSPACE BY DESIGN: a one-time migration that re-attributes the
    // pre-identity `'user'` sentinel in EVERY workspace to the owner. It runs
    // once at boot before any session exists, and it issues raw
    // `customStatement` UPDATEs rather than the typed reads
    // CrossWorkspaceQueries fans out; `forEachWorkspace` would fit the shape
    // but not the ordering — this has to complete before the RPC surface opens.
    for (final workspaceId in await _workspaces.allWorkspaceIds()) {
      final db = _workspaces.of(workspaceId);
      // Space participants: the 'user' sentinel row becomes the owner.
      await db.customStatement(
        'UPDATE space_participants '
        "SET principal_id = ?, participant_type = 'user' "
        "WHERE principal_id = 'user'",
        [ownerId],
      );
      // Human space messages: senderType 'user' is authoritative; senderId
      // may hold the literal 'user' (dispatch path) or a device id (the RPC
      // send path stamped the device before identity existed). Any human
      // message not attributable to a known user belongs to the owner.
      await db.customStatement(
        'UPDATE conversation_messages SET sender_id = ? '
        "WHERE sender_type = 'user' AND sender_id NOT IN ($idList)",
        [ownerId, ...knownUserIds],
      );
      // Tickets assigned to the human sentinel.
      await db.customStatement(
        "UPDATE tickets SET assigned_agent_id = ?, assignee_type = 'user' "
        "WHERE assigned_agent_id = 'user'",
        [ownerId],
      );
      // Ticket collaborators.
      await db.customStatement(
        'UPDATE ticket_collaborators '
        "SET principal_id = ?, collaborator_type = 'user' "
        "WHERE principal_id = 'user'",
        [ownerId],
      );
      // Approvals decided/requested by the anonymous human.
      await db.customStatement(
        'UPDATE approvals SET decided_by_id = ? '
        "WHERE decided_by_actor_type = 'user' AND decided_by_id IS NULL",
        [ownerId],
      );
      await db.customStatement(
        'UPDATE approvals SET requested_by_id = ? '
        "WHERE requested_by_actor_type = 'user' "
        "AND (requested_by_id IS NULL OR requested_by_id = 'user')",
        [ownerId],
      );
      await db.customStatement(
        'UPDATE approval_comments SET author_id = ? '
        "WHERE author_type = 'user' AND author_id IS NULL",
        [ownerId],
      );
    }
  }

  static String _sanitizeHandle(String raw) {
    final cleaned = raw
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9_.-]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return cleaned.isEmpty ? 'owner' : cleaned;
  }
}
