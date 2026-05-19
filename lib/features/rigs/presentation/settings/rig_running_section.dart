import 'dart:async';

import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/rig_labels.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
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
          // Resident memory, not a machine count: a parked VM frees CPU and
          // keeps every byte of its RAM, so megabytes are what the LRU counts
          // and what an operator is actually deciding about.
          final residentMb = live.fold<int>(0, (sum, r) => sum + r.memoryMb);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsSummary(
                facts: [
                  SettingsFact(
                    label: l10n.rigsRunningTitle,
                    value: '${live.length}',
                    tone: CcStatusTone.positive,
                  ),
                  SettingsFact(
                    label: l10n.rigsResidentMemory,
                    value: '$residentMb MB',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (final rig in live)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
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
    final l10n = AppLocalizations.of(context);
    return SettingsEntityRow(
      padding: EdgeInsets.zero,
      title: rigSurfaceLabel(l10n, rig.surfaceKind, engine: rig.browserEngine),
      icon: AppIcons.monitor,
      tone: rig.isStarting ? CcStatusTone.caution : CcStatusTone.positive,
      statusLabel: rig.isStarting ? l10n.rigsStarting : l10n.running,
      subtitle: rig.detail,
      meta: [
        SettingsMetaFact(value: rig.backendLabel),
        SettingsMetaFact(value: '${rig.memoryMb} MB'),
      ],
      trailing: CcIconButton(
        icon: AppIcons.power,
        tooltip: l10n.rigStopMachine,
        onPressed: () => unawaited(
          ref.read(rigRepositoryProvider).destroy(workspaceId, rig.id),
        ),
      ),
    );
  }
}
