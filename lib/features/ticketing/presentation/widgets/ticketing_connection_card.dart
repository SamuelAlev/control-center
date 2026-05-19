import 'dart:async';

import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/device_code_dialog.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/features/ticketing/providers/ticketing_connection_providers.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where tickets live, and who Control Center is when it talks to them.
///
/// ONE card for what used to be two: choosing the vendor and authenticating to
/// it are the same decision, and splitting them left "Ticketing API key" as a
/// card that meant nothing until you scrolled up and changed a dropdown.
///
/// The credential row is absent for [TicketProvider.local] — local tickets
/// live in this server's own database and have nothing to authenticate to.
class TicketingConnectionCard extends ConsumerWidget {
  /// Creates a [TicketingConnectionCard].
  const TicketingConnectionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = ref.watch(activeTicketProviderProvider);
    final connections = ref.watch(ticketingConnectionsProvider);

    return SectionCard(
      label: l10n.ticketing,
      child: Column(
        children: [
          SettingsRow(
            icon: AppIcons.ticket,
            title: l10n.ticketingProvider,
            subtitle: l10n.ticketingProviderHelp,
            trailing: SizedBox(
              width: 200,
              child: CcSelect<TicketProvider>(
                value: provider,
                options: [
                  for (final p in TicketProvider.values)
                    CcSelectOption(
                      value: p,
                      // The unimplemented vendors stay VISIBLE and say so.
                      // Hiding them reads as "Control Center does not do Jira",
                      // which is a different claim from "not yet".
                      label: _supported(p)
                          ? _label(p, l10n)
                          : l10n.providerComingSoon(_label(p, l10n)),
                    ),
                ],
                onChanged: (p) {
                  if (_supported(p)) {
                    unawaited(_select(context, ref, p));
                  }
                },
              ),
            ),
          ),
          if (provider != TicketProvider.local) ...[
            const SizedBox(height: 8),
            _TicketingCredentialRow(
              provider: provider,
              connection: connections.value?[provider],
              loading: connections.isLoading,
              canSignIn: (ref.watch(signInProvidersProvider).value ?? const {})
                  .containsKey(provider.toStorageString()),
            ),
          ],
        ],
      ),
    );
  }

  /// Writes the workspace's choice, surfacing the server's refusal rather
  /// than letting the dropdown snap back with no explanation — changing where
  /// a workspace's tickets live is admin-gated.
  static Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    TicketProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await setActiveTicketProvider(ref, provider);
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    }
  }

  static bool _supported(TicketProvider provider) =>
      provider == TicketProvider.local || provider == TicketProvider.linear;

  static String _label(TicketProvider provider, AppLocalizations l10n) =>
      switch (provider) {
        TicketProvider.local => l10n.ticketProviderLocal,
        TicketProvider.linear => 'Linear',
        TicketProvider.jira => 'Jira',
        TicketProvider.clickup => 'ClickUp',
      };
}

class _TicketingCredentialRow extends ConsumerStatefulWidget {
  const _TicketingCredentialRow({
    required this.provider,
    required this.connection,
    required this.loading,
    required this.canSignIn,
  });

  final TicketProvider provider;
  final TicketingConnection? connection;
  final bool loading;
  final bool canSignIn;

  @override
  ConsumerState<_TicketingCredentialRow> createState() =>
      _TicketingCredentialRowState();
}

class _TicketingCredentialRowState
    extends ConsumerState<_TicketingCredentialRow> {
  bool _busy = false;

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final started = await signInToTicketing(ref, widget.provider);
      if (!mounted) {
        return;
      }
      switch (started) {
        case SignInDeviceCode():
          await showDeviceCodeDialog(
            context,
            providerName: TicketingConnectionCard._label(widget.provider, l10n),
            prompt: started,
            connected: () => isTicketingConnected(ref, widget.provider),
          );
        case SignInBrowserOpened(:final opened):
          if (!opened) {
            CcToastScope.of(
              context,
            ).show(l10n.couldNotOpenBrowser, variant: CcToastVariant.danger);
            return;
          }
          final connected = await awaitSignIn(
            () => isTicketingConnected(ref, widget.provider),
          );
          if (mounted && !connected) {
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
    final connected = widget.connection?.connected ?? false;
    final name = TicketingConnectionCard._label(widget.provider, l10n);

    return SettingsRow(
      icon: AppIcons.keyRound,
      title: name,
      subtitle: _subtitle(l10n, connected),
      subtitleWidget: widget.loading && widget.connection == null
          ? const SkeletonBar(width: 140)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (connected) ...[
            CcButton(
              onPressed: () => clearTicketingToken(ref, widget.provider),
              variant: CcButtonVariant.ghost,
              child: Text(l10n.disconnect),
            ),
            const SizedBox(width: 8),
          ],
          if (!connected || !widget.canSignIn)
            CcButton(
              onPressed: () => showTokenDialog(
                context,
                title: l10n.forgeTokenTitle(name),
                save: (token) => setTicketingToken(ref, widget.provider, token),
              ),
              variant: widget.canSignIn
                  ? CcButtonVariant.ghost
                  : CcButtonVariant.secondary,
              child: Text(connected ? l10n.updateKey : l10n.addKey),
            ),
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

  String _subtitle(AppLocalizations l10n, bool connected) {
    if (!connected) {
      return widget.loading ? l10n.checkingConnection : l10n.notConnected;
    }
    final who = widget.connection?.username ?? '';
    return who.isEmpty ? l10n.signedIn : l10n.signedInAs(who);
  }
}
