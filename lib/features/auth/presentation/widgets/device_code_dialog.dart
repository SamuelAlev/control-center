import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The one screen of a device-code sign-in: the code to type, where to type
/// it, and a spinner until the server says it worked.
///
/// The code is the whole interaction, so it is rendered large and in the code
/// font — someone reading it off a laptop onto a phone should not have to
/// squint at `0` versus `O` — and it is copied to the clipboard the moment
/// this opens. The provider's page is opened for them when the flow starts.
///
/// Dismissing it does NOT cancel the sign-in: the server keeps polling until
/// the code expires, so finishing in the browser afterwards still connects.
///
/// The scrim does not dismiss. The browser is opened as this appears, and the
/// click that brings the window back would otherwise hit the barrier and throw
/// the code away before it can be read.
Future<void> showDeviceCodeDialog(
  BuildContext context, {
  required String providerName,
  required SignInDeviceCode prompt,
  required Future<bool> Function() connected,
}) => showCcDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (dialogContext) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () =>
          Navigator.of(dialogContext).maybePop(),
    },
    child: _DeviceCodeDialog(
      providerName: providerName,
      prompt: prompt,
      connected: connected,
    ),
  ),
);

class _DeviceCodeDialog extends StatefulWidget {
  const _DeviceCodeDialog({
    required this.providerName,
    required this.prompt,
    required this.connected,
  });

  final String providerName;
  final SignInDeviceCode prompt;
  final Future<bool> Function() connected;

  @override
  State<_DeviceCodeDialog> createState() => _DeviceCodeDialogState();
}

class _DeviceCodeDialogState extends State<_DeviceCodeDialog> {
  bool _done = false;
  bool _checking = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // The code lands on the clipboard the moment the dialog opens: every
    // person who sees this screen is about to paste it.
    Clipboard.setData(ClipboardData(text: widget.prompt.userCode));
    // After the code has painted. Opening the browser first hides this route
    // under another app, and coming back dismisses a barrier-dismissible
    // dialog on the same click.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final uri = widget.prompt.verificationUri;
      if (uri.isNotEmpty) {
        openExternalUrl(uri);
      }
    });
    _watch();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _watch() async {
    // "Sign in again" is already connected. The first poll would match that
    // existing row and close this before the new code can be read. Stay up;
    // the server still stores the new credential when the browser flow ends.
    final alreadyConnected = await widget.connected();
    if (!mounted || alreadyConnected) {
      return;
    }
    final deadline = DateTime.now().add(kSignInTimeout);
    _poll = Timer.periodic(const Duration(seconds: 2), (_) {
      if (DateTime.now().isAfter(deadline)) {
        _poll?.cancel();
        return;
      }
      unawaited(_check());
    });
  }

  Future<void> _check() async {
    if (_checking || !mounted) {
      return;
    }
    _checking = true;
    try {
      final ok = await widget.connected();
      if (!mounted || !ok) {
        return;
      }
      _poll?.cancel();
      setState(() => _done = true);
      Navigator.of(context).maybePop();
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;

    return CcDialog(
      title: l10n.signInWithProvider(widget.providerName),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.deviceCodeInstructions(widget.providerName),
            style: CcTypography.body.copyWith(color: tokens?.textSecondary),
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.prompt.userCode,
                  style: CcFonts.code(
                    textStyle: CcTypography.display,
                  ).copyWith(letterSpacing: 4, color: tokens?.textPrimary),
                ),
                // Same affordance as the harness-provider device flow: an
                // explicit copy beside the code, for when the clipboard moved
                // on between opening this dialog and pasting it.
                const SizedBox(width: 8),
                CcButton(
                  variant: CcButtonVariant.ghost,
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: widget.prompt.userCode),
                  ),
                  child: Text(l10n.copy),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const CcSpinner(size: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _done ? l10n.signedIn : l10n.deviceCodeWaiting,
                  style: CcTypography.caption.copyWith(
                    color: tokens?.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.of(context).maybePop(),
          variant: CcButtonVariant.ghost,
          child: Text(l10n.close),
        ),
        CcButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.prompt.userCode));
            if (widget.prompt.verificationUri.isNotEmpty) {
              openExternalUrl(widget.prompt.verificationUri);
            }
          },
          child: Text(l10n.copyCodeAndOpen),
        ),
      ],
    );
  }
}
