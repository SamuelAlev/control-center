import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shared chrome for the reviewer/assignee picker flyouts: a dismiss barrier, a
/// panel anchored under the section header (via [link]), a title, a search
/// field, and a scrollable [list] area. There is no save button — closing the
/// flyout (barrier tap or Esc) calls [onClose], where the caller applies the
/// diff.
class PickerFlyoutPanel extends StatelessWidget {
  /// Creates a [PickerFlyoutPanel].
  const PickerFlyoutPanel({
    super.key,
    required this.link,
    required this.title,
    required this.searchController,
    required this.searchFocus,
    required this.hintText,
    required this.onQueryChanged,
    required this.onClose,
    required this.list,
  });

  /// Link to the section header this flyout anchors to.
  final LayerLink link;

  /// Panel title.
  final String title;

  /// Search field controller.
  final TextEditingController searchController;

  /// Search field focus node (autofocused on open).
  final FocusNode searchFocus;

  /// Search field placeholder.
  final String hintText;

  /// Called as the user types.
  final ValueChanged<String> onQueryChanged;

  /// Called when the flyout should close (barrier tap / Esc) — apply here.
  final VoidCallback onClose;

  /// The scrollable candidate list.
  final Widget list;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onClose,
          ),
        ),
        CompositedTransformFollower(
          link: link,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 6),
          child: Align(
            alignment: Alignment.topRight,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): onClose,
              },
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  width: 300,
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    color: t.bgPrimary,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: t.borderSecondary),
                    boxShadow: AppShadows.golden,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: t.textPrimary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.search,
                              size: 15,
                              color: t.fgQuaternary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                focusNode: searchFocus,
                                cursorColor: t.fgBrandPrimary,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: t.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  isCollapsed: true,
                                  // Borderless inline search — suppress the
                                  // themed focused border so focus doesn't draw
                                  // a stray outline or shift the row layout.
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintText: hintText,
                                  hintStyle: TextStyle(
                                    color: t.textPlaceholder,
                                  ),
                                ),
                                onChanged: onQueryChanged,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 1, color: t.borderSecondary),
                      Flexible(child: list),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Leading selection indicator for a picker row — a brand-coloured check when
/// selected, an empty fixed-width slot otherwise (so rows stay aligned).
class PickerCheck extends StatelessWidget {
  /// Creates a [PickerCheck].
  const PickerCheck({super.key, required this.selected, this.dimmed = false});

  /// Whether the row is selected.
  final bool selected;

  /// Whether to dim the check (e.g. a locked code-owner row).
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return SizedBox(
      width: 18,
      child: selected
          ? Icon(
              LucideIcons.check,
              size: 16,
              color: dimmed ? t.fgQuaternary : t.fgBrandPrimary,
            )
          : null,
    );
  }
}

/// The clickable section header that triggers a picker flyout. Matches the
/// other sidebar section headers; shows a chevron when [interactive].
class PickerSectionHeader extends StatelessWidget {
  /// Creates a [PickerSectionHeader].
  const PickerSectionHeader({
    super.key,
    required this.icon,
    required this.label,
    required this.interactive,
  });

  /// Leading section icon.
  final IconData icon;

  /// Section label.
  final String label;

  /// Whether the header is a picker trigger (shows the chevron).
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final muted =
        (context.designSystem ?? DesignSystemTokens.light()).textTertiary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: muted),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (interactive) ...[
            const Spacer(),
            Icon(LucideIcons.chevronDown, size: 14, color: muted),
          ],
        ],
      ),
    );
  }
}
