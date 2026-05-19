import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig_action_log_entry.dart';

/// Durable storage for rig sessions and their action log.
///
/// The rig itself is ephemeral; the RECORD of it is not. A destroyed rig
/// leaves a closed row and its action log so a run can be reviewed after the
/// machine is gone.
///
/// Every method takes a required `workspaceId`: it is what selects the
/// workspace's database file, so there is nowhere for an unscoped call to go.
abstract interface class RigRepository {
  /// Inserts or updates [rig].
  Future<void> save(String workspaceId, Rig rig);

  /// One rig by id within [workspaceId], or null.
  Future<Rig?> getById(String workspaceId, String rigId);

  /// Every rig in [workspaceId], newest first.
  Future<List<Rig>> list(String workspaceId, {bool includeClosed = true});

  /// Live rigs in [workspaceId] — the ones still holding resources.
  Future<List<Rig>> listLive(String workspaceId);

  /// Live rigs across EVERY workspace.
  ///
  /// CROSS-WORKSPACE BY DESIGN: the idle/TTL reaper and the shutdown sweep
  /// must find every running VM on the host, not just one workspace's. A
  /// workspace-scoped alternative ([listLive]) exists and is what feature code
  /// uses; this one exists because an orphaned hypervisor process does not
  /// care which workspace opened it.
  Future<List<Rig>> listAllLive();

  /// Live view of [workspaceId]'s rigs.
  Stream<List<Rig>> watch(String workspaceId);

  /// Appends [entry] to the action log and returns it with its allocated
  /// [RigActionLogEntry.seq].
  Future<RigActionLogEntry> appendAction(
    String workspaceId,
    RigActionLogEntry entry,
  );

  /// The action log for one rig, oldest first.
  Future<List<RigActionLogEntry>> actions(
    String workspaceId,
    String rigId, {
    int limit = 200,
  });

  /// Live action log for one rig.
  Stream<List<RigActionLogEntry>> watchActions(
    String workspaceId,
    String rigId, {
    int limit = 200,
  });

  /// Deletes closed rigs (and their actions) older than [before]. Returns how
  /// many rows went.
  Future<int> purgeClosedBefore(String workspaceId, DateTime before);
}
