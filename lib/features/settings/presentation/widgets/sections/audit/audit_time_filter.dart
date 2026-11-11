import 'package:cc_domain/core/domain/value_objects/audit_log_filter.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// The comparison glyph of [op] (`≥`, `>`, `<`, `≤`), the way a filter chip
/// writes it.
String auditTimeSymbol(AuditTimeOperator op) => switch (op) {
  AuditTimeOperator.atOrAfter => '≥',
  AuditTimeOperator.after => '>',
  AuditTimeOperator.before => '<',
  AuditTimeOperator.atOrBefore => '≤',
};

/// [op] in words, for the panel and screen readers.
String auditTimeOperatorLabel(AppLocalizations l10n, AuditTimeOperator op) =>
    switch (op) {
      AuditTimeOperator.atOrAfter => l10n.auditLogTimeAtOrAfter,
      AuditTimeOperator.after => l10n.auditLogTimeAfter,
      AuditTimeOperator.before => l10n.auditLogTimeBefore,
      AuditTimeOperator.atOrBefore => l10n.auditLogTimeAtOrBefore,
    };

/// [c]'s instant in the active locale, local time.
String auditTimeValueLabel(AuditTimeCondition c) =>
    DateFormat.yMMMd().add_Hm().format(c.at.toLocal());

/// [c] as a chip reads it: `Time ≥ Nov 10, 2026 14:30`.
String auditTimeChipLabel(AppLocalizations l10n, AuditTimeCondition c) =>
    l10n.auditLogTimeChip(auditTimeSymbol(c.op), auditTimeValueLabel(c));

/// [c] for a screen reader: `Time on or after Nov 10, 2026 14:30`.
String auditTimeSemanticLabel(AppLocalizations l10n, AuditTimeCondition c) =>
    l10n.auditLogTimeChip(
      auditTimeOperatorLabel(l10n, c.op),
      auditTimeValueLabel(c),
    );

/// Parses a typed instant in local time: `YYYY-MM-DD`, optionally followed by
/// `HH:MM` (a space or `T` between). Null when it is not one.
DateTime? parseAuditTime(String raw) {
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2}))?$',
  ).firstMatch(raw.trim());
  if (match == null) {
    return null;
  }
  int part(int i) => int.parse(match.group(i) ?? '0');
  final (y, mo, d, h, mi) = (part(1), part(2), part(3), part(4), part(5));
  final at = DateTime(y, mo, d, h, mi);
  // DateTime normalizes overflow (Feb 30 → Mar 2); refuse it instead.
  if (at.year != y ||
      at.month != mo ||
      at.day != d ||
      at.hour != h ||
      at.minute != mi) {
    return null;
  }
  return at;
}

/// The panel that adds one time condition: pick the comparison, then a
/// preset ("24 hours ago") or an exact time. [onAdd] receives the condition.
class AuditTimeFilterPanel extends StatefulWidget {
  /// Creates the panel.
  const AuditTimeFilterPanel({super.key, required this.onAdd, this.now});

  /// Called with the condition to add.
  final ValueChanged<AuditTimeCondition> onAdd;

  /// The clock presets count back from; the wall clock when null.
  final DateTime Function()? now;

  @override
  State<AuditTimeFilterPanel> createState() => _AuditTimeFilterPanelState();
}

class _AuditTimeFilterPanelState extends State<AuditTimeFilterPanel> {
  final _controller = TextEditingController();
  AuditTimeOperator _op = AuditTimeOperator.atOrAfter;
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addExact() {
    final at = parseAuditTime(_controller.text);
    if (at == null) {
      setState(() => _invalid = true);
      return;
    }
    widget.onAdd(AuditTimeCondition(op: _op, at: at));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final now = (widget.now ?? DateTime.now)();
    final presets = [
      (l10n.auditLogTimePresetHour, const Duration(hours: 1)),
      (l10n.auditLogTimePresetDay, const Duration(days: 1)),
      (l10n.auditLogTimePresetWeek, const Duration(days: 7)),
      (l10n.auditLogTimePresetMonth, const Duration(days: 30)),
    ];
    final label = CcTypography.caption.copyWith(color: t.textSecondary);
    return DefaultTextStyle(
      style: CcTypography.bodySm.copyWith(
        color: t.textPrimary,
        decoration: TextDecoration.none,
      ),
      child: SizedBox(
        width: 288,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CcSegmentedToggle<AuditTimeOperator>(
                fullWidth: true,
                semanticLabel: auditTimeOperatorLabel(l10n, _op),
                value: _op,
                segments: [
                  for (final op in AuditTimeOperator.values)
                    CcSegment(value: op, label: auditTimeSymbol(op)),
                ],
                onChanged: (op) => setState(() => _op = op),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(auditTimeOperatorLabel(l10n, _op), style: label),
              const SizedBox(height: AppSpacing.md),
              for (final (name, ago) in presets)
                _PresetRow(
                  label: name,
                  onPressed: () => widget.onAdd(
                    AuditTimeCondition(op: _op, at: now.subtract(ago)),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.auditLogTimeExact, style: label),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CcTextField(
                      controller: _controller,
                      size: CcTextFieldSize.sm,
                      autofocus: true,
                      hintText: '2026-11-10 14:30',
                      errorText: _invalid ? l10n.auditLogTimeInvalid : null,
                      onChanged: (_) {
                        if (_invalid) {
                          setState(() => _invalid = false);
                        }
                      },
                      onSubmitted: (_) => _addExact(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  CcButton(
                    size: CcButtonSize.sm,
                    onPressed: _addExact,
                    child: Text(l10n.auditLogTimeAdd),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      semanticLabel: label,
      onPressed: onPressed,
      builder: (context, states) => Container(
        color: states.contains(WidgetState.hovered) ? t.bgSecondary : null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          style: CcTypography.bodySm.copyWith(color: t.textPrimary),
        ),
      ),
    );
  }
}
