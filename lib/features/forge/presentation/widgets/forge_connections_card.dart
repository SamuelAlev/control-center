import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/auth/presentation/widgets/device_code_dialog.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';

import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every code-hosting forge, connected or not, with the one action each needs.
///
/// ONE card, rendered by both onboarding and Settings → Integrations, so the
/// two surfaces cannot drift apart.
///
/// All supported forges are always shown, including the ones with no
/// credential: an operator cannot connect a forge they cannot see, and a repo
/// on an unconnected forge is exactly the case where they need to find this.
/// Connecting one is enough — the app does not require GitHub.
class ForgeConnectionsCard extends ConsumerWidget {
  /// Creates a [ForgeConnectionsCard].
  const ForgeConnectionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // A demo server does not wire the credential port at all, so `forge.*` is
    // absent from its op registry and `forgeConnectionsProvider` resolves to
    // an ERROR. Rendering the rows anyway would offer sign-in buttons for a
    // credential the demo cannot hold, each failing on press. Say what is
    // actually true instead.
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
    final canSignIn = ref.watch(forgeSignInProvidersProvider);

    return SectionCard(
      label: l10n.forgeConnections,
      child: Column(
        children: [
          for (var i = 0; i < ForgeHost.supported.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            ForgeConnectionRow(
              forge: ForgeHost.supported[i],
              connection: byForge[ForgeHost.supported[i]],
              loading: async.isLoading && byForge.isEmpty,
              canSignIn: canSignIn.contains(ForgeHost.supported[i]),
            ),
          ],
        ],
      ),
    );
  }
}

/// One forge's row: who you are on it, and how to change that.
class ForgeConnectionRow extends ConsumerStatefulWidget {
  /// Creates a [ForgeConnectionRow].
  const ForgeConnectionRow({
    required this.forge,
    required this.connection,
    required this.loading,
    required this.canSignIn,
    super.key,
  });

  /// The forge this row is about.
  final ForgeHost forge;

  /// Its connection state, or null before the first answer.
  final ForgeConnection? connection;

  /// Whether the connection list is still loading.
  final bool loading;

  /// Whether this server can run a browser sign-in for the forge.
  final bool canSignIn;

  @override
  ConsumerState<ForgeConnectionRow> createState() => _ForgeConnectionRowState();
}

class _ForgeConnectionRowState extends ConsumerState<ForgeConnectionRow> {
  bool _busy = false;

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final started = await signInToForge(ref, widget.forge);
      if (!mounted) {
        return;
      }
      switch (started) {
        // A device flow puts the code on screen and waits there. The SERVER
        // polls the provider, so closing the dialog does not cancel it.
        case SignInDeviceCode():
          await showDeviceCodeDialog(
            context,
            providerName: widget.forge.displayName,
            prompt: started,
            connected: () => isForgeConnected(ref, widget.forge),
          );
        case SignInBrowserOpened(:final opened):
          if (!opened) {
            CcToastScope.of(
              context,
            ).show(l10n.couldNotOpenBrowser, variant: CcToastVariant.danger);
            return;
          }
          final connected = await awaitSignIn(
            () => isForgeConnected(ref, widget.forge),
          );
          if (mounted && !connected) {
            // The sign-in is still valid server-side for a while, so this says
            // the app stopped WATCHING rather than that the login failed.
            CcToastScope.of(context).show(l10n.signInNotFinished);
          }
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final connected = widget.connection?.authenticated ?? false;
    final name = widget.forge.displayName;

    final tokenButton = CcButton(
      onPressed: () => showTokenDialog(
        context,
        title: l10n.forgeTokenTitle(name),
        save: (token) => setForgeToken(ref, widget.forge, token),
      ),
      // A pasted token is the secondary path once the server can run a real
      // sign-in, and the only path when it cannot.
      variant: widget.canSignIn
          ? CcButtonVariant.ghost
          : CcButtonVariant.secondary,
      child: Text(connected ? l10n.updateToken : l10n.addToken),
    );

    return SettingsRow(
      icon: AppIcons.gitBranch,
      title: name,
      subtitle: _subtitle(l10n),
      subtitleWidget: widget.loading ? const SkeletonBar(width: 140) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (connected) ...[
            CcButton(
              onPressed: () => clearForgeToken(ref, widget.forge),
              variant: CcButtonVariant.ghost,
              child: Text(l10n.disconnect),
            ),
            const SizedBox(width: 8),
          ],
          if (!connected || !widget.canSignIn) tokenButton,
          if (widget.canSignIn) ...[
            if (!connected) const SizedBox(width: 8),
            CcButton(
              onPressed: _busy ? null : _signIn,
              variant: CcButtonVariant.secondary,
              child: _busy
                  ? const CcSpinner(size: 14)
                  : Text(
                      connected
                          ? l10n.signInAgain
                          : l10n.signInWithProvider(name),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  /// The one line that has to carry both "is it working" and "why not", so an
  /// operator never has to guess whether a blank PR list is their setup or the
  /// forge being empty.
  String _subtitle(AppLocalizations l10n) {
    final c = widget.connection;
    if (c == null) {
      return widget.loading ? l10n.checkingConnection : l10n.notConnected;
    }
    if (!c.authenticated) {
      return c.error.isNotEmpty ? c.error : l10n.notConnected;
    }
    final who = c.username.isEmpty
        ? l10n.signedIn
        : l10n.signedInAs(c.username);
    return switch (c.source) {
      // Naming the source matters: someone who pasted a token and still sees
      // the wrong account needs to know an environment variable or the
      // server's own app is what is answering — and which one.
      ForgeCredentialSource.oauth || ForgeCredentialSource.settings => who,
      ForgeCredentialSource.app => '$who · ${l10n.viaServerApp}',
      ForgeCredentialSource.environment => '$who · ${l10n.fromEnvironment}',
      ForgeCredentialSource.none => l10n.notConnected,
    };
  }
}
