import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/sso/sso_text_field.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The roles an SSO connection may grant. Owner is deliberately absent: the
/// server refuses to provision it from a group claim, so offering it here would
/// be an option that silently does nothing.
List<CcSelectOption<String>> ssoRoleOptions(AppLocalizations l10n) => [
  CcSelectOption(value: 'admin', label: l10n.roleAdmin),
  CcSelectOption(value: 'member', label: l10n.roleMember),
  CcSelectOption(value: 'viewer', label: l10n.roleViewer),
  CcSelectOption(value: 'guest', label: l10n.roleGuest),
];

/// What someone who signs in successfully is allowed to do.
///
/// The consequential group, so it is last in the form and it is explicit: a
/// default role, an explicit group-to-role table, and the two switches that
/// decide whether an unknown person becomes a member at all.
class SsoAccessGroup extends StatelessWidget {
  /// Creates an [SsoAccessGroup].
  const SsoAccessGroup({
    super.key,
    required this.values,
    required this.onChanged,
    this.busy = false,
  });

  /// The current field values (the `sso.*` wire shape).
  final Map<String, dynamic> values;

  /// Fired with the changed key and its new value.
  final void Function(String key, Object? value) onChanged;

  /// Disables every control while a save or test is in flight.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roleOptions = ssoRoleOptions(l10n);
    final rawMap = values['groupRoleMap'];
    final pairs = <SettingsKeyValuePair>[
      if (rawMap is Map)
        for (final e in rawMap.entries)
          SettingsKeyValuePair('${e.key}', '${e.value}'),
    ];
    final defaultRole = values['defaultRole'] as String? ?? 'member';

    return SettingsGroup(
      title: l10n.ssoGroupAccess,
      description: l10n.ssoGroupAccessDescription,
      showRule: true,
      gap: AppSpacing.md,
      children: [
        SettingsField(
          label: l10n.ssoDefaultRoleShortLabel,
          description: l10n.ssoDefaultRoleDescription,
          controlWidth: 220,
          child: CcSelect<String>(
            options: roleOptions,
            value: roleOptions.any((o) => o.value == defaultRole)
                ? defaultRole
                : 'member',
            enabled: !busy,
            onChanged: (v) => onChanged('defaultRole', v),
          ),
        ),
        SettingsField(
          label: l10n.ssoRoleMapShortLabel,
          description: l10n.ssoRoleMapDescription,
          layout: SettingsFieldLayout.stacked,
          child: SettingsKeyValueEditor(
            entries: pairs,
            enabled: !busy,
            keyHint: l10n.ssoRoleMapGroupHint,
            valueOptions: roleOptions,
            addLabel: l10n.ssoRoleMapAdd,
            emptyLabel: l10n.ssoRoleMapEmpty,
            onChanged: (next) => onChanged('groupRoleMap', {
              for (final pair in next) pair.key: pair.value,
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SettingsToggle(
          title: l10n.ssoAutoMemberLabel,
          description: l10n.ssoAutoMemberDescription,
          value: values['autoMember'] as bool? ?? true,
          onChanged: busy ? null : (v) => onChanged('autoMember', v),
        ),
        SettingsToggle(
          title: l10n.ssoAllowJitLabel,
          description: l10n.ssoAllowJitDescription,
          value: values['allowJit'] as bool? ?? true,
          onChanged: busy ? null : (v) => onChanged('allowJit', v),
        ),
      ],
    );
  }
}

/// SAML's protocol knobs.
///
/// Collapsed because the defaults are the correct posture and touching them
/// loosens or tightens security — badged when they are not the defaults, so
/// collapsing cannot hide that this install is running something else.
class SsoAdvancedGroup extends StatelessWidget {
  /// Creates an [SsoAdvancedGroup].
  const SsoAdvancedGroup({
    super.key,
    required this.values,
    required this.onChanged,
    this.busy = false,
  });

  /// The current field values (the `sso.*` wire shape).
  final Map<String, dynamic> values;

  /// Fired with the changed key and its new value.
  final void Function(String key, Object? value) onChanged;

  /// Disables every control while a save or test is in flight.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final skew = values['clockSkewSeconds'] as int? ?? 90;
    final idpInitiated = values['allowIdpInitiated'] as bool? ?? false;
    final wantSigned = values['wantResponseSigned'] as bool? ?? false;
    final changed = skew != 90 || idpInitiated || wantSigned;

    return SettingsDisclosure(
      title: l10n.advanced,
      summary: l10n.ssoAdvancedSummary,
      badge: changed
          ? SettingsModifiedBadge(label: l10n.settingsChangedBadge)
          : null,
      childPadding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsField(
            label: l10n.ssoClockSkewShortLabel,
            description: l10n.ssoClockSkewDescription,
            controlWidth: 140,
            child: SsoTextField(
              value: '$skew',
              enabled: !busy,
              onChanged: (v) =>
                  onChanged('clockSkewSeconds', int.tryParse(v) ?? 90),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SettingsToggle(
            title: l10n.ssoAllowIdpInitiatedLabel,
            description: l10n.ssoAllowIdpInitiatedDescription,
            value: idpInitiated,
            onChanged: busy ? null : (v) => onChanged('allowIdpInitiated', v),
          ),
          SettingsToggle(
            title: l10n.ssoWantResponseSignedLabel,
            description: l10n.ssoWantResponseSignedDescription,
            value: wantSigned,
            onChanged: busy ? null : (v) => onChanged('wantResponseSigned', v),
          ),
        ],
      ),
    );
  }
}
