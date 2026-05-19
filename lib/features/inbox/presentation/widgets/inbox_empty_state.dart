import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
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
/// The inbox is a projection of GitHub state: an outage (or an unresolved
/// viewer identity) empties it exactly like a genuinely clear queue does, and
/// "You're all caught up" then reads as a confident lie. When one of these
/// holds, the empty state says what it actually knows instead.
enum InboxEmptyCaveat {
  /// githubstatus.com reports an incident, degradation or maintenance, so the
  /// snapshot behind this list may be stale or partial.
  githubDegraded,

  /// No forge resolved the operator's login. Every inbox section is classified
  /// relative to it (`ClassifyPrInboxUseCase` returns an all-empty inbox when
  /// every login is empty), so the list is empty *by construction* — regardless
  /// of how many pull requests are actually waiting.
  identityUnresolved,
}

/// Decides which caveat (if any) applies to an empty inbox.
///
/// An unresolved identity outranks a degraded GitHub, even though the outage is
/// usually what caused it. "GitHub might be down" is true but leaves the
/// operator staring at an inbox with no idea why it is empty; "we don't know
/// who you are on GitHub" is the specific fact, and it is the one that says
/// this list is empty *by construction* rather than possibly-incomplete. When
/// both hold, the degradation still shows up as the likely cause and the
/// status page stays one click away.
///
/// What counts as degraded is [isGitHubDegraded]'s call, shared with the banner
/// so the two surfaces cannot disagree.
///
/// [viewerLogins] is the per-forge login map, tested exactly as
/// `ClassifyPrInboxUseCase` tests it — every login empty (which an empty map
/// satisfies) is precisely when it returns an all-empty inbox. Deriving the
/// caveat from the same input is what keeps this screen from explaining a
/// condition the classifier isn't actually in.
InboxEmptyCaveat? resolveInboxEmptyCaveat({
  required GitHubStatusIndicator? indicator,
  required Map<ForgeHost, String> viewerLogins,
}) {
  if (viewerLogins.values.every((login) => login.isEmpty)) {
    return InboxEmptyCaveat.identityUnresolved;
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
    final caveat = resolveInboxEmptyCaveat(
      indicator: status?.indicator,
      viewerLogins: ref.watch(viewerLoginsProvider),
    );

    switch (caveat) {
      case null:
        return EmptyState(
          message: l10n.inboxAllCaughtUp,
          icon: AppIcons.checkCircle2,
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
