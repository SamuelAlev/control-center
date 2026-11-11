import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/connect/presentation/settings/workspace_connect_status_card.dart';
import 'package:control_center/features/connect/providers/workspace_connect_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Workspace → Integrations: whose apps this workspace signs
/// people in through, mirroring the server's Connect card.
///
/// "Same as this server" follows the server owner's choice; the other three
/// override it for this workspace only. Every member sees the choice and
/// where each sign-in runs; only an admin changes it, and only an admin sees
/// the install id. A demo server has no Connect, so it says so instead.
/// Shown while [watchWorkspaceConnectApplies] holds.
class WorkspaceConnectSection extends ConsumerWidget {
  /// Creates a [WorkspaceConnectSection].
  const WorkspaceConnectSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (ref.watch(isDemoServerProvider)) {
      return SectionCard(
        label: l10n.connectTitle,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: DemoUnavailable(
            capability: DemoCapability.forge,
            compact: true,
          ),
        ),
      );
    }
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final async = ref.watch(workspaceConnectStatusProvider(workspaceId));
    if (async.hasError && !async.hasValue) {
      return SectionCard(
        label: l10n.connectTitle,
        child: CcAlert(
          title: l10n.failedWithError('${async.error}'),
          variant: CcAlertVariant.danger,
        ),
      );
    }
    final status = async.value;
    if (status == null) {
      return const SizedBox.shrink();
    }
    return WorkspaceConnectStatusCard(
      key: ValueKey(workspaceId),
      workspaceId: workspaceId,
      status: status,
      canEdit:
          ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false,
    );
  }
}

/// Whether [WorkspaceConnectSection] has anything to show: always on a demo
/// server (which says it has no Connect); elsewhere, inside a workspace, once
/// its Connect choice has arrived or failed to.
bool watchWorkspaceConnectApplies(WidgetRef ref) {
  if (ref.watch(isDemoServerProvider)) {
    return true;
  }
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return false;
  }
  final async = ref.watch(workspaceConnectStatusProvider(workspaceId));
  return async.value != null || (async.hasError && !async.hasValue);
}
