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
Future<void> showDeviceCodeDialog(
  BuildContext context, {
  required String providerName,
  required SignInDeviceCode prompt,
  required Future<bool> Function() connected,
}) => showCcDialog<void>(
  context: context,
  builder: (dialogContext) => _DeviceCodeDialog(
    providerName: providerName,
    prompt: prompt,
    connected: connected,
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

  @override
  void initState() {
    super.initState();
    // The code lands on the clipboard the moment the dialog opens: every
    // person who sees this screen is about to paste it.
    Clipboard.setData(ClipboardData(text: widget.prompt.userCode));
    _watch();
  }

  Future<void> _watch() async {
    final ok = await awaitSignIn(widget.connected);
    if (!mounted) {
      return;
    }
    setState(() => _done = ok);
    if (ok) {
      Navigator.of(context).maybePop();
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
