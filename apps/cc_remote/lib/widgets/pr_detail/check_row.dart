import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/external_link.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// One CI check run row with status icon, name and elapsed time.
class CheckRow extends StatelessWidget {
  const CheckRow({super.key, required this.run});

  final CheckRun run;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final (icon, color, label) = _state(t, l10n);
    final elapsed = run.startedAt == null
        ? null
        : (run.completedAt ?? DateTime.now()).difference(run.startedAt!);
    return CcTappable(
      onPressed: run.htmlUrl.isEmpty ? null : () => openExternal(run.htmlUrl),
      semanticLabel: l10n.checkSemanticLabel(run.name, label),
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    run.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: t.textPrimary),
                  ),
                  if (run.workflowName != null &&
                      run.workflowName!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      run.workflowName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: t.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              elapsed == null
                  ? label
                  : l10n.labelWithDuration(
                      label,
                      shortDuration(context, elapsed),
                    ),
              style: TextStyle(fontSize: 11, color: t.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, String) _state(
    DesignSystemTokens t,
    AppLocalizations l10n,
  ) {
    if (run.status != CheckRunStatus.completed) {
      return (AppIcons.clock, t.textWarningPrimary, l10n.checkRunning);
    }
    return switch (run.conclusion) {
      CheckRunConclusion.success => (
        AppIcons.circleCheck,
        t.textSuccessPrimary,
        l10n.checkPassed,
      ),
      CheckRunConclusion.failure ||
      CheckRunConclusion.timedOut ||
      CheckRunConclusion.actionRequired => (
        AppIcons.circleX,
        t.textErrorPrimary,
        l10n.checkFailed,
      ),
      CheckRunConclusion.cancelled || CheckRunConclusion.stale => (
        AppIcons.circleSlash,
        t.fgTertiary,
        l10n.checkCancelled,
      ),
      _ => (AppIcons.circleDot, t.fgTertiary, l10n.checkSkipped),
    };
  }
}
