import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/server/invite_redeemer.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Renders a connection failure on the server-setup / connect-gate surfaces:
/// a friendly, localized explanation with the raw error tucked behind a
/// "technical details" toggle, so diagnostics (timeouts, relay probes) stay
/// reachable without confronting the user with an exception dump.
///
/// [error] is classified through [classifyConnectionError] — including plain
/// strings, which supervisor statuses carry (`e.toString()`). To show an
/// already localized message verbatim (e.g. form validation), wrap it in a
/// [UserFacingMessage].
class ConnectionErrorAlert extends StatefulWidget {
  /// Creates a [ConnectionErrorAlert] for [error].
  const ConnectionErrorAlert({super.key, required this.error, this.title});

  /// The failure to present.
  final Object error;

  /// Optional headline override; defaults to the localized
  /// "Could not connect" connect-gate title.
  final String? title;

  @override
  State<ConnectionErrorAlert> createState() => _ConnectionErrorAlertState();
}

/// An already user-facing (localized) message. [ConnectionErrorAlert]
/// renders it verbatim, with no classification and no details toggle.
class UserFacingMessage {
  /// Creates a [UserFacingMessage] wrapping [text].
  const UserFacingMessage(this.text);

  /// The message to show as-is.
  final String text;
}

class _ConnectionErrorAlertState extends State<ConnectionErrorAlert> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final error = widget.error;

    // An already user-facing message (localized upstream) renders as-is.
    if (error is UserFacingMessage) {
      return CcAlert(
        variant: CcAlertVariant.danger,
        title: widget.title ?? l10n.serverSetupCouldNotConnect,
        description: Text(
          error.text,
          style: CcTypography.bodySm.copyWith(
            color: t.textErrorPrimary,
            decoration: TextDecoration.none,
          ),
        ),
      );
    }

    // Invite refusals are app-side (only this client redeems invite codes),
    // so the transport classifier doesn't know the type — check it first.
    final message = error is InviteRejectedException
        ? l10n.serverSetupErrorInviteRejected
        : switch (classifyConnectionError(error)) {
            ConnectionFailureKind.unreachable =>
              l10n.serverSetupErrorUnreachable,
            ConnectionFailureKind.identityMismatch =>
              l10n.serverSetupErrorIdentityMismatch,
            ConnectionFailureKind.authRejected =>
              l10n.serverSetupErrorAuthRejected,
            ConnectionFailureKind.unknown => l10n.serverSetupErrorGeneric,
          };
    var detail = error.toString();
    // Strip only leading wrapper prefixes — a naive replaceFirst would
    // mangle 'NoReachablePathException: …' into 'NoReachablePath…'.
    for (final prefix in const ['Exception: ', 'Bad state: ']) {
      if (detail.startsWith(prefix)) {
        detail = detail.substring(prefix.length);
        break;
      }
    }

    return CcAlert(
      variant: CcAlertVariant.danger,
      title: widget.title ?? l10n.serverSetupCouldNotConnect,
      description: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: CcTypography.bodySm.copyWith(
              color: t.textErrorPrimary,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            button: true,
            expanded: _expanded,
            label: l10n.serverSetupErrorDetails,
            child: CcTappable(
              onPressed: () => setState(() => _expanded = !_expanded),
              semanticButton: false,
              borderRadius: AppRadii.brSm,
              builder: (context, states) {
                final hovered = states.contains(WidgetState.hovered);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _expanded ? AppIcons.chevronDown : AppIcons.chevronRight,
                      size: 12,
                      color: t.textErrorPrimary.withValues(
                        alpha: hovered ? 1 : 0.7,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.serverSetupErrorDetails,
                      style: CcTypography.caption.copyWith(
                        color: t.textErrorPrimary.withValues(
                          alpha: hovered ? 1 : 0.7,
                        ),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              detail,
              style:
                  CcFonts.code(
                    textStyle: CcTypography.caption,
                    family: context.ccTheme?.monoFontFamily,
                  ).copyWith(
                    color: t.textErrorPrimary.withValues(alpha: 0.8),
                    decoration: TextDecoration.none,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
