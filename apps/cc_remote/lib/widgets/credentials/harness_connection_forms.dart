part of 'harness_connection_card.dart';

class _HarnessKeyForm extends StatelessWidget {
  const _HarnessKeyForm({
    required this.controller,
    required this.busy,
    required this.signingIn,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool busy;
  final bool signingIn;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        CcTextField(
          controller: controller,
          obscureText: true,
          label: l.credentialsApiKey,
          hintText: l.credentialsApiKeyHint,
        ),
        const SizedBox(height: 8),
        CcButton(
          size: CcButtonSize.lg,
          variant: CcButtonVariant.secondary,
          onPressed: busy || signingIn ? null : onSave,
          child: Text(l.save),
        ),
      ],
    );
  }
}

class _HarnessOAuthForm extends StatelessWidget {
  const _HarnessOAuthForm({
    required this.flow,
    required this.controller,
    required this.busy,
    required this.onStart,
    required this.onComplete,
    required this.onCancel,
  });

  final HarnessOAuthStart? flow;
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final active = flow;
    final code = active?.userCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        if (active == null)
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.secondary,
            onPressed: busy ? null : onStart,
            child: Text(l.credentialsBrowserLogin),
          ),
        if (active != null) ...[
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
          const SizedBox(height: 8),
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.secondary,
            onPressed: () => openExternal(active.authUrl),
            child: Text(l.openInBrowser),
          ),
          if (code == null &&
              active.supportsManualPaste &&
              !active.isDeviceCode) ...[
            const SizedBox(height: 8),
            CcTextField(
              controller: controller,
              label: l.credentialsPasteRedirect,
              hintText: l.credentialsPasteRedirectHint,
            ),
            const SizedBox(height: 8),
            CcButton(
              size: CcButtonSize.lg,
              variant: CcButtonVariant.secondary,
              onPressed: busy ? null : onComplete,
              child: Text(l.credentialsCompleteLogin),
            ),
          ],
          const SizedBox(height: 8),
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
