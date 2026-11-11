import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/your_account_line.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the Code hosting group on Workspace → Integrations: the reader's
/// own forge accounts in one line, leading to their profile (You → Profile),
/// where they are managed.
///
/// Lists every forge the reader holds a credential for, working or not, so a
/// lapsed sign-in shows here too; with none, says so. Shown while
/// [watchForgeAccountStatusApplies] holds.
class ForgeAccountStatusLine extends ConsumerWidget {
  /// Creates a [ForgeAccountStatusLine].
  const ForgeAccountStatusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final connections = ref.watch(forgeConnectionsProvider).value;
    if (workspaceId == null || connections == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final byForge = {for (final c in connections) c.forge: c};
    final held = [
      for (final forge in ForgeHost.supported)
        if (byForge[forge] case final c?
            when c.status != ForgeConnectionStatus.notConnected)
          c,
    ];
    return YourAccountLine(
      workspaceId: workspaceId,
      status: held.isEmpty
          ? l10n.yourForgeAccountNone
          : [
              for (final c in held)
                yourAccountEntry(
                  l10n,
                  provider: c.forge.displayName,
                  status: c.status,
                  account: c.username,
                ),
            ].join(' · '),
      attention: held.isEmpty || held.any((c) => !c.isUsable),
    );
  }
}

/// Whether [ForgeAccountStatusLine] has anything to say: inside a workspace,
/// once the reader's forge accounts have arrived (before the first answer
/// "not connected" would be a guess), and never on a demo server, which
/// holds no forge credential to report.
bool watchForgeAccountStatusApplies(WidgetRef ref) =>
    !ref.watch(isDemoServerProvider) &&
    ref.watch(activeWorkspaceIdProvider) != null &&
    ref.watch(forgeConnectionsProvider).value != null;
