import 'dart:ui' as ui;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Read-only interpretation of the skillBehavior report, including partial runs.
class SkillBehaviorSummary extends StatelessWidget {
  /// Creates a summary for a campaign's behavior evidence.
  const SkillBehaviorSummary({required this.behavior, super.key});

  /// The server's `skillBehavior` report section, including partial results.
  final Map<String, dynamic> behavior;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final percent = NumberFormat.percentPattern(locale);
    String count(Object? value) => value is num && value.isFinite
        ? number.format(value)
        : l.skillEvalUnknown;
    String rate(Object? value) => value is num && value.isFinite
        ? percent.format(value)
        : l.skillEvalUnknown;
    final routing = _rows(behavior['routing']);
    final safety = _rows(behavior['safety']);
    final utility = _rows(behavior['utilityByFamily']);
    final families = <String, List<Map<String, dynamic>>>{};
    for (final row in utility) {
      families
          .putIfAbsent('${row['family'] ?? l.skillEvalUnknown}', () => [])
          .add(row);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, l.skillBehaviorRouting),
        for (final row in routing)
          _group(context, row['armId'], [
            if (row['forced'] == true)
              CcStatusTag(
                label: l.skillBehaviorForced,
                tone: CcStatusTone.neutral,
                dot: false,
              ),
            Text(
              l.skillBehaviorRoutingCounts(
                count(row['truePositive']),
                count(row['falsePositive']),
                count(row['falseNegative']),
                count(row['trueNegative']),
              ),
              style: CcTypography.bodySm.copyWith(color: t.textPrimary),
            ),
            Text(
              l.skillBehaviorUnknownCounts(
                count(row['unknownPositive']),
                count(row['unknownNegative']),
                count(row['notOffered']),
              ),
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
            Text(
              l.skillBehaviorRoutingRates(
                rate(row['precision']),
                rate(row['recall']),
                rate(row['falsePositiveRate']),
              ),
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          ]),
        if (routing.isEmpty) _empty(context),
        _note(context, l.skillBehaviorRoutingNote),
        const SizedBox(height: AppSpacing.lg),
        const CcDivider(),
        const SizedBox(height: AppSpacing.md),
        _heading(context, l.skillBehaviorSafety),
        for (final row in safety)
          _group(context, row['armId'], [
            Text(
              l.skillBehaviorSafetyCounts(
                count(row['artifactPasses']),
                count(row['attempts']),
                count(row['policyDenials']),
                count(row['protectedFileViolations']),
              ),
              style: CcTypography.bodySm.copyWith(color: t.textPrimary),
            ),
          ]),
        if (safety.isEmpty) _empty(context),
        _note(context, l.skillBehaviorSafetyNote),
        const SizedBox(height: AppSpacing.lg),
        const CcDivider(),
        const SizedBox(height: AppSpacing.md),
        _heading(context, l.skillBehaviorUtility),
        for (final family in families.entries) ...[
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
            child: _identifier(context, family.key),
          ),
          for (final row in family.value)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
              child: _group(context, row['armId'], [
                Text(
                  l.skillBehaviorUtilityCounts(
                    count(row['verifiedSuccesses']),
                    count(row['attempts']),
                  ),
                  style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                ),
              ]),
            ),
        ],
        if (families.isEmpty) _empty(context),
        _note(context, l.skillBehaviorUtilityNote),
      ],
    );
  }
}

List<Map<String, dynamic>> _rows(Object? value) => [
  for (final row in value is List ? value : const [])
    if (row is Map) row.cast<String, dynamic>(),
];

Widget _heading(BuildContext context, String title) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Semantics(
    header: true,
    child: Text(
      title,
      style: CcTypography.label.copyWith(color: t.textPrimary),
    ),
  );
}

Widget _identifier(BuildContext context, Object? value) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final label = '${value ?? AppLocalizations.of(context).skillEvalUnknown}';
  // RTL carve-out: arm and family identifiers are machine-provided labels.
  return Semantics(
    label: label,
    excludeSemantics: true,
    child: Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textDirection: ui.TextDirection.ltr,
      style: CcTypography.label.copyWith(color: t.textPrimary),
    ),
  );
}

Widget _group(BuildContext context, Object? id, List<Widget> details) =>
    Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _identifier(context, id),
          const SizedBox(height: AppSpacing.xs),
          for (final detail in details)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
              child: detail,
            ),
        ],
      ),
    );

Widget _empty(BuildContext context) =>
    _note(context, AppLocalizations.of(context).skillEvalNoAttempts);

Widget _note(BuildContext context, String text) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Padding(
    padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
    child: Text(
      text,
      style: CcTypography.caption.copyWith(color: t.textSecondary),
    ),
  );
}
