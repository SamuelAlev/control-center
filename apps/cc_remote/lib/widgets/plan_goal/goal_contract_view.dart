import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/work/work_text.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A small section heading inside the goal detail.
Widget goalSectionHeading(BuildContext context, String text) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Padding(
    padding: const EdgeInsetsDirectional.only(top: 20, bottom: 6),
    child: Text(
      text,
      style: CcTypography.body.copyWith(
        color: t.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// What done means for a goal: the criteria, the checks the server runs
/// (commands in code style), the boundaries and when to stop and ask. A goal
/// without checks says that a reviewer judges it from what it can read.
/// Every line is the person's or agent's own text, shown as plain text.
class GoalContractView extends StatelessWidget {
  const GoalContractView({super.key, required this.contract});

  final GoalContract? contract;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    final c = contract;
    final body = CcTypography.bodySm.copyWith(color: t.textPrimary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c != null && c.criteria.isNotEmpty) ...[
          goalSectionHeading(context, l.goalDoneMeans),
          for (var i = 0; i < c.criteria.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}.',
                      style: CcFonts.numeric(
                        textStyle: CcTypography.numeric.copyWith(
                          color: t.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: Text(inertText(c.criteria[i]), style: body)),
                ],
              ),
            ),
        ],
        goalSectionHeading(context, l.goalChecks),
        if (c == null || c.hasNoChecks)
          Text(
            l.goalNoMachineCheck,
            style: CcTypography.bodySm.copyWith(color: t.textSecondary),
          )
        else
          for (final check in c.checks)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _CheckLine(check: check),
            ),
        if (c?.boundaries case final boundaries?) ...[
          goalSectionHeading(context, l.goalBoundaries),
          WorkQuote(boundaries),
        ],
        if (c?.stopWhen case final stopWhen?) ...[
          goalSectionHeading(context, l.goalStopWhen),
          WorkQuote(stopWhen),
        ],
      ],
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.check});

  final GoalCheck check;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (check.where == GoalCheckLocation.environment)
          Text(
            AppLocalizations.of(context).goalCheckEnvironment,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
        WorkCode(check.run),
      ],
    );
  }
}
