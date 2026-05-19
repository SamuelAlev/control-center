import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Directory sync: the SCIM endpoint an identity provider pushes users to, and
/// the bearer token that authenticates it.
///
/// Deprovisioning through SCIM revokes sessions and workspace access within
/// seconds, which makes the token the most consequential secret on this page —
/// so it is shown exactly once, on generation, and its presence is a fact in
/// the card header from then on.
class SsoScimCard extends ConsumerStatefulWidget {
  /// Creates an [SsoScimCard].
  const SsoScimCard({
    super.key,
    required this.status,
    required this.origin,
    required this.onChanged,
  });

  /// The `sso.status` wire map.
  final Map<String, dynamic>? status;

  /// The server's canonical origin, or null when it has none.
  final String? origin;

  /// Called after a successful regeneration so the parent reloads status.
  final VoidCallback onChanged;

  @override
  ConsumerState<SsoScimCard> createState() => _SsoScimCardState();
}

class _SsoScimCardState extends ConsumerState<SsoScimCard> {
  bool _busy = false;

  bool get _tokenPresent {
    final scim = widget.status?['scim'];
    return scim is Map && scim['token_present'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final origin = widget.origin;
    final present = _tokenPresent;

    return SectionCard(
      label: l10n.ssoScimCardTitle,
      subtitle: Text(l10n.ssoScimDescription),
      trailing: CcStatusTag(
        label: present ? l10n.ssoStateActive : l10n.ssoStateNoToken,
        tone: present ? CcStatusTone.positive : CcStatusTone.neutral,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsField(
            label: l10n.ssoScimEndpoint,
            layout: SettingsFieldLayout.stacked,
            child: SettingsCopyField(
              value: origin == null ? null : '$origin/scim/v2/Users',
              emptyLabel: l10n.ssoScimEndpointUnknownOrigin,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsField(
            label: l10n.ssoScimTokenTitle,
            description: present
                ? l10n.ssoScimTokenPresent
                : l10n.ssoScimTokenAbsent,
            layout: SettingsFieldLayout.inline,
            controlWidth: 180,
            child: CcButton(
              variant: present
                  ? CcButtonVariant.secondary
                  : CcButtonVariant.accent,
              loading: _busy,
              onPressed: _busy ? null : _regenerate,
              child: Text(
                present ? l10n.ssoScimRegenerate : l10n.ssoScimGenerate,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _regenerate() async {
    final l10n = AppLocalizations.of(context);
    if (_tokenPresent && !await _confirm(l10n)) {
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(rpcClientProvider)
          .call('sso.scimRegenerateToken', const {});
      final token = result['token'] as String;
      await Clipboard.setData(ClipboardData(text: token));
      if (!mounted) {
        return;
      }
      await showCcDialog<void>(
        context: context,
        builder: (context) => CcDialog(
          title: l10n.ssoScimTokenOnce,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.ssoScimTokenOnceBody,
                style: CcTypography.bodySm.copyWith(
                  color: context.designSystem?.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SettingsCopyField(value: token, maxLines: 3),
            ],
          ),
          actions: [
            CcButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
      widget.onChanged();
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<bool> _confirm(AppLocalizations l10n) async {
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (context) => CcDialog(
        title: l10n.ssoScimRegenerate,
        content: Text(l10n.ssoScimRegenerateConfirm),
        actions: [
          CcButton(
            onPressed: () => Navigator.of(context).pop(false),
            variant: CcButtonVariant.ghost,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(context).pop(true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.ssoScimRegenerate),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}

/// The other way into this server: invite codes and pairing keys.
///
/// It belongs on the SSO page because "who can reach this server" is one
/// question, and answering it in two places is how an admin ends up with SSO
/// configured and a pairing code still circulating.
class SsoPairingCard extends ConsumerStatefulWidget {
  /// Creates an [SsoPairingCard].
  const SsoPairingCard({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  /// Whether manual pairing is currently allowed.
  final bool enabled;

  /// Called with the fresh `sso.status` map after a successful change.
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  ConsumerState<SsoPairingCard> createState() => _SsoPairingCardState();
}

class _SsoPairingCardState extends ConsumerState<SsoPairingCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.ssoPairingCardTitle,
      subtitle: Text(l10n.ssoPairingCardDescription),
      child: SettingsToggle(
        title: l10n.ssoPairingToggle,
        description: l10n.ssoPairingToggleDescription,
        icon: AppIcons.keyRound,
        value: widget.enabled,
        onChanged: _busy ? null : _set,
      ),
    );
  }

  Future<void> _set(bool enabled) async {
    setState(() => _busy = true);
    try {
      final status = await ref.read(rpcClientProvider).call(
        'sso.setPairingEnabled',
        {'enabled': enabled},
      );
      widget.onChanged(status);
    } on Object catch (e) {
      // The server refuses to disable pairing while no SSO connection is
      // enabled AND configured — that guard is the only thing standing between
      // an admin and locking every new device out of their own server, so its
      // message is surfaced verbatim rather than reduced to "failed".
      if (mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
