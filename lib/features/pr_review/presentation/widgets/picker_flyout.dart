import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared chrome for the reviewer/assignee picker flyouts: a dismiss barrier, a
/// panel anchored under the section header (via [link]), a title, a search
/// field and a scrollable [list] area. There is no save button — closing the
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
                              AppIcons.search,
                              size: 15,
                              color: t.fgQuaternary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CcTextField(
                                controller: searchController,
                                focusNode: searchFocus,
                                textStyle: TextStyle(
                                  fontSize: 13.5,
                                  color: t.textPrimary,
                                ),
                                onChanged: onQueryChanged,
                                hintText: hintText,
                                chromeless: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 1, color: t.borderSecondary),
                      Flexible(child: CcFadeEdges(child: list)),
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
              AppIcons.check,
              size: 16,
              color: dimmed ? t.fgQuaternary : t.fgBrandPrimary,
            )
          : null,
    );
  }
}

/// A presentational square checkbox for picker rows. Unlike an interactive
/// [CcCheckbox], the enclosing row owns the tap — this only *reflects* state:
/// a filled accent box with a check when [selected], an empty bordered box when
/// [hovered] (so the checkbox affordance appears on hover), a dimmed checked box
/// when [locked] (a code-owner that can't be unchecked) and an empty
/// fixed-width slot otherwise so avatars stay column-aligned across rows.
class PickerCheckBox extends StatelessWidget {
  /// Creates a [PickerCheckBox].
  const PickerCheckBox({
    super.key,
    required this.selected,
    this.hovered = false,
    this.locked = false,
  });

  /// Whether the row is selected.
  final bool selected;

  /// Whether the row is hovered (reveals the empty checkbox affordance).
  final bool hovered;

  /// Whether the row is locked (required code-owner) — shows a dimmed check.
  final bool locked;

  static const double _size = 18;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final checked = selected || locked;
    if (!checked && !hovered) {
      return const SizedBox(width: _size, height: _size);
    }
    final Color fill;
    final Color border;
    if (checked) {
      fill = locked ? t.bgDisabled : t.accent;
      border = fill;
    } else {
      fill = t.surface;
      border = t.borderPrimary;
    }
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: border),
      ),
      child: checked
          ? Icon(
              AppIcons.check,
              size: 13,
              color: locked ? t.fgQuaternary : t.fgWhite,
            )
          : null,
    );
  }
}

/// A muted section label used to group picker rows (e.g. "Teams",
/// "Suggested reviewers").
class PickerGroupHeader extends StatelessWidget {
  /// Creates a [PickerGroupHeader].
  const PickerGroupHeader({super.key, required this.label});

  /// The group label.
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: t.textTertiary,
        ),
      ),
    );
  }
}

/// A compact `+` add affordance used as a picker trigger inside a section
/// header's trailing slot (e.g. the PR-detail Overview sidebar reviewer /
/// assignee sections). The tap is claimed here so it never toggles the
/// enclosing collapsible section (`CollapsibleSidebarSection`).
class CompactPickerAddButton extends StatelessWidget {
  /// Creates a [CompactPickerAddButton].
  const CompactPickerAddButton({
    super.key,
    required this.semanticLabel,
    required this.onPressed,
  });

  /// Accessible label describing the add action.
  final String semanticLabel;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      borderRadius: AppRadii.brSm,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: hovered ? t.hover : t.hover.withValues(alpha: 0),
            borderRadius: AppRadii.brSm,
          ),
          child: Icon(
            AppIcons.plus,
            size: 14,
            color: hovered ? t.fgSecondary : t.textTertiary,
          ),
        );
      },
    );
  }
}

/// The section header used as a reviewer/assignee picker trigger: a leading
/// icon, a label and (when [interactive]) a trailing chevron.
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
            style: CcTypography.caption.copyWith(
              color: muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (interactive) ...[
            const Spacer(),
            Icon(AppIcons.chevronDown, size: 14, color: muted),
          ],
        ],
      ),
    );
  }
}
