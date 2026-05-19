import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A yes/no capability marker: glyph plus word, never colour alone.
class ProviderAppCapability extends StatelessWidget {
  /// Creates a [ProviderAppCapability].
  const ProviderAppCapability({
    super.key,
    required this.label,
    required this.enabled,
  });

  /// What the app can do.
  final String label;

  /// Whether it can, on this install.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final color = enabled ? tokens.textSuccessPrimary : tokens.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(enabled ? AppIcons.check : AppIcons.x, size: 12, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: CcTypography.caption.copyWith(color: color)),
      ],
    );
  }
}

/// One editable credential field. Secrets show presence, never a value — there
/// is nothing to render, because the server does not return one.
class ProviderAppSecretField extends StatelessWidget {
  /// Creates a [ProviderAppSecretField].
  const ProviderAppSecretField({
    super.key,
    required this.title,
    required this.onSet,
    this.value = '',
    this.configured = false,
    this.secret = false,
    this.multiline = false,
  });

  /// The field label.
  final String title;

  /// The current value; empty for a secret.
  final String value;

  /// Whether a secret is stored.
  final bool configured;

  /// Whether the value is a secret the server never returns.
  final bool secret;

  /// Whether the editor should accept a pasted block (a PEM key).
  final bool multiline;

  /// Persists a new value; the empty string clears it.
  final Future<void> Function(String) onSet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final isSet = secret ? configured : value.isNotEmpty;
    return SettingsField(
      label: title,
      description: secret
          ? null
          : (value.isEmpty ? l10n.notConfiguredLabel : value),
      badge: secret
          ? CcBadge(
              label: isSet ? l10n.configuredLabel : l10n.notConfiguredLabel,
              variant: isSet ? CcBadgeVariant.success : CcBadgeVariant.neutral,
            )
          : null,
      controlWidth: 200,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcButton(
            onPressed: () => showTokenDialog(
              context,
              title: title,
              save: onSet,
              obscure: secret && !multiline,
              multiline: multiline,
            ),
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            child: Text(isSet ? l10n.updateLabel : l10n.setLabel),
          ),
          if (isSet) ...[
            const SizedBox(width: AppSpacing.sm),
            CcIconButton(
              icon: AppIcons.x,
              size: CcButtonSize.sm,
              variant: CcButtonVariant.ghost,
              color: tokens.fgTertiary,
              tooltip: l10n.clear,
              onPressed: () => onSet(''),
            ),
          ],
        ],
      ),
    );
  }
}
