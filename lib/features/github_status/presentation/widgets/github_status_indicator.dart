import 'package:control_center/core/theme/app_shadows.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/github_status/domain/entities/github_service_status.dart';
import 'package:control_center/features/github_status/providers/github_status_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public githubstatus.com landing page opened by the "Open in browser" button.
const String _statusPageUrl = 'https://www.githubstatus.com/';

/// Compact GitHub status chip that opens a flyout listing each component's
/// status, active incidents, and a link to githubstatus.com.
class GitHubStatusButton extends ConsumerWidget {
  /// Creates a [GitHubStatusButton].
  const GitHubStatusButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(githubStatusProvider);
    final theme = FTheme.of(context);

    return FPopover(
      popoverAnchor: Alignment.bottomRight,
      childAnchor: Alignment.topRight,
      style: FPopoverStyle(
        popoverPadding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colors.border),
          boxShadow: AppShadows.golden,
        ),
      ),
      hideRegion: FPopoverHideRegion.excludeChild,
      popoverBuilder: (context, _) => _StatusFlyout(
        status: status,
        onRefresh: () => ref.read(githubStatusProvider.notifier).refresh(),
      ),
      builder: (context, controller, child) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: controller.toggle,
        child: child,
      ),
      child: _StatusChip(status: status),
    );
  }
}

class _StatusChip extends StatefulWidget {
  const _StatusChip({required this.status});

  final AsyncValue<GitHubServiceStatus> status;

  @override
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final indicator = widget.status.value?.indicator;
    final hasError = widget.status.hasError && !widget.status.hasValue;
    final accent = _indicatorColor(tokens, indicator, hasError: hasError);

    final bg = _hover
        ? theme.colors.secondary
        : theme.colors.background.withValues(alpha: 0.7);
    final borderColor = theme.colors.border.withValues(alpha: _hover ? 1 : 0.6);
    final fg = theme.colors.foreground;
    final chevron = theme.colors.mutedForeground;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusDot(color: accent),
            const SizedBox(width: 8),
            Text(
              l10n.githubStatusTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            Icon(LucideIcons.chevronUp, size: 12, color: chevron),
          ],
        ),
      ),
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
  const _StatusFlyout({required this.status, required this.onRefresh});

  final AsyncValue<GitHubServiceStatus> status;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 380,
      child: status.when(
        data: (s) => _FlyoutBody(status: s, onRefresh: onRefresh),
        loading: () => const _LoadingBody(),
        error: (_, _) => _ErrorBody(onRefresh: onRefresh),
      ),
    );
  }
}

class _FlyoutBody extends StatelessWidget {
  const _FlyoutBody({required this.status, required this.onRefresh});

  final GitHubServiceStatus status;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final allOperational = status.indicator == GitHubStatusIndicator.none;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          child: Row(
            children: [
              _StatusDot(
                color: _indicatorColor(tokens, status.indicator),
                size: 12,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      allOperational
                          ? l10n.githubStatusAllOperational
                          : status.description,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.githubStatusUpdated(
                        _relativeTime(context, status.fetchedAt),
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colors.mutedForeground,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              _IconAction(
                icon: LucideIcons.refreshCw,
                tooltip: l10n.githubStatusRefresh,
                onTap: onRefresh,
              ),
            ],
          ),
        ),
        if (status.incidents.isNotEmpty) ...[
          Divider(height: 1, color: theme.colors.border),
          _IncidentsSection(incidents: status.incidents),
        ],
        Divider(height: 1, color: theme.colors.border),
        _ComponentsSection(components: status.components),
        Divider(height: 1, color: theme.colors.border),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: TextButton.icon(
            onPressed: () => _open(_statusPageUrl),
            icon: const Icon(LucideIcons.externalLink, size: 14),
            label: Text(l10n.githubStatusOpenInBrowser),
            style: TextButton.styleFrom(
              foregroundColor: theme.colors.foreground,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
      ],
    );
  }
}

class _IncidentsSection extends StatelessWidget {
  const _IncidentsSection({required this.incidents});

  final List<GitHubStatusIncident> incidents;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.githubStatusIncidents.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.colors.mutedForeground,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < incidents.length; i++) ...[
            _IncidentTile(incident: incidents[i]),
            if (i < incidents.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  const _IncidentTile({required this.incident});

  final GitHubStatusIncident incident;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final tokens = context.designSystem;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _open(incident.shortlink),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colors.secondary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.circleAlert,
                size: 14,
                color: tokens?.warn ?? const Color(0xFFE07B00),
              ),
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
                        color: theme.colors.foreground,
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
                        color: theme.colors.mutedForeground,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.externalLink,
                size: 12,
                color: theme.colors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComponentsSection extends StatelessWidget {
  const _ComponentsSection({required this.components});

  final List<GitHubStatusComponent> components;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.githubStatusComponents.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.colors.mutedForeground,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          for (final c in components) _ComponentRow(component: c),
        ],
      ),
    );
  }
}

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({required this.component});

  final GitHubStatusComponent component;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final tokens = context.designSystem;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _StatusDot(color: _componentColor(tokens, component.status), size: 7),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              component.name,
              style: TextStyle(
                fontSize: 12,
                color: theme.colors.foreground,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 140,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.circleAlert,
                size: 16,
                color: theme.colors.mutedForeground,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.githubStatusFetchFailed,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colors.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(LucideIcons.refreshCw, size: 14),
                label: Text(l10n.githubStatusRefresh),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () => _open(_statusPageUrl),
                icon: const Icon(LucideIcons.externalLink, size: 14),
                label: Text(l10n.githubStatusOpenInBrowser),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatefulWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Future<void> Function() onTap;

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool _hover = false;
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return FTooltip(
      tipBuilder: (_, _) => Text(widget.tooltip),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            if (_running) {
              return;
            }
            setState(() => _running = true);
            try {
              await widget.onTap();
            } finally {
              if (mounted) {
                setState(() => _running = false);
              }
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _hover ? theme.colors.secondary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

void _open(String url) {
  // ignore: discarded_futures
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
