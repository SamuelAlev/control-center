part of 'personal_connection_card.dart';

class _PersonalSignInForm extends StatelessWidget {
  const _PersonalSignInForm({
    required this.provider,
    required this.canSignIn,
    required this.ownUnreachable,
    required this.unavailable,
    required this.connected,
    required this.needsAttention,
    required this.attempt,
    required this.code,
    required this.busy,
    required this.onBegin,
    required this.onConfirmCode,
    required this.onStop,
  });

  final String provider;
  final bool canSignIn;
  final bool ownUnreachable;
  final bool unavailable;
  final bool connected;
  final bool needsAttention;
  final SignInAttempt? attempt;
  final TextEditingController code;
  final bool busy;
  final VoidCallback onBegin;
  final VoidCallback onConfirmCode;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final current = attempt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canSignIn && current == null && (!connected || needsAttention))
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.secondary,
            onPressed: busy ? null : onBegin,
            child: Text(
              connected || needsAttention
                  ? l.credentialsSignInAgain
                  : l.credentialsBrowserLogin,
            ),
          ),
        if (current == null && ownUnreachable)
          Text(
            l.credentialsSignInPhoneUnreachable,
            style: TextStyle(color: t.textSecondary),
          ),
        if (current == null && unavailable)
          Text(
            l.credentialsSignInUnavailable(provider),
            style: TextStyle(color: t.textSecondary),
          ),
        if (current != null) ...[
          // Both modes end on a browser page that shows a confirmation code.
          Text(
            l.credentialsSignInConfirmInBrowser,
            style: TextStyle(color: t.textSecondary),
          ),
          const SizedBox(height: 8),
          // RTL carve-out: the confirmation code is a Latin token.
          Directionality(
            textDirection: TextDirection.ltr,
            child: CcTextField(
              controller: code,
              label: l.credentialsConnectCodePrompt,
              textStyle: TextStyle(
                fontSize: 22,
                letterSpacing: 3,
                color: t.textPrimary,
              ),
              onSubmitted: (_) => onConfirmCode(),
            ),
          ),
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.primary,
            onPressed: busy ? null : onConfirmCode,
            child: Text(l.confirm),
          ),
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.secondary,
            onPressed: () => openExternal(current.url),
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
    this.emailController,
  });

  final bool connected;
  final bool editing;
  final bool busy;
  final TextEditingController controller;

  /// The Atlassian account email, asked for alongside a Bitbucket API token;
  /// null for a forge whose token stands alone.
  final TextEditingController? emailController;
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
          if (emailController case final email?)
            CcTextField(
              controller: email,
              label: l.credentialsAtlassianEmail,
              hintText: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
          CcTextField(
            controller: controller,
            obscureText: true,
            label: emailController == null
                ? l.credentialsPersonalToken
                : l.credentialsBitbucketApiToken,
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
