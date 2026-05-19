import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/repos/providers/repo_index_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compact per-repo "index code" action: a button that starts the `index_code`
/// pipeline, becomes a small progress loader (N/M files) while it runs, then a
/// status icon — indexed ✓ / grammars-missing ⚠ / failed ⚠. Tapping re-runs.
class RepoIndexButton extends ConsumerStatefulWidget {
  /// Creates a [RepoIndexButton].
  const RepoIndexButton({
    required this.repo,
    required this.workspaceId,
    super.key,
  });

  /// The repo to index.
  final Repo repo;

  /// Workspace whose `index_code` template to run.
  final String workspaceId;

  @override
  ConsumerState<RepoIndexButton> createState() => _RepoIndexButtonState();
}

class _RepoIndexButtonState extends ConsumerState<RepoIndexButton> {
  static const String _templateId = 'index_code';

  String? _runId;
  bool _starting = false;

  Future<void> _start() async {
    if (_starting) {
      return;
    }
    setState(() => _starting = true);
    try {
      final run = await ref
          .read(pipelineEngineProvider)
          .start(
            _templateId,
            workspaceId: widget.workspaceId,
            triggerEventType: 'RepoAdded',
            triggerPayload: {
              'repoId': widget.repo.id,
              'repoLocalPath': widget.repo.path,
            },
            dedupKey: widget.repo.id,
          );
      // Dedup: a run is already active for this repo — attach to it.
      final runId =
          run?.id ??
          (await ref
                  .read(pipelineRunRepositoryProvider)
                  .activeForDedupKey(
                    templateId: _templateId,
                    workspaceId: widget.workspaceId,
                    dedupKey: widget.repo.id,
                  ))
              ?.id;
      if (mounted) {
        setState(() {
          _runId = runId;
          _starting = false;
        });
      }
    } on Object catch (e, st) {
      AppLog.e('RepoIndex', 'failed to start indexing ${widget.repo.id}', e, st);
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  Future<void> _cancel() async {
    final runId = _runId;
    if (runId == null) {
      return;
    }
    await ref.read(pipelineEngineProvider).cancel(runId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;

    Widget idleButton() => _IconAction(
      icon: AppIcons.scanSearch,
      color: tokens?.textTertiary ?? const Color(0xFF656D76),
      tooltip: l10n.indexCode,
      onPress: _start,
    );

    if (_starting && _runId == null) {
      return const SizedBox(width: 14, height: 14, child: CcSpinner());
    }

    final runId = _runId;
    if (runId == null) {
      return idleButton();
    }

    final run = ref.watch(pipelineRunProvider(runId)).asData?.value;

    // Run loading, or actively running → progress loader.
    if (run == null || !run.isTerminal) {
      final progress = ref.watch(repoIndexProgressProvider(runId)).asData?.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 14, height: 14, child: CcSpinner()),
          if (progress != null && progress.total > 0) ...[
            const SizedBox(width: 6),
            Text(
              '${progress.done}/${progress.total}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens?.textTertiary ?? const Color(0xFF656D76),
              ),
            ),
          ],
          _IconAction(
            icon: AppIcons.x,
            color: tokens?.textTertiary ?? const Color(0xFF656D76),
            tooltip: l10n.cancel,
            onPress: _cancel,
          ),
        ],
      );
    }

    // Cancelled → offer to run again.
    if (run.status == PipelineRunStatus.cancelled) {
      return idleButton();
    }

    final summary = run.state['indexSummary'];
    final nativeAvailable = summary is Map && summary['nativeAvailable'] == true;
    final symbols = summary is Map && summary['symbols'] is int
        ? summary['symbols'] as int
        : 0;

    if (run.status == PipelineRunStatus.completed && nativeAvailable) {
      return _IconAction(
        icon: AppIcons.circleCheck,
        color: tokens?.textPrimary ?? const Color(0xFF1A1A1A),
        tooltip: l10n.indexedSymbolsCount(symbols),
        onPress: _start,
      );
    }
    if (run.status == PipelineRunStatus.completed) {
      // Completed but nothing indexed — grammars aren't installed.
      return _IconAction(
        icon: AppIcons.triangleAlert,
        color: tokens?.warn ?? Colors.amber.shade700,
        tooltip: l10n.indexNoGrammars,
        onPress: _start,
      );
    }

    // Failed.
    return _IconAction(
      icon: AppIcons.triangleAlert,
      color: Theme.of(context).colorScheme.error,
      tooltip: l10n.indexFailed,
      onPress: _start,
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPress,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: CcButton(
        variant: CcButtonVariant.ghost,
        size: CcButtonSize.sm,
        onPressed: onPress,
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
