part of 'personal_connection_card.dart';

mixin _PersonalConnectionView
    on
        ConsumerState<PersonalConnectionCard>,
        _PersonalCredentialActions,
        _PersonalConnectionFlow {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final canSignIn =
        widget.signInFlow == 'device' ||
        (widget.signInFlow == 'redirect' &&
            phoneCanUseRedirect(widget.redirectUri));
    return CcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.name,
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            widget.statusError?.isNotEmpty == true
                ? widget.statusError!
                : widget.connected
                ? widget.username.isEmpty
                      ? l.credentialsConnected
                      : l.credentialsSignedInAs(widget.username)
                : l.credentialsNotConnected,
            style: TextStyle(color: t.textSecondary),
          ),
          if (widget.hostManaged)
            Text(
              l.credentialsHostManaged,
              style: TextStyle(color: t.textSecondary),
            ),
          if (widget.canManage) ...[
            const SizedBox(height: 10),
            if (widget.connected && !widget.hostManaged)
              CcButton(
                size: CcButtonSize.lg,
                variant: CcButtonVariant.ghost,
                onPressed: _busy
                    ? null
                    : () => setState(() => _confirmRemove = !_confirmRemove),
                child: Text(l.disconnect),
              ),
            if (_confirmRemove && widget.connected && !widget.hostManaged) ...[
              Text(
                l.credentialsRemoveConfirm,
                style: TextStyle(color: t.textSecondary),
              ),
              CcButton(
                size: CcButtonSize.lg,
                variant: CcButtonVariant.destructive,
                onPressed: _busy ? null : _remove,
                child: Text(l.credentialsRemove),
              ),
            ],
            _PersonalSignInForm(
              canSignIn: canSignIn,
              connected: widget.connected,
              signInFlow: widget.signInFlow,
              verificationUrl: _verificationUrl,
              userCode: _userCode,
              busy: _busy,
              onBegin: _begin,
              onStop: _stop,
            ),
            _PersonalTokenForm(
              connected: widget.connected,
              editing: _editing,
              busy: _busy,
              controller: _token,
              onEdit: () => setState(() => _editing = true),
              onSave: _save,
              onCancel: () {
                _token.clear();
                setState(() => _editing = false);
              },
            ),
          ],
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
