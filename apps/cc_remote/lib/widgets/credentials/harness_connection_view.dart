part of 'harness_connection_card.dart';

mixin _HarnessConnectionView
    on ConsumerState<HarnessConnectionCard>, _HarnessConnectionFlow {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final info = widget.info;
    final flow = _flow;
    return CcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            info.displayName,
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            info.connected ? l.credentialsConnected : l.credentialsNotConnected,
            style: TextStyle(color: t.textSecondary),
          ),
          for (final credential in info.credentials)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          credential.label ??
                              credential.hint ??
                              (credential.method == HarnessAuthMethod.oauth
                                  ? l.credentialsAccount
                                  : l.credentialsStoredKey),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: t.textPrimary),
                        ),
                      ),
                      if (credential.isActive)
                        Text(
                          l.credentialsActive,
                          style: TextStyle(color: t.textSecondary),
                        ),
                      if (widget.canManage && credential.removable)
                        SizedBox(
                          width: 88,
                          child: CcButton(
                            size: CcButtonSize.lg,
                            variant:
                                _confirmRemovalId == credential.credentialId
                                ? CcButtonVariant.destructive
                                : CcButtonVariant.ghost,
                            onPressed: _busy
                                ? null
                                : () {
                                    if (_confirmRemovalId ==
                                        credential.credentialId) {
                                      unawaited(_remove(credential));
                                    } else {
                                      setState(
                                        () => _confirmRemovalId =
                                            credential.credentialId,
                                      );
                                    }
                                  },
                            child: Text(l.credentialsRemove),
                          ),
                        ),
                    ],
                  ),
                  if (_confirmRemovalId == credential.credentialId)
                    Text(
                      l.credentialsRemoveConfirm,
                      style: TextStyle(color: t.textSecondary),
                    ),
                ],
              ),
            ),
          if (info.credentials.isEmpty && info.hasCredential)
            Text(
              info.accountLabel ?? l.credentialsStoredKey,
              style: TextStyle(color: t.textSecondary),
            ),
          if (widget.canManage && info.isCustom && info.hasCredential) ...[
            const SizedBox(height: 8),
            CcButton(
              size: CcButtonSize.lg,
              variant: _confirmRemovalId == ''
                  ? CcButtonVariant.destructive
                  : CcButtonVariant.ghost,
              onPressed: _busy
                  ? null
                  : () {
                      if (_confirmRemovalId == '') {
                        unawaited(_remove(null));
                      } else {
                        setState(() => _confirmRemovalId = '');
                      }
                    },
              child: Text(l.credentialsRemove),
            ),
            if (_confirmRemovalId == '')
              Text(
                l.credentialsRemoveConfirm,
                style: TextStyle(color: t.textSecondary),
              ),
          ],
          if (widget.canManage && info.supportsApiKey)
            _HarnessKeyForm(
              controller: _secret,
              busy: _busy,
              signingIn: flow != null,
              onSave: _save,
            ),
          if (widget.canManage && info.supportsOAuth)
            _HarnessOAuthForm(
              flow: flow,
              controller: _code,
              busy: _busy,
              onStart: _start,
              onComplete: _complete,
              onCancel: _cancel,
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: t.textErrorPrimary)),
            ),
        ],
      ),
    );
  }
}
