import 'package:cc_data/cc_data.dart' show ConnectModeSetting, ConnectStatus;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/connect/providers/connect_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/provider_app_detail.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/provider_app_fields.dart';
import 'package:control_center/features/settings/providers/provider_apps_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the server runs on its own apps rather than a Connect.
///
/// Held back until the Connect choice is known so the card does not flash in
/// and out. A status that could not be read keeps the card: an operator who
/// cannot see the choice must still be able to reach the apps.
bool _usesOwnApps(AsyncValue<ConnectStatus?> status) {
  if (!status.hasValue && !status.hasError) {
    return false;
  }
  return switch (status.value?.mode) {
    ConnectModeSetting.hosted || ConnectModeSetting.custom => false,
    _ => true,
  };
}

/// The provider's name as people know it; brand names stay untranslated.
String providerAppName(String provider) => switch (provider) {
  'github' => 'GitHub',
  'google' => 'Google Calendar',
  'linear' => 'Linear',
  _ => provider,
};

/// This server's own provider apps: the GitHub App, the Google OAuth client
/// and the Linear app, for the lanes that do not run through Connect.
///
/// Server scope, operator only — the `providerApps.*` ops are gated to the
/// server admin, and a member who cannot change these never sees the card
/// (the list resolves empty for them).
///
/// Shown only while the server uses its own apps ("Use my own apps" in the
/// Connect card). Under Control Center's or a custom Connect the server
/// ignores these apps, so showing them would offer settings that do nothing;
/// what is stored is kept and comes back when the operator switches back.
///
/// Two different jobs come out of one registration and the card says so: the
/// app id + private key are what lets the server read repositories with no
/// human behind the request (webhooks, polling, sync), while the client id +
/// secret are what lets a PERSON sign in and get a credential of their own.
/// Configuring only the second is a valid, common setup — so each app's row
/// reports the two capabilities separately rather than collapsing them into one
/// "configured" verdict that would be true and useless.
class ProviderAppsSection extends ConsumerStatefulWidget {
  /// Creates a [ProviderAppsSection].
  const ProviderAppsSection({super.key});

  @override
  ConsumerState<ProviderAppsSection> createState() =>
      _ProviderAppsSectionState();
}

class _ProviderAppsSectionState extends ConsumerState<ProviderAppsSection> {
  final _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final apps = ref.watch(providerAppsProvider).value ?? const [];
    if (apps.isEmpty || !_usesOwnApps(ref.watch(connectStatusProvider))) {
      return const SizedBox.shrink();
    }

    return SectionCard(
      label: l10n.providerApps,
      subtitle: Text(l10n.providerAppsDescription),
      padding: const EdgeInsets.only(top: AppSpacing.md),
      headerPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final app in apps) ...[
            const CcDivider(),
            _ProviderAppRow(
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

class _ProviderAppRow extends ConsumerStatefulWidget {
  const _ProviderAppRow({
    required this.app,
    required this.expanded,
    required this.onExpandedChanged,
  });

  final ProviderAppStatusView app;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  @override
  ConsumerState<_ProviderAppRow> createState() => _ProviderAppRowState();
}

class _ProviderAppRowState extends ConsumerState<_ProviderAppRow> {
  bool _testing = false;

  Future<void> _test() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _testing = true);
    try {
      final result = await testProviderApp(ref, widget.app.provider);
      if (!mounted) {
        return;
      }
      CcToastScope.of(context).show(
        result.error.isNotEmpty
            ? result.error
            : l10n.providerAppInstalledOn(result.installations.join(', ')),
        variant: result.error.isEmpty
            ? CcToastVariant.success
            : CcToastVariant.danger,
      );
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = widget.app;
    final broken =
        app.error.isNotEmpty || app.state == ProviderAppState.partial;
    final ready = app.state == ProviderAppState.complete;

    return SettingsEntityRow(
      title: providerAppName(app.provider),
      icon: switch (app.provider) {
        'github' => AppIcons.gitBranch,
        'google' => AppIcons.calendar,
        _ => AppIcons.ticket,
      },
      tone: broken
          ? CcStatusTone.negative
          : ready
          ? CcStatusTone.positive
          : CcStatusTone.neutral,
      statusLabel: broken
          ? l10n.settingsStateFailed
          : ready
          ? l10n.configuredLabel
          : l10n.notConfiguredLabel,
      subtitle: _summary(l10n),
      // The capabilities, always all stated. "Configured" alone hid which
      // half worked, and the halves fail in completely different ways: one
      // breaks background work silently, the other breaks the sign-in button.
      meta: [
        if (app.provider != 'google')
          ProviderAppCapability(
            label: l10n.providerAppCapActsAsServer,
            enabled: app.canActAsServer,
          ),
        ProviderAppCapability(
          label: l10n.providerAppCapSignsIn,
          enabled: app.canSignIn,
        ),
      ],
      trailing: CcButton(
        onPressed: _testing ? null : _test,
        variant: CcButtonVariant.secondary,
        size: CcButtonSize.sm,
        loading: _testing,
        child: Text(l10n.testLabel),
      ),
      expanded: widget.expanded,
      onExpandedChanged: widget.onExpandedChanged,
      detail: ProviderAppDetail(app: app),
    );
  }

  String _summary(AppLocalizations l10n) {
    final app = widget.app;
    if (app.error.isNotEmpty) {
      return app.error;
    }
    if (app.state == ProviderAppState.partial) {
      return l10n.providerAppPartial;
    }
    if (app.provider == 'google') {
      return app.canSignIn
          ? l10n.providerAppSignInReady
          : l10n.notConfiguredLabel;
    }
    return switch ((app.canActAsServer, app.canSignIn)) {
      (true, true) => l10n.providerAppFullyConfigured,
      (true, false) => l10n.providerAppServerOnly,
      (false, true) => l10n.providerAppSignInOnly,
      (false, false) => l10n.notConfiguredLabel,
    };
  }
}
