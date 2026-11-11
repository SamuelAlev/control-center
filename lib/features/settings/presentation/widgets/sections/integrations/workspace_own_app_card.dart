import 'package:cc_domain/core/domain/value_objects/workspace_connect_mode.dart';
import 'package:control_center/features/connect/providers/workspace_connect_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/workspace_provider_app_detail.dart';
import 'package:control_center/features/settings/providers/workspace_provider_apps_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The workspace's own [provider] app (`google` or `linear`), right after
/// that provider's section on Workspace → Integrations.
///
/// Only while the workspace uses its own apps: in every other mode the app
/// is not used, so a form for it would be a setting that does nothing.
/// Admin-only (the list resolves empty for anyone else, and in the demo).
/// Shown while [watchWorkspaceOwnAppApplies] holds for [provider].
class WorkspaceOwnAppCard extends ConsumerWidget {
  /// Creates the card for [provider].
  const WorkspaceOwnAppCard({super.key, required this.provider});

  /// The provider's wire id.
  final String provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = workspaceProviderAppFor(
      ref.watch(workspaceProviderAppsProvider).value,
      provider,
    );
    if (app == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final name = workspaceProviderAppName(provider);
    return SectionCard(
      label: l10n.workspaceOwnAppTitle(name),
      subtitle: Text(l10n.workspaceOwnAppDescription(name)),
      child: WorkspaceProviderAppDetail(app: app),
    );
  }
}

/// Whether [WorkspaceOwnAppCard] applies to [provider]: inside a workspace
/// on its own apps, while the reader can see that app.
bool watchWorkspaceOwnAppApplies(WidgetRef ref, String provider) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  return workspaceId != null &&
      ref.watch(workspaceConnectModeProvider(workspaceId)) ==
          WorkspaceConnectMode.own &&
      workspaceProviderAppFor(
            ref.watch(workspaceProviderAppsProvider).value,
            provider,
          ) !=
          null;
}

/// [provider]'s entry in [apps], or null.
WorkspaceProviderAppView? workspaceProviderAppFor(
  List<WorkspaceProviderAppView>? apps,
  String provider,
) {
  for (final app in apps ?? const <WorkspaceProviderAppView>[]) {
    if (app.provider == provider) {
      return app;
    }
  }
  return null;
}
