import 'dart:async';

import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/rig_labels.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The machines running right now, with a way to stop one.
class RunningSection extends ConsumerWidget {
  /// Creates a [RunningSection].
  const RunningSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null || workspaceId.isEmpty) {
      // No workspace is not the empty workspace: `''` opened an unscoped
      // subscription that could only fail, and the section rendered its error
      // state instead of saying nothing.
      return SectionCard(
        label: l10n.rigsRunningTitle,
        child: Text(
          l10n.rigsNoneRunning,
          style: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
      );
    }
    final sessions = ref.watch(rigSessionsProvider(workspaceId));

    return SectionCard(
      label: l10n.rigsRunningTitle,
      child: sessions.when(
        loading: () => const Center(child: CcSpinner()),
        error: (e, _) => Text(
          l10n.failedWithError('$e'),
          style: CcTypography.caption.copyWith(color: t.danger),
        ),
        data: (rigs) {
          final live = rigs.where((r) => r.isLive || r.isStarting).toList();
          if (live.isEmpty) {
            return Text(
              l10n.rigsNoneRunning,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            );
          }
          return Column(
            children: [
              for (final rig in live)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: RunningRow(workspaceId: workspaceId, rig: rig),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One running machine, with a way to stop it.
class RunningRow extends ConsumerWidget {
  /// Creates a [RunningRow].
  const RunningRow({super.key, required this.workspaceId, required this.rig});

  /// The workspace the rig belongs to.
  final String workspaceId;

  /// The machine this row describes.
  final RigView rig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        CcStatusDot(
          tone: rig.isStarting ? CcStatusTone.caution : CcStatusTone.positive,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rigSurfaceLabel(l10n, rig.surfaceKind),
                style: CcTypography.bodySm.copyWith(color: t.textPrimary),
              ),
              Text(
                rig.detail ?? '${rig.backendLabel} · ${rig.memoryMb} MB',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            ],
          ),
        ),
        CcIconButton(
          icon: AppIcons.power,
          tooltip: l10n.rigStopMachine,
          onPressed: () => unawaited(
            ref.read(rigRepositoryProvider).destroy(workspaceId, rig.id),
          ),
        ),
      ],
    );
  }
}
