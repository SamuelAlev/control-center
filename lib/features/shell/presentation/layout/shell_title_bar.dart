import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/demo/presentation/widgets/demo_badge.dart';
import 'package:control_center/features/focus_mode/presentation/widgets/focus_config_dialog.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/presence/presentation/widgets/workspace_presence_rail.dart';
import 'package:control_center/features/shell/presentation/widgets/notification_bell.dart';
import 'package:control_center/features/shell/presentation/widgets/title_bar_breadcrumb.dart';
import 'package:control_center/features/shell/providers/sidebar_providers.dart';
import 'package:control_center/features/soundscape/presentation/notifiers/soundscape_mini_player_controller.dart';
import 'package:control_center/features/soundscape/presentation/screens/soundscape_panel.dart';
import 'package:control_center/features/soundscape/providers/soundscape_providers.dart';
import 'package:control_center/features/subscriptions/presentation/widgets/subscription_usage_pill.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/window_drag_area.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The slim 40px top bar: back/forward navigation, the route breadcrumb, the
/// command-palette search field, notifications and the focus-mode control.
///
/// The bar spans the FULL window width (the sidebar starts below it, so no
/// sidebar border runs up beside it) and the global-sidebar rail toggle
/// lives here, left of the back/forward buttons. On macOS the window uses a
/// hidden native title bar, so the bar's content keeps a left reserve clear
/// of the traffic-light cluster.
class ShellTitleBar extends ConsumerWidget {
  /// Creates a [ShellTitleBar].
  const ShellTitleBar({
    super.key,
    this.canGoBack = false,
    this.canGoForward = false,
    this.onGoBack,
    this.onGoForward,
  });

  /// Whether backward navigation is currently available.
  final bool canGoBack;

  /// Whether forward navigation is currently available.
  final bool canGoForward;

  /// Navigates back in history; null disables the back button.
  final VoidCallback? onGoBack;

  /// Navigates forward in history; null disables the forward button.
  final VoidCallback? onGoForward;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusMode = ref.watch(focusModeProvider);
    final t = context.designSystem ?? DesignSystemTokens.light();
    // macOS traffic-light clearance: the cluster (3 ~14px circles, ~8px
    // gaps, ~12px left inset) ends near x=70; 80 leaves a comfortable gap so
    // the rail toggle never slides under it. macOS only — other platforms
    // have no in-window controls in this corner.
    final hasMacTrafficLights =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    return WindowDragArea(
      enableDoubleClickMaximize: true,
      // The primary window is not system-movable (that is what stops macOS
      // dragging it out from under this bar's buttons), so this bar moves it.
      moveWindowManually: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.topbar,
          border: Border(bottom: BorderSide(color: t.borderPrimary)),
        ),
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: EdgeInsets.only(
              left: hasMacTrafficLights ? 80 : AppSpacing.md,
              right: AppSpacing.md,
            ),
            child: Row(
              children: [
                _buildNavButtons(context, ref),
                const SizedBox(width: AppSpacing.sm),
                // No per-child drag opt-out here: `WindowDragArea` refuses to
                // start a window move on anything that paints a pressable
                // cursor, so the crumbs and the trailing controls stay clickable
                // while the inert gaps between them keep dragging and
                // double-click-to-zoom.
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TitleBarBreadcrumb(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Renders nothing against a real server, so it costs one
                // boolean read on a normal install. Always visible in a demo
                // (and not dismissible): the note and the tour can be waved
                // away, but "none of this data is real" should not be
                // something a visitor can forget half an hour in.
                const DemoBadge(),
                const SizedBox(width: AppSpacing.xs),
                const WorkspacePresenceRail(),
                const SizedBox(width: AppSpacing.xs),
                const SubscriptionUsagePill(),
                const SizedBox(width: AppSpacing.xs),
                const NotificationBell(),
                const SizedBox(width: AppSpacing.xs),
                const _SoundscapeButton(),
                const SizedBox(width: AppSpacing.xs),
                if (focusMode.active)
                  _FocusModeChip(
                    minutesRemaining: focusMode.minutesRemaining,
                    onDeactivate: () =>
                        ref.read(focusModeProvider.notifier).deactivate(),
                    onFloat: () =>
                        ref.read(focusModeProvider.notifier).enterCompactMode(),
                  )
                else
                  const _StartFocusButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButtons(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sidebarCollapsed = ref.watch(sidebarCollapsedProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The global sidebar's rail toggle lives in the title bar (not the
        // sidebar header), immediately left of the history buttons.
        _NavButton(
          icon: sidebarCollapsed
              ? AppIcons.panelLeftOpen
              : AppIcons.panelLeftClose,
          tooltip: sidebarCollapsed ? l10n.expandSidebar : l10n.collapseSidebar,
          onPressed: () => ref.read(sidebarCollapsedProvider.notifier).toggle(),
        ),
        _NavButton(
          icon: AppIcons.chevronLeft,
          tooltip: l10n.goBack,
          onPressed: canGoBack ? onGoBack : null,
        ),
        _NavButton(
          icon: AppIcons.chevronRight,
          tooltip: l10n.goForward,
          onPressed: canGoForward ? onGoForward : null,
        ),
      ],
    );
  }
}

class _FocusModeChip extends StatelessWidget {
  const _FocusModeChip({
    required this.minutesRemaining,
    required this.onDeactivate,
    required this.onFloat,
  });

  final int minutesRemaining;
  final VoidCallback onDeactivate;
  final VoidCallback onFloat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // A live focus session is the operator's single "I'm heads-down" signal, so
    // it carries the brand accent — the status-capsule recipe from DESIGN.md
    // (soft accent fill, accent text, fully-rounded). Accent (never amber):
    // amber/`warn` means *blocked* in this system, which a focus session is not.
    final tokens = context.designSystem;
    final accent = tokens?.accent ?? const Color(0xFFFA500F);
    final accentSoft = tokens?.accentSoft ?? const Color(0x1FFA500F);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CcTooltip(
          message: l10n.focusModeActiveTooltip,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onDeactivate,
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(color: accent.withValues(alpha: 0.30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.focus, size: 12, color: accent),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${minutesRemaining}m',
                      style: CcTypography.caption.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        CcIconButton(
          icon: AppIcons.pictureInPicture2,
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          onPressed: onFloat,
          tooltip: l10n.focusModeFloat,
        ),
      ],
    );
  }
}

class _StartFocusButton extends StatelessWidget {
  const _StartFocusButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcIconButton(
      icon: AppIcons.focus,
      variant: CcButtonVariant.ghost,
      size: CcButtonSize.sm,
      onPressed: () => showCcDialog<void>(
        context: context,
        builder: (_) => const FocusConfigDialog(),
      ),
      tooltip: l10n.focusModeStart,
    );
  }
}

/// Title-bar entry point to the soundscape panel. Reflects playback state with
/// the brand accent when audio is playing (presence-over-decoration: the color
/// reports a real, live thing).
class _SoundscapeButton extends ConsumerWidget {
  const _SoundscapeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playing = ref.watch(soundscapeProvider.select((s) => s.playing));
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CcIconButton(
          icon: playing ? AppIcons.audioLines : AppIcons.volume2,
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          color: playing ? tokens.accent : null,
          onPressed: () => showSoundscapePanel(context),
          tooltip: l10n.soundscapeTitle,
        ),
        if (playing) ...[
          const SizedBox(width: AppSpacing.xs),
          CcIconButton(
            icon: AppIcons.pictureInPicture2,
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: () => ref
                .read(soundscapeMiniPlayerControllerProvider.notifier)
                .open(),
            tooltip: l10n.soundscapePopOut,
          ),
        ],
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CcIconButton(
      icon: icon,
      variant: CcButtonVariant.ghost,
      size: CcButtonSize.sm,
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}
