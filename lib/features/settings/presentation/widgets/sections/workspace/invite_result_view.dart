import 'dart:convert';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The post-creation view of an invite: the ONE-TIME code, a copyable invite
/// link (when the server advertises a reachable redemption URL) and a QR of
/// the redemption payload for a phone camera.
class InviteResultView extends StatelessWidget {
  /// Creates an [InviteResultView].
  const InviteResultView({
    super.key,
    required this.code,
    required this.redeemUrl,
    this.descriptor,
  });

  /// The one-time invite code (never shown again after this dialog closes).
  final String code;

  /// The server's redemption URL; empty when the host advertises none.
  final String redeemUrl;

  /// The server's live connection descriptor JSON (every path + fingerprint),
  /// embedded in the QR so the resolver can find a way in even when the redeem
  /// URL alone is unreachable. Null when the server didn't publish one.
  final Map<String, dynamic>? descriptor;

  /// The server origin (scheme + host + port) derived from [redeemUrl].
  String get _serverOrigin {
    final uri = Uri.tryParse(redeemUrl);
    if (uri == null || uri.host.isEmpty) {
      return '';
    }
    return uri.replace(path: '', query: '', fragment: '').toString();
  }

  /// Whether the derived origin points at the local machine — an address no
  /// off-host collaborator can reach. Triggers the warning banner.
  bool get _isLoopbackOrigin {
    final origin = _serverOrigin;
    if (origin.isEmpty) {
      return true;
    }
    final uri = Uri.tryParse(origin);
    final host = uri?.host ?? '';
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '[::1]' ||
        host.isEmpty;
  }

  /// The QR/link payload: `{s: <server origin>, inv: <one-time code>}` plus
  /// `d: <descriptor JSON>` when the server published one — the exact fragment
  /// shape the web client's boot reads to redeem in place.
  String get _qrPayload => jsonEncode({
    's': _serverOrigin,
    'inv': code,
    if (descriptor != null) 'd': descriptor,
  });

  /// The one-tap invite link: the server-hosted web client with the payload
  /// in the URL FRAGMENT (a fragment never reaches server logs). Opening it
  /// redeems the code and connects as the new member. Empty when the server
  /// advertises no reachable URL.
  String get _inviteLink {
    final origin = _serverOrigin;
    if (origin.isEmpty) {
      return '';
    }
    final fragment = base64UrlEncode(
      utf8.encode(_qrPayload),
    ).replaceAll('=', '');
    return '$origin/#$fragment';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.inviteCodeShownOnce,
          style: CcTypography.bodySm.copyWith(color: t.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        _CopyRow(label: l10n.inviteOneTimeCodeLabel, value: code),
        if (_inviteLink.isNotEmpty)
          _CopyRow(label: l10n.inviteLinkLabel, value: _inviteLink)
        else ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.inviteRedeemHint,
            style: CcTypography.bodySm.copyWith(color: t.textTertiary),
          ),
        ],
        if (_isLoopbackOrigin) ...[
          const SizedBox(height: AppSpacing.md),
          CcAlert(
            variant: CcAlertVariant.warning,
            title: l10n.inviteLoopbackWarningTitle,
            description: Text(
              l10n.inviteLoopbackWarningBody,
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.inviteScanQr,
          style: CcTypography.bodySm.copyWith(color: t.textTertiary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: const Color(0xFFFFFFFF),
            child: QrImageView(
              data: _qrPayload,
              size: 180,
              backgroundColor: const Color(0xFFFFFFFF),
            ),
          ),
        ),
      ],
    );
  }
}

/// A label + monospaced value + copy button row (the pairing-panel treatment).
class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CcTypography.bodySm.copyWith(color: t.textTertiary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              CcToastScope.of(
                context,
              ).show(l10n.copied, variant: CcToastVariant.success);
            },
            child: Text(l10n.copy),
          ),
        ],
      ),
    );
  }
}
