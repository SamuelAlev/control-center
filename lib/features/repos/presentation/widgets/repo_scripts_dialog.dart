import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/repo_script_run.dart';
import 'package:cc_domain/core/domain/value_objects/repo_scripts.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/providers.dart';

import 'package:control_center/features/repos/providers/repo_script_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Shows the per-repo lifecycle scripts editor: a setup script and an archive
/// script (server-executed shell — see `RepoScripts`), plus the recorded run
/// history with each run's bounded output tail. Saving writes through
/// `repos.setScripts` (admin-gated on the server).
Future<void> showRepoScriptsDialog(
  BuildContext context, {
  required String workspaceId,
  required Repo repo,
}) {
  return showCcDialog<void>(
    context: context,
    builder: (_) => _RepoScriptsDialog(workspaceId: workspaceId, repo: repo),
  );
}

class _RepoScriptsDialog extends ConsumerStatefulWidget {
  const _RepoScriptsDialog({required this.workspaceId, required this.repo});

  final String workspaceId;
  final Repo repo;

  @override
  ConsumerState<_RepoScriptsDialog> createState() => _RepoScriptsDialogState();
}

class _RepoScriptsDialogState extends ConsumerState<_RepoScriptsDialog> {
  TextEditingController? _setup;
  TextEditingController? _archive;
  bool _saving = false;

  /// The lifecycle slot whose test run is in flight (drives that section's
  /// button spinner). Cleared when the run row the test minted leaves
  /// `running` — the run list below is the live feedback surface.
  RepoScriptKind? _testing;

  /// The run id the in-flight test minted.
  String? _testRunId;

  @override
  void dispose() {
    _setup?.dispose();
    _archive?.dispose();
    super.dispose();
  }

  Future<void> _test(RepoScriptKind kind) async {
    final body = (kind == RepoScriptKind.setup ? _setup?.text : _archive?.text)
        ?.trim();
    if (body == null || body.isEmpty) {
      return;
    }
    final toasts = CcToastScope.maybeOf(context);
    setState(() => _testing = kind);
    try {
      final runId = await ref
          .read(repoScriptRepositoryProvider)
          .testScript(widget.workspaceId, widget.repo.id, kind, body);
      if (mounted) {
        setState(() => _testRunId = runId);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _testing = null;
          _testRunId = null;
        });
      }
      toasts?.show(e.toString(), variant: CcToastVariant.danger);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final toasts = CcToastScope.maybeOf(context);
    try {
      await ref
          .read(repoScriptRepositoryProvider)
          .setScripts(
            widget.workspaceId,
            widget.repo.id,
            RepoScripts(setup: _setup?.text, archive: _archive?.text),
          );
      ref.invalidate(
        repoScriptsProvider((
          workspaceId: widget.workspaceId,
          repoId: widget.repo.id,
        )),
      );
      toasts?.show(l10n.repoScriptsSaved, variant: CcToastVariant.success);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      // Keep the dialog open so the editor's contents survive the failure.
      toasts?.show(e.toString(), variant: CcToastVariant.danger);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDemo = ref.watch(isDemoServerProvider);
    final scriptsAsync = ref.watch(
      repoScriptsProvider((
        workspaceId: widget.workspaceId,
        repoId: widget.repo.id,
      )),
    );
    // The test's spinner clears when ITS run row reaches a terminal state —
    // the same stream the run list renders, so button and list can't disagree.
    ref.listen(
      repoScriptRunsProvider((
        workspaceId: widget.workspaceId,
        repoId: widget.repo.id,
      )),
      (_, next) {
        final testRunId = _testRunId;
        if (testRunId == null) {
          return;
        }
        final run = next.value?.where((r) => r.id == testRunId).firstOrNull;
        if (run != null && !run.isRunning) {
          setState(() {
            _testing = null;
            _testRunId = null;
          });
        }
      },
    );

    return CcDialog(
      title: '${l10n.repoScriptsTitle} — ${widget.repo.name}',
      content: SizedBox(
        width: 560,
        child: scriptsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CcSpinner()),
          ),
          error: (Object e, StackTrace _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              e.toString(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          data: (scripts) {
            // Seed the controllers once; later provider emissions (e.g. our
            // own invalidate after save) must not clobber what the user is
            // typing.
            _setup ??= TextEditingController(text: scripts.setup ?? '');
            _archive ??= TextEditingController(text: scripts.archive ?? '');
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.repoScriptsEnvHelp,
                    style: CcTypography.caption.copyWith(
                      color: context.designSystem?.textTertiary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // demo: the dialog stays (it is part of the tour of the
                  // product), but scripts never run and never save — both
                  // execute on the server host, which a demo does not have.
                  _ScriptSection(
                    label: l10n.repoScriptsSetupLabel,
                    help: l10n.repoScriptsSetupHelp,
                    controller: _setup!,
                    hintText: l10n.repoScriptsSetupPlaceholder,
                    onTest: isDemo ? null : (_testing == null
                        ? () => _test(RepoScriptKind.setup)
                        : null),
                    testing: _testing == RepoScriptKind.setup,
                  ),
                  const SizedBox(height: 16),
                  _ScriptSection(
                    label: l10n.repoScriptsArchiveLabel,
                    help: l10n.repoScriptsArchiveHelp,
                    controller: _archive!,
                    hintText: l10n.repoScriptsArchivePlaceholder,
                    onTest: isDemo ? null : (_testing == null
                        ? () => _test(RepoScriptKind.archive)
                        : null),
                    testing: _testing == RepoScriptKind.archive,
                  ),
                  const SizedBox(height: 20),
                  _RunsSection(
                    workspaceId: widget.workspaceId,
                    repoId: widget.repo.id,
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        CcButton(
          onPressed:
              _saving
                  ? null
                  : () => Navigator.of(context, rootNavigator: true).pop(),
          variant: CcButtonVariant.ghost,
          child: Text(AppLocalizations.of(context).cancel),
        ),
        CcTooltip(
          message: isDemo
              ? AppLocalizations.of(context).demoReadOnlySave
              : '',
          child: CcButton(
            onPressed: (!isDemo && !_saving) ? _save : null,
            child:
                _saving
                    ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CcSpinner(size: 14),
                    )
                    : Text(AppLocalizations.of(context).save),
          ),
        ),
      ],
    );
  }
}

class _ScriptSection extends StatefulWidget {
  const _ScriptSection({
    required this.label,
    required this.help,
    required this.controller,
    required this.hintText,
    this.onTest,
    this.testing = false,
  });

  final String label;
  final String help;
  final TextEditingController controller;
  final String hintText;

  /// Starts a test run of the CURRENT DRAFT (unsaved edits included) in a
  /// throwaway clone of the repo. Null while another test is in flight (one
  /// at a time — the clone is a whole copy of the checkout).
  final VoidCallback? onTest;

  /// Whether this section's test run is executing (button spinner).
  final bool testing;

  @override
  State<_ScriptSection> createState() => _ScriptSectionState();
}

class _ScriptSectionState extends State<_ScriptSection> {
  bool _hasDraft = false;

  @override
  void initState() {
    super.initState();
    _hasDraft = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onDraftChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onDraftChanged);
    super.dispose();
  }

  void _onDraftChanged() {
    final hasDraft = widget.controller.text.trim().isNotEmpty;
    if (hasDraft != _hasDraft) {
      setState(() => _hasDraft = hasDraft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: CcTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ds?.textPrimary,
                ),
              ),
            ),
            if (widget.onTest != null)
              CcTooltip(
                message: l10n.repoScriptsTestTooltip,
                child: CcButton(
                  icon: AppIcons.play,
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  onPressed:
                      (widget.onTest != null && _hasDraft && !widget.testing)
                      ? widget.onTest
                      : null,
                  loading: widget.testing,
                  child: Text(l10n.repoScriptsTest),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.help,
          style: CcTypography.caption.copyWith(
            color: ds?.textTertiary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: ds?.bgSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ds?.borderSecondary ?? const Color(0x22000000),
            ),
          ),
          child: CcTextField(
            controller: widget.controller,
            minLines: 4,
            maxLines: 10,
            textStyle: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: ds?.textPrimary,
            ),
            hintText: widget.hintText,
            chromeless: true,
          ),
        ),
      ],
    );
  }
}

class _RunsSection extends ConsumerWidget {
  const _RunsSection({required this.workspaceId, required this.repoId});

  final String workspaceId;
  final String repoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final runsAsync = ref.watch(
      repoScriptRunsProvider((workspaceId: workspaceId, repoId: repoId)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.repoScriptsRecentRuns,
          style: CcTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: context.designSystem?.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        runsAsync.when(
          loading: () => const Center(child: CcSpinner(size: 16)),
          error: (Object e, StackTrace _) => Text(
            e.toString(),
            style: CcTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          data: (runs) {
            if (runs.isEmpty) {
              return Text(
                l10n.repoScriptsNoRuns,
                style: CcTypography.caption.copyWith(
                  color: context.designSystem?.textTertiary,
                ),
              );
            }
            return Column(
              children: [for (final run in runs) _RunRow(run: run)],
            );
          },
        ),
      ],
    );
  }
}

class _RunRow extends StatefulWidget {
  const _RunRow({required this.run});

  final RepoScriptRun run;

  @override
  State<_RunRow> createState() => _RunRowState();
}

class _RunRowState extends State<_RunRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem;
    final run = widget.run;
    final duration =
        run.completedAt?.difference(run.startedAt) ?? Duration.zero;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CcBadge(
                label: switch (run.kind) {
                  RepoScriptKind.setup => l10n.repoScriptsRunKindSetup,
                  RepoScriptKind.archive => l10n.repoScriptsRunKindArchive,
                  RepoScriptKind.test => l10n.repoScriptsRunKindTest,
                },
              ),
              const SizedBox(width: 8),
              CcBadge(
                label: switch (run.status) {
                  RepoScriptRunStatus.running => l10n
                      .repoScriptsRunStatusRunning,
                  RepoScriptRunStatus.succeeded => l10n
                      .repoScriptsRunStatusSucceeded,
                  RepoScriptRunStatus.failed => l10n.repoScriptsRunStatusFailed,
                  RepoScriptRunStatus.timedOut => l10n
                      .repoScriptsRunStatusTimedOut,
                },
                variant: switch (run.status) {
                  RepoScriptRunStatus.succeeded => CcBadgeVariant.success,
                  RepoScriptRunStatus.failed ||
                  RepoScriptRunStatus.timedOut => CcBadgeVariant.danger,
                  RepoScriptRunStatus.running => CcBadgeVariant.neutral,
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${DateFormat.Hm().format(run.startedAt)} · ${_formatDuration(duration)}'
                  '${run.exitCode != null ? ' · ${l10n.repoScriptsExitCode(run.exitCode!)}' : ''}'
                  '${run.spaceId != null ? ' · ${run.spaceId}' : ''}',
                  style: CcTypography.caption.copyWith(
                    color: ds?.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (run.output.isNotEmpty)
                CcButton(
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  onPressed:
                      () => setState(() => _expanded = !_expanded),
                  child: Icon(
                    _expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                    size: 14,
                    color: ds?.fgTertiary,
                  ),
                ),
            ],
          ),
          if (_expanded && run.output.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ds?.bgSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ds?.borderSecondary ?? const Color(0x22000000)),
              ),
              child: SelectionArea(
                child: Text(
                  run.output,
                  style: TextStyle(
                    fontFamily: CcFonts.codeFamily,
                    fontSize: 12,
                    height: 1.45,
                    color: ds?.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDuration(Duration d) {
  if (d.inHours > 0) {
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }
  if (d.inMinutes > 0) {
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }
  return '${d.inSeconds}s';
}
