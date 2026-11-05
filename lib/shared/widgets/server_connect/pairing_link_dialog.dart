import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/server/pairing_link.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/connection_error_alert.dart';
import 'package:control_center/shared/widgets/server_connect/server_connect_dialog.dart';
import 'package:flutter/widgets.dart';

/// Connects with a pasted invite or pairing link.
///
/// A link can name any server and anyone can forge one, so this never connects
/// on paste: the operator sees where the link leads, then presses Connect. The
/// field is obscured because the link carries a live credential.
class PairingLinkDialog extends StatefulWidget {
  /// Creates a [PairingLinkDialog].
  const PairingLinkDialog({super.key, required this.onConnect, this.footer});

  /// Connects with the link's credentials. A throw keeps the dialog open and
  /// shows the failure beside the link.
  final Future<void> Function(ServerConnectCredentials) onConnect;

  /// Extra content under the form, such as a remember-this-device choice.
  final Widget? footer;

  @override
  State<PairingLinkDialog> createState() => _PairingLinkDialogState();
}

class _PairingLinkDialogState extends State<PairingLinkDialog> {
  final TextEditingController _link = TextEditingController();
  PairingLink? _parsed;
  bool _connecting = false;
  Object? _error;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _parsed = PairingLink.parse(value);
      _error = null;
    });
  }

  Future<void> _connect() async {
    final link = _parsed;
    if (link == null || _connecting) {
      return;
    }
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      await widget.onConnect((
        rawUrl: link.server,
        inviteCode: link.inviteCode,
        deviceId: link.deviceId,
        psk: link.psk,
      ));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _connecting = false;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final parsed = _parsed;
    final invalid = parsed == null && _link.text.trim().isNotEmpty;
    final error = _error;
    return CcDialog(
      title: l10n.connectPasteLink,
      onClose: _connecting ? null : () => Navigator.of(context).pop(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.connectPasteLinkIntro,
            style: CcTypography.bodySm.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          CcTextField(
            controller: _link,
            label: l10n.connectPasteLinkLabel,
            hintText: 'https://host/#…',
            obscureText: true,
            autofocus: true,
            enabled: !_connecting,
            errorText: invalid ? l10n.connectPasteLinkInvalid : null,
            onChanged: _onChanged,
            onSubmitted: (_) => unawaited(_connect()),
          ),
          if (parsed != null) ...[
            const SizedBox(height: AppSpacing.md),
            _LinkTarget(server: parsed.displayServer),
          ],
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            ConnectionErrorAlert(error: error),
          ],
          if (widget.footer case final footer?) ...[
            const SizedBox(height: AppSpacing.md),
            footer,
          ],
        ],
      ),
      actions: [
        CcButton(
          onPressed: _connecting ? null : () => Navigator.of(context).pop(),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: parsed == null || _connecting
              ? null
              : () => unawaited(_connect()),
          variant: CcButtonVariant.accent,
          icon: AppIcons.link,
          loading: _connecting,
          child: Text(l10n.serverSetupConnect),
        ),
      ],
    );
  }
}

/// Where the pasted link leads, shown before anything connects.
class _LinkTarget extends StatelessWidget {
  const _LinkTarget({required this.server});

  final String server;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.connectPasteLinkTarget,
          style: CcTypography.caption.copyWith(color: t.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        // RTL carve-out: a server address is an LTR machine value.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            server,
            style: CcFonts.code(
              textStyle: CcTypography.bodySm.copyWith(color: t.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
