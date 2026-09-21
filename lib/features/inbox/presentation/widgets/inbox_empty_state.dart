import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/service_status/presentation/widgets/github_degraded_banner.dart'
    show isGitHubDegraded, kGitHubStatusPageUrl;
import 'package:control_center/features/service_status/presentation/widgets/service_status_indicator.dart'
    show serviceStatusWord;
import 'package:control_center/features/service_status/providers/service_status_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Why an empty inbox may not be the truth.
///
/// The inbox is a projection of GitHub state: an outage, a suspended GitHub
/// App install, or an unresolved viewer identity empties it exactly like a
/// genuinely clear queue does, and "You're all caught up" then reads as a
/// confident lie. When one of these holds, the empty state says what it
/// actually knows instead.
enum InboxEmptyCaveat {
  /// githubstatus.com reports an incident, degradation or maintenance, so the
  /// snapshot behind this list may be stale or partial.
  githubDegraded,

  /// No forge resolved the operator's login. Every inbox section is classified
  /// relative to it (`ClassifyPrInboxUseCase` returns an all-empty inbox when
  /// every login is empty), so the list is empty *by construction* — regardless
  /// of how many pull requests are actually waiting.
  identityUnresolved,

  /// The GitHub App installation covering linked repos is suspended, so the
  /// poller has parked them and this empty inbox is last-known data (or never
  /// fetched), not a trustworthy clear queue.
  installationSuspended,
}

/// Decides which caveat (if any) applies to an empty inbox.
/// "GitHub might be down" / "the install is suspended" are true but leave the operator
/// staring at an inbox with no idea why it is empty; "we don't know who you are on GitHub"
/// is the specific fact, and it is the one that says this list is empty *by construction*
/// rather than possibly-incomplete.
InboxEmptyCaveat? resolveInboxEmptyCaveat({
  required GitHubStatusIndicator? indicator,
  required Map<ForgeHost, String> viewerLogins,
  bool installationSuspended = false,
}) {
  if (viewerLogins.values.every((login) => login.isEmpty)) {
    return InboxEmptyCaveat.identityUnresolved;
  }
  if (installationSuspended) {
    return InboxEmptyCaveat.installationSuspended;
  }
  return isGitHubDegraded(indicator) ? InboxEmptyCaveat.githubDegraded : null;
}

/// The inbox's empty state.
///
/// Renders the plain "You're all caught up" only when the emptiness is
/// trustworthy. When [resolveInboxEmptyCaveat] finds a reason to doubt it, the
/// same slot explains that instead — headline, cause and a way to check —
/// rather than reporting a clear queue the app cannot vouch for.
class InboxEmptyState extends ConsumerWidget {
  /// Creates an [InboxEmptyState].
  const InboxEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(githubStatusProvider).value;
    final inaccessible =
        ref.watch(prsByRepoProvider).value?.inaccessibleRepos ?? const [];
    final suspended = [
      for (final repo in inaccessible)
        if (repo.isInstallationSuspended) repo,
    ];
    final caveat = resolveInboxEmptyCaveat(
      indicator: status?.indicator,
      viewerLogins: ref.watch(viewerLoginsProvider),
      installationSuspended: suspended.isNotEmpty,
    );

    switch (caveat) {
      case null:
        return EmptyState(
          message: l10n.inboxAllCaughtUp,
          icon: AppIcons.checkCircle2,
        );
      case InboxEmptyCaveat.installationSuspended:
        return EmptyState(
          message: l10n.repoAccessNoticeSuspendedTitle,
          description: l10n.repoAccessNoticeSuspendedBody(
            suspended.map((r) => r.repoFullName).join(', '),
          ),
          icon: AppIcons.alertTriangle,
        );
      case InboxEmptyCaveat.githubDegraded:
        return EmptyState(
          message: l10n.inboxGitHubDownTitle,
          description: _degradedDescription(l10n, status),
          icon: AppIcons.cloudOff,
          actionLabel: l10n.githubStatusOpenInBrowser,
          primaryAction: () => openExternalUrl(kGitHubStatusPageUrl),
        );
      case InboxEmptyCaveat.identityUnresolved:
        // A degraded GitHub is the usual cause, so name it as the likely
        // culprit and keep the status page one click away — without letting it
        // take over the headline, which has to stay the specific fact.
        final degraded = isGitHubDegraded(status?.indicator);
        return EmptyState(
          message: l10n.inboxGitHubIdentityTitle,
          description: degraded
              ? '${l10n.inboxGitHubIdentityBody}\n'
                    '${_statusLine(l10n, status)}'
              : l10n.inboxGitHubIdentityBody,
          icon: AppIcons.alertTriangle,
          actionLabel: degraded ? l10n.githubStatusOpenInBrowser : null,
          primaryAction: degraded
              ? () => openExternalUrl(kGitHubStatusPageUrl)
              : null,
        );
    }
  }

  /// The compact `GitHub status: <word>` line, with the active incident's own
  /// headline when GitHub named one.
  String _statusLine(AppLocalizations l10n, GitHubServiceStatus? status) {
    final line = l10n.githubDegradedStatusLine(
      serviceStatusWord(l10n, status?.indicator),
    );
    final headline = status?.incidents.firstOrNull?.name.trim() ?? '';
    return headline.isEmpty ? line : '$line $headline';
  }

  /// The degraded body: the same status word the service-status tag shows,
  /// plus the active incident's own headline when GitHub named one (that
  /// string comes from GitHub, so it stays verbatim rather than translated).
  String _degradedDescription(
    AppLocalizations l10n,
    GitHubServiceStatus? status,
  ) {
    final body = l10n.inboxGitHubDownBody(
      serviceStatusWord(l10n, status?.indicator),
    );
    final incident = status?.incidents.firstOrNull;
    final headline = incident?.name.trim() ?? '';
    return headline.isEmpty ? body : '$body\n$headline';
  }
}
