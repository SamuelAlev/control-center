import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/workspace_provider_app_detail.dart';
import 'package:control_center/features/settings/providers/provider_apps_providers.dart';
import 'package:control_center/features/settings/providers/workspace_provider_apps_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Workspace → General: which Google Calendar, Linear and Klipy
/// apps this workspace uses, beside its GitHub identity.
///
/// Admin-only (the list resolves empty for anyone else, and in the demo).
/// Each provider either uses this server's lane (its own app, else Control
/// Center Connect) or the workspace's own app, which then is the only one:
/// a half-configured own app turns the provider off here rather than fall
/// back. Secrets are write-only; the card shows whether one is saved.
class WorkspaceProviderAppsCard extends ConsumerStatefulWidget {
  /// Creates a [WorkspaceProviderAppsCard].
  const WorkspaceProviderAppsCard({super.key});

  @override
  ConsumerState<WorkspaceProviderAppsCard> createState() =>
      _WorkspaceProviderAppsCardState();
}

class _WorkspaceProviderAppsCardState
    extends ConsumerState<WorkspaceProviderAppsCard> {
  final _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final apps = ref.watch(workspaceProviderAppsProvider).value ?? const [];
    if (apps.isEmpty) {
      return const SizedBox.shrink();
    }
    return SectionCard(
      label: l10n.workspaceProviderApps,
      subtitle: Text(l10n.workspaceProviderAppsDescription),
      padding: const EdgeInsets.only(top: AppSpacing.md),
      headerPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final app in apps) ...[
            const CcDivider(),
            _WorkspaceProviderAppRow(
              app: app,
              expanded: _expanded.contains(app.provider),
              onExpandedChanged: (open) => setState(() {
                if (open) {
                  _expanded.add(app.provider);
                } else {
                  _expanded.remove(app.provider);
                }
              }),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _WorkspaceProviderAppRow extends ConsumerWidget {
  const _WorkspaceProviderAppRow({
    required this.app,
    required this.expanded,
    required this.onExpandedChanged,
  });

  final WorkspaceProviderAppView app;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  /// Switching moves grants to another app, so everyone connected through
  /// the old one signs in again; that is confirmed first. Klipy holds no
  /// grants, so only deleting its saved key asks.
  Future<void> _setMode(
    BuildContext context,
    WidgetRef ref,
    WorkspaceAppMode mode,
  ) async {
    if (mode == app.mode) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final name = workspaceProviderAppName(app.provider);
    final toOwn = mode == WorkspaceAppMode.own;
    final ask = app.provider != 'klipy' || (!toOwn && app.hasAppKey);
    if (ask) {
      final confirmed = await showCcConfirmDialog(
        context: context,
        title: l10n.workspaceProviderAppSwitchTitle(name),
        message: toOwn
            ? l10n.workspaceProviderAppSwitchToOwnBody(name)
            : l10n.workspaceProviderAppSwitchToServerBody(name),
        confirmLabel: l10n.workspaceProviderAppSwitchAction,
        cancelLabel: l10n.cancel,
        danger: true,
      );
      if (!confirmed) {
        return;
      }
    }
    try {
      await setWorkspaceProviderAppMode(ref, app.provider, mode);
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final own = app.mode == WorkspaceAppMode.own;
    final broken = own && app.state != ProviderAppState.complete;
    return SettingsEntityRow(
      title: workspaceProviderAppName(app.provider),
      icon: switch (app.provider) {
        'google' => AppIcons.calendar,
        'klipy' => AppIcons.clapperboard,
        _ => AppIcons.ticket,
      },
      tone: broken
          ? CcStatusTone.negative
          : own
          ? CcStatusTone.positive
          : CcStatusTone.neutral,
      statusLabel: broken
          ? l10n.settingsStateFailed
          : own
          ? l10n.workspaceProviderAppStatusOwn
          : l10n.workspaceProviderAppStatusInherit,
      subtitle: broken
          ? l10n.providerAppPartial
          : own
          ? (app.clientId.isNotEmpty ? app.clientId : l10n.configuredLabel)
          : l10n.workspaceProviderAppModeInherit,
      expanded: expanded,
      onExpandedChanged: onExpandedChanged,
      detail: WorkspaceProviderAppDetail(
        app: app,
        onModeSelected: (mode) => unawaited(_setMode(context, ref, mode)),
      ),
    );
  }
}
