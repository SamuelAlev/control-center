import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/forge/presentation/widgets/forge_connection_row.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every code-hosting forge, connected or not, with the one action each needs.
///
/// ONE card, rendered by both onboarding and Settings → You → Connected
/// accounts, so the two surfaces cannot drift apart.
///
/// All supported forges are always shown, including the ones with no
/// credential: an operator cannot connect a forge they cannot see. GitHub is
/// sign-in only (the person's own App user token); GitLab and Bitbucket take a
/// pasted token. Connecting one is enough — the app does not require GitHub.
///
/// The card's one line says where these accounts apply. A pasted token is
/// the person's in every workspace; a GitHub sign-in is too, unless this
/// workspace signs in to GitHub through its own app ([ForgeConnection.scope]
/// is then [ForgeCredentialScope.workspace]), which keeps its own grant.
class ForgeConnectionsCard extends ConsumerWidget {
  /// Creates a [ForgeConnectionsCard].
  const ForgeConnectionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // A demo server does not wire the credential port at all, so `forge.*` is
    // absent from its op registry. Rendering the rows anyway would offer
    // sign-in buttons for a credential the demo cannot hold.
    if (ref.watch(isDemoServerProvider)) {
      return SectionCard(
        label: l10n.forgeConnections,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: DemoUnavailable(
            capability: DemoCapability.forge,
            compact: true,
          ),
        ),
      );
    }

    final async = ref.watch(forgeConnectionsProvider);
    final byForge = {
      for (final c in async.value ?? const <ForgeConnection>[]) c.forge: c,
    };

    // Said once the server has answered, so it never flips under the reader.
    final githubScope = byForge[ForgeHost.github]?.scope;
    final ownAppWorkspace = githubScope == ForgeCredentialScope.workspace
        ? ref.watch(activeWorkspaceProvider)?.name
        : null;
    final reach = switch (githubScope) {
      null => null,
      ForgeCredentialScope.global => l10n.accountReachServer,
      ForgeCredentialScope.workspace =>
        ownAppWorkspace == null
            ? null
            : l10n.forgeReachGitHubOwnApp(ownAppWorkspace),
    };

    return SectionCard(
      label: l10n.forgeConnections,
      subtitle: reach == null ? null : Text(reach),
      child: Column(
        children: [
          for (var i = 0; i < ForgeHost.supported.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            ForgeConnectionRow(
              forge: ForgeHost.supported[i],
              connection: byForge[ForgeHost.supported[i]],
              loading: async.isLoading && byForge.isEmpty,
            ),
          ],
        ],
      ),
    );
  }
}
