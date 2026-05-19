import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_shared.dart';
import 'package:control_center/features/dashboard/providers/fleet_state_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The active fleet — a horizontal rail of agent cards, the dashboard's "alive"
/// centerpiece. Each card reports the agent's live state (running / blocked /
/// failed / idle) with colour, shape and label, never colour alone.
class DashboardFleetRail extends ConsumerStatefulWidget {
  /// Creates a [DashboardFleetRail].
  const DashboardFleetRail({super.key, required this.codeFont});

  /// User-selected code font.
  final String codeFont;

  @override
  ConsumerState<DashboardFleetRail> createState() => _DashboardFleetRailState();
}

class _DashboardFleetRailState extends ConsumerState<DashboardFleetRail> {
  // A horizontal ListView never adopts the PrimaryScrollController, so the
  // Scrollbar and the list must share an explicit controller — otherwise the
  // thumb is painted but not wired to the scroll position (can't be dragged).
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fleet = ref.watch(dashboardFleetProvider);
    final codeFont = widget.codeFont;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashboardSectionHeader(
          title: l10n.activeFleet,
          count: fleet.isEmpty ? null : l10n.agentsCountLabel(fleet.length),
          codeFont: codeFont,
          trailing: DashboardLinkArrow(
            label: l10n.agentRegistry,
            onTap: () => GoRouter.of(context).go(agentsRoute),
          ),
        ),
        if (fleet.isEmpty)
          _EmptyFleet(l10n: l10n)
        else
          SizedBox(
            height: 180,
            child: ScrollConfiguration(
              // Desktop has no touch surface; allow click-drag (and trackpad
              // swipe) so the rail is scrollable with a mouse. Suppress the
              // implicit scrollbar — the explicit one below owns the thumb.
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: const {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                },
                scrollbars: false,
              ),
              child: Scrollbar(
                controller: _controller,
                thumbVisibility: true,
                interactive: true,
                child: ListView.separated(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  // Reserve room below the cards so the scrollbar track sits in
                  // its own gutter instead of overlapping the card edges.
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  itemCount: fleet.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, i) =>
                      _FleetCard(fleet: fleet[i], codeFont: codeFont),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyFleet extends StatelessWidget {
  const _EmptyFleet({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    return DashboardPanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            Icon(LucideIcons.bot, size: 22, color: ds.muted),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.noAgentsConfigured,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ds.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maps an [AgentLiveState] onto its presentation tokens.
class _StateVisual {
  const _StateVisual(this.color, this.background, this.label, this.icon);
  final Color color;
  final Color background;
  final String label;
  final IconData? icon;

  static _StateVisual of(
    AgentLiveState state,
    DesignSystemTokens ds,
    AppLocalizations l10n,
  ) {
    switch (state) {
      case AgentLiveState.running:
        return _StateVisual(
          ds.success,
          ds.successSoft,
          l10n.runningStatus,
          null,
        );
      case AgentLiveState.blocked:
        return _StateVisual(
          Color.lerp(ds.warn, Colors.black, 0.28)!,
          ds.warnSoft,
          l10n.blockedStatus,
          LucideIcons.pause,
        );
      case AgentLiveState.failed:
        return _StateVisual(
          ds.danger,
          ds.dangerSoft,
          l10n.failedStatus,
          LucideIcons.x,
        );
      case AgentLiveState.idle:
        return _StateVisual(ds.muted, ds.hoverStrong, l10n.idleStatus, null);
      case AgentLiveState.neverRun:
        return _StateVisual(
          ds.muted,
          ds.hoverStrong,
          l10n.neverRunStatus,
          null,
        );
    }
  }
}

class _FleetCard extends StatelessWidget {
  const _FleetCard({required this.fleet, required this.codeFont});

  final FleetAgent fleet;
  final String codeFont;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    final l10n = AppLocalizations.of(context);
    final agent = fleet.agent;
    final visual = _StateVisual.of(fleet.state, ds, l10n);

    final borderColor = switch (fleet.state) {
      AgentLiveState.running => Color.lerp(ds.success, ds.borderPrimary, 0.55)!,
      AgentLiveState.blocked => Color.lerp(ds.warn, ds.borderPrimary, 0.5)!,
      AgentLiveState.failed => Color.lerp(ds.danger, ds.borderPrimary, 0.55)!,
      _ => ds.borderPrimary,
    };

    final task = fleet.latestRun?.summary?.trim();
    final taskText = (task != null && task.isNotEmpty) ? task : l10n.noActiveRun;
    final role = agent.role?.label ?? agent.title;
    final footTime = formatRelativeTime(context, fleet.lastActive);
    final footLead = fleet.latestRun?.adapter ?? role.toLowerCase();

    return Container(
      width: 244,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ds.panel,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AvatarGlyph(name: agent.name, codeFont: codeFont),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      agent.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: dashMono(codeFont, size: 13, color: ds.fg),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      role.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: dashMono(
                        codeFont,
                        size: 10,
                        color: ds.muted,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StateBadge(
                visual: visual,
                codeFont: codeFont,
                animate: fleet.state == AgentLiveState.running,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Text(
              taskText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, height: 1.4, color: ds.muted),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Flexible(
                child: Text(
                  footLead,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: dashMono(codeFont, size: 11, color: ds.muted),
                ),
              ),
              if (footTime.isNotEmpty) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration:
                        BoxDecoration(color: ds.idle, shape: BoxShape.circle),
                  ),
                ),
                Text(
                  footTime,
                  style: dashMono(codeFont, size: 11, color: ds.muted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarGlyph extends StatelessWidget {
  const _AvatarGlyph({required this.name, required this.codeFont});

  final String name;
  final String codeFont;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ds.surface,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: ds.borderPrimary),
      ),
      child: Text(initial, style: dashMono(codeFont, size: 13, color: ds.fg)),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({
    required this.visual,
    required this.codeFont,
    required this.animate,
  });

  final _StateVisual visual;
  final String codeFont;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return DashboardPill(
      background: visual.background,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (animate)
            _ActivityBars(color: visual.color)
          else if (visual.icon != null)
            Icon(visual.icon, size: 11, color: visual.color)
          else
            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: visual.color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 5),
          Text(
            visual.label.toUpperCase(),
            style: dashMono(
              codeFont,
              size: 10,
              color: visual.color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Four bars that breathe to signal a live run. Honours reduced-motion by
/// holding a static, fully-legible shape rather than animating.
class _ActivityBars extends StatefulWidget {
  const _ActivityBars({required this.color});

  final Color color;

  @override
  State<_ActivityBars> createState() => _ActivityBarsState();
}

class _ActivityBarsState extends State<_ActivityBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  static const _phases = [0.0, 0.18, 0.36, 0.54];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 11,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final phase in _phases) ...[
                _bar(phase),
                if (phase != _phases.last) const SizedBox(width: 2),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _bar(double phase) {
    final t = (_controller.value + phase) % 1.0;
    final eased = Curves.easeInOut.transform(t < 0.5 ? t * 2 : (1 - t) * 2);
    final height = 4.0 + 7.0 * eased;
    return Container(
      width: 2,
      height: height,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: const BorderRadius.all(Radius.circular(1)),
      ),
    );
  }
}
