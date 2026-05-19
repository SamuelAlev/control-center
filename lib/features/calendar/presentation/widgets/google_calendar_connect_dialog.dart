import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/providers/connect_account_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the Google Calendar connect dialog: the user either approves with
/// Control Center's own Google app or supplies an OAuth device-code client id +
/// secret of their own, the host runs the device flow, and they approve the
/// printed code on any device. Used from every connect entry point (the calendar
/// empty state, the sidebar, the reauth banner, settings).
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

  /// Whether to connect with Control Center's own Google app. The no-setup path
  /// is the default whenever this build has one; a host without a built-in
  /// client forces it off below.
  bool _preferBuiltin = true;

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
    final builtin = ref.watch(calendarBuiltinClientAvailableProvider);
    // An error here (an older server that has no `calendar.connectInfo`) reads as
    // "no built-in app", which renders exactly the form that always worked.
    final builtinAvailable = builtin.asData?.value ?? false;
    final useBuiltin = builtinAvailable && _preferBuiltin;

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
          : builtin.isLoading
          // Which options exist is a server answer, and showing the
          // bring-your-own form first only to swap it for the no-setup choice a
          // moment later would read as a glitch.
          ? const _LoadingView()
          : _CredentialsView(
              clientId: _clientId,
              clientSecret: _clientSecret,
              error: state.error,
              builtinAvailable: builtinAvailable,
              useBuiltin: useBuiltin,
              onUseBuiltinChanged: (next) =>
                  setState(() => _preferBuiltin = next),
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
                onPressed:
                    state.phase == CalendarConnectPhase.starting ||
                        builtin.isLoading
                    ? null
                    : () => notifier.connect(
                        useBuiltin: useBuiltin,
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

/// Held while the host is asked which connect options it can offer.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CcSpinner(size: 18, color: t.textTertiary)),
    );
  }
}

/// The connect form (idle / starting / failed phases).
///
/// One box or three, depending on the host: with a built-in Google app the
/// no-setup path leads and the client id/secret only appear once the user asks
/// for their own; without one this is exactly the form it has always been.
class _CredentialsView extends StatelessWidget {
  const _CredentialsView({
    required this.clientId,
    required this.clientSecret,
    required this.error,
    required this.builtinAvailable,
    required this.useBuiltin,
    required this.onUseBuiltinChanged,
  });

  final TextEditingController clientId;
  final TextEditingController clientSecret;
  final CalendarConnectError? error;

  /// Whether the host has a Google app of its own to offer.
  final bool builtinAvailable;

  /// Whether that app is the current choice.
  final bool useBuiltin;

  /// Switches between the host's app and a user-supplied client.
  final ValueChanged<bool> onUseBuiltinChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (builtinAvailable) ...[
          _ClientChoice(
            value: true,
            selected: useBuiltin,
            title: l10n.calendarUseBuiltinApp,
            hint: l10n.calendarUseBuiltinAppHint,
            onSelected: onUseBuiltinChanged,
          ),
          const SizedBox(height: 4),
          _ClientChoice(
            value: false,
            selected: !useBuiltin,
            title: l10n.calendarUseOwnClient,
            hint: l10n.calendarUseOwnClientHint,
            onSelected: onUseBuiltinChanged,
          ),
        ] else
          Text(
            l10n.calendarConnectCredsHint,
            style: TextStyle(fontSize: 13, height: 1.4, color: t.textSecondary),
          ),
        if (!useBuiltin) ...[
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
        ],
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

/// One of the two ways to connect, as a radio with its own explanation.
class _ClientChoice extends StatelessWidget {
  const _ClientChoice({
    required this.value,
    required this.selected,
    required this.title,
    required this.hint,
    required this.onSelected,
  });

  final bool value;
  final bool selected;
  final String title;
  final String hint;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return GestureDetector(
      // The whole row is the target, not just the 18px dot.
      onTap: () => onSelected(value),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CcRadio<bool>(
              value: value,
              groupValue: selected ? value : !value,
              onChanged: onSelected,
              semanticLabel: title,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: t.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
                tooltip: l10n.copy,
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
            CcSpinner(size: 14, color: t.textTertiary),
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
