import 'dart:async';

import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/environment_setup_prompt.dart';
import 'package:control_center/features/environments/presentation/settings/environment_definition_delete.dart';
import 'package:control_center/features/environments/presentation/settings/environment_editor_state.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The workspace's definitions.
class EnvironmentDefinitionList extends ConsumerWidget {
  /// Creates an [EnvironmentDefinitionList].
  const EnvironmentDefinitionList({
    super.key,
    required this.definitions,
    required this.workspaceId,
  });

  /// What the server holds.
  final AsyncValue<List<EnvironmentDefinitionRecord>> definitions;

  /// The owning workspace.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return definitions.when(
      loading: () => const Center(child: CcSpinner()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: CcAlert(
          variant: CcAlertVariant.danger,
          title: environmentFailureMessage(error),
        ),
      ),
      data: (records) => records.isEmpty
          ? CcEmptyState(icon: AppIcons.boxes, message: l10n.environmentsEmpty)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: SectionCard(
                label: l10n.environmentsTitle,
                count: records.length,
                padding: EdgeInsets.zero,
                headerPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  14,
                  AppSpacing.lg,
                  0,
                ),
                child: SettingsGroup(
                  separator: SettingsGroupSeparator.rule,
                  children: [
                    for (final record in records)
                      _DefinitionRow(record: record),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Opens on a click. Deleting sits behind hover, and behind a confirmation.
class _DefinitionRow extends ConsumerWidget {
  const _DefinitionRow({required this.record});

  final EnvironmentDefinitionRecord record;

  String _summary(AppLocalizations l10n, EnvironmentDefinition? definition) {
    if (definition == null) {
      return l10n.environmentsUnreadable;
    }
    final placement = switch (definition.placement) {
      EnvironmentPlacement.host => l10n.environmentsPlacementHost,
      EnvironmentPlacement.rig => l10n.environmentsPlacementRig,
    };
    return '${l10n.environmentsComponentCount(definition.components.length)}'
        ' · $placement';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final definition = environmentDefinitionOf(record);
    final isAdmin =
        ref.watch(myWorkspaceRoleProvider(record.workspaceId))?.isAdmin ??
        false;
    final update = record.hasSource
        ? ref
              .watch(
                environmentSourceUpdateProvider((
                  workspaceId: record.workspaceId,
                  definitionId: record.id,
                )),
              )
              .value
        : null;
    return SettingsEntityRow(
      icon: AppIcons.boxes,
      title: record.name,
      subtitle: _summary(l10n, definition),
      tone: update?.hasUpdate == true ? CcStatusTone.caution : null,
      statusLabel: update?.hasUpdate == true
          ? l10n.environmentsUpdateAvailable
          : null,
      onPressed: () => openEnvironmentEditor(
        context,
        ref,
        EnvironmentEditorSeed.record(record),
      ),
      revealTrailing: true,
      trailing: isAdmin
          ? CcIconButton(
              variant: CcButtonVariant.destructive,
              icon: AppIcons.trash2,
              size: CcButtonSize.sm,
              tooltip: l10n.delete,
              onPressed: () => unawaited(
                deleteEnvironmentDefinition(
                  context,
                  ref,
                  workspaceId: record.workspaceId,
                  id: record.id,
                  name: record.name,
                ),
              ),
            )
          : null,
    );
  }
}
