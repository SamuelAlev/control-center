import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// One repeating thing in a settings list: a model provider, a detected runner,
/// an MCP server, a rig image.
///
/// These lists are where settings pages go wrong at scale. The old shape
/// rendered every item fully expanded — API-key field, sampling panel, capability
/// matrix, environment editor — so eighteen providers meant eighteen forms
/// stacked vertically and the reader could not answer "which of these am I
/// actually using?" without scrolling past all of them.
///
/// The fix is a fixed collapsed anatomy that answers exactly that question:
///
/// ```
/// [◆]  Anthropic          Connected            [•]  2 models   ▸
///      sam@example.com                              allow
/// ```
///
/// - a **status marker** (tinted glyph, never colour alone — the [statusLabel]
///   is required whenever a [tone] is given);
/// - the **name**, and directly under it the one line that identifies THIS
///   install of it (the account, the version, the path);
/// - **meta** — small facts that decide whether to open it;
/// - **trailing** — the one control you might use without opening it (an
///   allow switch, a connect button);
/// - a **chevron**, only when there is detail to see.
///
/// Everything else lives in [detail] and is not built until the row is opened.
class SettingsEntityRow extends StatelessWidget {
  /// Creates a [SettingsEntityRow].
  const SettingsEntityRow({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.icon,
    this.tone,
    this.statusLabel,
    this.meta = const [],
    this.trailing,
    this.detail,
    this.expanded = false,
    this.onExpandedChanged,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
  });

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

  /// Drives the marker colour and the status tag.
  final CcStatusTone? tone;

  /// The status in words. Required alongside [tone]: this product never ships
  /// status by colour alone.
  final String? statusLabel;

  /// Small facts that help decide whether to open the row.
  final List<Widget> meta;

  /// The one control usable without opening the row.
  final Widget? trailing;

  /// Everything else. Built only while [expanded].
  final Widget? detail;

  /// Whether [detail] is showing.
  final bool expanded;

  /// Fired when the header is activated. Null (with a non-null [detail]) leaves
  /// the row permanently open.
  final ValueChanged<bool>? onExpandedChanged;

  /// Insets around the header.
  final EdgeInsetsGeometry padding;

  bool get _expandable => detail != null && onExpandedChanged != null;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final reducedMotion =
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
        (context.ccTheme?.reducedMotion ?? false);

    final header = CcTappable(
      onPressed: _expandable ? () => onExpandedChanged!(!expanded) : null,
      semanticLabel: title,
      semanticButton: _expandable,
      canRequestFocus: _expandable,
      showFocusRing: _expandable,
      mouseCursor: _expandable
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered) && _expandable;
        return AnimatedContainer(
          duration: CcMotion.fast,
          color: hovered ? tokens.hover : const Color(0x00000000),
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StatusMarker(icon: icon, tone: tone),
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
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                trailing!,
              ],
              if (_expandable) ...[
                const SizedBox(width: AppSpacing.sm),
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
              ],
            ],
          ),
        );
      },
    );

    if (detail == null) {
      return header;
    }

    final open = onExpandedChanged == null || expanded;
    final body = open
        ? Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg + 28 + AppSpacing.md,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: detail,
          )
        : const SizedBox(width: double.infinity, height: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        if (reducedMotion)
          body
        else
          AnimatedSize(
            duration: CcMotion.normal,
            curve: CcMotion.standard,
            alignment: Alignment.topCenter,
            child: body,
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
      CcStatusTone.neutral || null => (t.fgTertiary, t.bgSecondary),
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
