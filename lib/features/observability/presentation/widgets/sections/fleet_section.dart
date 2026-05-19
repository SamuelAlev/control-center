import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/providers/fleet_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The fleet panel (PRD 20 §7): a live view of the workers that can run jobs and
/// the jobs currently distributed across them, with worker lifecycle actions.
/// A thin client surface — every action is forwarded to `cc_server` over the
/// `fleet.*` RPC ops via [RpcFleetClient]. Non-scrolling; the parent tab owns
/// the scroll view.
class FleetSection extends ConsumerWidget {
  /// Creates a [FleetSection].
  const FleetSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WorkersSection(),
        SizedBox(height: AppSpacing.lg),
        _JobsSection(),
      ],
    );
  }
}

/// The WORKERS section: one tile per [FleetWorkerView].
class _WorkersSection extends ConsumerWidget {
  const _WorkersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workers = ref.watch(fleetWorkersProvider);
    return ObsSection(
      title: l10n.fleetWorkersTitle,
      subtitle: l10n.fleetWorkersSubtitle,
      icon: AppIcons.boxes,
      child: workers.when(
        data: (list) => list.isEmpty
            ? _EmptyLine(text: l10n.fleetNoWorkers)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0) const CcDivider(),
                    _WorkerTile(worker: list[i]),
                  ],
                ],
              ),
        loading: () => const _LoadingLine(),
        error: (_, _) => _EmptyLine(text: l10n.fleetError),
      ),
    );
  }
}

/// A single worker: name + status, platform/cores, capability chips, last
/// heartbeat, an optional last-error line, and lifecycle actions.
class _WorkerTile extends ConsumerWidget {
  const _WorkerTile({required this.worker});

  final FleetWorkerView worker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final name = worker.name.isNotEmpty ? worker.name : worker.id;
    final heartbeat = worker.lastHeartbeatAt != null
        ? l10n.fleetHeartbeat(
            formatRelativeTime(context, worker.lastHeartbeatAt),
          )
        : l10n.fleetNoHeartbeat;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: CcTypography.bodySm.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CcStatusTag(
                label: _workerStatusLabel(l10n, worker.status),
                tone: _workerStatusTone(worker.status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${worker.platform} · ${l10n.fleetCores(worker.cores)}',
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          if (worker.capabilityKeys.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final cap in worker.capabilityKeys) CcChip(label: cap),
              ],
            ),
          ],
          if (worker.lastError != null && worker.lastError!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.alertTriangle, size: 12, color: t.danger),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.fleetLastErrorLabel(worker.lastError!),
                    style: CcTypography.caption.copyWith(color: t.danger),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          if (worker.lastHeartbeatAt != null)
            AppTimestamp(
              dateTime: worker.lastHeartbeatAt!,
              child: Text(
                heartbeat,
                style: CcTypography.caption.copyWith(color: t.textQuaternary),
              ),
            )
          else
            Text(
              heartbeat,
              style: CcTypography.caption.copyWith(color: t.textQuaternary),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _actions(context, ref, l10n),
          ),
        ],
      ),
    );
  }

  List<Widget> _actions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final client = ref.read(rpcFleetClientProvider);
    final status = worker.status;
    final isOnline = status == 'online';
    final isDraining = status == 'draining';
    final isRevoked = status == 'revoked';
    return [
      if (isOnline)
        CcButton(
          size: CcButtonSize.sm,
          variant: CcButtonVariant.secondary,
          icon: AppIcons.pause,
          onPressed: () =>
              _run(context, l10n, () => client.drainWorker(worker.id)),
          child: Text(l10n.fleetDrain),
        ),
      if (isDraining)
        CcButton(
          size: CcButtonSize.sm,
          variant: CcButtonVariant.secondary,
          icon: AppIcons.play,
          onPressed: () =>
              _run(context, l10n, () => client.resumeWorker(worker.id)),
          child: Text(l10n.fleetResume),
        ),
      if (!isRevoked && (isOnline || isDraining))
        CcButton(
          size: CcButtonSize.sm,
          variant: CcButtonVariant.secondary,
          icon: AppIcons.ban,
          onPressed: () => _confirmAndRun(
            context,
            l10n,
            title: l10n.fleetRevokeTitle,
            body: l10n.fleetRevokeBody(
              worker.name.isNotEmpty ? worker.name : worker.id,
            ),
            confirmLabel: l10n.fleetRevoke,
            action: () => client.revokeWorker(worker.id),
          ),
          child: Text(l10n.fleetRevoke),
        ),
      CcButton(
        size: CcButtonSize.sm,
        variant: CcButtonVariant.destructive,
        icon: AppIcons.trash2,
        onPressed: () => _confirmAndRun(
          context,
          l10n,
          title: l10n.fleetRemoveTitle,
          body: l10n.fleetRemoveBody(
            worker.name.isNotEmpty ? worker.name : worker.id,
          ),
          confirmLabel: l10n.fleetRemove,
          action: () => client.removeWorker(worker.id),
        ),
        child: Text(l10n.fleetRemove),
      ),
    ];
  }
}

/// The JOBS section: one expandable row per [FleetJobView].
class _JobsSection extends ConsumerWidget {
  const _JobsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final jobs = ref.watch(fleetJobsProvider);
    // Resolve worker ids to names for the job rows (best-effort; falls back to
    // the id when the worker list has not loaded).
    final names = <String, String>{
      for (final w
          in ref.watch(fleetWorkersProvider).asData?.value ??
              const <FleetWorkerView>[])
        w.id: w.name.isNotEmpty ? w.name : w.id,
    };
    return ObsSection(
      title: l10n.fleetJobsTitle,
      subtitle: l10n.fleetJobsSubtitle,
      icon: AppIcons.workflow,
      child: jobs.when(
        data: (list) => list.isEmpty
            ? _EmptyLine(text: l10n.fleetNoJobs)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0) const CcDivider(),
                    _JobRow(job: list[i], workerNames: names),
                  ],
                ],
              ),
        loading: () => const _LoadingLine(),
        error: (_, _) => _EmptyLine(text: l10n.fleetError),
      ),
    );
  }
}

/// A job row that expands to reveal its placement decisions.
class _JobRow extends StatefulWidget {
  const _JobRow({required this.job, required this.workerNames});

  final FleetJobView job;
  final Map<String, String> workerNames;

  @override
  State<_JobRow> createState() => _JobRowState();
}

class _JobRowState extends State<_JobRow> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final job = widget.job;
    final workerLabel = job.workerId != null
        ? (widget.workerNames[job.workerId] ?? job.workerId!)
        : l10n.fleetJobUnassigned;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CcTappable(
            onPressed: _toggle,
            borderRadius: AppRadii.brSm,
            semanticLabel: job.kind,
            builder: (context, states) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.workflow, size: 16, color: t.fgSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.kind,
                            style: CcTypography.bodySm.copyWith(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            workerLabel,
                            style: CcTypography.caption.copyWith(
                              color: t.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    CcStatusTag(
                      label: _jobStatusLabel(l10n, job.status),
                      tone: _jobStatusTone(job.status),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      fmtCents(job.costCents),
                      style: CcTypography.monoNum.copyWith(
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AnimatedRotation(
                      duration: CcMotion.normal,
                      curve: CcMotion.standard,
                      turns: _expanded ? 0 : -0.25,
                      child: Icon(
                        AppIcons.chevronDown,
                        size: 14,
                        color: t.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final cap in job.requiredCaps) CcChip(label: cap),
                    Text(
                      l10n.fleetJobAttempts(job.attempts, job.maxAttempts),
                      style: CcTypography.caption.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: CcMotion.resolve(context, CcMotion.normal),
            curve: CcMotion.standard,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      top: AppSpacing.sm,
                    ),
                    child: _Placements(jobId: job.id),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// The placement-decision log for a job, shown when its row is expanded.
class _Placements extends ConsumerWidget {
  const _Placements({required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final placements = ref.watch(fleetPlacementsProvider(jobId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.fleetPlacementReasons,
          style: CcTypography.label.copyWith(color: t.textTertiary),
        ),
        const SizedBox(height: AppSpacing.xs),
        placements.when(
          data: (list) => list.isEmpty
              ? _EmptyLine(text: l10n.fleetNoPlacements)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in list)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xxs,
                        ),
                        child: Text(
                          '${p.decision} · ${p.reason}',
                          style: CcTypography.caption.copyWith(
                            color: t.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
          loading: () => const _LoadingLine(),
          error: (_, _) => _EmptyLine(text: l10n.fleetError),
        ),
      ],
    );
  }
}

/// A muted, centered spinner used while a section's data resolves.
class _LoadingLine extends StatelessWidget {
  const _LoadingLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(child: CcSpinner()),
    );
  }
}

/// A muted single-line hint used for empty / error states inside a section.
class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Text(
      text,
      style: CcTypography.bodySm.copyWith(color: t.textTertiary),
    );
  }
}

CcStatusTone _workerStatusTone(String status) => switch (status) {
  'online' => CcStatusTone.positive,
  'draining' => CcStatusTone.caution,
  'revoked' => CcStatusTone.negative,
  _ => CcStatusTone.neutral,
};

String _workerStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'online' => l10n.fleetStatusOnline,
      'draining' => l10n.fleetStatusDraining,
      'offline' => l10n.fleetStatusOffline,
      'incompatible' => l10n.fleetStatusIncompatible,
      'revoked' => l10n.fleetStatusRevoked,
      _ => status,
    };

CcStatusTone _jobStatusTone(String status) => switch (status) {
  'running' => CcStatusTone.info,
  'succeeded' || 'completed' => CcStatusTone.positive,
  'failed' => CcStatusTone.negative,
  _ => CcStatusTone.neutral,
};

String _jobStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'queued' => l10n.fleetJobStatusQueued,
      'running' => l10n.fleetJobStatusRunning,
      'succeeded' || 'completed' => l10n.fleetJobStatusSucceeded,
      'failed' => l10n.fleetJobStatusFailed,
      'cancelled' || 'canceled' => l10n.fleetJobStatusCancelled,
      _ => status,
    };

/// Runs [action], surfacing a toast on failure. Fleet streams update on their
/// own, so success needs no acknowledgement.
Future<void> _run(
  BuildContext context,
  AppLocalizations l10n,
  Future<void> Function() action,
) async {
  try {
    await action();
  } on Object {
    if (context.mounted) {
      CcToastScope.maybeOf(
        context,
      )?.show(l10n.fleetActionFailed, variant: CcToastVariant.danger);
    }
  }
}

/// Confirms a destructive action in a [CcDialog], then runs it via [_run].
Future<void> _confirmAndRun(
  BuildContext context,
  AppLocalizations l10n, {
  required String title,
  required String body,
  required String confirmLabel,
  required Future<void> Function() action,
}) async {
  final confirmed = await showCcDialog<bool>(
    context: context,
    builder: (ctx) => CcDialog(
      title: title,
      content: Text(body),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        CcButton(
          variant: CcButtonVariant.destructive,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  await _run(context, l10n, action);
}
