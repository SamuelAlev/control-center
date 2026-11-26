import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_copy.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_copy_field.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/focus_on_mount.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A spinner and one line of state.
class SignInStatusLine extends StatelessWidget {
  /// Creates a [SignInStatusLine].
  const SignInStatusLine({super.key, required this.text});

  /// What is happening.
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          CcSpinner(size: 14, color: t.textTertiary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Why the attempt is over, with the glyph that says so.
class SignInFailureView extends StatelessWidget {
  /// Creates a [SignInFailureView].
  const SignInFailureView({super.key, required this.message});

  /// The localized reason.
  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcAlert(
      title: l10n.signInFailedTitle,
      description: Text(message),
      variant: CcAlertVariant.danger,
    );
  }
}

/// What to do when the browser could not be opened: the link itself.
class _BrowserFallback extends StatelessWidget {
  const _BrowserFallback({required this.session, required this.onReopen});

  final SignInSession session;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!session.browserOpened) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CcAlert(
            title: l10n.couldNotOpenBrowser,
            variant: CcAlertVariant.warning,
          ),
          const SizedBox(height: AppSpacing.sm),
          SettingsCopyField(value: session.attempt.url, maxLines: 2),
        ],
      );
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: CcButton(
        variant: CcButtonVariant.ghost,
        size: CcButtonSize.sm,
        icon: AppIcons.externalLink,
        onPressed: onReopen,
        child: Text(l10n.signInReopenPage),
      ),
    );
  }
}

/// The browser's last page (Connect's, or this server's own-app callback)
/// shows an eight-character code to bring back.
class SignInCodeEntry extends StatelessWidget {
  /// Creates a [SignInCodeEntry].
  const SignInCodeEntry({
    super.key,
    required this.session,
    required this.controller,
    required this.onSubmit,
    required this.onReopen,
  });

  /// The running attempt.
  final SignInSession session;

  /// The typed code.
  final TextEditingController controller;

  /// Sends the code.
  final VoidCallback onSubmit;

  /// Opens the provider page again.
  final VoidCallback onReopen;

  static final _codeChars = FilteringTextInputFormatter.allow(
    RegExp('[A-Za-z0-9 -]'),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final error = switch (session.codeError) {
      SignInCodeMalformed() => l10n.signInCodeMalformed,
      SignInCodeRejected(:final failure) => signInFailureMessage(
        l10n,
        failure,
        session.attempt.lane,
      ),
      null => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.signInCodePrompt,
          style: CcTypography.body.copyWith(color: t.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        // RTL carve-out: the code is a machine string read left to right.
        Directionality(
          textDirection: TextDirection.ltr,
          // Asked for outright: after Retry, an autofocus would yield to a
          // dialog button focused earlier, which is where Retry hands focus
          // as it goes.
          child: FocusOnMount(
            builder: (context, focusNode) => CcTextField(
              controller: controller,
              focusNode: focusNode,
              // An example code, not copy: codes are the same in every locale.
              hintText: 'K7Q2-9WXM',
              maxLength: 9,
              inputFormatters: [_codeChars, _UpperCase()],
              textInputAction: TextInputAction.done,
              enabled: !session.completing,
              errorText: error,
              onSubmitted: (_) => onSubmit(),
              textStyle: CcFonts.code(
                textStyle: CcTypography.title.copyWith(
                  letterSpacing: 3,
                  color: t.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.signInCodeDeepLinkHint,
          style: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
        const SizedBox(height: AppSpacing.md),
        _BrowserFallback(session: session, onReopen: onReopen),
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
