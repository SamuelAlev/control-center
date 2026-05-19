import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A collapsible region whose header says what is inside it.
///
/// This is the load-bearing piece of the settings redesign. A settings page
/// gets long for one of two reasons: it has many things (providers, runners,
/// servers) or each thing has many knobs (sampling parameters, capability
/// matrices, environment variables). Rendering all of it at once is what turned
/// three pages into walls. Hiding it behind a bare chevron is the other failure:
/// the reader cannot tell whether opening it is worth the click, and cannot see
/// that a value inside was changed.
///
/// So the header carries three things:
///
/// - the **title**, naming what is inside;
/// - a **summary**, a short right-aligned fact about the contents ("4 variables",
///   "not configured", "gpt-4o, o3, o3-mini") so the collapsed state still
///   reports;
/// - a **modified badge**, shown when the values inside are not the defaults.
///   Without it, collapsing would hide the fact that this install is running an
///   override, which is the one thing a collapsed section must never do.
class SettingsDisclosure extends StatefulWidget {
  /// Creates a [SettingsDisclosure].
  const SettingsDisclosure({
    super.key,
    required this.title,
    required this.child,
    this.summary,
    this.icon,
    this.badge,
    this.initiallyExpanded = false,
    this.expanded,
    this.onExpandedChanged,
    this.dense = false,
    this.childPadding = const EdgeInsets.only(
      top: AppSpacing.md,
      left: AppSpacing.xl,
    ),
  });

  /// What is inside. Sentence case.
  final String title;

  /// The revealed content.
  final Widget child;

  /// A short fact about the contents, shown while collapsed. Keep it to a
  /// handful of words: it is read at a glance, not studied.
  final String? summary;

  /// Optional leading glyph.
  final IconData? icon;

  /// Shown beside the title in both states — use it for "modified" / "override"
  /// so a collapsed section cannot hide a changed value.
  final Widget? badge;

  /// Initial state when [expanded] is not supplied.
  final bool initiallyExpanded;

  /// Drives the state from the parent. When null the disclosure owns it.
  final bool? expanded;

  /// Fired with the new state on every toggle.
  final ValueChanged<bool>? onExpandedChanged;

  /// Tightens the header for use inside an already-indented row.
  final bool dense;

  /// Padding around the revealed child. The default indents it under the
  /// chevron so the hierarchy is visible without a border.
  final EdgeInsetsGeometry childPadding;

  @override
  State<SettingsDisclosure> createState() => _SettingsDisclosureState();
}

class _SettingsDisclosureState extends State<SettingsDisclosure> {
  late bool _expanded = widget.initiallyExpanded;

  bool get _isExpanded => widget.expanded ?? _expanded;

  void _toggle() {
    final next = !_isExpanded;
    if (widget.expanded == null) {
      setState(() => _expanded = next);
    }
    widget.onExpandedChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final expanded = _isExpanded;
    final reducedMotion =
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
        (context.ccTheme?.reducedMotion ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CcTappable(
          onPressed: _toggle,
          semanticLabel: widget.title,
          builder: (context, states) {
            final hovered = states.contains(WidgetState.hovered);
            return AnimatedContainer(
              duration: CcMotion.fast,
              color: hovered ? tokens.hover : const Color(0x00000000),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: widget.dense ? AppSpacing.xs : AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // The chevron rotates rather than swapping glyphs: the
                  // rotation is the state change, so there is nothing to
                  // recognise between two similar icons.
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: reducedMotion ? Duration.zero : CcMotion.fast,
                    curve: CcMotion.standard,
                    child: Icon(
                      AppIcons.chevronRight,
                      size: 16,
                      color: tokens.fgTertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 15, color: tokens.fgTertiary),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      widget.title,
                      style: CcTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.badge != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    widget.badge!,
                  ],
                  const Spacer(),
                  if (widget.summary != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        widget.summary!,
                        style: CcTypography.caption.copyWith(
                          color: tokens.textTertiary,
                        ),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        // AnimatedSize only over the reveal, and only when motion is allowed —
        // a settings page that grows by 400px under a cursor is disorienting,
        // and a page that animates when the user asked it not to is a bug.
        if (reducedMotion)
          if (expanded)
            Padding(padding: widget.childPadding, child: widget.child)
          else
            const SizedBox.shrink()
        else
          AnimatedSize(
            duration: CcMotion.normal,
            curve: CcMotion.standard,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(padding: widget.childPadding, child: widget.child)
                : const SizedBox(width: double.infinity, height: 0),
          ),
      ],
    );
  }
}

/// The "this is not the default" badge for a [SettingsDisclosure] header.
///
/// Small, ink-on-accent-soft, and it carries the word as well as the tint — a
/// coloured pill alone would be status by colour, which this product does not
/// ship.
class SettingsModifiedBadge extends StatelessWidget {
  /// Creates a [SettingsModifiedBadge].
  const SettingsModifiedBadge({super.key, required this.label});

  /// The word, e.g. "Overridden" or "3 changed".
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.accentSoft,
        borderRadius: AppRadii.brSm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.slidersHorizontal, size: 11, color: tokens.accent),
            const SizedBox(width: 3),
            Text(
              label,
              style: CcTypography.caption.copyWith(
                color: tokens.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
