// Shared "log in to a harness provider" surface.
//
// Extracted from the Settings → Providers & models tile so the same flow —
// API-key save, browser OAuth (loopback, device-code and paste-code
// fallback) and polling — also runs inside a dialog during onboarding and
// anywhere else a provider connection is required inline. Both surfaces share
// this one implementation; a second copy would drift.

import 'dart:async';

import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connection controls for one built-in-harness provider: the stored
/// credentials (API keys and OAuth accounts — several per provider, rotated
/// automatically when one is exhausted), an API-key add row (when the provider
/// accepts keys) and/or a browser-OAuth login (when it offers one), with the
/// pending states for device-code and paste-code flows. Calls [onConnected]
/// once a credential lands.
class HarnessProviderLoginPanel extends ConsumerStatefulWidget {
  /// Creates a [HarnessProviderLoginPanel].
  const HarnessProviderLoginPanel({
    required this.info,
    this.onConnected,
    super.key,
  });

  /// The provider to connect.
  final HarnessProviderInfo info;

  /// Called after a key save or OAuth completion connects the provider.
  final VoidCallback? onConnected;

  @override
  ConsumerState<HarnessProviderLoginPanel> createState() =>
      _HarnessProviderLoginPanelState();
}

class _HarnessProviderLoginPanelState
    extends ConsumerState<HarnessProviderLoginPanel> {
  final _keyController = TextEditingController();
  final _codeController = TextEditingController();
  bool _busy = false;

  /// The code the user must confirm in the browser, for device-code logins.
  String? _userCode;
  String? _oauthFlowId;
  String? _oauthError;
  Timer? _pollTimer;

  HarnessProviderInfo get info => widget.info;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _keyController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final hasOAuthAccount = info.credentials.any(
      (c) => c.method == HarnessAuthMethod.oauth,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Every stored credential, in rotation order: runs start on the active
        // one and advance down the list when a key/subscription is exhausted.
        if (info.credentials.isNotEmpty) ...[
          for (final cred in info.credentials)
            _CredentialRow(
              cred: cred,
              busy: _busy,
              onRemove: cred.removable ? () => _removeCredential(cred) : null,
            ),
          const SizedBox(height: 8),
        ],
        // An OAuth-only provider (a plan, not a metered API) issues no key —
        // showing a key box would invite pasting one that can never work.
        if (info.supportsApiKey)
          Row(
            children: [
              Expanded(
                child: CcTextField(
                  controller: _keyController,
                  hintText: info.credentials.isNotEmpty
                      ? l10n.providerApiKeyStoredHint
                      : l10n.providerApiKeyHint,
                  obscureText: true,
                ),
              ),
              const SizedBox(width: 8),
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: _busy ? null : _saveApiKey,
                child: Text(l10n.save),
              ),
            ],
          ),
        // Signing in again adds ANOTHER account to the rotation (dedup by
        // account identity), so the login stays offered no matter how many
        // accounts are already connected.
        if (info.supportsOAuth) ...[
          const SizedBox(height: 8),
          if (_oauthFlowId == null)
            _hug(
              CcButton(
                variant: CcButtonVariant.secondary,
                icon: AppIcons.externalLink,
                onPressed: _busy ? null : _startOAuth,
                child: Text(
                  hasOAuthAccount
                      ? l10n.providerAddAnotherAccount
                      : l10n.providerLogInWithBrowser,
                ),
              ),
            )
          else
            _oauthPendingControls(l10n, tokens),
        ],
        if (_oauthError != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.providerLoginFailed(_oauthError!),
            style: TextStyle(fontSize: 12, color: tokens?.textErrorPrimary),
          ),
        ],
      ],
    );
  }

  /// Confirms, then removes one credential of the rotation. Removing is not
  /// undoable from here — a key is not shown again after saving and an OAuth
  /// account needs the whole browser login repeated.
  Future<void> _removeCredential(HarnessCredentialSummary cred) async {
    final l10n = AppLocalizations.of(context);
    final oauth = cred.method == HarnessAuthMethod.oauth;
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: oauth
            ? l10n.providerSignOutAccountConfirmTitle
            : l10n.providerRemoveCredentialConfirmTitle,
        content: Text(
          l10n.providerCredentialRemoveConfirmBody(info.displayName),
        ),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(oauth ? l10n.providerSignOut : l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await removeHarnessCredential(
        ref,
        providerId: info.id,
        credentialId: cred.credentialId,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Keeps a button at its natural width. `CcButton` paints through a
  /// `Container` with an `alignment`, which makes it greedy: given the bounded
  /// width a Column hands down it stretches edge to edge and centres its label.
  /// A `Row` with `mainAxisSize.min` hands it unbounded width instead, so it
  /// hugs its content the way it does everywhere else in this screen.
  static Widget _hug(Widget button) =>
      Row(mainAxisSize: MainAxisSize.min, children: [button]);

  Widget _oauthPendingControls(
    AppLocalizations l10n,
    DesignSystemTokens? tokens,
  ) {
    final userCode = _userCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CcSpinner(size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                userCode == null
                    ? l10n.providerWaitingForBrowser
                    : l10n.providerWaitingForDeviceCode,
                style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
              ),
            ),
            CcButton(
              variant: CcButtonVariant.ghost,
              onPressed: _cancelOAuth,
              child: Text(l10n.cancel),
            ),
          ],
        ),
        // Device-code login: the browser asks the user to confirm this exact
        // code. Rendered large and monospaced because it is read and compared
        // character by character and selectable so it can be sent to whichever
        // device is doing the signing in.
        if (userCode != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                userCode,
                style: CcFonts.code(
                  textStyle: const TextStyle(
                    fontSize: 22,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ).copyWith(color: tokens?.textPrimary),
              ),
              const SizedBox(width: 8),
              CcButton(
                variant: CcButtonVariant.ghost,
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: userCode)),
                child: Text(l10n.copy),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.providerDeviceCodeHint,
            style: TextStyle(fontSize: 11, color: tokens?.textTertiary),
          ),
        ],
        // Manual code-paste fallback (web / remote server where the loopback
        // callback isn't reachable). A device flow has nothing to paste — it
        // resolves by polling — so the box would be a dead end there.
        if (userCode == null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CcTextField(
                  controller: _codeController,
                  hintText: l10n.providerPasteCodeHint,
                ),
              ),
              const SizedBox(width: 8),
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: _busy ? null : _completeOAuth,
                child: Text(l10n.providerCompleteLogin),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _saveApiKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      await saveHarnessApiKey(ref, providerId: info.id, apiKey: key);
      _keyController.clear();
      widget.onConnected?.call();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _startOAuth() async {
    setState(() {
      _busy = true;
      _oauthError = null;
    });
    try {
      final start = await startHarnessOAuth(ref, info.id);
      openExternalUrl(start.authUrl);
      if (!mounted) {
        return;
      }
      setState(() {
        _oauthFlowId = start.flowId;
        _userCode = start.userCode;
      });
      _startPolling(start.flowId);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _oauthError = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _startPolling(String flowId) {
    _pollTimer?.cancel();
    var ticks = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      ticks++;
      // ~15 min: a device-code login is read off one screen and typed on
      // another, so it needs the provider's full code lifetime, not the few
      // seconds a redirect round-trip takes.
      if (ticks > 450) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _oauthFlowId = null;
            _userCode = null;
          });
        }
        return;
      }
      try {
        final status = await pollHarnessOAuth(ref, flowId);
        if (status.state == HarnessOAuthState.completed) {
          timer.cancel();
          ref
            ..invalidate(harnessProvidersProvider)
            ..invalidate(harnessModelsProvider);
          widget.onConnected?.call();
          if (mounted) {
            setState(() {
              _oauthFlowId = null;
              _userCode = null;
            });
          }
        } else if (status.state == HarnessOAuthState.error) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _oauthFlowId = null;
              _userCode = null;
              _oauthError = status.error;
            });
          }
        }
      } on Object {
        // Transient poll failure — keep trying until the timeout.
      }
    });
  }

  Future<void> _completeOAuth() async {
    final flowId = _oauthFlowId;
    final code = _codeController.text.trim();
    if (flowId == null || code.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      await completeHarnessOAuth(ref, flowId: flowId, code: code);
      _pollTimer?.cancel();
      _codeController.clear();
      ref
        ..invalidate(harnessProvidersProvider)
        ..invalidate(harnessModelsProvider);
      widget.onConnected?.call();
      if (mounted) {
        setState(() {
          _oauthFlowId = null;
          _userCode = null;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _oauthError = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _cancelOAuth() async {
    final flowId = _oauthFlowId;
    _pollTimer?.cancel();
    setState(() {
      _oauthFlowId = null;
      _userCode = null;
    });
    if (flowId != null) {
      await cancelHarnessOAuth(ref, flowId);
    }
  }
}

/// One stored credential in a provider's rotation: an icon for the auth
/// method, the account label or masked key tail, an "active" marker on the
/// credential runs start from, and a remove action when the credential is
/// removable (env-var credentials are read-only).
class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.cred, required this.busy, this.onRemove});

  final HarnessCredentialSummary cred;
  final bool busy;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final oauth = cred.method == HarnessAuthMethod.oauth;
    final label =
        cred.label ??
        cred.hint ??
        (oauth
            ? l10n.providerOauthAccountFallback
            : l10n.providerApiKeyFallback);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            oauth ? AppIcons.user : AppIcons.keyRound,
            size: 13,
            color: tokens?.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: tokens?.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (cred.isActive) ...[
            CcChip(label: l10n.providerActiveBadge),
            const SizedBox(width: 4),
          ],
          if (onRemove != null)
            CcIconButton(
              icon: AppIcons.trash2,
              tooltip: oauth ? l10n.providerSignOut : l10n.remove,
              onPressed: busy ? null : onRemove,
            ),
        ],
      ),
    );
  }
}

/// Presents [HarnessProviderLoginPanel] in a dialog. Resolves `true` when the
/// provider connected, `false` when the user dismissed the dialog.
Future<bool> showHarnessProviderLoginDialog(
  BuildContext context,
  HarnessProviderInfo info,
) async {
  final l10n = AppLocalizations.of(context);
  final connected = await showCcDialog<bool>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: l10n.providerLoginDialogTitle(info.displayName),
      onClose: () => Navigator.pop(dialogContext, false),
      content: HarnessProviderLoginPanel(
        info: info,
        onConnected: () => Navigator.pop(dialogContext, true),
      ),
    ),
  );
  return connected ?? false;
}
