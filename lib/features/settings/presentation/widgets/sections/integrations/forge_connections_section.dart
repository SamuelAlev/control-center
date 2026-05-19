import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings section listing every code-hosting forge, connected or not.
///
/// All supported forges are always shown, including the ones with no
/// credential: an operator cannot connect a forge they cannot see, and a repo
/// on an unconnected forge is exactly the case where they need to find this
/// screen. Connecting one is enough — the app does not require GitHub.
class ForgeConnectionsSection extends ConsumerWidget {
  /// Creates a [ForgeConnectionsSection].
  const ForgeConnectionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(forgeConnectionsProvider);
    final byForge = {
      for (final c in async.value ?? const <ForgeConnection>[]) c.forge: c,
    };

    return SectionCard(
      label: l10n.forgeConnections,
      child: Column(
        children: [
          for (var i = 0; i < ForgeHost.supported.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _ForgeRow(
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

class _ForgeRow extends ConsumerWidget {
  const _ForgeRow({
    required this.forge,
    required this.connection,
    required this.loading,
  });

  final ForgeHost forge;
  final ForgeConnection? connection;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final connected = connection?.authenticated ?? false;

    return SettingsRow(
      icon: AppIcons.gitBranch,
      title: forge.displayName,
      subtitle: _subtitle(l10n),
      subtitleWidget: loading ? const SkeletonBar(width: 140) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (connected) ...[
            CcButton(
              onPressed: () => clearForgeToken(ref, forge),
              variant: CcButtonVariant.ghost,
              child: Text(l10n.disconnect),
            ),
            const SizedBox(width: 8),
          ],
          CcButton(
            onPressed: () => showTokenDialog(
              context,
              title: l10n.forgeTokenTitle(forge.displayName),
              save: (token) => setForgeToken(ref, forge, token),
            ),
            variant: CcButtonVariant.secondary,
            child: Text(connected ? l10n.updateLabel : l10n.connect),
          ),
        ],
      ),
    );
  }

  /// The one line that has to carry both "is it working" and "why not", so an
  /// operator never has to guess whether a blank PR list is their setup or the
  /// forge being empty.
  String _subtitle(AppLocalizations l10n) {
    final c = connection;
    if (c == null) {
      return loading ? l10n.checkingConnection : l10n.notConnected;
    }
    if (!c.authenticated) {
      return c.error.isNotEmpty ? c.error : l10n.notConnected;
    }
    final who = c.username.isEmpty
        ? l10n.signedIn
        : l10n.signedInAs(c.username);
    return switch (c.source) {
      // Naming the source matters: an operator who pasted a token and still
      // sees the wrong account needs to know an environment variable or the
      // `gh` CLI is not what is answering — and which one is.
      ForgeCredentialSource.settings => who,
      ForgeCredentialSource.environment => '$who · ${l10n.fromEnvironment}',
      ForgeCredentialSource.cli => '$who · ${l10n.fromGhCli}',
      ForgeCredentialSource.none => l10n.notConnected,
    };
  }
}
