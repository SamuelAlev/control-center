import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/providers/connect_account_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the Google Calendar connect dialog: the user enters an OAuth
/// device-code client id + secret, the host runs the device flow, and they
/// approve the printed code on any device. Used from every connect entry point
/// (the calendar empty state, the sidebar, the reauth banner, settings).
Future<void> showGoogleCalendarConnectDialog(BuildContext context) {
  return showCcDialog<void>(
    context: context,
    builder: (_) => const _GoogleCalendarConnectDialog(),
  );
}

class _GoogleCalendarConnectDialog extends ConsumerStatefulWidget {
  const _GoogleCalendarConnectDialog();

  @override
  ConsumerState<_GoogleCalendarConnectDialog> createState() =>
      _GoogleCalendarConnectDialogState();
}

class _GoogleCalendarConnectDialogState
    extends ConsumerState<_GoogleCalendarConnectDialog> {
  final _clientId = TextEditingController();
  final _clientSecret = TextEditingController();

  @override
  void dispose() {
    _clientId.dispose();
    _clientSecret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(connectGoogleCalendarProvider);
    final notifier = ref.read(connectGoogleCalendarProvider.notifier);

    // Close the dialog once the host reports the account is connected — the
    // accounts stream then refreshes the surface that opened this.
    ref.listen(connectGoogleCalendarProvider, (_, next) {
      if (next.phase == CalendarConnectPhase.success && mounted) {
        Navigator.of(context).pop();
      }
    });

    final awaiting = state.phase == CalendarConnectPhase.awaitingApproval;
    return CcDialog(
      title: l10n.calendarSettingsTitle,
      content: awaiting
          ? _ApprovalView(
              userCode: state.userCode ?? '',
              verificationUrl: state.verificationUrl ?? '',
            )
          : _CredentialsView(
              clientId: _clientId,
              clientSecret: _clientSecret,
              error: state.error,
            ),
      actions: awaiting
          ? [
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: notifier.cancel,
                child: Text(l10n.cancel),
              ),
            ]
          : [
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              CcButton(
                onPressed: state.phase == CalendarConnectPhase.starting
                    ? null
                    : () => notifier.connect(
                        clientId: _clientId.text,
                        clientSecret: _clientSecret.text,
                      ),
                icon: AppIcons.calendarPlus,
                child: Text(
                  state.phase == CalendarConnectPhase.starting
                      ? l10n.calendarConnecting
                      : l10n.calendarConnectGoogle,
                ),
              ),
            ],
    );
  }
}

/// The client id / secret entry form (idle / starting / failed phases).
class _CredentialsView extends StatelessWidget {
  const _CredentialsView({
    required this.clientId,
    required this.clientSecret,
    required this.error,
  });

  final TextEditingController clientId;
  final TextEditingController clientSecret;
  final CalendarConnectError? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.calendarConnectCredsHint,
          style: TextStyle(fontSize: 13, height: 1.4, color: t.textSecondary),
        ),
        const SizedBox(height: 16),
        CcTextField(
          controller: clientId,
          hintText: l10n.calendarClientIdLabel,
          autofocus: true,
        ),
        const SizedBox(height: 8),
        CcTextField(
          controller: clientSecret,
          hintText: l10n.calendarClientSecretLabel,
          obscureText: true,
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorText(l10n, error!),
            style: TextStyle(fontSize: 12, color: t.bgErrorSolid),
          ),
        ],
      ],
    );
  }

  static String _errorText(AppLocalizations l10n, CalendarConnectError error) =>
      switch (error) {
        CalendarConnectError.denied => l10n.calendarConnectDenied,
        CalendarConnectError.expired => l10n.calendarConnectExpired,
        CalendarConnectError.failed => l10n.calendarConnectError,
      };
}

/// The "approve on another device" view: the code to enter + the link to open.
class _ApprovalView extends StatelessWidget {
  const _ApprovalView({required this.userCode, required this.verificationUrl});

  final String userCode;
  final String verificationUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.calendarConnectApproveInstruction,
          style: TextStyle(fontSize: 13, height: 1.4, color: t.textSecondary),
        ),
        const SizedBox(height: 16),
        // The code to enter, prominent + copyable.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: t.bgSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  userCode,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: t.textPrimary,
                  ),
                ),
              ),
              CcIconButton(
                size: CcButtonSize.sm,
                icon: AppIcons.copy,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: userCode));
                  if (context.mounted) {
                    CcToastScope.of(
                      context,
                    ).show(l10n.copied, variant: CcToastVariant.success);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CcButton(
          variant: CcButtonVariant.secondary,
          icon: AppIcons.externalLink,
          onPressed: () => openExternalUrl(verificationUrl),
          child: Text(l10n.calendarConnectOpenPage),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: t.textTertiary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.calendarConnectWaiting,
              style: TextStyle(fontSize: 13, color: t.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
