import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_formatting.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_status_visuals.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Jumps between the runs of ONE pipeline template, newest first.
///
/// A run page answers "what happened here"; the question that follows is
/// almost always "and how is that different from last time" — which run
/// failed, which one was slower, which step's log changed. Without this the
/// only way across was back out to the queue and hunt the same template's rows
/// out of every other pipeline's, which is enough friction that nobody
/// compares. A retry reuses the run's own row (it re-opens the failed steps
/// rather than minting a second run — the superseded tries survive archived on
/// each step row, shown in the step detail and as ghost bars on the
/// waterfall), so what this lists is genuinely different executions, not
/// attempts of one.
class PipelineRunHistoryMenu extends ConsumerWidget {
  /// Creates a [PipelineRunHistoryMenu] for the run currently open.
  const PipelineRunHistoryMenu({super.key, required this.run});

  /// The run the page is showing — excluded from the list and used to scope it
  /// to its own template and workspace.
  final PipelineRun run;

  /// How many sibling runs the menu offers. Past this the queue page, with its
  /// filters, is the right tool — a menu nobody can scan is not a shortcut.
  static const int maxEntries = 15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final now = DateTime.now();

    final siblings =
        (ref.watch(workspacePipelineRunsProvider(run.workspaceId)).value ??
                const <PipelineRun>[])
            .where((r) => r.templateId == run.templateId && r.id != run.id)
            .toList()
          ..sort(
            (a, b) =>
                b.currentAttemptStartedAt.compareTo(a.currentAttemptStartedAt),
          );

    return CcMenu(
      semanticLabel: l10n.pipelineRunHistory,
      minWidth: 240,
      maxWidth: 340,
      targetAnchor: Alignment.bottomRight,
      followerAnchor: Alignment.topRight,
      items: [
        if (siblings.isEmpty)
          CcMenuItem(
            label: l10n.pipelineRunHistoryEmpty,
            enabled: false,
            onSelected: () {},
          )
        else
          for (final r in siblings.take(maxEntries))
            CcMenuItem(
              label: _entryLabel(r, now, l10n),
              icon: pipelineRunStatusIcon(r.status),
              onSelected: () => GoRouter.of(
                context,
              ).go(pipelineRunRoute(r.workspaceId, r.id)),
            ),
      ],
      target: CcTooltip(
        message: l10n.pipelineRunHistory,
        // Inert by construction: CcMenu supplies the tap, and a target that
        // handles its own would swallow the toggle.
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: t.borderSecondary),
            borderRadius: AppRadii.brSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.clock, size: 14, color: t.fgSecondary),
              const SizedBox(width: 4),
              Icon(AppIcons.chevronDown, size: 14, color: t.fgQuaternary),
            ],
          ),
        ),
      ),
    );
  }

  /// One row: status, when it started, how long it was active. Everything the
  /// operator needs to pick the run worth comparing against, in one line.
  String _entryLabel(PipelineRun r, DateTime now, AppLocalizations l10n) {
    final started = formatPipelineRelative(
      r.currentAttemptStartedAt,
      now,
      l10n,
    );
    final duration = formatPipelineDurationCoarse(r.activeDurationAt(now));
    return '${pipelineRunStatusLabel(r.status, l10n)} · $started · $duration';
  }
}
