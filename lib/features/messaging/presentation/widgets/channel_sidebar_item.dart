import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_hover_target.dart';
import 'package:control_center/features/messaging/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Extracts the selected channel id from the current [location] path, or null
/// when not on a `/workspaces/<ws>/channels/<id>` location. Parses the location
/// rather than `pathParameters` because the sidebar sits in the shell, above
/// the channel route, so its `:channelId` is not in `GoRouterState` scope here.
String? selectedChannelIdFromLocation(String location, String? workspaceId) {
  if (workspaceId == null) {
    return null;
  }
  final prefix = '${channelsRoute(workspaceId)}/';
  if (!location.startsWith(prefix)) {
    return null;
  }
  final rest = location.substring(prefix.length);
  final slash = rest.indexOf('/');
  final id = slash == -1 ? rest : rest.substring(0, slash);
  return id.isEmpty ? null : id;
}

/// A channel row with its live status, unread signal, and delete affordances,
/// shared by the global sidebar's inline channel list
/// (`ConversationsSidebarSection`) and the channels directory page's filtered
/// list (`ChannelsSubSidebar`).
class ChannelSidebarItem extends ConsumerWidget {
  /// Creates a [ChannelSidebarItem].
  const ChannelSidebarItem({
    super.key,
    required this.channel,
    required this.selected,
    required this.onPress,
    this.muted = false,
  });

  /// The channel to render.
  final Channel channel;

  /// Whether the row reads as the route's selected channel.
  final bool selected;

  /// Tap handler (navigation; the URL is the source of truth for selection).
  final VoidCallback onPress;

  /// Whether this is a muted agent-DM row: dimmed and with no unread indicator,
  /// so agent chatter stays quiet and never touches the human unread counts.
  final bool muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final status = ref.watch(channelStatusProvider(channel.id));
    // Muted agent rows never read the unread provider — their notifications are
    // deliberately suppressed.
    final unread = muted ? false : ref.watch(channelUnreadProvider(channel.id));
    final running = status == ChannelStatus.running;

    final label = channel.name.isNotEmpty ? channel.name : l10n.channelLabel;
    // The leading slot carries the running signal (a spinner), so the trailing
    // indicator stays clear of a redundant running dot.
    final leading = _ChannelLeading(channelId: channel.id, running: running);

    return GestureDetector(
      onSecondaryTapDown: (details) =>
          _showDeleteMenu(context, ref, details.globalPosition),
      // Dwelling on the row opens a flyout to its right with the channel's live
      // state (which agents and subagents are running, for how long, how much
      // context is left). The row itself is unchanged; the card is additive.
      child: ChannelHoverTarget(
        channel: channel,
        child: ChannelRow(
          leading: leading,
          label: label,
          selected: selected,
          status: status,
          unread: unread,
          leadingHandlesRunning: true,
          muted: muted,
          onPress: onPress,
          onLongPress: () => _confirmDelete(context, ref),
        ),
      ),
    );
  }

  void _showDeleteMenu(BuildContext context, WidgetRef ref, Offset position) {
    final l10n = AppLocalizations.of(context);
    showCcMenuAt(
      context: context,
      position: position,
      items: [
        CcMenuItem(
          label: l10n.delete,
          icon: AppIcons.trash2,
          destructive: true,
          onSelected: () => _confirmDelete(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.deleteConversation,
        content: Text(
          l10n.deleteNamedConversation(
            channel.name.isNotEmpty ? channel.name : l10n.thisConversation,
          ),
        ),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    final service = ref.read(messagingServiceProvider);
    await service.deleteChannel(ref.requireWorkspaceId(), channel.id);

    if (context.mounted) {
      // If the deleted channel is the one open in the URL, drop back to the
      // channel list (the URL is the source of truth for selection).
      final workspaceId = context.currentWorkspaceId;
      final routeChannelId = selectedChannelIdFromLocation(
        GoRouterState.of(context).uri.path,
        workspaceId,
      );
      if (routeChannelId == channel.id && workspaceId != null) {
        GoRouter.of(context).go(channelsRoute(workspaceId));
      }
    }
  }
}

/// A channel navigation row that reproduces [CcSidebarItem]'s exact look — the
/// `accentSoft` fill + reserved 1px `accent` border when [selected], the same
/// hover/pressed washes and padding — so channels read as first-class sidebar
/// items. It can't be a [CcSidebarItem] itself because that widget's icon-only
/// API hosts neither a [leading] widget (an agent avatar / PR badge / spinner)
/// nor the [onLongPress] used for the delete menu. (The 4px inter-item gap
/// comes from the enclosing [CcSidebarGroup], same as [CcSidebarItem].)
class ChannelRow extends StatelessWidget {
  /// Creates a [ChannelRow].
  const ChannelRow({
    super.key,
    required this.leading,
    required this.label,
    required this.selected,
    required this.status,
    required this.unread,
    required this.leadingHandlesRunning,
    required this.onPress,
    required this.onLongPress,
    this.muted = false,
  });

  /// The leading slot: a spinner while running, else the PR badge / pencil.
  final Widget leading;

  /// The channel display name.
  final String label;

  /// Whether this is the route's selected channel.
  final bool selected;

  /// The channel's live status (drives the trailing indicator).
  final ChannelStatus status;

  /// Whether the channel has unseen agent messages (drives the notification dot
  /// on idle channels).
  final bool unread;

  /// Whether the leading slot already shows the running signal (the channel
  /// leading spins). Suppresses a redundant trailing running dot when true.
  final bool leadingHandlesRunning;

  /// Whether this is a muted agent-DM row: dimmed label and no trailing
  /// status/unread indicator.
  final bool muted;

  /// Tap handler.
  final VoidCallback onPress;

  /// Long-press handler (delete shortcut).
  final VoidCallback onLongPress;

  Color _background(DesignSystemTokens t, Set<WidgetState> states) {
    if (selected) {
      return t.accentSoft;
    }
    if (states.contains(WidgetState.pressed)) {
      return t.hoverStrong;
    }
    if (states.contains(WidgetState.hovered)) {
      return t.hover;
    }
    // Alpha-0 hover colour (not transparent-black), mirroring CcSidebarItem, so
    // the AnimatedContainer lerps only alpha on hover↔idle (no dark-gray flash).
    return t.hover.withValues(alpha: 0);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final fg = selected ? t.accent : (muted ? t.textTertiary : t.textSecondary);
    final transitioning = CcSidebarScope.transitioningOf(context) ?? false;

    return CcTappable(
      onPressed: onPress,
      onLongPress: onLongPress,
      borderRadius: AppRadii.brSm,
      semanticLabel: label,
      builder: (context, states) {
        return AnimatedContainer(
          duration: CcMotion.fast,
          curve: CcMotion.standard,
          // Mirrors CcSidebarItem's fixed 32px row height, and its
          // asymmetric inset (left 9 + the 1px reserved border = the visual
          // 10px) so a channel row's leading glyph lands on the same x=27
          // line as a nav item's icon in both modes. While the width
          // animates the trailing inset drops to 0 so the fixed leading
          // glyph + gap can't overflow the narrowing row.
          height: kCcSidebarItemExtent,
          padding: EdgeInsets.only(left: 9, right: transitioning ? 0 : 10),
          decoration: BoxDecoration(
            color: _background(t, states),
            borderRadius: AppRadii.brSm,
            // A 1px border is reserved on every row (alpha-0 when idle) so the
            // layout never shifts when [selected] toggles the brand border on —
            // mirrors CcSidebarItem's selected treatment.
            border: Border.all(
              color: selected ? t.accent : t.accent.withValues(alpha: 0),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              IconTheme.merge(
                data: IconThemeData(color: fg, size: 18),
                child: leading,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                // The label fades while the sidebar's width animates — kept
                // in the layout so the row geometry never changes — mirroring
                // CcSidebarItem's label fade.
                child: AnimatedOpacity(
                  opacity: transitioning ? 0 : 1,
                  duration: CcMotion.fast,
                  curve: CcMotion.standard,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: CcTypography.regularWeight,
                      color: fg,
                    ),
                  ),
                ),
              ),
              if (!muted &&
                  !transitioning &&
                  _ChannelTrailing.shouldShow(
                    status: status,
                    unread: unread,
                    leadingHandlesRunning: leadingHandlesRunning,
                  )) ...[
                const SizedBox(width: AppSpacing.sm),
                _ChannelTrailing(
                  status: status,
                  unread: unread,
                  leadingHandlesRunning: leadingHandlesRunning,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Trailing indicator on a channel row. Differentiated by shape as well as
/// colour (never status-by-colour-alone per DESIGN.md):
/// - `needsInput` → a ringed accent target (the actionable "answer me" signal).
/// - `running` → handled on the leading slot (a spinner), so nothing renders
///   here to avoid a redundant double indicator.
/// - `idle` + unread → a filled accent dot (the "agent finished, you have
///   unseen messages" notification). Needs-input wins over it.
class _ChannelTrailing extends StatelessWidget {
  const _ChannelTrailing({
    required this.status,
    required this.unread,
    required this.leadingHandlesRunning,
  });

  final ChannelStatus status;
  final bool unread;
  final bool leadingHandlesRunning;

  /// Whether anything should render at all (avoids reserving trailing space
  /// when there's no signal).
  static bool shouldShow({
    required ChannelStatus status,
    required bool unread,
    required bool leadingHandlesRunning,
  }) {
    switch (status) {
      case ChannelStatus.needsInput:
        return true;
      case ChannelStatus.running:
        return !leadingHandlesRunning;
      case ChannelStatus.idle:
        return unread;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    switch (status) {
      case ChannelStatus.needsInput:
        // Ringed accent target — the strongest call to action.
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: t.accent, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle),
          ),
        );
      case ChannelStatus.running:
        // Fallback only — channels spin on the leading slot.
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: t.textTertiary,
            shape: BoxShape.circle,
          ),
        );
      case ChannelStatus.idle:
        // The unseen-messages notification dot (accent, distinct from the
        // muted running dot by colour).
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle),
        );
    }
  }
}

/// The leading icon for a channel row: a spinner while an agent is running,
/// otherwise the aggregate PR-status badge (with a count of open PRs) when the
/// conversation is linked to one or more PRs, and a pencil glyph as the default
/// for a channel with no PR yet. The PR state hydrates from cache after the
/// first paint, so the row renders instantly and never blocks.
class _ChannelLeading extends ConsumerWidget {
  const _ChannelLeading({required this.channelId, required this.running});

  final String channelId;
  final bool running;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (running) {
      return const CcSpinner(size: 18);
    }
    final prs = ref.watch(channelPrsProvider(channelId));
    final status = PrSidebarStatus.aggregate(prs);
    if (status == null) {
      // No PR linked yet — a fresh conversation in the editing stage.
      return const Icon(AppIcons.pencil, size: 18);
    }
    final openCount = prs.where((pr) => pr.isOpen).length;
    final badge = PrStatusBadge(status: status);
    if (openCount < 1) {
      return badge;
    }
    // The badge already conveys the (aggregate) state; the count tells the user
    // how many PRs are open across the channel's repo(s).
    return _PrCountAdornment(count: openCount, child: badge);
  }
}

/// Overlays a small numeric badge on the top-right of [child] — the count of a
/// channel's open PRs. A number (not colour) is the differentiator, per
/// DESIGN.md's never-status-by-colour-alone rule.
class _PrCountAdornment extends StatelessWidget {
  const _PrCountAdornment({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -6,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 14),
            decoration: BoxDecoration(
              color: t.accent,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(
              count > 9 ? '9+' : '$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w600,
                color: t.accentOn,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
