import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_automation_token.dart';
import 'package:control_center/features/forge/presentation/widgets/automation_token_row.dart';
import 'package:control_center/features/forge/providers/automation_token_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Repositories: the automation token of each linked GitLab and
/// Bitbucket repository, for admins.
///
/// Background work on those forges (the pull request poller, AI review
/// comments, merge requests and pushes nobody asked for) uses only this
/// token, the repository's own or else the workspace's, and shows as its
/// bot. Renders nothing for members, on a demo, or without such
/// repositories.
class RepoAutomationTokensCard extends ConsumerWidget {
  /// Creates a [RepoAutomationTokensCard] over [repos].
  const RepoAutomationTokensCard({
    super.key,
    required this.workspaceId,
    required this.repos,
  });

  /// The workspace.
  final String workspaceId;

  /// The workspace's linked repositories (any forge; this card filters).
  final List<Repo> repos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligible = [
      for (final repo in repos)
        if (repo.hasForgeRemote && automationTokenForges.contains(repo.forge))
          repo,
    ];
    if (eligible.isEmpty ||
        !ref.watch(canManageAutomationTokensProvider(workspaceId))) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final tokens =
        ref.watch(automationTokensProvider(workspaceId)).value ??
        const <ForgeAutomationToken>[];
    ForgeAutomationToken? own(Repo repo) => tokens
        .where((t) => t.repoId == repo.id && t.forge == repo.forge)
        .firstOrNull;
    bool workspaceCovers(Repo repo) => tokens.any(
      (t) =>
          t.scope == ForgeAutomationTokenScope.workspace &&
          t.forge == repo.forge &&
          !t.rejected,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 16),
      child: SectionCard(
        label: l10n.automationTokensTitle,
        subtitle: Text(l10n.automationTokensRepoHint),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final repo in eligible)
              AutomationTokenRow(
                workspaceId: workspaceId,
                forge: repo.forge,
                title: '${repo.fullName} · ${repo.forge.displayName}',
                repoId: repo.id,
                token: own(repo),
                inherited: workspaceCovers(repo),
              ),
          ],
        ),
      ),
    );
  }
}
