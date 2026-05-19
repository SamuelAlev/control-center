import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/focus_mode/presentation/widgets/focus_config_dialog.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/shell/presentation/widgets/notification_bell.dart';
import 'package:control_center/features/shell/presentation/widgets/title_bar_breadcrumb.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

/// The slim 40px top bar: back/forward navigation, the route breadcrumb, the
/// command-palette search field, notifications, and the focus-mode control.
class ShellTitleBar extends ConsumerWidget {
  /// Creates a [ShellTitleBar].
  const ShellTitleBar({
    super.key,
    required this.colors,
    this.canGoBack = false,
    this.canGoForward = false,
    this.onGoBack,
    this.onGoForward,
  });

  /// The active ForUI color set, passed down from the shell layout.
  final FColors colors;

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
    return DragToMoveArea(
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              _buildNavButtons(context),
              const SizedBox(width: AppSpacing.sm),
              // Interactive: opt out of window drag so clicks register on the
              // crumbs instead of moving the window.
              const Expanded(child: _NoDrag(child: TitleBarBreadcrumb())),
              const SizedBox(width: AppSpacing.sm),
              const _NoDrag(child: NotificationBell()),
              const SizedBox(width: AppSpacing.xs),
              _NoDrag(
                child: focusMode.active
                    ? _FocusModeChip(
                        minutesRemaining: focusMode.minutesRemaining,
                        onDeactivate: () =>
                            ref.read(focusModeProvider.notifier).deactivate(),
                        onFloat: () => ref
                            .read(focusModeProvider.notifier)
                            .enterCompactMode(),
                      )
                    : _StartFocusButton(colors: colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavButton(
          icon: LucideIcons.chevronLeft,
          tooltip: l10n.goBack,
          onPressed: canGoBack ? onGoBack : null,
          color: colors.mutedForeground,
        ),
        _NavButton(
          icon: LucideIcons.chevronRight,
          tooltip: l10n.goForward,
          onPressed: canGoForward ? onGoForward : null,
          color: colors.mutedForeground,
        ),
      ],
    );
  }
}

/// Stops `DragToMoveArea` from swallowing pointer events on interactive
/// children, so the workspace chip and breadcrumb stay clickable.
class _NoDrag extends StatelessWidget {
  const _NoDrag({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // `DragToMoveArea` listens via a [Listener] at its top — wrapping the
    // child in a [GestureDetector] that opaquely absorbs hit-tests prevents
    // the drag from starting on the interactive area below.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) {},
      child: child,
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
    final accent = tokens?.accent ?? const Color(0xFFFA520F);
    final accentSoft = tokens?.accentSoft ?? const Color(0x1FFA520F);
    final muted = tokens?.muted ?? const Color(0xFF3D3D3D);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FTooltip(
          tipAnchor: Alignment.topCenter,
          childAnchor: Alignment.bottomCenter,
          tipBuilder: (_, _) => Text(l10n.focusModeActiveTooltip),
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
                    Icon(LucideIcons.focus, size: 12, color: accent),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${minutesRemaining}m',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        FTooltip(
          tipAnchor: Alignment.topCenter,
          childAnchor: Alignment.bottomCenter,
          tipBuilder: (_, _) => Text(l10n.focusModeFloat),
          child: FButton.icon(
            variant: FButtonVariant.ghost,
            size: FButtonSizeVariant.sm,
            onPress: onFloat,
            child: Icon(
              LucideIcons.pictureInPicture2,
              size: 13,
              color: muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _StartFocusButton extends StatefulWidget {
  const _StartFocusButton({required this.colors});

  final FColors colors;

  @override
  State<_StartFocusButton> createState() => _StartFocusButtonState();
}

class _StartFocusButtonState extends State<_StartFocusButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = widget.colors;
    final tokens = context.designSystem;
    final bg = _hover
        ? (tokens?.bgSecondaryHover ?? colors.muted)
        : (tokens?.bgSecondary ?? colors.secondary);
    // Secondary-button recipe: hairline border that strengthens on hover,
    // muted label/icon. Tokens first, ForUI colors as the fallback.
    final border = _hover
        ? (tokens?.lineStrong ?? colors.border)
        : (tokens?.borderPrimary ?? colors.border);
    final fg = tokens?.muted ?? colors.mutedForeground;
    return FTooltip(
      tipAnchor: Alignment.topCenter,
      childAnchor: Alignment.bottomCenter,
      tipBuilder: (_, _) => Text(l10n.focusModeStart),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => const FocusConfigDialog(),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadii.brSm,
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.focus,
                  size: 11,
                  color: fg,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.focusModeStart,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final effectiveColor = onPressed == null
        ? (tokens?.fgDisabled ?? color.withValues(alpha: 0.4))
        : color;
    return FTooltip(
      tipAnchor: Alignment.topCenter,
      childAnchor: Alignment.bottomCenter,
      tipBuilder: (_, _) => Text(tooltip),
      child: FButton.icon(
        variant: FButtonVariant.ghost,
        size: FButtonSizeVariant.sm,
        onPress: onPressed,
        child: Icon(icon, size: 16, color: effectiveColor),
      ),
    );
  }
}
