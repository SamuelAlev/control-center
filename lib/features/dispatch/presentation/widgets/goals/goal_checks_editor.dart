import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter/widgets.dart';

/// The machine checks of a goal, edited: each a command (or an environment
/// task's name), where it runs, and how long it may take. At most
/// [GoalContract.maxChecks]; a timeout from 1 to
/// [GoalCheck.maxTimeoutSeconds] seconds. Shared by the goal page's contract
/// editor, the guided goal dialog and the pipeline goal node.
class GoalChecksEditor extends StatefulWidget {
  /// Creates the editor seeded with [initial].
  const GoalChecksEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  /// The checks it starts with.
  final List<GoalCheck> initial;

  /// Called with the checks the rows describe (blank rows left out) and
  /// whether every row is within its limits.
  final void Function(List<GoalCheck> checks, bool valid) onChanged;

  @override
  State<GoalChecksEditor> createState() => _GoalChecksEditorState();
}

class _CheckDraft {
  _CheckDraft(GoalCheck? check)
    : run = TextEditingController(text: check?.run ?? ''),
      timeout = TextEditingController(
        text: '${check?.timeoutSeconds ?? GoalCheck.defaultTimeoutSeconds}',
      ),
      where = check?.where ?? GoalCheckLocation.worktree;

  final TextEditingController run;
  final TextEditingController timeout;
  GoalCheckLocation where;

  int? get seconds => int.tryParse(timeout.text.trim());

  bool get timeoutValid {
    final s = seconds;
    return s != null && s >= 1 && s <= GoalCheck.maxTimeoutSeconds;
  }

  bool get blank => run.text.trim().isEmpty;

  void dispose() {
    run.dispose();
    timeout.dispose();
  }
}

class _GoalChecksEditorState extends State<GoalChecksEditor> {
  late final List<_CheckDraft> _rows = [
    for (final c in widget.initial) _CheckDraft(c),
  ];

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _emit() {
    setState(() {});
    final valid = _rows.every((r) => r.blank || r.timeoutValid);
    widget.onChanged([
      for (final r in _rows)
        if (!r.blank && r.timeoutValid)
          GoalCheck(
            run: r.run.text.trim(),
            where: r.where,
            timeoutSeconds: r.seconds!,
          ),
    ], valid);
  }

  void _add() {
    _rows.add(_CheckDraft(null));
    _emit();
  }

  void _remove(int i) {
    _rows.removeAt(i).dispose();
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.ds;
    final full = _rows.length >= GoalContract.maxChecks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
            child: _CheckRowFields(
              index: i,
              draft: _rows[i],
              onChanged: _emit,
              onRemove: () => _remove(i),
            ),
          ),
        Row(
          children: [
            CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              icon: AppIcons.plus,
              onPressed: full ? null : _add,
              child: Text(l10n.goalContractAddCheck),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                full
                    ? l10n.goalContractChecksFull(GoalContract.maxChecks)
                    : l10n.goalContractChecksCount(
                        _rows.length,
                        GoalContract.maxChecks,
                      ),
                style: CcTypography.caption.copyWith(color: ds.textTertiary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CheckRowFields extends StatelessWidget {
  const _CheckRowFields({
    required this.index,
    required this.draft,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final _CheckDraft draft;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final environment = draft.where == GoalCheckLocation.environment;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: CcTextField(
            key: ValueKey('goal-check-run-$index'),
            controller: draft.run,
            maxLength: GoalCheck.maxRunLength,
            hintText: environment
                ? l10n.goalContractCheckTaskHint
                : l10n.goalContractCheckCommandHint,
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 168,
          child: CcSelect<GoalCheckLocation>(
            value: draft.where,
            semanticLabel: l10n.goalContractCheckWhere,
            options: [
              CcSelectOption(
                value: GoalCheckLocation.worktree,
                label: l10n.goalContractCheckInWorktree,
              ),
              CcSelectOption(
                value: GoalCheckLocation.environment,
                label: l10n.goalContractCheckInEnvironment,
              ),
            ],
            onChanged: (v) {
              draft.where = v;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 112,
          child: CcTextField(
            key: ValueKey('goal-check-timeout-$index'),
            controller: draft.timeout,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            suffix: Text(l10n.goalContractSecondsSuffix),
            errorText: draft.timeoutValid
                ? null
                : l10n.goalContractTimeoutRange(GoalCheck.maxTimeoutSeconds),
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        CcIconButton(
          icon: AppIcons.x,
          variant: CcButtonVariant.ghost,
          tooltip: l10n.goalContractRemoveCheck,
          onPressed: onRemove,
        ),
      ],
    );
  }
}
