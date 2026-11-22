import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The command strip's row: an icon, what the command reads as (wrapping
/// when the composer is narrow), an optional control at the end, and the
/// hairline that sets it apart from the field below.
class CommandStripFrame extends StatelessWidget {
  /// Creates the row.
  const CommandStripFrame({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.children,
    this.trailing,
  });

  /// What kind of command, or a warning.
  final IconData icon;

  /// The icon's color.
  final Color iconColor;

  /// The reading, in order.
  final List<Widget> children;

  /// A control at the end of the row.
  final Widget? trailing;

  /// The row's height, which a control at its end must not change.
  static const double rowHeight = 24;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: rowHeight),
            child: Row(
              children: [
                // The field's text starts 4px in; the icon lines up with it.
                const SizedBox(width: AppSpacing.xs),
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: children,
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const CcDivider(),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// A piece of command text that writes itself into the draft when pressed.
class CommandStripToken extends StatelessWidget {
  /// Creates the token.
  const CommandStripToken(this.token, {super.key, required this.onPressed});

  /// The command text, shown as it is written.
  final String token;

  /// Writes it.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return CcTappable(
      onPressed: onPressed,
      semanticLabel: token,
      // The field keeps the focus: the same choices are in its suggestion
      // list for the keyboard.
      canRequestFocus: false,
      builder: (context, states) => ColoredBox(
        color: states.contains(WidgetState.pressed)
            ? ds.hoverStrong
            : states.contains(WidgetState.hovered)
            ? ds.hover
            : ds.bgTertiary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          // RTL carve-out: command text reads left to right.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              token,
              style: CcFonts.code(
                textStyle: CcTypography.caption.copyWith(
                  color: ds.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The limits a `/loop` or `/schedule` may still take, behind one quiet
/// control at the end of the strip. Picking one writes its option.
class CommandLimitsMenu extends StatefulWidget {
  /// Creates the menu for [options] (`--max`, `--days`, `--budget`).
  const CommandLimitsMenu({
    super.key,
    required this.options,
    required this.onSelected,
  });

  /// The options not written yet.
  final List<String> options;

  /// Called with the option picked.
  final ValueChanged<String> onSelected;

  @override
  State<CommandLimitsMenu> createState() => _CommandLimitsMenuState();
}

class _CommandLimitsMenuState extends State<CommandLimitsMenu> {
  final CcOverlayController _menu = CcOverlayController();

  @override
  void initState() {
    super.initState();
    // The control stays washed while its menu is open.
    _menu.addListener(_onMenu);
  }

  @override
  void dispose() {
    _menu
      ..removeListener(_onMenu)
      ..dispose();
    super.dispose();
  }

  void _onMenu() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    return CcMenu(
      controller: _menu,
      toggleOnTargetTap: false,
      semanticLabel: l10n.scheduleLimits,
      targetAnchor: AlignmentDirectional.topEnd,
      followerAnchor: AlignmentDirectional.bottomEnd,
      offset: const Offset(0, -4),
      items: [
        for (final option in widget.options)
          CcMenuItem(
            label: switch (option) {
              '--max' => l10n.scheduleMaxRuns,
              '--days' => l10n.scheduleExpiresInDays,
              _ => l10n.scheduleCostCap,
            },
            trailing: option,
            onSelected: () => widget.onSelected(option),
          ),
      ],
      target: CcTooltip(
        message: l10n.scheduleLimits,
        child: CcTappable(
          onPressed: _menu.toggle,
          semanticLabel: l10n.scheduleLimits,
          canRequestFocus: false,
          builder: (context, states) => ColoredBox(
            color: states.contains(WidgetState.pressed)
                ? ds.hoverStrong
                : states.contains(WidgetState.hovered) || _menu.isOpen
                ? ds.hover
                : const Color(0x00000000),
            child: SizedBox.square(
              dimension: CommandStripFrame.rowHeight,
              child: Icon(
                AppIcons.slidersHorizontal,
                size: 14,
                color: ds.fgSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
