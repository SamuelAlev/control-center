import 'dart:async';

import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/features/environments/presentation/settings/environment_worktree_runs.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_labels.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runs a throwaway environment end to end and shows its output as it goes.
class EnvironmentTestPanel extends ConsumerStatefulWidget {
  /// Creates an [EnvironmentTestPanel].
  const EnvironmentTestPanel({super.key, required this.form});

  /// The draft.
  final EnvironmentForm form;

  @override
  ConsumerState<EnvironmentTestPanel> createState() =>
      _EnvironmentTestPanelState();
}

class _EnvironmentTestPanelState extends ConsumerState<EnvironmentTestPanel> {
  String? _runId;
  bool _starting = false;

  Future<void> _run(String definitionId) async {
    final toasts = CcToastScope.maybeOf(context);
    setState(() => _starting = true);
    try {
      final runId = await ref
          .read(environmentRepositoryProvider)
          .testDefinition(widget.form.workspaceId, definitionId);
      if (mounted) {
        setState(() => _runId = runId);
      }
    } on Object catch (error) {
      toasts?.show(
        environmentFailureMessage(error),
        variant: CcToastVariant.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final record = widget.form.state.record;
    final dirty = widget.form.state.dirty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.environmentsTestHelp,
            style: CcTypography.bodySm.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (record == null || dirty)
            Text(
              l10n.environmentsTestSaveFirst,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            )
          else ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CcButton(
                size: CcButtonSize.sm,
                icon: AppIcons.play,
                loading: _starting,
                onPressed: _starting || !widget.form.enabled
                    ? null
                    : () => unawaited(_run(record.id)),
                child: Text(l10n.environmentsRunTest),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Runs(
              runKey: (
                workspaceId: widget.form.workspaceId,
                definitionId: record.id,
              ),
              runId: _runId,
            ),
            const SizedBox(height: AppSpacing.lg),
            EnvironmentWorktreeRuns(
              runKey: (
                workspaceId: widget.form.workspaceId,
                definitionId: record.id,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Runs extends ConsumerWidget {
  const _Runs({required this.runKey, required this.runId});

  final EnvironmentDefinitionKey runKey;
  final String? runId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final runs =
        ref.watch(environmentDefinitionRunsProvider(runKey)).value ??
        const <EnvironmentRun>[];
    final tests = runs.where((run) => run.kind == EnvironmentRunKind.test);
    final run =
        tests.firstWhereOrNull((run) => run.id == runId) ?? tests.firstOrNull;
    if (run == null) {
      return Text(
        l10n.environmentsNoRuns,
        style: CcTypography.caption.copyWith(color: t.textTertiary),
      );
    }
    final (label, tone) = environmentRunStatusDisplay(l10n, run.status);
    final error = run.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CcStatusTag(label: label, tone: tone),
            const SizedBox(width: AppSpacing.sm),
            AppTimestamp.relative(
              run.startedAt,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              error,
              style: CcTypography.caption.copyWith(color: t.textErrorPrimary),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        // RTL carve-out: command output is a log.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            constraints: const BoxConstraints(minHeight: 120, maxHeight: 360),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: t.bgSecondary,
              border: Border.all(color: t.borderSecondary),
            ),
            child: SingleChildScrollView(
              reverse: true,
              child: Text(
                run.output,
                style: CcFonts.code(
                  textStyle: CcTypography.caption.copyWith(
                    color: t.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
