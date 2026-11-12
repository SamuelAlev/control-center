import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/person_token_refusal.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Why the server refused [error]'s pasted token for [forge], in words the
/// person can act on; null when [error] is not such a refusal.
String? personTokenRefusalMessage(
  AppLocalizations l10n,
  Object error,
  ForgeHost forge,
) {
  final refusal = error is RemoteRpcException
      ? PersonTokenRefusal.ofErrorData(error.data)
      : null;
  final name = forge.displayName;
  return switch (refusal) {
    PersonTokenRefusal.unreachable => l10n.personTokenUnreachable(name),
    PersonTokenRefusal.rejected => l10n.personTokenRejected(name),
    PersonTokenRefusal.wrongKind => l10n.personTokenWrongKind(name),
    PersonTokenRefusal.narrowScope => l10n.personTokenNarrowScope(
      switch (forge) {
        // The forges' own scope names, never translated.
        ForgeHost.bitbucket => 'write:pullrequest:bitbucket',
        _ => 'api',
      },
    ),
    PersonTokenRefusal.expired => l10n.personTokenExpired,
    null => null,
  };
}

/// Asks for a token-only [forge]'s token (GitLab, Bitbucket), then stores
/// it as the reader's own credential, used in every workspace on this
/// server. Resolves true once it is saved.
///
/// Bitbucket API tokens authenticate together with the Atlassian account's
/// email, so Bitbucket asks for both and stores them as `email:token`; a
/// GitLab token is one field.
Future<bool> showForgeTokenDialog(
  BuildContext context, {
  required ForgeHost forge,
}) async {
  final saved = await showCcDialog<bool>(
    context: context,
    builder: (_) => ForgeTokenDialog(forge: forge),
  );
  return saved ?? false;
}

/// The body of [showForgeTokenDialog].
class ForgeTokenDialog extends ConsumerStatefulWidget {
  /// Creates a [ForgeTokenDialog].
  const ForgeTokenDialog({super.key, required this.forge});

  /// The token-only forge.
  final ForgeHost forge;

  @override
  ConsumerState<ForgeTokenDialog> createState() => _ForgeTokenDialogState();
}

class _ForgeTokenDialogState extends ConsumerState<ForgeTokenDialog> {
  final _token = TextEditingController();
  final _email = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _token.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    var token = _token.text.trim();
    if (token.isEmpty || _saving) {
      return;
    }
    if (_needsEmail) {
      final email = _email.text.trim();
      if (!isPlausibleAccountEmail(email)) {
        setState(() => _error = l10n.forgeTokenEmailInvalid);
        return;
      }
      token = '$email:$token';
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await setForgeToken(ref, widget.forge, token);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              personTokenRefusalMessage(l10n, e, widget.forge) ??
              failureMessage(l10n, e);
        });
      }
    }
  }

  bool get _needsEmail => widget.forge == ForgeHost.bitbucket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcDialog(
      title: l10n.forgeTokenTitle(widget.forge.displayName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_needsEmail) ...[
            Text(
              l10n.forgeTokenBitbucketHint,
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            CcTextField(
              controller: _email,
              label: l10n.forgeTokenEmailLabel,
              hintText: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          CcTextField(
            controller: _token,
            label: _needsEmail ? l10n.forgeTokenApiTokenLabel : null,
            hintText: l10n.pasteValueHere,
            obscureText: true,
            autofocus: !_needsEmail,
            onSubmitted: (_) => unawaited(_save()),
          ),
          if (_error case final error?) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              error,
              style: CcTypography.caption.copyWith(color: t.textErrorPrimary),
            ),
          ],
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        CcButton(
          loading: _saving,
          onPressed: _saving ? null : () => unawaited(_save()),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Whether [email] can be an Atlassian account's email: one `@` with text on
/// both sides, a dot in the domain, and no colon or whitespace, since the
/// stored credential is `email:token`.
bool isPlausibleAccountEmail(String email) =>
    RegExp(r'^[^\s@:]+@[^\s@:]+\.[^\s@:]+$').hasMatch(email);
