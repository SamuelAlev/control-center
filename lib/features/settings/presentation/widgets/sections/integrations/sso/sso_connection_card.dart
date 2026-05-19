import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/sso/sso_status_summary.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/sso_connection_form.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';

/// The connection card: state summary, method picker, the live switch, the form
/// and the save bar.
///
/// Presentation only — every mutation is a callback, so the section above owns
/// the RPC and this can be rendered from a fixed map in a test.
class SsoConnectionCard extends StatelessWidget {
  /// Creates an [SsoConnectionCard].
  const SsoConnectionCard({
    super.key,
    required this.kind,
    required this.kinds,
    required this.values,
    required this.origin,
    required this.busy,
    required this.enabled,
    required this.dirty,
    required this.otherDirtyKinds,
    required this.saveError,
    required this.status,
    required this.onKindChanged,
    required this.onFieldChanged,
    required this.onSave,
    required this.onDiscard,
    required this.onTest,
    required this.onCopyMetadata,
  });

  /// The connection kind on screen (`saml` or `oidc`).
  final String kind;

  /// Every kind, in display order.
  final List<String> kinds;

  /// The draft values for [kind].
  final Map<String, dynamic> values;

  /// The server's canonical origin, or null when it has none.
  final String? origin;

  /// Whether a save or test is in flight.
  final bool busy;

  /// Whether this connection is switched on.
  final bool enabled;

  /// Whether [values] differ from what the server last returned.
  final bool dirty;

  /// Kinds OTHER than [kind] that have uncommitted edits.
  final List<String> otherDirtyKinds;

  /// The last save failure, if any.
  final String? saveError;

  /// The `sso.status` wire map, for the summary.
  final Map<String, dynamic>? status;

  /// Switches which connection is on screen.
  final ValueChanged<String> onKindChanged;

  /// Fired with a changed field key and value.
  final void Function(String key, Object? value) onFieldChanged;

  /// Commits the draft.
  final VoidCallback onSave;

  /// Reverts the draft.
  final VoidCallback onDiscard;

  /// Runs the connection test.
  final VoidCallback onTest;

  /// Copies the SP metadata XML (SAML only).
  final VoidCallback onCopyMetadata;

  static const _insets = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SectionCard(
      label: l10n.settingsServerSso,
      subtitle: Text(l10n.ssoConnectionCardDescription),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      headerPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: _insets,
            child: SsoStatusSummary(status: status),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: _insets,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CcDivider(),
                const SizedBox(height: AppSpacing.lg),
                _methodPicker(context, l10n),
                const SizedBox(height: AppSpacing.md),
                SettingsToggle(
                  title: kind == 'saml'
                      ? l10n.ssoUseSamlForSignIn
                      : l10n.ssoUseOidcForSignIn,
                  description: enabled
                      ? l10n.ssoEnabledDescriptionOn
                      : l10n.ssoEnabledDescription,
                  icon: AppIcons.shieldCheck,
                  value: enabled,
                  onChanged: busy ? null : (v) => onFieldChanged('enabled', v),
                ),
                const SizedBox(height: AppSpacing.lg),
                SsoConnectionForm(
                  kind: kind,
                  values: values,
                  onChanged: onFieldChanged,
                  origin: origin,
                  busy: busy,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          SettingsSaveBar(
            dirty: dirty,
            busy: busy,
            error: saveError,
            saveLabel: l10n.ssoSaveConnection,
            onSave: onSave,
            onDiscard: onDiscard,
            secondaryActions: [
              if (kind == 'saml')
                CcButton(
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  icon: AppIcons.copy,
                  onPressed: busy ? null : onCopyMetadata,
                  child: Text(l10n.ssoCopySpMetadata),
                ),
              CcButton(
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                icon: AppIcons.plug,
                onPressed: busy ? null : onTest,
                child: Text(l10n.ssoTestConnectionButton),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _methodPicker(BuildContext context, AppLocalizations l10n) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      children: [
        CcSegmentedToggle<String>(
          segments: [
            CcSegment(value: 'saml', label: l10n.ssoProviderSaml),
            CcSegment(value: 'oidc', label: l10n.ssoProviderOidc),
          ],
          value: kind,
          onChanged: onKindChanged,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            kind == 'saml' ? l10n.ssoMethodSamlBlurb : l10n.ssoMethodOidcBlurb,
            style: CcTypography.caption.copyWith(color: tokens.textTertiary),
          ),
        ),
        // Only the OTHER kind's unsaved work is announced here. Edits survive a
        // switch (they live per kind), but the save bar only ever reports the
        // one on screen — so without this, editing SAML, switching to OIDC and
        // leaving would drop the SAML edits with nothing having said so.
        for (final other in otherDirtyKinds) ...[
          const SizedBox(width: AppSpacing.md),
          CcBadge(
            label: l10n.ssoOtherKindUnsaved(
              other == 'saml' ? l10n.ssoProviderSaml : l10n.ssoProviderOidc,
            ),
            variant: CcBadgeVariant.warning,
          ),
        ],
      ],
    );
  }
}
