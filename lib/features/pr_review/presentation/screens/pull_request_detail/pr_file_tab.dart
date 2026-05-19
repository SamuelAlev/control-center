import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/worktree_file_pane.dart';
import 'package:control_center/features/pr_review/providers/pr_channel_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/inline_load_error.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A file at the PR head, opened as an editor tab (view + edit + ⌘S save to the
/// PR worktree). Resolves the PR channel + the workspace repo id, then hands off
/// to the shared [WorktreeFilePane]. Commit & push of these edits lives in the
/// PR's Source Control tab.
class PrFileTab extends ConsumerWidget {
  /// Creates a [PrFileTab].
  const PrFileTab({super.key, required this.pr, required this.path});

  /// The pull request whose head tree the file is read from.
  final PullRequest pr;

  /// Repo-relative file path.
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final repoId = prRepoIdFor(ref, pr);
    final channelAsync = ref.watch(prChannelProvider(pr));
    if (workspaceId == null || repoId == null) {
      return Center(child: Text(AppLocalizations.of(context).ideFileLoading));
    }
    return channelAsync.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => InlineLoadError(e),
      data: (channelId) => WorktreeFilePane(
        workspaceId: workspaceId,
        channelId: channelId,
        repoId: repoId,
        path: path,
      ),
    );
  }
}
