import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Shared presentational building blocks for the observability surfaces, so the
/// Agent Hub, dashboard tabs and cards share one visual vocabulary built on the
/// `cc_ui` design tokens.

/// Semantic tone for a bar / value, mapped to the design-system palette.
enum ObsTone {
  /// Quiet / default.
  neutral,

  /// Brand-tinted (primary metric).
  brand,

  /// Positive.
  success,

  /// Caution.
  warning,

  /// Error / over-limit.
  danger,
}

/// Resolves an [ObsTone] to its solid accent color from [t].
Color obsToneColor(DesignSystemTokens t, ObsTone tone) => switch (tone) {
  ObsTone.neutral => t.fgTertiary,
  ObsTone.brand => t.bgBrandSolid,
  ObsTone.success => t.bgSuccessSolid,
  ObsTone.warning => t.bgWarningSolid,
  ObsTone.danger => t.bgErrorSolid,
};

/// A titled panel (a [CcCard] with a header row and optional trailing action).
class ObsSection extends StatelessWidget {
  /// Creates an [ObsSection].
  const ObsSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.icon,
  });

  /// Section heading.
  final String title;

  /// Optional one-line description under the title.
  final String? subtitle;

  /// Section body.
  final Widget child;

  /// Optional trailing widget in the header (e.g. a button or filter).
  final Widget? trailing;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: t.fgSecondary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CcTypography.body.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Text(
                          subtitle!,
                          style: CcTypography.caption.copyWith(
                            color: t.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// A single big-number stat: a small label over a large value, with an optional
/// sub-label. Sized to flex inside a [Wrap] or [Row].
class ObsStatTile extends StatelessWidget {
  /// Creates an [ObsStatTile].
  const ObsStatTile({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.tone = ObsTone.neutral,
    this.icon,
  });

  /// The metric label (e.g. "total cost").
  final String label;

  /// The formatted value (e.g. "$4.20").
  final String value;

  /// Optional secondary line.
  final String? sub;

  /// Accent tone for the value.
  final ObsTone tone;

  /// Optional leading icon next to the label.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final valueColor = tone == ObsTone.neutral
        ? t.textPrimary
        : obsToneColor(t, tone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: t.fgTertiary),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Text(
              label,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: CcTypography.title.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (sub != null)
          Text(
            sub!,
            style: CcTypography.caption.copyWith(color: t.textQuaternary),
          ),
      ],
    );
  }
}

/// One figure in an [ObsStatStrip].
@immutable
class ObsStatStripEntry {
  /// Creates an [ObsStatStripEntry].
  const ObsStatStripEntry({
    required this.label,
    required this.value,
    this.tone = ObsTone.neutral,
    this.detail,
    this.detailTone = ObsTone.neutral,
  });

  /// The metric name, under the value.
  final String label;

  /// The formatted figure.
  final String value;

  /// Accent tone for the value. Reserved for figures that carry a real
  /// verdict (an error rate, a failure count) — a tone on a neutral number is
  /// the decoration DESIGN.md cuts.
  final ObsTone tone;

  /// Optional third line under the label (e.g. a vs-previous delta).
  final String? detail;

  /// Accent tone for [detail].
  final ObsTone detailTone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObsStatStripEntry &&
          label == other.label &&
          value == other.value &&
          tone == other.tone &&
          detail == other.detail &&
          detailTone == other.detailTone;

  @override
  int get hashCode => Object.hash(label, value, tone, detail, detailTone);
}

/// A row of headline figures in one bordered card: the value over its label,
/// evenly distributed and parted by hairline dividers.
///
/// The observability tabs all open on a strip like this, so it is one widget
/// rather than four hand-rolled `Wrap`s that drift apart. Deliberately
/// icon-free — a gauge glyph beside "Total runs" reports nothing the number
/// does not, and DESIGN.md cuts anything that decorates without reporting.
///
/// Falls back to a wrap (dividers dropped, figures left-aligned) once the row
/// is too narrow to give every figure [_minStatWidth]; a divided row that has
/// to ellipsize its labels is worse than an honest wrap.
class ObsStatStrip extends StatelessWidget {
  /// Creates an [ObsStatStrip].
  const ObsStatStrip({super.key, required this.entries});

  /// The figures, in display order.
  final List<ObsStatStripEntry> entries;

  /// Width each figure needs before the row breaks into a wrap.
  static const double _minStatWidth = 120;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    return CcCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < entries.length * _minStatWidth) {
            return Wrap(
              spacing: AppSpacing.xl,
              runSpacing: AppSpacing.lg,
              children: [for (final entry in entries) _StripStat(entry: entry)],
            );
          }
          // IntrinsicHeight so each divider spans the tallest figure — a
          // fixed height would clip once an entry carries a delta line.
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const CcDivider(axis: Axis.vertical),
                  Expanded(
                    child: _StripStat(entry: entries[i], centered: true),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One figure: the value above its label, plus an optional detail line.
class _StripStat extends StatelessWidget {
  const _StripStat({required this.entry, this.centered = false});

  final ObsStatStripEntry entry;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final align = centered ? TextAlign.center : TextAlign.start;
    final detail = entry.detail;
    return Semantics(
      label: detail == null
          ? '${entry.label}: ${entry.value}'
          : '${entry.label}: ${entry.value}, $detail',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: centered ? AppSpacing.sm : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: centered
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              entry.value,
              textAlign: align,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.title.copyWith(
                color: entry.tone == ObsTone.neutral
                    ? t.textPrimary
                    : obsToneColor(t, entry.tone),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              entry.label,
              textAlign: align,
              // Two lines, because an evenly-divided row gives a long label
              // like "Time to first token" less width than it needs and
              // ellipsizing it would hide which metric this is.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
            if (detail != null)
              Text(
                detail,
                textAlign: align,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.caption.copyWith(
                  color: entry.detailTone == ObsTone.neutral
                      ? t.textQuaternary
                      : obsToneColor(t, entry.detailTone),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A label/value row (label left in tertiary, value right in mono).
class ObsKeyValue extends StatelessWidget {
  /// Creates an [ObsKeyValue].
  const ObsKeyValue({
    super.key,
    required this.label,
    required this.value,
    this.valueTone = ObsTone.neutral,
  });

  /// Left label.
  final String label;

  /// Right value.
  final String value;

  /// Optional tone for the value text.
  final ObsTone valueTone;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
          ),
          Text(
            value,
            style: CcTypography.monoNum.copyWith(
              color: valueTone == ObsTone.neutral
                  ? t.textPrimary
                  : obsToneColor(t, valueTone),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labeled horizontal meter: a track filled to [fraction] (0..1) in the
/// tone's color, with a label and trailing value. Used for budgets and quotas.
class ObsBar extends StatelessWidget {
  /// Creates an [ObsBar].
  const ObsBar({
    super.key,
    required this.label,
    required this.fraction,
    required this.valueLabel,
    this.tone = ObsTone.brand,
    this.detail,
  });

  /// Left label.
  final String label;

  /// Fill fraction, clamped to 0..1.
  final double fraction;

  /// Trailing value (e.g. "92%" or "12k / 50k").
  final String valueLabel;

  /// Fill tone.
  final ObsTone tone;

  /// Optional sub-line (e.g. "resets in 40m").
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final fill = fraction.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: CcTypography.bodySm.copyWith(color: t.textSecondary),
                ),
              ),
              Text(
                valueLabel,
                style: CcTypography.monoNum.copyWith(color: t.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadii.pill),
            ),
            child: Stack(
              children: [
                Container(height: 6, color: t.bgTertiary),
                FractionallySizedBox(
                  widthFactor: fill,
                  child: Container(height: 6, color: obsToneColor(t, tone)),
                ),
              ],
            ),
          ),
          if (detail != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                detail!,
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            ),
        ],
      ),
    );
  }
}

/// One entry in an [ObsChartLegend]: a series' swatch and its label.
@immutable
class ObsLegendEntry {
  /// Creates an [ObsLegendEntry].
  const ObsLegendEntry({required this.label, required this.color, this.detail});

  /// The series name.
  final String label;

  /// Optional trailing figure (e.g. a token total or a share).
  final String? detail;

  /// The swatch color, matching the series as drawn.
  final Color color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObsLegendEntry &&
          label == other.label &&
          color == other.color &&
          detail == other.detail;

  @override
  int get hashCode => Object.hash(label, color, detail);
}

/// A chart's series key. Always rendered beside a chart — a series is never
/// identified by color alone (WCAG).
class ObsChartLegend extends StatelessWidget {
  /// Creates an [ObsChartLegend].
  const ObsChartLegend({super.key, required this.entries});

  /// The series to name, in the order they are drawn.
  final List<ObsLegendEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final entry in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 9, height: 9, color: entry.color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                entry.label,
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
              if (entry.detail != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  entry.detail!,
                  style: CcTypography.caption.copyWith(color: t.textQuaternary),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// A small status dot whose color reflects an [ObsTone]; pairs with a text label
/// so status is never conveyed by color alone (WCAG).
class ObsStatusDot extends StatelessWidget {
  /// Creates an [ObsStatusDot].
  const ObsStatusDot({super.key, required this.tone, this.size = 8});

  /// The tone.
  final ObsTone tone;

  /// Diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: obsToneColor(t, tone),
        shape: BoxShape.circle,
      ),
    );
  }
}
