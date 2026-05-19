import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/service_status/presentation/widgets/service_status_indicator.dart'
    show serviceStatusWord;
import 'package:control_center/features/service_status/providers/service_status_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Public githubstatus.com landing page the banner's action opens.
const String kGitHubStatusPageUrl = 'https://www.githubstatus.com/';

/// Whether [indicator] is GitHub telling us something is wrong.
///
/// The single definition of "degraded" every surface reads, so the banner and
/// the inbox's empty-state caveat can never disagree about it. Deliberately
/// exhaustive: a new indicator has to be classified here rather than defaulting
/// to silence. `unknown` is NOT degraded — it means the host could not reach
/// the status page, which is no evidence either way, and `null` (not loaded
/// yet) says nothing at all.
bool isGitHubDegraded(GitHubStatusIndicator? indicator) => switch (indicator) {
  GitHubStatusIndicator.minor ||
  GitHubStatusIndicator.major ||
  GitHubStatusIndicator.critical ||
  GitHubStatusIndicator.maintenance => true,
  GitHubStatusIndicator.none || GitHubStatusIndicator.unknown || null => false,
};

/// Identifies what the banner is currently reporting, so a dismissal sticks to
/// that trouble and no further.
///
/// Keyed by the open incidents when GitHub named any (a new incident is new
/// news and shows again), and by the indicator otherwise. Null whenever
/// [isGitHubDegraded] is false.
String? githubDegradedKey(GitHubServiceStatus? status) {
  if (status == null || !isGitHubDegraded(status.indicator)) {
    return null;
  }
  final ids = [
    for (final i in status.incidents)
      if (i.id.isNotEmpty) i.id,
  ]..sort();
  return ids.isEmpty ? 'indicator:${status.indicator.name}' : ids.join(',');
}

/// The banner keys the operator has dismissed this session.
///
/// Session-scoped on purpose: an incident the operator waved away this
/// afternoon is worth re-raising after a restart, and persisting it would mean
/// a stale dismissal outliving the outage it referred to.
class DismissedGitHubBannersNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Hides the banner for [key] until GitHub's trouble changes.
  void dismiss(String key) => state = {...state, key};
}

/// Tracks dismissed GitHub-degradation banners.
final dismissedGitHubBannersProvider =
    NotifierProvider<DismissedGitHubBannersNotifier, Set<String>>(
      DismissedGitHubBannersNotifier.new,
    );

/// An inline banner that reports a degraded GitHub on the surfaces whose data
/// comes from it (the inbox and the pull-request queue).
///
/// The PR surfaces are projections of GitHub state, and a struggling GitHub
/// degrades them silently: the server keeps serving its last snapshot, so the
/// list looks authoritative while being stale or partial. The banner is the
/// standing caveat — it says the data may not be current and points at the
/// status page — and it renders nothing at all while GitHub is healthy
/// (presence reports trouble, never its absence).
///
/// Carries its own bottom margin so callers can drop it into a column
/// unconditionally without leaving a gap behind when it hides.
class GitHubDegradedBanner extends ConsumerWidget {
  /// Creates a [GitHubDegradedBanner].
  const GitHubDegradedBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(githubStatusProvider).value;
    final key = githubDegradedKey(status);
    if (key == null ||
        ref.watch(dismissedGitHubBannersProvider).contains(key)) {
      return const SizedBox.shrink();
    }

    final indicator = status!.indicator;
    final incident = status.incidents.firstOrNull;
    final headline = incident?.name.trim() ?? '';
    // The body quotes the same status word as the service-status tag; the
    // incident headline is GitHub's own string and stays verbatim.
    final body = l10n.githubDegradedBody(serviceStatusWord(l10n, indicator));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CcAlert(
        variant:
            indicator == GitHubStatusIndicator.critical ||
                indicator == GitHubStatusIndicator.major
            ? CcAlertVariant.danger
            : CcAlertVariant.warning,
        icon: AppIcons.cloudOff,
        title: l10n.githubDegradedTitle,
        description: Text(headline.isEmpty ? body : '$body\n$headline'),
        // Trailing, not stacked below: the banner sits above a list the
        // operator came here to read, so the caveat must not cost a third row
        // of height. The status page is a side trip, not the point.
        trailing: CcButton(
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          onPressed: () => openExternalUrl(kGitHubStatusPageUrl),
          child: Text(l10n.githubStatusOpenInBrowser),
        ),
        onClose: () =>
            ref.read(dismissedGitHubBannersProvider.notifier).dismiss(key),
      ),
    );
  }
}
