import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_copy_field.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The confirmation code the browser's last page shows (`XXXX-XXXX`), typed
/// back into the app.
class McpServerSignInCodeField extends StatelessWidget {
  /// Creates the field.
  const McpServerSignInCodeField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSubmit,
    this.errorText,
  });

  /// The typed code.
  final TextEditingController controller;

  /// Whether a code can be typed now.
  final bool enabled;

  /// Sends the code.
  final VoidCallback onSubmit;

  /// Why the last code was not taken.
  final String? errorText;

  static final _codeChars = FilteringTextInputFormatter.allow(
    RegExp('[A-Za-z0-9 -]'),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    // RTL carve-out: the code is a machine string read left to right.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: CcTextField(
        controller: controller,
        autofocus: true,
        // An example code, not copy: codes are the same in every locale.
        hintText: 'K7Q2-9WXM',
        maxLength: 9,
        inputFormatters: [_codeChars, _UpperCase()],
        textInputAction: TextInputAction.done,
        enabled: enabled,
        errorText: errorText,
        onSubmitted: (_) => onSubmit(),
        textStyle: CcFonts.code(
          textStyle: CcTypography.title.copyWith(
            letterSpacing: 3,
            color: t.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// The sign-in page's link: opened again or copied, or — when no browser
/// could be opened — shown whole to be copied by hand.
class McpServerSignInLink extends StatelessWidget {
  /// Creates the link controls for [url].
  const McpServerSignInLink({
    super.key,
    required this.url,
    required this.opened,
    required this.onReopen,
  });

  /// The provider's sign-in page.
  final String url;

  /// Whether the browser took it; false shows the link itself.
  final bool opened;

  /// Opens it again.
  final VoidCallback onReopen;

  Future<void> _copy(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final toasts = CcToastScope.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: url));
    toasts?.show(l10n.copied, variant: CcToastVariant.success);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!opened) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CcAlert(
            title: l10n.couldNotOpenBrowser,
            variant: CcAlertVariant.warning,
          ),
          const SizedBox(height: AppSpacing.sm),
          SettingsCopyField(value: url, maxLines: 2),
        ],
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        CcButton(
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          icon: AppIcons.externalLink,
          onPressed: onReopen,
          child: Text(l10n.signInReopenPage),
        ),
        CcButton(
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          icon: AppIcons.copy,
          onPressed: () => _copy(context),
          child: Text(l10n.copyLink),
        ),
      ],
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
