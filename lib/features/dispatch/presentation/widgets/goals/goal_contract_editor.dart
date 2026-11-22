import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_checks_editor.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// What "done" means for a goal, edited: its success criteria (at most
/// [GoalContract.maxCriteria], each up to [GoalContract.maxCriterionLength]
/// characters), its checks ([GoalChecksEditor]), its boundaries and when to
/// stop and ask (each up to [GoalContract.maxTextLength] characters).
///
/// Shared by the goal page and the pipeline goal node; the caller decides
/// what to do with the contract.
class GoalContractEditor extends StatefulWidget {
  /// Creates the editor seeded with [initial].
  const GoalContractEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  /// The contract it starts with, or null for an empty one.
  final GoalContract? initial;

  /// Called with the contract the fields describe (null when every field is
  /// empty) and whether every field is within its limits.
  final void Function(GoalContract? contract, bool valid) onChanged;

  @override
  State<GoalContractEditor> createState() => _GoalContractEditorState();
}

class _GoalContractEditorState extends State<GoalContractEditor> {
  late final List<TextEditingController> _criteria = [
    for (final c in widget.initial?.criteria ?? const <String>[])
      TextEditingController(text: c),
  ];
  late final _boundaries = TextEditingController(
    text: widget.initial?.boundaries ?? '',
  );
  late final _stopWhen = TextEditingController(
    text: widget.initial?.stopWhen ?? '',
  );
  late List<GoalCheck> _checks = widget.initial?.checks ?? const [];
  bool _checksValid = true;

  @override
  void dispose() {
    for (final c in _criteria) {
      c.dispose();
    }
    _boundaries.dispose();
    _stopWhen.dispose();
    super.dispose();
  }

  static bool _textOk(String s) => s.length <= GoalContract.maxTextLength;

  void _emit() {
    setState(() {});
    final criteria = [
      for (final c in _criteria)
        if (c.text.trim().isNotEmpty) c.text.trim(),
    ];
    final valid =
        _checksValid &&
        criteria.length <= GoalContract.maxCriteria &&
        criteria.every((c) => c.length <= GoalContract.maxCriterionLength) &&
        _textOk(_boundaries.text.trim()) &&
        _textOk(_stopWhen.text.trim());
    if (!valid) {
      widget.onChanged(widget.initial, false);
      return;
    }
    final boundaries = _boundaries.text.trim();
    final stopWhen = _stopWhen.text.trim();
    final empty =
        criteria.isEmpty &&
        _checks.isEmpty &&
        boundaries.isEmpty &&
        stopWhen.isEmpty;
    widget.onChanged(
      empty
          ? null
          : GoalContract(
              criteria: criteria,
              checks: _checks,
              boundaries: boundaries.isEmpty ? null : boundaries,
              stopWhen: stopWhen.isEmpty ? null : stopWhen,
            ),
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final heading = CcTypography.bodySm.copyWith(
      color: ds.textPrimary,
      fontWeight: FontWeight.w600,
    );
    final caption = CcTypography.caption.copyWith(color: ds.textTertiary);
    final full = _criteria.length >= GoalContract.maxCriteria;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.goalContractDoneMeans, style: heading),
        const SizedBox(height: AppSpacing.xxs),
        Text(l10n.goalContractDoneMeansHelp, style: caption),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < _criteria.length; i++)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CcTextField(
                    key: ValueKey('goal-criterion-$i'),
                    controller: _criteria[i],
                    maxLength: GoalContract.maxCriterionLength,
                    hintText: l10n.goalContractCriterionHint,
                    errorText:
                        _criteria[i].text.length >
                            GoalContract.maxCriterionLength
                        ? l10n.goalContractCriterionTooLong(
                            GoalContract.maxCriterionLength,
                          )
                        : null,
                    onChanged: (_) => _emit(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                CcIconButton(
                  icon: AppIcons.x,
                  variant: CcButtonVariant.ghost,
                  tooltip: l10n.goalContractRemoveCriterion,
                  onPressed: () {
                    _criteria.removeAt(i).dispose();
                    _emit();
                  },
                ),
              ],
            ),
          ),
        Row(
          children: [
            CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              icon: AppIcons.plus,
              onPressed: full
                  ? null
                  : () {
                      _criteria.add(TextEditingController());
                      _emit();
                    },
              child: Text(l10n.goalContractAddCriterion),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                full
                    ? l10n.goalContractCriteriaFull(GoalContract.maxCriteria)
                    : l10n.goalContractCriteriaCount(
                        _criteria.length,
                        GoalContract.maxCriteria,
                      ),
                style: caption,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.goalContractChecks, style: heading),
        const SizedBox(height: AppSpacing.xxs),
        Text(l10n.goalContractChecksHelp, style: caption),
        const SizedBox(height: AppSpacing.sm),
        GoalChecksEditor(
          initial: _checks,
          onChanged: (checks, valid) {
            _checks = checks;
            _checksValid = valid;
            _emit();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        CcTextArea(
          controller: _boundaries,
          label: l10n.goalContractBoundaries,
          hintText: l10n.goalContractBoundariesHint,
          maxLength: GoalContract.maxTextLength,
          minLines: 2,
          maxLines: 6,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: AppSpacing.md),
        CcTextArea(
          controller: _stopWhen,
          label: l10n.goalContractStopWhen,
          hintText: l10n.goalContractStopWhenHint,
          maxLength: GoalContract.maxTextLength,
          minLines: 2,
          maxLines: 6,
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}
