import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A collapsible sidebar section shell: a chevron + leading icon + uppercase
/// eyebrow, an optional right-aligned count badge and a trailing action slot,
/// over an animated body.
///
/// This is the shared shell behind the messaging IDE sidebar's "General" panel
/// sections and the PR-detail Overview sidebar, so both surfaces read as one
/// component vocabulary (chevron + eyebrow + count, panel on `bgSecondary`).
class CollapsibleSidebarSection extends StatefulWidget {
  /// Creates a [CollapsibleSidebarSection].
  const CollapsibleSidebarSection({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.count,
    this.trailing,
    this.initiallyExpanded = true,
  });

  /// Leading section icon rendered next to the eyebrow.
  final IconData icon;

  /// Section label, rendered upper-cased as the eyebrow.
  final String label;

  /// Optional count rendered in a pill at the trailing edge of the header.
  final String? count;

  /// Optional trailing action (e.g. a `+` add affordance). Rendered after the
  /// count badge, beside (not inside) the toggle, so tapping it does not
  /// toggle the section and assistive tech sees two separate controls.
  final Widget? trailing;

  /// The section body, revealed/hidden by the header chevron.
  final Widget child;

  /// Whether the section starts expanded.
  final bool initiallyExpanded;

  @override
  State<CollapsibleSidebarSection> createState() =>
      _CollapsibleSidebarSectionState();
}

class _CollapsibleSidebarSectionState extends State<CollapsibleSidebarSection> {
  late bool _expanded = widget.initiallyExpanded;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final hasTrailing = widget.trailing != null;
    final count = widget.count;
    // The toggle and the trailing action are siblings, not nested: a button
    // inside the toggle's button would be one merged node to a screen reader,
    // and its expanded state has to sit on the node that actually toggles.
    // The hover wash still spans the whole header, as before.
    final toggle = MergeSemantics(
      child: Semantics(
        expanded: _expanded,
        child: CcTappable(
          onPressed: () => setState(() => _expanded = !_expanded),
          semanticLabel: count == null
              ? widget.label
              : '${widget.label}, $count',
          borderRadius: AppRadii.brSm,
          builder: (context, states) => Padding(
            padding: EdgeInsetsDirectional.only(
              start: AppSpacing.sm,
              end: hasTrailing ? 0 : AppSpacing.sm,
              top: 6,
              bottom: 6,
            ),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Icon(
                    _expanded ? AppIcons.chevronDown : AppIcons.chevronRight,
                    size: 14,
                    color: t.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(widget.icon, size: 14, color: t.textTertiary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      widget.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: t.textTertiary,
                      ),
                    ),
                  ),
                  if (count != null) SidebarSectionCountBadge(label: count),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _hovered ? t.hover : t.hover.withValues(alpha: 0),
              borderRadius: AppRadii.brSm,
            ),
            child: Row(
              children: [
                Expanded(child: toggle),
                if (hasTrailing)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: AppSpacing.xs,
                      end: AppSpacing.sm,
                    ),
                    child: widget.trailing,
                  ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? widget.child
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// The small count pill rendered at the trailing edge of a
/// [CollapsibleSidebarSection] header.
class SidebarSectionCountBadge extends StatelessWidget {
  /// Creates a [SidebarSectionCountBadge].
  const SidebarSectionCountBadge({super.key, required this.label});

  /// The (already formatted) count text.
  final String label;

  @override
  Widget build(BuildContext context) {
    return CcBadge(label: label);
  }
}

/// The muted "nothing here yet" line a [CollapsibleSidebarSection] shows in
/// place of its rows.
class SidebarEmptyRow extends StatelessWidget {
  /// Creates a [SidebarEmptyRow].
  const SidebarEmptyRow({super.key, required this.message});

  /// The empty-state message.
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 12, color: t.textTertiary),
      ),
    );
  }
}
