import 'package:cc_persistence/database/tables/channel_repos.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'channel_repo_dao.g.dart';

/// Data access object for the [ChannelReposTable] — the per-channel repo
/// selection recorded at channel creation.
@DriftAccessor(tables: [ChannelReposTable])
class ChannelRepoDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ChannelRepoDaoMixin {
  /// Creates a [ChannelRepoDao] bound to the given database.
  ChannelRepoDao(super.attachedDatabase);

  /// The repo ids selected for [channelId] in [workspaceId], in link order.
  /// Empty means "no explicit selection" — callers treat that as all workspace
  /// repos.
  Future<List<String>> repoIdsForChannel(
    String workspaceId,
    String channelId,
  ) async {
    final rows =
        await (select(channelReposTable)
              ..where(
                (t) =>
                    t.workspaceId.equals(workspaceId) &
                    t.channelId.equals(channelId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows.map((r) => r.repoId).toList(growable: false);
  }

  /// Records [repoIds] as the selection for [channelId]. Idempotent per
  /// `(channelId, repoId)`. A no-op when [repoIds] is empty (leaves the channel
  /// on the "all workspace repos" default).
  Future<void> setReposForChannel({
    required String workspaceId,
    required String channelId,
    required List<String> repoIds,
  }) async {
    if (repoIds.isEmpty) {
      return;
    }
    await batch((b) {
      b.insertAll(channelReposTable, [
        for (final repoId in repoIds)
          ChannelReposTableCompanion.insert(
            workspaceId: workspaceId,
            channelId: channelId,
            repoId: repoId,
          ),
      ], mode: InsertMode.insertOrIgnore);
    });
  }
}
