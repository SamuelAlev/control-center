import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_remote/pr_providers.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Review comments are subscribed only while the Files tab is visible. The
/// index omits diff hunks: bodies, anchors and thread state are still included.
final prThreadCommentsProvider = StreamProvider.autoDispose
    .family<List<PrCodeReviewComment>, PrCoords>((ref, coords) {
      final repository = ref.watch(prReviewRepositoryProvider(coords));
      if (repository == null) return const Stream.empty();
      return repository.watchReviewComments(coords.number, includeHunks: false);
    });

/// Large patches are never subscribed to when only the file index is visible.
/// One subscription per PR is shared by all expanded file tiles.
final prPatchesProvider = StreamProvider.autoDispose
    .family<List<PrFile>, PrCoords>((ref, coords) {
      final repository = ref.watch(prReviewRepositoryProvider(coords));
      if (repository == null) return const Stream.empty();
      return repository.watchFiles(coords.number);
    });

/// Unlike the task-list permission shortcut, a failed lookup is not mapped to
/// \"none\": an outage must not be presented as an authorization decision.
final prThreadPermissionProvider = FutureProvider.autoDispose
    .family<String, PrCoords>((ref, coords) async {
      final repo = ref.watch(prRepoProvider(coords));
      final client = await ref.watch(rpcClientProvider.future);
      final workspaceId = await ref.watch(activeWorkspaceIdProvider.future);
      if (repo == null || workspaceId == null) {
        throw StateError(
          'Review repository is not available in this workspace',
        );
      }
      final response = await client.call('github.repoPermission', {
        'workspace_id': workspaceId,
        'owner': repo.remoteOwner,
        'repo': repo.remoteName,
      });
      return response['permission'] as String? ?? 'none';
    });
