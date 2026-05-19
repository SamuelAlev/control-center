import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shared primitives for the redesigned dashboard — the panel surface, headers,
/// eyebrows, count chips, link arrows and mono text helper that every section
/// composes. They translate the design-source CSS (`.panel`, `.panel-head`,
/// `.eyebrow`, `.count-mono`, `.link-arrow`) onto `context.designSystem` tokens
/// so the cockpit reads as one warm, architectural surface.

/// Non-null design-system token accessor. The extension is always registered on
/// the active theme (light + dark), so the fallback is defensive only.
DesignSystemTokens dashTokens(BuildContext context) =>
    context.designSystem ?? DesignSystemTokens.light();

/// Mono text style for ids, counts, branch names and metadata — honours the
/// user-selected code font (`codeFontFamilyProvider`).
TextStyle dashMono(
  String family, {
  double size = 12,
  Color? color,
  FontWeight weight = FontWeight.w400,
  double? letterSpacing,
  double height = 1.2,
}) =>
    AppFonts.codeDynamic(
      family,
      textStyle: TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
      ),
    );

/// A mono, uppercase, wide-tracked eyebrow — the quiet region/section cue.
class DashboardEyebrow extends StatelessWidget {
  /// Creates a [DashboardEyebrow].
  const DashboardEyebrow(this.text, {super.key, this.codeFont, this.color});

  /// Eyebrow label.
  final String text;

  /// Optional code-font family; defaults to JetBrains Mono.
  final String? codeFont;

  /// Optional colour override.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    final family = codeFont;
    final style = TextStyle(
      fontSize: 11,
      letterSpacing: 1.1,
      height: 1.2,
      fontWeight: FontWeight.w500,
      color: color ?? ds.muted,
    );
    return Text(
      text.toUpperCase(),
      style: family != null
          ? AppFonts.codeDynamic(family, textStyle: style)
          : AppFonts.code(textStyle: style),
    );
  }
}

/// Bordered, near-zero-radius white data surface — the in-flow `.panel`.
/// Separates with a hairline border, never a shadow (DESIGN.md elevation rule).
class DashboardPanel extends StatelessWidget {
  /// Creates a [DashboardPanel].
  const DashboardPanel({super.key, required this.child});

  /// Panel contents (typically a [DashboardPanelHeader] followed by rows).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ds.panel,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: ds.borderPrimary),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.brLg,
        child: child,
      ),
    );
  }
}

/// The header strip inside a [DashboardPanel] — title, optional mono count and
/// a trailing action, with a hairline bottom border.
class DashboardPanelHeader extends StatelessWidget {
  /// Creates a [DashboardPanelHeader].
  const DashboardPanelHeader({
    super.key,
    required this.title,
    this.count,
    this.trailing,
    this.titleAdornment,
    this.codeFont,
  });

  /// Panel title.
  final String title;

  /// Optional mono count shown next to the title (`.count-mono`).
  final String? count;

  /// Optional trailing widget, flush to the right edge (a link or count).
  final Widget? trailing;

  /// Optional widget shown immediately after the title (e.g. an info icon).
  final Widget? titleAdornment;

  /// Code-font family for the count.
  final String? codeFont;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ds.borderPrimary)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: ds.fg,
                    ),
                  ),
                ),
                if (titleAdornment != null) ...[
                  const SizedBox(width: 6),
                  titleAdornment!,
                ],
                if (count != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    count!,
                    style: dashMono(codeFont ?? '', size: 12, color: ds.muted),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// A section header that sits directly on the page canvas (not inside a panel):
/// a display title, a mono count, and a trailing link — the `.block-head`.
class DashboardSectionHeader extends StatelessWidget {
  /// Creates a [DashboardSectionHeader].
  const DashboardSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.trailing,
    this.codeFont,
  });

  /// Section title.
  final String title;

  /// Optional mono count next to the title.
  final String? count;

  /// Optional trailing widget (link arrow).
  final Widget? trailing;

  /// Code-font family for the count.
  final String? codeFont;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              height: 1.1,
              letterSpacing: -0.2,
              fontWeight: FontWeight.w500,
              color: ds.fg,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.md),
            Text(
              count!,
              style: dashMono(codeFont ?? '', size: 13, color: ds.muted),
            ),
          ],
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// A quiet "label →" link that warms to the accent on hover (`.link-arrow`).
class DashboardLinkArrow extends StatefulWidget {
  /// Creates a [DashboardLinkArrow].
  const DashboardLinkArrow({super.key, required this.label, this.onTap});

  /// Link label.
  final String label;

  /// Tap callback.
  final VoidCallback? onTap;

  @override
  State<DashboardLinkArrow> createState() => _DashboardLinkArrowState();
}

class _DashboardLinkArrowState extends State<DashboardLinkArrow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    final color = _hover ? ds.accent : ds.muted;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

/// The visual styles of [DashboardButton], mirroring the design source's
/// `.btn-dark` (primary, ink), `.btn-line` (secondary, hairline), `.btn-accent`
/// (the scarce orange signal) and `.btn-cream` (quiet warm fill).
enum DashButtonStyle {
  /// Ink-black primary CTA.
  dark,

  /// Hairline-outlined secondary.
  line,

  /// The single orange signal — reserved for the one go-action in a view.
  accent,

  /// Quiet warm-neutral fill.
  cream,
}

/// A compact button matching the design source's `.btn` family. Near-zero
/// radius, hairline-or-solid fills, a subtle press nudge.
class DashboardButton extends StatefulWidget {
  /// Creates a [DashboardButton].
  const DashboardButton({
    super.key,
    required this.label,
    required this.style,
    this.icon,
    this.onTap,
    this.small = false,
  });

  /// Button label.
  final String label;

  /// Visual style.
  final DashButtonStyle style;

  /// Optional leading icon.
  final IconData? icon;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Whether to use the compact `.btn-sm` sizing.
  final bool small;

  @override
  State<DashboardButton> createState() => _DashboardButtonState();
}

class _DashboardButtonState extends State<DashboardButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    final (Color bg, Color fg, Color? border) = switch (widget.style) {
      DashButtonStyle.dark => (
          _hover ? Color.lerp(ds.fg, Colors.black, 0.2)! : ds.fg,
          // Foreground is the page canvas, the inverse of `fg`: near-white text
          // on the light theme's ink fill, near-black text on dark mode's
          // inverted off-white fill. `accentOn` (always white) read as
          // white-on-white in dark mode.
          ds.canvas,
          null,
        ),
      DashButtonStyle.accent => (
          _hover ? ds.accentHover : ds.accent,
          ds.accentOn,
          null,
        ),
      DashButtonStyle.cream => (
          _hover ? Color.lerp(ds.surface, ds.fg, 0.06)! : ds.surface,
          ds.fg,
          null,
        ),
      DashButtonStyle.line => (
          ds.panel,
          ds.fg,
          _hover ? ds.fg : ds.borderPrimary,
        ),
    };
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: widget.small
              ? const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadii.brSm,
            border: border != null ? Border.all(color: border) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: widget.small ? 14 : 15, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.small ? 13 : 14,
                  fontWeight: FontWeight.w500,
                  color: fg,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pill capsule used for state badges and filter chips.
class DashboardPill extends StatelessWidget {
  /// Creates a [DashboardPill].
  const DashboardPill({
    super.key,
    required this.child,
    required this.background,
    this.border,
    this.padding =
        const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
  });

  /// Pill contents.
  final Widget child;

  /// Fill colour.
  final Color background;

  /// Optional border colour.
  final Color? border;

  /// Inner padding.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
        border: border != null ? Border.all(color: border!) : null,
      ),
      child: child,
    );
  }
}
