import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_hover_reveal.dart';
import 'package:flutter/widgets.dart';

/// Collapsed settings list row (provider, runner, MCP server, rig image).
///
/// Anatomy: status marker ([statusLabel] required with [tone]), name + identity
/// line, meta, optional trailing control. Detail builds only when opened.
///
/// A row that opens says so with its hover wash and cursor, not a chevron: one
/// at the row's end sits beside the trailing actions, where it is a misclick
/// away from a delete.
class SettingsEntityRow extends StatelessWidget {
  /// Creates a [SettingsEntityRow].
  const SettingsEntityRow({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.icon,
    this.leading,
    this.tone,
    this.statusLabel,
    this.meta = const [],
    this.trailing,
    this.hoverTrailing,
    this.detail,
    this.expanded = false,
    this.onExpandedChanged,
    this.onPressed,
    this.revealTrailing = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    this.detailPadding = const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.lg + 28 + AppSpacing.md,
      0,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
  }) : assert(
         onPressed == null || detail == null,
         'A row either opens elsewhere or expands in place',
       );

  /// The thing's display name.
  final String title;

  /// The one line identifying this install of it. Prefer a fact (an account, a
  /// version, a path) over a description — the description is the same for
  /// everyone and tells the reader nothing about their machine.
  final String? subtitle;

  /// Replaces [subtitle] when the line needs more than text (e.g. a mono path
  /// beside a version).
  final Widget? subtitleWidget;

  /// Optional glyph for the status marker. Defaults to a dot.
  final IconData? icon;

  /// Replaces the status marker, for a row whose opening glyph has more to say
  /// than a tone. Keep it the marker's 28px, so [detailPadding] still lines up.
  final Widget? leading;

  /// Drives the marker colour and the status tag.
  final CcStatusTone? tone;

  /// The status in words. Required alongside [tone]: this product never ships
  /// status by colour alone.
  final String? statusLabel;

  /// Small facts that help decide whether to open the row.
  final List<Widget> meta;

  /// The one control usable without opening the row.
  final Widget? trailing;

  /// An action held out of sight until the row is hovered or focused, sitting
  /// before a [trailing] that stays visible. For a row that shows state in
  /// [trailing]; use [revealTrailing] when nothing needs to stay in view.
  final Widget? hoverTrailing;

  /// Everything else. Built only while [expanded].
  final Widget? detail;

  /// Whether [detail] is showing.
  final bool expanded;

  /// Fired when the header is activated. Null (with a non-null [detail]) leaves
  /// the row permanently open.
  final ValueChanged<bool>? onExpandedChanged;

  /// Makes the whole row a link to somewhere else.
  final VoidCallback? onPressed;

  /// Keeps [trailing] out of sight until the row is hovered or focused.
  final bool revealTrailing;

  /// Insets around the header.
  final EdgeInsetsGeometry padding;

  /// Insets around [detail]. The default sits under the title.
  final EdgeInsetsGeometry detailPadding;

  bool get _expandable => detail != null && onExpandedChanged != null;

  bool get _interactive => _expandable || onPressed != null;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    final header = CcTappable(
      onPressed: _expandable ? () => onExpandedChanged!(!expanded) : onPressed,
      semanticLabel: title,
      semanticButton: _interactive,
      canRequestFocus: _interactive,
      showFocusRing: _interactive,
      mouseCursor: _interactive
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered) && _interactive;
        return AnimatedContainer(
          duration: CcMotion.fast,
          color: hovered ? tokens.hover : const Color(0x00000000),
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leading ?? _StatusMarker(icon: icon, tone: tone),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: CcTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (statusLabel != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          CcStatusTag(
                            label: statusLabel!,
                            tone: tone ?? CcStatusTone.neutral,
                          ),
                        ],
                      ],
                    ),
                    if (subtitleWidget != null) ...[
                      const SizedBox(height: 3),
                      DefaultTextStyle.merge(
                        style: CcTypography.caption.copyWith(
                          color: tokens.textTertiary,
                        ),
                        child: subtitleWidget!,
                      ),
                    ] else if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: CcTypography.caption.copyWith(
                          color: tokens.textTertiary,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: meta,
                      ),
                    ],
                  ],
                ),
              ),
              if (hoverTrailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                SettingsHoverReveal(
                  active:
                      states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.focused),
                  child: hoverTrailing!,
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                if (revealTrailing)
                  SettingsHoverReveal(
                    active:
                        states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused),
                    child: trailing!,
                  )
                else
                  trailing!,
              ],
            ],
          ),
        );
      },
    );

    if (detail == null) {
      return header;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        CcCollapsible(
          expanded: onExpandedChanged == null || expanded,
          duration: CcMotion.normal,
          child: Padding(padding: detailPadding, child: detail),
        ),
      ],
    );
  }
}

/// The tinted glyph that opens an entity row.
///
/// 28px, squared like everything else in the system, tinted with the tone's
/// soft fill so a list of rows shows its shape of health in peripheral vision
/// — while the status tag beside the title carries the actual claim in words.
class _StatusMarker extends StatelessWidget {
  const _StatusMarker({required this.icon, required this.tone});

  final IconData? icon;
  final CcStatusTone? tone;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final (fg, bg) = switch (tone) {
      CcStatusTone.positive => (t.success, t.successSoft),
      CcStatusTone.negative => (t.danger, t.dangerSoft),
      CcStatusTone.caution => (t.warn, t.warnSoft),
      CcStatusTone.info => (t.accent, t.accentSoft),
      // Translucent, like the tones above: an opaque fill reads as a hole in
      // the row's hover wash.
      CcStatusTone.neutral || null => (t.fgTertiary, t.hover),
    };
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: bg, borderRadius: AppRadii.brSm),
      child: icon == null
          ? Center(child: CcStatusDot(tone: tone ?? CcStatusTone.neutral))
          : Icon(icon, size: 15, color: fg),
    );
  }
}
