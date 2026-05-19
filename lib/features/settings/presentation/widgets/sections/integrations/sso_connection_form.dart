import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The editable fields of one SSO connection kind (SAML or OIDC).
///
/// Stateless-by-design: the parent section owns the values (loaded from
/// `sso.getConfig`) and every edit calls back up, so "save" serializes
/// exactly what is on screen and a reload discards edits cleanly.
class SsoConnectionForm extends StatelessWidget {
  /// Creates an [SsoConnectionForm].
  const SsoConnectionForm({
    super.key,
    required this.kind,
    required this.values,
    required this.onChanged,
  });

  /// `saml` or `oidc`.
  final String kind;

  /// The current field values (the `sso.*` wire shape).
  final Map<String, dynamic> values;

  /// Fired with the changed key and its new value.
  final void Function(String key, Object? value) onChanged;

  bool _bool(String key, {required bool fallback}) =>
      values[key] as bool? ?? fallback;

  String _string(String key, String fallback) =>
      values[key] as String? ?? fallback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kind == 'saml') ...[
          _field(
            context,
            label: l10n.ssoIdpMetadataLabel,
            hint: l10n.ssoIdpMetadataHint,
            value: _string('idpMetadataXml', ''),
            maxLines: 6,
            onChanged: (v) => onChanged('idpMetadataXml', v),
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            context,
            label: l10n.ssoSpEntityIdLabel,
            hint: 'https://cc.example.com/saml',
            value: _string('spEntityId', ''),
            onChanged: (v) => onChanged('spEntityId', v),
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            context,
            label: l10n.ssoEmailAttributeLabel,
            value: _string('emailAttribute', 'email'),
            onChanged: (v) => onChanged('emailAttribute', v),
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            context,
            label: l10n.ssoDisplayNameAttributeLabel,
            value: _string('displayNameAttribute', 'displayName'),
            onChanged: (v) => onChanged('displayNameAttribute', v),
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            context,
            label: l10n.ssoGroupsAttributeLabel,
            value: _string('groupsAttribute', 'groups'),
            onChanged: (v) => onChanged('groupsAttribute', v),
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            context,
            label: l10n.ssoClockSkewLabel,
            value: '${values['clockSkewSeconds'] as int? ?? 90}',
            onChanged: (v) =>
                onChanged('clockSkewSeconds', int.tryParse(v) ?? 90),
          ),
        ] else ...[
          _field(
            context,
            label: l10n.ssoIssuerLabel,
            hint: 'https://idp.example.com',
            value: _string('issuer', ''),
            onChanged: (v) => onChanged('issuer', v),
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            context,
            label: l10n.ssoClientIdLabel,
            hint: l10n.ssoClientIdHint,
            value: _string('clientId', ''),
            onChanged: (v) => onChanged('clientId', v),
          ),
          const SizedBox(height: AppSpacing.md),
          // Confidential IdP clients only: the secret itself never comes
          // back over RPC, so this field stays write-only — blank on save
          // keeps the stored one.
          _field(
            context,
            label: l10n.ssoClientSecretLabel,
            hint: _bool('clientSecretPresent', fallback: false)
                ? l10n.ssoClientSecretHintSet
                : l10n.ssoClientSecretHintUnset,
            value: _string('clientSecret', ''),
            obscure: true,
            onChanged: (v) => onChanged('clientSecret', v),
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            context,
            label: l10n.ssoGroupsClaimLabel,
            value: _string('groupsClaim', 'groups'),
            onChanged: (v) => onChanged('groupsClaim', v),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _field(
          context,
          label: l10n.ssoDefaultRoleLabel,
          value: _string('defaultRole', 'member'),
          onChanged: (v) => onChanged('defaultRole', v),
        ),
        const SizedBox(height: AppSpacing.md),
        _field(
          context,
          label: l10n.ssoRoleMapLabel,
          hint: '{"platform-leads": "admin"}',
          value: _roleMapText(),
          maxLines: 3,
          onChanged: (v) => onChanged('groupRoleMapRaw', v),
        ),
        const SizedBox(height: AppSpacing.md),
        _switchRow(
          context,
          label: l10n.ssoAutoMemberLabel,
          description: l10n.ssoAutoMemberDescription,
          value: _bool('autoMember', fallback: true),
          onChanged: (v) => onChanged('autoMember', v),
        ),
        _switchRow(
          context,
          label: l10n.ssoAllowJitLabel,
          description: l10n.ssoAllowJitDescription,
          value: _bool('allowJit', fallback: true),
          onChanged: (v) => onChanged('allowJit', v),
        ),
        if (kind == 'saml')
          _switchRow(
            context,
            label: l10n.ssoAllowIdpInitiatedLabel,
            description: l10n.ssoAllowIdpInitiatedDescription,
            value: _bool('allowIdpInitiated', fallback: false),
            onChanged: (v) => onChanged('allowIdpInitiated', v),
          ),
        if (kind == 'saml')
          _switchRow(
            context,
            label: l10n.ssoWantResponseSignedLabel,
            description: l10n.ssoWantResponseSignedDescription,
            value: _bool('wantResponseSigned', fallback: false),
            onChanged: (v) => onChanged('wantResponseSigned', v),
          ),
      ],
    );
  }

  String _roleMapText() {
    final raw = values['groupRoleMapRaw'];
    if (raw is String) {
      return raw;
    }
    final map = values['groupRoleMap'];
    if (map is Map && map.isNotEmpty) {
      return map.entries.map((e) => '"${e.key}": "${e.value}"').join(', ');
    }
    return '';
  }

  Widget _field(
    BuildContext context, {
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    String? hint,
    int maxLines = 1,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: CcTypography.caption.copyWith(
            color: context.designSystem?.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _FormField(
          value: value,
          hint: hint,
          maxLines: maxLines,
          obscure: obscure,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _switchRow(
    BuildContext context, {
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CcTypography.bodySm.copyWith(
                    color: context.designSystem?.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: CcTypography.caption.copyWith(
                    color: context.designSystem?.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          CcSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// One text field that owns its controller for the widget's lifetime and
/// re-seeds it when the parent reloads the config (external value changes
/// win only while the user is not mid-edit).
class _FormField extends StatefulWidget {
  const _FormField({
    required this.value,
    required this.onChanged,
    this.hint,
    this.maxLines = 1,
    this.obscure = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int maxLines;
  final bool obscure;

  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _FormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CcTextField(
      controller: _controller,
      hintText: widget.hint,
      maxLines: widget.maxLines,
      obscureText: widget.obscure,
      onChanged: widget.onChanged,
    );
  }
}
