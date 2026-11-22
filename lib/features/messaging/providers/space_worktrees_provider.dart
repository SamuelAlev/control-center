import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:control_center/core/providers/cache_for.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifies one conversation's set of isolated worktrees.
typedef SpaceWorktreesArgs = ({String workspaceId, String spaceId});

/// The isolated copy-on-write worktrees a conversation actually owns — one row
/// per repo the space checked out at provisioning time.
///
/// This is what "the repos in this conversation" means: a workspace can link a
/// dozen repos while a space provisions one (a PR space) or an explicitly
/// chosen subset, and a repo with no worktree here has no working tree to diff,
/// stage or commit. The Source Control panel scopes itself to these rows rather
/// than to every linked repo.
///
/// The rows are written by the server's provisioner and there is no per-space
/// worktree subscription, so the read follows the space's live provisioning
/// status and step instead: a panel opened mid-clone would otherwise hold the
/// empty list it read then until something else invalidated it. Each repo the
/// provisioner finishes advances the step, so the rows fill in as they land.
final spaceWorktreesProvider = FutureProvider.autoDispose
    .family<List<IsolatedRepo>, SpaceWorktreesArgs>((ref, args) async {
      ref
        ..cacheFor(kPanelCacheTtl)
        ..watch(spaceProvisioningStatusProvider(args.spaceId))
        ..watch(spaceProvisioningStepProvider(args.spaceId));
      return ref
          .watch(isolatedRepoRepositoryProvider)
          .forSpace(args.workspaceId, args.spaceId);
    });
