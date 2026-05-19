import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_fonts.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// Where a layered config value originates. Used to make policy provenance
/// legible — "this rule is project-scoped" vs "globally inherited".
enum CcConfigSource {
  /// Built-in default; no one set it.
  defaultValue,

  /// Set by the app/runtime itself.
  system,

  /// Set at the user/global level.
  global,

  /// Inherited from a parent scope (e.g. global → workspace).
  inherited,

  /// Set at the project/workspace level.
  project,

  /// A local override on top of an inherited value.
  localOverride,
}

/// Whether a source should read as an active override (project / local) and so
/// earn the accent stripe and tinted badge.
bool _isOverride(CcConfigSource source) =>
    source == CcConfigSource.project || source == CcConfigSource.localOverride;

/// The built-in uppercase label for a source, used when no localized [label]
/// override is supplied to [CcSourceBadge].
String _defaultSourceLabel(CcConfigSource source) => switch (source) {
  CcConfigSource.defaultValue => 'DEFAULT',
  CcConfigSource.system => 'SYSTEM',
  CcConfigSource.global => 'GLOBAL',
  CcConfigSource.inherited => 'INHERITED',
  CcConfigSource.project => 'PROJECT',
  CcConfigSource.localOverride => 'LOCAL OVERRIDE',
};

/// A small monospace badge naming where a config value comes from. Project and
/// local-override sources take the brand/info tint to draw the eye; everything
/// else is quiet neutral.
///
/// Pass [label] to localize the text; when omitted a built-in uppercase name is
/// used so the badge is usable standalone.
class CcSourceBadge extends StatelessWidget {
  /// Creates a [CcSourceBadge].
  const CcSourceBadge({super.key, required this.source, this.label});

  /// The provenance of the value.
  final CcConfigSource source;

  /// Optional localized label; falls back to a built-in uppercase name.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final override = _isOverride(source);
    final fg = override ? t.accent : t.textTertiary;
    final bg = override ? t.accentSoft : t.bgSecondary;
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: AppRadii.brSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 1,
        ),
        child: Text(
          label ?? _defaultSourceLabel(source),
          style: CcFonts.code(
            textStyle: CcTypography.caption.copyWith(
              color: fg,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single config / policy row: optional [leading] glyph, a [title] (and
/// optional [subtitle]), a trailing [CcSourceBadge] for provenance, and
/// optional [status] and [actions] slots.
///
/// When the value is a project/local override (or [highlightOverride] is set)
/// the row grows a left accent stripe so layered overrides are scannable in a
/// long list — making Phase 2/3 policy layering legible at a glance.
class CcConfigRow extends StatelessWidget {
  /// Creates a [CcConfigRow].
  const CcConfigRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.source,
    this.sourceLabel,
    this.status,
    this.actions,
    this.highlightOverride = false,
    this.onTap,
  });

  /// Primary label (a config key, a command rule, a policy name).
  final Widget title;

  /// Optional secondary line (the value, a description).
  final Widget? subtitle;

  /// Optional leading glyph/icon.
  final Widget? leading;

  /// Provenance of the value; renders a trailing [CcSourceBadge] when set.
  final CcConfigSource? source;

  /// Optional localized label for the source badge.
  final String? sourceLabel;

  /// Optional trailing status widget (e.g. a [CcStatusTag]).
  final Widget? status;

  /// Optional trailing actions (buttons/menus).
  final Widget? actions;

  /// Force the override accent stripe regardless of [source].
  final bool highlightOverride;

  /// Optional tap handler; when set the whole row becomes activatable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final override =
        highlightOverride || (source != null && _isOverride(source!));

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle.merge(
                  style: CcTypography.body.copyWith(color: t.textPrimary),
                  child: title,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  DefaultTextStyle.merge(
                    style: CcTypography.bodySm.copyWith(color: t.textTertiary),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (source != null) ...[
            const SizedBox(width: AppSpacing.sm),
            CcSourceBadge(source: source!, label: sourceLabel),
          ],
          if (status != null) ...[
            const SizedBox(width: AppSpacing.sm),
            status!,
          ],
          if (actions != null) ...[
            const SizedBox(width: AppSpacing.sm),
            actions!,
          ],
        ],
      ),
    );

    final body = Stack(
      children: [
        if (override)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 2, color: t.accent),
          ),
        row,
      ],
    );

    if (onTap == null) {
      return body;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: body,
    );
  }
}
