import 'dart:convert';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/sso_connection_form.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Server → Single sign-on: the SAML and OIDC connection rows
/// (admin-only over RPC), the SP metadata the IdP wants and the SCIM
/// provisioning surface. Server-wide by design — authentication is not a
/// per-workspace concern.
class SsoSection extends ConsumerStatefulWidget {
  /// Creates an [SsoSection].
  const SsoSection({super.key});

  @override
  ConsumerState<SsoSection> createState() => _SsoSectionState();
}

class _SsoSectionState extends ConsumerState<SsoSection> {
  static const _kinds = ['saml', 'oidc'];

  String _kind = 'saml';
  final _values = <String, Map<String, dynamic>>{
    'saml': <String, dynamic>{},
    'oidc': <String, dynamic>{},
  };
  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _unavailable = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(rpcClientProvider);
    try {
      final status = await client.call('sso.status', const {});
      final results = await Future.wait([
        for (final kind in _kinds) client.call('sso.getConfig', {'kind': kind}),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _status = status;
        for (var i = 0; i < _kinds.length; i++) {
          final connection = results[i]['connection'];
          _values[_kinds[i]] = connection is Map
              ? {...connection.cast<String, dynamic>()}
              : <String, dynamic>{'kind': _kinds[i]};
        }
        _loading = false;
        _unavailable = false;
        _error = null;
      });
    } on Object catch (e) {
      // Unknown op (an older server binary) or the admin gate refusing —
      // either way this surface is not usable from here.
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _unavailable = true;
        _error = '$e';
      });
    }
  }

  Map<String, dynamic> get _current => _values[_kind]!;

  void _change(String key, Object? value) {
    setState(() => _current[key] = value);
  }

  bool get _enabled => _current['enabled'] as bool? ?? false;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(rpcClientProvider)
          .call('sso.saveConfig', _saveArgs());
      if (!mounted) {
        return;
      }
      setState(() {
        _values[_kind] = {
          ...(result['connection'] as Map).cast<String, dynamic>(),
        };
      });
      CcToastScope.of(context).show(AppLocalizations.of(context).ssoSavedToast);
      await _load();
    } on Object catch (e) {
      _showError('$e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Map<String, dynamic> _saveArgs() {
    final args = {..._current, 'kind': _kind, 'groupRoleMap': _parsedRoleMap()}
      ..remove('groupRoleMapRaw');
    return args;
  }

  /// The free-text role map editor holds JSON-ish `{"a": "b"}` pairs; empty
  /// and unparseable both save as "no mapping" (fail closed server-side
  /// anyway, which also refuses owner mappings).
  Map<String, String> _parsedRoleMap() {
    final raw =
        _current['groupRoleMapRaw'] as String? ??
        (_current['groupRoleMap'] is Map
            ? ({
                for (final e in (_current['groupRoleMap'] as Map).entries)
                  '"${e.key}": "${e.value}"',
              }.join(', '))
            : '');
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const {};
    }
    try {
      final wrapped = '{$trimmed}';
      final decoded = jsonDecode(
        wrapped.startsWith('{') ? wrapped : '{$trimmed}',
      );
      if (decoded is Map) {
        return {for (final e in decoded.entries) '${e.key}': '${e.value}'};
      }
    } on Object {
      // Fall through to the pair parser.
    }
    final pairs = <String, String>{};
    for (final part in trimmed.split(',')) {
      final match = RegExp('"([^"]+)"\\s*:\\s*"([^"]+)"').firstMatch(part);
      if (match != null) {
        pairs[match.group(1)!] = match.group(2)!;
      }
    }
    return pairs;
  }

  Future<void> _testConnection() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(rpcClientProvider)
          .call('sso.testConnection', {
            'kind': _kind,
            if (_kind == 'saml')
              'idpMetadataXml': _current['idpMetadataXml'] as String? ?? '',
            if (_kind == 'oidc') 'issuer': _current['issuer'] as String? ?? '',
          });
      if (!mounted) {
        return;
      }
      // SAML reports the IdP's SSO endpoint; OIDC the authorization one.
      final endpoint =
          (result['sso_endpoint'] ?? result['authorization_endpoint'])
              as String? ??
          '';
      CcToastScope.of(context).show(
        endpoint.isEmpty
            ? l10n.ssoTestConnectionOk
            : '${l10n.ssoTestConnectionOk} $endpoint',
      );
    } on Object catch (e) {
      _showError('$e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _copySpMetadata() async {
    setState(() => _busy = true);
    try {
      final origin = _status?['origin'] as String?;
      final result = await ref
          .read(rpcClientProvider)
          .call(
            'sso.spMetadata',
            origin == null ? const <String, dynamic>{} : {'origin': origin},
          );
      await Clipboard.setData(
        ClipboardData(text: result['xml'] as String? ?? ''),
      );
      if (!mounted) {
        return;
      }
      CcToastScope.of(
        context,
      ).show(AppLocalizations.of(context).ssoCopySpMetadataDone);
    } on Object catch (e) {
      _showError('$e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _regenerateScimToken() async {
    final l10n = AppLocalizations.of(context);
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
    if (confirmed != true) {
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
          content: Text(token, style: CcTypography.monoNum),
          actions: [
            CcButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
      await _load();
    } on Object catch (e) {
      _showError('$e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    CcToastScope.of(context).show(message, variant: CcToastVariant.danger);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const SectionCard(
        label: '',
        child: Center(child: CcSpinner()),
      );
    }
    if (_unavailable) {
      return SectionCard(
        label: l10n.settingsServerSso,
        child: Text(
          l10n.ssoUnavailable,
          style: CcTypography.bodySm.copyWith(
            color: context.designSystem?.textTertiary,
          ),
        ),
      );
    }
    return Column(
      children: [
        SectionCard(label: l10n.settingsServerSso, child: _buildConnection()),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(label: l10n.ssoScimCardTitle, child: _buildScim()),
      ],
    );
  }

  Widget _buildConnection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final kind in _kinds) ...[
              CcButton(
                onPressed: _busy ? null : () => setState(() => _kind = kind),
                variant: _kind == kind
                    ? CcButtonVariant.secondary
                    : CcButtonVariant.ghost,
                child: Text(
                  kind == 'saml' ? l10n.ssoProviderSaml : l10n.ssoProviderOidc,
                ),
              ),
              if (kind != _kinds.last) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsRow(
          icon: AppIcons.shieldCheck,
          title: l10n.ssoEnabled,
          subtitle: _enabled
              ? l10n.ssoEnabledDescriptionOn
              : l10n.ssoEnabledDescription,
          trailing: CcSwitch(
            value: _enabled,
            onChanged: _busy ? null : (v) => _change('enabled', v),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SsoConnectionForm(kind: _kind, values: _current, onChanged: _change),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            style: CcTypography.caption.copyWith(
              color: context.designSystem?.danger,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            if (_kind == 'saml') ...[
              CcButton(
                onPressed: _busy ? null : _copySpMetadata,
                variant: CcButtonVariant.secondary,
                child: Text(l10n.ssoCopySpMetadata),
              ),
            ],
            const Spacer(),
            CcButton(
              onPressed: _busy ? null : _save,
              variant: CcButtonVariant.accent,
              loading: _busy,
              child: Text(l10n.ssoSaveButton),
            ),
            const SizedBox(width: AppSpacing.sm),
            CcButton(
              onPressed: _busy ? null : _testConnection,
              variant: CcButtonVariant.secondary,
              child: Text(l10n.ssoTestConnectionButton),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScim() {
    final l10n = AppLocalizations.of(context);
    final scim = _status?['scim'];
    final tokenPresent = scim is Map && scim['token_present'] == true;
    final origin = _status?['origin'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.ssoScimDescription,
          style: CcTypography.bodySm.copyWith(
            color: context.designSystem?.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsRow(
          icon: AppIcons.globe,
          title: l10n.ssoScimEndpoint,
          subtitle: origin == null
              ? l10n.ssoScimEndpointUnknownOrigin
              : '$origin/scim/v2/Users',
          trailing: CcButton(
            onPressed: _busy ? null : _regenerateScimToken,
            variant: CcButtonVariant.secondary,
            child: Text(l10n.ssoScimRegenerate),
          ),
        ),
        SettingsRow(
          icon: AppIcons.keyRound,
          title: l10n.ssoScimTokenTitle,
          subtitle: tokenPresent
              ? l10n.ssoScimTokenPresent
              : l10n.ssoScimTokenAbsent,
          trailing: const SizedBox(width: AppSpacing.xl),
        ),
      ],
    );
  }
}
