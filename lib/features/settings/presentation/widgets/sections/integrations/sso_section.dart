import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/sso/sso_connection_card.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/sso/sso_connection_draft.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/sso/sso_provisioning_cards.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Server → Single sign-on: how people get into this server.
///
/// Server-wide by design — authentication is not a per-workspace concern.
///
/// The page opens with the answer to the only question an admin arrives with:
/// can anyone sign in right now, and how. Below it, one connection at a time —
/// a segmented SAML/OIDC choice, the switch that decides whether it is live,
/// and the connection's fields in the four groups an admin works through. Edits
/// are committed as a unit through a save bar that only exists while there is
/// something to commit.
///
/// This class owns the RPC and the draft state; [SsoConnectionCard] renders it.
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

  /// What the server last told us, per kind, canonicalized for comparison.
  final _saved = <String, String>{'saml': '', 'oidc': ''};

  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _unavailable = false;
  bool _busy = false;
  String? _error;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
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
          final values = connection is Map
              ? {...connection.cast<String, dynamic>()}
              : <String, dynamic>{'kind': _kinds[i]};
          _values[_kinds[i]] = values;
          _saved[_kinds[i]] = ssoCanonical(values);
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

  bool _isDirty(String kind) => ssoCanonical(_values[kind]!) != _saved[kind];

  bool get _dirty => _isDirty(_kind);

  bool get _enabled => _current['enabled'] as bool? ?? false;

  String? get _origin {
    final origin = _status?['origin'] as String?;
    return (origin == null || origin.isEmpty) ? null : origin;
  }

  void _change(String key, Object? value) {
    setState(() {
      _current[key] = value;
      _saveError = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _saveError = null;
    });
    try {
      await ref
          .read(rpcClientProvider)
          .call('sso.saveConfig', ssoSaveArgs(_kind, _current));
      if (!mounted) {
        return;
      }
      CcToastScope.of(context).show(AppLocalizations.of(context).ssoSavedToast);
      await _load();
    } on Object catch (e) {
      if (mounted) {
        setState(() => _saveError = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Drops the local edits back to what the server last returned.
  void _discard() {
    setState(() => _saveError = null);
    unawaited(_load());
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
        variant: CcToastVariant.success,
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
      final origin = _origin;
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
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: CcSpinner()),
        ),
      );
    }
    if (_unavailable) {
      return SectionCard(
        label: l10n.settingsServerSso,
        child: CcAlert(
          title: l10n.ssoUnavailable,
          variant: CcAlertVariant.warning,
          description: _error == null
              ? null
              : Text(
                  _error!,
                  style: CcTypography.caption.copyWith(
                    color: context.designSystem?.textTertiary,
                  ),
                ),
        ),
      );
    }
    return Column(
      children: [
        SsoConnectionCard(
          kind: _kind,
          kinds: _kinds,
          values: _current,
          origin: _origin,
          busy: _busy,
          enabled: _enabled,
          dirty: _dirty,
          otherDirtyKinds: [
            for (final kind in _kinds)
              if (kind != _kind && _isDirty(kind)) kind,
          ],
          saveError: _saveError,
          status: _status,
          onKindChanged: (kind) => setState(() {
            _kind = kind;
            _saveError = null;
          }),
          onFieldChanged: _change,
          onSave: _save,
          onDiscard: _discard,
          onTest: _testConnection,
          onCopyMetadata: _copySpMetadata,
        ),
        const SizedBox(height: AppSpacing.lg),
        SsoScimCard(
          status: _status,
          origin: _origin,
          onChanged: () => unawaited(_load()),
        ),
        const SizedBox(height: AppSpacing.lg),
        SsoPairingCard(
          enabled: _status?['pairing_enabled'] != false,
          onChanged: (status) => setState(() => _status = status),
        ),
      ],
    );
  }
}
