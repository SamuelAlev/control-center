import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/focus_mode/presentation/widgets/focus_config_dialog.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/shell/presentation/widgets/notification_bell.dart';
import 'package:control_center/features/shell/presentation/widgets/title_bar_breadcrumb.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/window_drag_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The slim 40px top bar: back/forward navigation, the route breadcrumb, the
/// command-palette search field, notifications, and the focus-mode control.
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
    return WindowDragArea(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.topbar,
          border: Border(bottom: BorderSide(color: t.borderPrimary)),
        ),
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
                      : const _StartFocusButton(),
                ),
              ],
            ),
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

/// Stops `WindowDragArea` from swallowing pointer events on interactive
/// children, so the workspace chip and breadcrumb stay clickable.
class _NoDrag extends StatelessWidget {
  const _NoDrag({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // `WindowDragArea` listens via a [Listener] at its top — wrapping the
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CcTooltip(
          followerAnchor: Alignment.topCenter,
          targetAnchor: Alignment.bottomCenter,
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

class _StartFocusButton extends StatefulWidget {
  const _StartFocusButton();

  @override
  State<_StartFocusButton> createState() => _StartFocusButtonState();
}

class _StartFocusButtonState extends State<_StartFocusButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final bg = _hover ? tokens.bgSecondaryHover : tokens.bgSecondary;
    // Secondary-button recipe: hairline border that strengthens on hover,
    // muted label/icon.
    final border = _hover ? tokens.lineStrong : tokens.borderPrimary;
    final fg = tokens.muted;
    return CcTooltip(
      followerAnchor: Alignment.topCenter,
      targetAnchor: Alignment.bottomCenter,
      message: l10n.focusModeStart,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () => showCcDialog<void>(
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
                  AppIcons.focus,
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
