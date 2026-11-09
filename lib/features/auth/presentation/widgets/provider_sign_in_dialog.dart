import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_copy.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_dialog_parts.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runs [lane]'s browser sign-in in [workspaceId]'s scope (null =
/// server-wide) and resolves with the final attempt once it succeeds, or
/// null when the dialog is closed first.
///
/// Closing does not cancel anything: an own-mode attempt keeps being polled
/// and a Connect attempt can still complete from its deep link, and every
/// connection list re-reads when it lands. A success is announced with a
/// toast on [context]'s scope.
///
/// The scrim does not dismiss. The browser takes focus as this opens, and the
/// click that brings the window back would otherwise land on the barrier.
Future<SignInAttempt?> showProviderSignInDialog(
  BuildContext context, {
  required ConnectOAuthLane lane,
  String? workspaceId,
}) async {
  final toasts = CcToastScope.maybeOf(context);
  final l10n = AppLocalizations.of(context);
  final result = await showCcDialog<SignInAttempt>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(dialogContext).maybePop(),
      },
      child: ProviderSignInDialog(lane: lane, workspaceId: workspaceId),
    ),
  );
  if (result != null) {
    toasts?.show(
      signInSuccessMessage(l10n, lane, result.account),
      variant: CcToastVariant.success,
    );
  }
  return result;
}

/// The sign-in dialog's body: starting, waiting on the browser, the Connect
/// code, and the failure with its reason.
class ProviderSignInDialog extends ConsumerStatefulWidget {
  /// Creates a [ProviderSignInDialog].
  const ProviderSignInDialog({
    super.key,
    required this.lane,
    required this.workspaceId,
  });

  /// The lane being signed in.
  final ConnectOAuthLane lane;

  /// The scope the sign-in runs in; null is server-wide.
  final String? workspaceId;

  @override
  ConsumerState<ProviderSignInDialog> createState() =>
      _ProviderSignInDialogState();
}

class _ProviderSignInDialogState extends ConsumerState<ProviderSignInDialog> {
  final _code = TextEditingController();
  String? _loginId;
  String? _beginError;
  bool _starting = true;

  @override
  void initState() {
    super.initState();
    // After the dialog has painted: opening the browser first hides this
    // route under another app before it can be read.
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _starting = true;
      _beginError = null;
      _loginId = null;
    });
    _code.clear();
    try {
      final controller = ref.read(providerSignInControllerProvider.notifier);
      final loginId = await controller.begin(
        widget.lane,
        workspaceId: widget.workspaceId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _loginId = loginId;
        _starting = false;
      });
      final attempt = await controller.result(loginId);
      if (mounted &&
          attempt != null &&
          attempt.status == SignInAttemptStatus.succeeded &&
          _loginId == loginId) {
        Navigator.of(context).pop(attempt);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _starting = false;
          _beginError = describeSignInStartError(e);
        });
      }
    }
  }

  void _submit() {
    final loginId = _loginId;
    if (loginId != null) {
      unawaited(
        ref
            .read(providerSignInControllerProvider.notifier)
            .submitCode(loginId, _code.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loginId = _loginId;
    final session = loginId == null
        ? null
        : ref.watch(
            providerSignInControllerProvider.select((s) => s.sessions[loginId]),
          );
    final provider = signInProviderName(widget.lane);
    final failed = _beginError != null || (session?.isTerminal ?? false);
    final awaitingCode =
        session != null &&
        !session.isTerminal &&
        session.attempt.mode == SignInLaneMode.connect;

    final Widget body;
    if (_starting || (session == null && _beginError == null)) {
      body = SignInStatusLine(text: l10n.signInOpeningBrowser(provider));
    } else if (failed) {
      body = SignInFailureView(
        message:
            _beginError ??
            signInFailureMessage(l10n, session!.attempt.error, widget.lane),
      );
    } else if (awaitingCode) {
      body = SignInCodeEntry(
        session: session,
        controller: _code,
        onSubmit: _submit,
        onReopen: () => ref
            .read(providerSignInControllerProvider.notifier)
            .reopen(session.loginId),
      );
    } else {
      body = SignInBrowserWait(
        session: session!,
        provider: provider,
        onReopen: () => ref
            .read(providerSignInControllerProvider.notifier)
            .reopen(session.loginId),
      );
    }

    return CcDialog(
      title: signInActionLabel(l10n, widget.lane),
      content: body,
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(l10n.close),
        ),
        if (failed)
          CcButton(
            onPressed: () => unawaited(_start()),
            child: Text(l10n.retry),
          )
        else if (awaitingCode)
          CcButton(
            loading: session.completing,
            onPressed: session.completing ? null : _submit,
            child: Text(l10n.continueLabel),
          ),
      ],
    );
  }
}
