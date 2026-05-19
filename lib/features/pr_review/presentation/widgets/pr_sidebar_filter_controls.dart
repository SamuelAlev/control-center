import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The small disclosure row shown under a sidebar text field that toggles an
/// auxiliary filter surface (the content search's include/exclude globs, the
/// file tree's status chips). One shared design so both sidebar modes read
/// identically.
class PrSidebarFilterToggle extends StatelessWidget {
  /// Creates a [PrSidebarFilterToggle].
  const PrSidebarFilterToggle({
    super.key,
    required this.label,
    required this.active,
    required this.onToggle,
  });

  /// The row's label (e.g. "Search filters").
  final String label;

  /// Highlights the row — the surface is expanded, or a hidden filter is
  /// still applied.
  final bool active;

  /// Toggles the filter surface.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.slidersHorizontal,
                  size: 13,
                  color: active ? tokens.fg : tokens.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: active ? tokens.fg : tokens.textTertiary,
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

/// A clear (×) affordance for a sidebar text field's suffix. Renders nothing
/// while the field is empty; clearing empties the controller and notifies
/// [onCleared] so the host can reset its debounced query.
class PrFieldClearButton extends StatelessWidget {
  /// Creates a [PrFieldClearButton].
  const PrFieldClearButton({
    super.key,
    required this.controller,
    required this.onCleared,
  });

  /// The field's controller — listened to so the button tracks emptiness.
  final TextEditingController controller;

  /// Invoked after the controller is cleared.
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.text.isEmpty) {
          return const SizedBox.shrink();
        }
        return CcTooltip(
          message: l10n.clear,
          showDelay: const Duration(milliseconds: 400),
          child: CcTappable(
            onPressed: () {
              controller.clear();
              onCleared();
            },
            mouseCursor: SystemMouseCursors.click,
            builder: (context, states) => SizedBox(
              width: 20,
              height: 20,
              child: Icon(
                AppIcons.x,
                size: 13,
                color: states.contains(WidgetState.hovered)
                    ? tokens.textPrimary
                    : tokens.textTertiary,
              ),
            ),
          ),
        );
      },
    );
  }
}
