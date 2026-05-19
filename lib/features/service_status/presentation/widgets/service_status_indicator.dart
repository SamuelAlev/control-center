import 'package:cc_domain/features/service_status/domain/entities/github_service_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/service_status/providers/service_status_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/refresh_control.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Public githubstatus.com landing page opened by the provider block link.
const String _githubStatusPageUrl = 'https://www.githubstatus.com/';

/// Public status.claude.com landing page opened by the provider block link.
const String _claudeStatusPageUrl = 'https://status.claude.com/';

/// Public status.openai.com landing page opened by the provider block link.
const String _openaiStatusPageUrl = 'https://status.openai.com/';

/// Public status.moonshot.cn landing page opened by the provider block link.
const String _kimiStatusPageUrl = 'https://status.moonshot.cn/';

/// Global-sidebar entry for external service status, pinned in the footer
/// above the newsfeed. Unlike the nav items around it, the entry is ALWAYS
/// mounted and opens no route: tapping it opens a flyout to the RIGHT of the
/// sidebar (the sidebar hugs the window's left edge, so right is the only side
/// with room) covering the external services the operator depends on (GitHub,
/// Claude, Codex, Kimi): each provider's status word, active incidents,
/// degraded components and a link to its status page.
///
/// The row reports the worst indicator across all providers through its
/// badge — the same headline pattern as the subscription usage pill. A status
/// dot is always present (green when healthy, muted before the first snapshot
/// lands, so a healthy boot never flashes "Unknown"); the status word joins
/// the dot once the headline is anything but operational, so a degraded state
/// is never carried by colour alone.
class ServiceStatusSidebarEntry extends ConsumerStatefulWidget {
  /// Creates a [ServiceStatusSidebarEntry].
  const ServiceStatusSidebarEntry({super.key});

  @override
  ConsumerState<ServiceStatusSidebarEntry> createState() =>
      _ServiceStatusSidebarEntryState();
}

class _ServiceStatusSidebarEntryState
    extends ConsumerState<ServiceStatusSidebarEntry> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    _controller.toggle();
    // Opening the entry is an explicit "show me now" — refresh in the
    // background so the flyout is fresh without blocking the open.
    ref.read(githubStatusProvider.notifier).refresh();
    ref.read(claudeStatusProvider.notifier).refresh();
    ref.read(openaiStatusProvider.notifier).refresh();
    ref.read(kimiStatusProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final github = ref.watch(githubStatusProvider);
    final claude = ref.watch(claudeStatusProvider);
    final openai = ref.watch(openaiStatusProvider);
    final kimi = ref.watch(kimiStatusProvider);
    final headline = _worstIndicator([
      github.value?.indicator,
      claude.value?.indicator,
      openai.value?.indicator,
      kimi.value?.indicator,
    ]);

    return CcPopover(
      controller: _controller,
      // The row itself handles the tap (it refreshes the providers as it
      // toggles), so the popover must not wrap the target in a second tap
      // layer or one press would toggle twice.
      toggleOnTargetTap: false,
      targetAnchor: Alignment.centerRight,
      followerAnchor: Alignment.centerLeft,
      offset: const Offset(6, 0),
      semanticLabel: l10n.serviceStatusTitle,
      overlayBuilder: (context, _) => _StatusFlyout(
        github: github,
        claude: claude,
        openai: openai,
        kimi: kimi,
        onRefresh: () async {
          await ref.read(githubStatusProvider.notifier).refresh();
          await ref.read(claudeStatusProvider.notifier).refresh();
          await ref.read(openaiStatusProvider.notifier).refresh();
          await ref.read(kimiStatusProvider.notifier).refresh();
        },
      ),
      target: CcSidebarItem(
        icon: AppIcons.activity,
        label: l10n.serviceStatusTitle,
        badge: _StatusBadge(indicator: headline),
        onPressed: _open,
      ),
    );
  }
}

/// The worst indicator across providers, `null` when nothing has loaded yet.
/// Maintenance outranks "operational" (a live maintenance window is worth a
/// glance) but never a real incident; an unknown (unfetched/unreachable) page
/// only beats a clean bill of health.
GitHubStatusIndicator? _worstIndicator(
  List<GitHubStatusIndicator?> indicators,
) {
  var worst = 0;
  GitHubStatusIndicator? result;
  for (final indicator in indicators) {
    if (indicator == null) {
      continue;
    }
    final severity = _severity(indicator);
    if (result == null || severity > worst) {
      worst = severity;
      result = indicator;
    }
  }
  return result;
}

int _severity(GitHubStatusIndicator indicator) => switch (indicator) {
  GitHubStatusIndicator.critical => 5,
  GitHubStatusIndicator.major => 4,
  GitHubStatusIndicator.minor => 3,
  GitHubStatusIndicator.maintenance => 2,
  GitHubStatusIndicator.unknown => 1,
  GitHubStatusIndicator.none => 0,
};

/// Short status word for the tag / provider blocks ("Operational", …). Never
/// the API's own description string — it is English-only and verbose.
///
/// Public because other surfaces quote a provider's health in their own copy
/// (the inbox's empty-state caveat) and must use the same words as the status
/// tag, not a second vocabulary.
String serviceStatusWord(
  AppLocalizations l10n,
  GitHubStatusIndicator? indicator,
) => switch (indicator) {
  GitHubStatusIndicator.none => l10n.serviceStatusOperational,
  GitHubStatusIndicator.minor => l10n.serviceStatusMinorIssues,
  GitHubStatusIndicator.major => l10n.serviceStatusMajorIssues,
  GitHubStatusIndicator.critical => l10n.serviceStatusOutage,
  GitHubStatusIndicator.maintenance => l10n.serviceStatusMaintenance,
  GitHubStatusIndicator.unknown || null => l10n.serviceStatusUnknown,
};

/// The entry's live status badge: a colored dot at all times, joined by the
/// status word once the headline is anything but operational — quiet when
/// everything is good (presence reports trouble, not its absence) and never
/// colour-alone when it isn't. The bare dot carries the word as a semantic
/// label so screen readers hear the state without the text.
///
/// In the icon-only rail the badge straddles the item square's top-right
/// corner, where a word would overflow the 54px rail — so it degrades to the
/// dot alone (the tooltip still names the entry).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.indicator});

  /// Headline indicator (worst across providers); null before the first load.
  final GitHubStatusIndicator? indicator;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final color = _indicatorColor(tokens, indicator);
    final rail = CcSidebarScope.collapsedOf(context) ?? false;
    final quiet =
        rail || indicator == null || indicator == GitHubStatusIndicator.none;
    if (quiet) {
      return Semantics(
        label: serviceStatusWord(l10n, indicator),
        child: _StatusDot(color: color),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusDot(color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          serviceStatusWord(l10n, indicator),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
}

class _StatusFlyout extends StatelessWidget {
  const _StatusFlyout({
    required this.github,
    required this.claude,
    required this.openai,
    required this.kimi,
    required this.onRefresh,
  });

  final AsyncValue<GitHubServiceStatus> github;
  final AsyncValue<GitHubServiceStatus> claude;
  final AsyncValue<GitHubServiceStatus> openai;
  final AsyncValue<GitHubServiceStatus> kimi;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final statuses = [github, claude, openai, kimi];
    final refreshing = statuses.any((s) => s.isLoading);
    // The header refresh refetches all four providers, so the freshness card
    // reports the most recent fetch across them.
    DateTime? lastChecked;
    for (final s in statuses) {
      final fetchedAt = s.value?.fetchedAt;
      if (fetchedAt != null &&
          (lastChecked == null || fetchedAt.isAfter(lastChecked))) {
        lastChecked = fetchedAt;
      }
    }
    // Off-Material overlay: supply a concrete text style so nothing falls
    // through to the 48px yellow error fallback (same guard as the
    // subscription usage flyout).
    return DefaultTextStyle(
      style: TextStyle(
        color: tokens.textPrimary,
        fontSize: 13,
        decoration: TextDecoration.none,
      ),
      child: SizedBox(
        width: 320,
        // Incidents can stack up during a bad week — scroll rather than push
        // past the viewport cap imposed by [CcOverlayAnchor].
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.serviceStatusTitle,
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    RefreshControl(
                      onRefresh: onRefresh,
                      lastChecked: lastChecked,
                      isLoading: refreshing,
                      tooltip: l10n.githubStatusRefresh,
                    ),
                  ],
                ),
              ),
              _ProviderBlock(
                name: 'GitHub',
                status: github,
                pageUrl: _githubStatusPageUrl,
                openLabel: l10n.githubStatusOpenInBrowser,
                fetchFailedLabel: l10n.githubStatusFetchFailed,
              ),
              CcDivider(color: tokens.borderSecondary),
              _ProviderBlock(
                name: 'Claude',
                status: claude,
                pageUrl: _claudeStatusPageUrl,
                openLabel: l10n.claudeStatusOpenInBrowser,
                fetchFailedLabel: l10n.claudeStatusFetchFailed,
              ),
              CcDivider(color: tokens.borderSecondary),
              _ProviderBlock(
                name: 'Codex',
                status: openai,
                pageUrl: _openaiStatusPageUrl,
                openLabel: l10n.openaiStatusOpenInBrowser,
                fetchFailedLabel: l10n.openaiStatusFetchFailed,
              ),
              CcDivider(color: tokens.borderSecondary),
              _ProviderBlock(
                name: 'Kimi',
                status: kimi,
                pageUrl: _kimiStatusPageUrl,
                openLabel: l10n.kimiStatusOpenInBrowser,
                fetchFailedLabel: l10n.kimiStatusFetchFailed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One provider's slice of the flyout: status word + updated time, active
/// incidents and degraded components (only when present — the flyout stays
/// small by never listing healthy components) and a status-page link.
class _ProviderBlock extends StatelessWidget {
  const _ProviderBlock({
    required this.name,
    required this.status,
    required this.pageUrl,
    required this.openLabel,
    required this.fetchFailedLabel,
  });

  final String name;
  final AsyncValue<GitHubServiceStatus> status;
  final String pageUrl;
  final String openLabel;
  final String fetchFailedLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: status.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CcSpinner(size: 14)),
        ),
        error: (_, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  AppIcons.circleAlert,
                  size: 14,
                  color: tokens.textTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fetchFailedLabel,
                    style: TextStyle(color: tokens.textTertiary, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // The status page is most useful exactly when the fetch failed —
            // offer the same link button the data state has.
            _pageLinkButton(),
          ],
        ),
        data: (s) {
          final degraded = s.components
              .where(
                (c) =>
                    c.status != GitHubComponentStatus.operational &&
                    c.status != GitHubComponentStatus.unknown,
              )
              .toList();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusDot(
                    color: _indicatorColor(tokens, s.indicator),
                    size: 10,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    serviceStatusWord(l10n, s.indicator),
                    style: TextStyle(
                      color: _indicatorColor(tokens, s.indicator),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              AppTimestamp(
                dateTime: s.fetchedAt,
                child: Text(
                  l10n.githubStatusUpdated(_relativeTime(context, s.fetchedAt)),
                  style: TextStyle(
                    color: tokens.textTertiary,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ),
              if (s.incidents.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (var i = 0; i < s.incidents.length; i++) ...[
                  _IncidentTile(incident: s.incidents[i]),
                  if (i < s.incidents.length - 1) const SizedBox(height: 6),
                ],
              ],
              if (degraded.isNotEmpty) ...[
                const SizedBox(height: 6),
                for (final c in degraded)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        _StatusDot(
                          color: _componentColor(tokens, c.status),
                          size: 7,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.name,
                            style: TextStyle(
                              color: tokens.textPrimary,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              _pageLinkButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _pageLinkButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: CcButton(
        onPressed: () => _open(pageUrl),
        // `line`, not `ghost`: ghost is transparent until hovered, which read
        // as plain text (not a button) at rest.
        variant: CcButtonVariant.line,
        size: CcButtonSize.sm,
        icon: AppIcons.externalLink,
        child: Text(openLabel),
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  const _IncidentTile({required this.incident});

  final GitHubStatusIncident incident;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: () => _open(incident.shortlink),
      borderRadius: BorderRadius.circular(8),
      semanticLabel: incident.name,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: hovered
                ? tokens.bgSecondary
                : tokens.bgSecondary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: tokens.borderSecondary.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(AppIcons.circleAlert, size: 14, color: tokens.warn),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      incident.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      incident.status,
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.textTertiary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(AppIcons.externalLink, size: 12, color: tokens.textTertiary),
            ],
          ),
        );
      },
    );
  }
}

void _open(String url) {
  openExternalUrl(url);
}

Color _indicatorColor(
  DesignSystemTokens? tokens,
  GitHubStatusIndicator? indicator, {
  bool hasError = false,
}) {
  if (hasError) {
    return tokens?.muted ?? const Color(0xFF8B8B8B);
  }
  switch (indicator) {
    case GitHubStatusIndicator.none:
      return tokens?.success ?? const Color(0xFF1FAE5C);
    case GitHubStatusIndicator.minor:
      return tokens?.warn ?? const Color(0xFFE0B400);
    case GitHubStatusIndicator.major:
      return tokens?.warn ?? const Color(0xFFE07B00);
    case GitHubStatusIndicator.critical:
      return tokens?.danger ?? const Color(0xFFD93636);
    case GitHubStatusIndicator.maintenance:
      return tokens?.muted ?? const Color(0xFF3478F6);
    case GitHubStatusIndicator.unknown:
    case null:
      return tokens?.muted ?? const Color(0xFF8B8B8B);
  }
}

Color _componentColor(
  DesignSystemTokens? tokens,
  GitHubComponentStatus status,
) {
  switch (status) {
    case GitHubComponentStatus.operational:
      return tokens?.success ?? const Color(0xFF1FAE5C);
    case GitHubComponentStatus.degradedPerformance:
      return tokens?.warn ?? const Color(0xFFE0B400);
    case GitHubComponentStatus.partialOutage:
      return tokens?.warn ?? const Color(0xFFE07B00);
    case GitHubComponentStatus.majorOutage:
      return tokens?.danger ?? const Color(0xFFD93636);
    case GitHubComponentStatus.underMaintenance:
      return tokens?.muted ?? const Color(0xFF3478F6);
    case GitHubComponentStatus.unknown:
      return tokens?.muted ?? const Color(0xFF8B8B8B);
  }
}

String _relativeTime(BuildContext context, DateTime when) {
  final l10n = AppLocalizations.of(context);
  final delta = DateTime.now().difference(when);
  if (delta.inSeconds < 60) {
    return l10n.justNow.toLowerCase();
  }
  if (delta.inMinutes < 60) {
    return l10n.minutesAgo(delta.inMinutes);
  }
  if (delta.inHours < 24) {
    return l10n.hoursAgo(delta.inHours);
  }
  return l10n.daysAgo(delta.inDays);
}
