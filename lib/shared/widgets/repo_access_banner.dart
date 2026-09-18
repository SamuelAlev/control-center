import 'package:cc_domain/features/pr_review/domain/repositories/open_pr_list_repository.dart'
    show InaccessibleRepo;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// An inline notice naming the linked repos the SERVER's forge credential
/// cannot access — the server's PR poller probes them, gets denied (GitHub
/// answers 404 for a repo the token cannot see) and parks them, and without
/// this notice their queues just look silently empty.
///
/// Two causes, two fixes: a GitHub App not installed on the repo's org, or
/// an installation that has been suspended. A suspended install parks polling,
/// so the inbox and PR queue keep serving last-known rows; the notice says so
/// instead of letting that cache look live. Both only a human can fix on the
/// forge, so the notice names the repos and the fix instead of an error code.
///
/// Renders nothing while every repo is reachable (presence reports trouble,
/// never its absence) and carries its own bottom margin so callers can drop it
/// into a column unconditionally, matching `GitHubDegradedBanner`.
class RepoAccessBanner extends StatelessWidget {
  /// Creates a [RepoAccessBanner] over [repos].
  const RepoAccessBanner({required this.repos, super.key});

  /// The repos the server cannot access; empty renders nothing.
  final List<InaccessibleRepo> repos;

  @override
  Widget build(BuildContext context) {
    if (repos.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final suspended = [
      for (final repo in repos)
        if (repo.isInstallationSuspended) repo,
    ];
    final other = [
      for (final repo in repos)
        if (!repo.isInstallationSuspended) repo,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (suspended.isNotEmpty)
          _notice(
            icon: AppIcons.alertTriangle,
            title: l10n.repoAccessNoticeSuspendedTitle,
            body: l10n.repoAccessNoticeSuspendedBody(
              suspended.map((r) => r.repoFullName).join(', '),
            ),
          ),
        if (other.isNotEmpty)
          _notice(
            icon: AppIcons.lock,
            title: l10n.repoAccessNoticeTitle(other.length),
            body: l10n.repoAccessNoticeBody(
              other.map((r) => r.repoFullName).join(', '),
            ),
          ),
      ],
    );
  }

  Widget _notice({
    required IconData icon,
    required String title,
    required String body,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: CcAlert(
      variant: CcAlertVariant.warning,
      icon: icon,
      title: title,
      description: Text(body),
    ),
  );
}
