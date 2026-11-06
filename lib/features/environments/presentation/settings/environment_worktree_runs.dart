import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_run_row.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Recent provision and archive runs of a definition.
class EnvironmentWorktreeRuns extends ConsumerWidget {
  /// Creates an [EnvironmentWorktreeRuns].
  const EnvironmentWorktreeRuns({super.key, required this.runKey});

  /// The definition whose runs to list.
  final EnvironmentDefinitionKey runKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final caption = CcTypography.caption.copyWith(color: t.textTertiary);
    // A worktree task runs for a repo, not an environment.
    final runs = [
      for (final run
          in ref.watch(environmentDefinitionRunsProvider(runKey)).value ??
              const <EnvironmentRun>[])
        if (run.kind == EnvironmentRunKind.task &&
            run.repoId != null &&
            run.environmentId == null)
          run,
    ].take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.environmentsWorktreeRuns,
          style: CcTypography.bodySm.copyWith(
            color: t.textPrimary,
            fontWeight: CcTypography.semiboldWeight,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (runs.isEmpty) Text(l10n.environmentsNoWorktreeRuns, style: caption),
        for (final run in runs) EnvironmentRunRow(run: run),
      ],
    );
  }
}
