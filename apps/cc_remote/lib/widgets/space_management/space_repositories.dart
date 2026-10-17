import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/space_management_providers.dart';
import 'package:cc_remote/widgets/space_management/space_controls.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceRepositories extends StatelessWidget {
  const SpaceRepositories({
    required this.workspaceId,
    required this.repos,
    required this.selected,
    required this.allRepos,
    required this.editing,
    required this.enabled,
    required this.baseBranches,
    required this.branchController,
    required this.onAllRepos,
    required this.onClear,
    required this.onRepo,
    required this.onBranch,
    super.key,
  });

  final String workspaceId;
  final List<Repo> repos;
  final Set<String> selected;
  final bool allRepos;
  final bool editing;
  final bool enabled;
  final Map<String, String> baseBranches;
  final TextEditingController Function(String) branchController;
  final VoidCallback onAllRepos;
  final VoidCallback onClear;
  final ValueChanged<String> onRepo;
  final void Function(String repoId, String branch) onBranch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpaceHeading(l10n.mobileSpacesRepos),
        SpacePick(
          l10n.mobileSpacesAllRepos,
          allRepos,
          enabled ? onAllRepos : null,
        ),
        if (allRepos)
          Text(
            l10n.mobileSpacesAllRepoWarning,
            style: TextStyle(color: tokens.textSecondary),
          )
        else
          SpacePick(
            l10n.mobileSpacesNoRepos,
            selected.isEmpty,
            enabled ? onClear : null,
          ),
        for (final repo in repos) ...[
          if (!allRepos)
            SpacePick(
              repo.name,
              selected.contains(repo.id),
              enabled ? () => onRepo(repo.id) : null,
            ),
          if ((allRepos || selected.contains(repo.id)) && !editing) ...[
            CcTextField(
              controller: branchController(repo.id),
              label: '${repo.name} · ${l10n.mobileSpacesBaseBranch}',
              hintText: l10n.mobileSpacesDefaultBranch,
              enabled: enabled,
            ),
            if (enabled)
              RepoBranchChoices(
                repo: repo,
                workspaceId: workspaceId,
                onPick: (branch) => onBranch(repo.id, branch),
              ),
            const SizedBox(height: 12),
          ],
          if ((allRepos || selected.contains(repo.id)) && editing)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, bottom: 8),
              child: Text(
                '${repo.name} · ${l10n.mobileSpacesBaseBranch}: '
                '${baseBranches[repo.id] ?? l10n.mobileSpacesDefaultBranch}',
                style: TextStyle(fontSize: 12, color: tokens.textSecondary),
              ),
            ),
        ],
        if (editing)
          Text(
            l10n.mobileSpacesBranchUnavailable,
            style: TextStyle(fontSize: 12, color: tokens.textSecondary),
          ),
      ],
    );
  }
}

class RepoBranchChoices extends ConsumerWidget {
  const RepoBranchChoices({
    required this.repo,
    required this.workspaceId,
    required this.onPick,
    super.key,
  });

  final Repo repo;
  final String workspaceId;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!repo.hasForgeRemote || repo.forge.name != 'github') {
      return const SizedBox.shrink();
    }
    final key = (workspaceId, repo.remoteOwner, repo.remoteName);
    final branches = ref.watch(remoteRepoBranchesProvider(key));
    if (branches.hasError) {
      return CcAlert(
        title: AppLocalizations.of(context).mobileSpacesRepoError,
        description: Text(branches.error.toString()),
        variant: CcAlertVariant.danger,
        action: CcButton(
          size: CcButtonSize.sm,
          onPressed: () => ref.invalidate(remoteRepoBranchesProvider(key)),
          child: Text(AppLocalizations.of(context).mobileSpacesRetry),
        ),
      );
    }
    if (!branches.hasValue || branches.value!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final branch in branches.value!)
          CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.secondary,
            onPressed: () => onPick(branch),
            child: Text(branch),
          ),
      ],
    );
  }
}
