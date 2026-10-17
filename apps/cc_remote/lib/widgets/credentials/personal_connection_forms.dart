part of 'personal_connection_card.dart';

class _PersonalSignInForm extends StatelessWidget {
  const _PersonalSignInForm({
    required this.canSignIn,
    required this.connected,
    required this.signInFlow,
    required this.verificationUrl,
    required this.userCode,
    required this.busy,
    required this.onBegin,
    required this.onStop,
  });

  final bool canSignIn;
  final bool connected;
  final String? signInFlow;
  final String? verificationUrl;
  final String? userCode;
  final bool busy;
  final VoidCallback onBegin;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final url = verificationUrl;
    final code = userCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canSignIn && url == null && (!connected || signInFlow == 'device'))
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.secondary,
            onPressed: busy ? null : onBegin,
            child: Text(
              connected ? l.credentialsSignInAgain : l.credentialsBrowserLogin,
            ),
          ),
        if (signInFlow == 'redirect' && !canSignIn)
          Text(
            l.credentialsRedirectUnavailable,
            style: TextStyle(color: t.textSecondary),
          ),
        if (url != null) ...[
          Text(
            l.credentialsWaitingForLogin,
            style: TextStyle(color: t.textSecondary),
          ),
          if (code != null) ...[
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: CcTextField(
                key: ValueKey(code),
                initialValue: code,
                readOnly: true,
                textStyle: TextStyle(
                  fontSize: 22,
                  letterSpacing: 3,
                  color: t.textPrimary,
                ),
              ),
            ),
            CcButton(
              size: CcButtonSize.lg,
              variant: CcButtonVariant.ghost,
              onPressed: () => Clipboard.setData(ClipboardData(text: code)),
              child: Text(l.credentialsCopyCode),
            ),
            Text(
              l.credentialsDeviceCodeHint,
              style: TextStyle(color: t.textSecondary),
            ),
          ],
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.secondary,
            onPressed: () => openExternal(url),
            child: Text(l.openInBrowser),
          ),
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.ghost,
            onPressed: onStop,
            child: Text(l.credentialsStopWatching),
          ),
        ],
      ],
    );
  }
}

class _PersonalTokenForm extends StatelessWidget {
  const _PersonalTokenForm({
    required this.connected,
    required this.editing,
    required this.busy,
    required this.controller,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
  });

  final bool connected;
  final bool editing;
  final bool busy;
  final TextEditingController controller;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!editing)
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.ghost,
            onPressed: busy ? null : onEdit,
            child: Text(
              connected ? l.credentialsUpdateToken : l.credentialsAddToken,
            ),
          ),
        if (editing) ...[
          const SizedBox(height: 8),
          CcTextField(
            controller: controller,
            obscureText: true,
            label: l.credentialsPersonalToken,
            hintText: l.credentialsPersonalTokenHint,
          ),
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.secondary,
            onPressed: busy ? null : onSave,
            child: Text(l.save),
          ),
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.ghost,
            onPressed: busy ? null : onCancel,
            child: Text(l.cancel),
          ),
        ],
      ],
    );
  }
}
