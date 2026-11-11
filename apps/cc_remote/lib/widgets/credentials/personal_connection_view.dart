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
    return CcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.name,
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(_statusLine(l), style: TextStyle(color: t.textSecondary)),
          if (widget.canManage) ...[
            const SizedBox(height: 10),
            if (widget.hasGrant)
              CcButton(
                size: CcButtonSize.lg,
                variant: CcButtonVariant.ghost,
                onPressed: _busy
                    ? null
                    : () => setState(() => _confirmRemove = !_confirmRemove),
                child: Text(l.disconnect),
              ),
            if (_confirmRemove && widget.hasGrant) ...[
              Text(
                widget.scope == ForgeCredentialScope.workspace
                    ? l.credentialsRemoveConfirmWorkspace
                    : widget.scope == ForgeCredentialScope.global
                    ? l.credentialsRemoveConfirmAllWorkspaces
                    : l.credentialsRemoveConfirm,
                style: TextStyle(color: t.textSecondary),
              ),
              CcButton(
                size: CcButtonSize.lg,
                variant: CcButtonVariant.destructive,
                onPressed: _busy ? null : _remove,
                child: Text(l.credentialsRemove),
              ),
            ],
            if (widget.lane != null)
              _PersonalSignInForm(
                provider: widget.name,
                canSignIn: _canSignIn && widget.offersSignIn,
                ownUnreachable: _ownUnreachable,
                unavailable:
                    widget.laneInfo?.mode == SignInLaneMode.unavailable,
                connected: widget.connected,
                needsAttention:
                    widget.statusError?.isNotEmpty == true ||
                    widget.status == ForgeConnectionStatus.needsSignIn,
                attempt: _attempt,
                code: _code,
                busy: _busy,
                onBegin: _begin,
                onConfirmCode: _confirmCode,
                onStop: _stop,
              )
            else
              _PersonalTokenForm(
                connected: widget.connected,
                editing: _editing,
                busy: _busy,
                controller: _token,
                emailController: _needsEmail ? _email : null,
                onEdit: () => setState(() => _editing = true),
                onSave: _save,
                onCancel: () {
                  _token.clear();
                  _email.clear();
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

  /// The card's one status line: an error first, then where the sign-in
  /// stands, then who it is and where it applies.
  String _statusLine(AppLocalizations l) {
    if (widget.statusError?.isNotEmpty == true) {
      return widget.statusError!;
    }
    switch (widget.status) {
      case ForgeConnectionStatus.needsSignIn:
        return l.credentialsSignInLapsed(widget.name);
      case ForgeConnectionStatus.paused:
        return l.credentialsSignInPaused;
      case ForgeConnectionStatus.unreachable:
        return l.credentialsProviderUnreachable(widget.name);
      case ForgeConnectionStatus.connected ||
          ForgeConnectionStatus.notConnected ||
          null:
        break;
    }
    if (!widget.connected) {
      return l.credentialsNotConnected;
    }
    final who = widget.username.isEmpty
        ? l.credentialsConnected
        : l.credentialsSignedInAs(widget.username);
    return switch (widget.scope) {
      ForgeCredentialScope.workspace => '$who · ${l.credentialsScopeWorkspace}',
      ForgeCredentialScope.global =>
        '$who · ${l.credentialsScopeAllWorkspaces}',
      null => who,
    };
  }
}
