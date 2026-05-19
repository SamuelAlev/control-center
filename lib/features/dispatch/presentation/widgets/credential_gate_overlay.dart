import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show RunCredentialBlockDto, RunCredentialLane, RunCredentialReason;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/widgets/credential_gate_body.dart';
import 'package:control_center/features/dispatch/providers/credential_gate_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens a modal whenever the server parks a run on a credential it cannot use,
/// and closes it by itself the moment the credential works.
///
/// The turn is NOT lost while this is up. The server is holding the dispatch —
/// nothing has been spawned, nothing has failed — and it re-probes the
/// credential on its own every few seconds, so signing in or pasting a key ends
/// the block and the same turn continues where it stopped. That is why the
/// dialog has no "OK": the useful outcomes are "fixed" (it closes itself) and
/// "give up" (cancel the run).
///
/// Mounted permanently in the app shell beside `AgentApprovalOverlay` and
/// renders nothing until something is parked, which is nearly always.
class CredentialGateOverlay extends ConsumerStatefulWidget {
  /// Creates a [CredentialGateOverlay].
  const CredentialGateOverlay({super.key});

  @override
  ConsumerState<CredentialGateOverlay> createState() =>
      _CredentialGateOverlayState();
}

class _CredentialGateOverlayState extends ConsumerState<CredentialGateOverlay> {
  /// Block ids this overlay has already opened a dialog for.
  ///
  /// Keyed by id rather than a single "is a dialog up" flag because a resolved
  /// block lingers in the stream for the frame or two it takes the server's
  /// snapshot to come back. Without this the dialog would close on the resolve
  /// and immediately re-open over the same, now-dead, block. Ids are minted
  /// monotonically and never reused, so a handled one can never be a new one.
  final Set<String> _handled = {};

  @override
  Widget build(BuildContext context) {
    ref.listen(blockedRunsProvider, (_, next) {
      final blocked = next.asData?.value ?? const <RunCredentialBlockDto>[];
      // One at a time. Two parked runs are almost always the same missing
      // credential, and stacking modals would ask the operator to fix it twice;
      // the second opens on its own if it is genuinely different.
      final first = blocked.where((b) => !_handled.contains(b.id)).firstOrNull;
      if (first == null) {
        return;
      }
      _handled.add(first.id);
      unawaited(_open(first.id));
    });
    return const SizedBox.shrink();
  }

  Future<void> _open(String id) => showCcDialog<void>(
    context: context,
    // The run is held open behind this. Dismissing by clicking away would
    // leave it parked with nothing on screen explaining why nothing is
    // happening — the two ways out are both buttons.
    barrierDismissible: false,
    builder: (_) => _CredentialGateDialog(blockId: id),
  );
}

class _CredentialGateDialog extends ConsumerStatefulWidget {
  const _CredentialGateDialog({required this.blockId});

  final String blockId;

  @override
  ConsumerState<_CredentialGateDialog> createState() =>
      _CredentialGateDialogState();
}

class _CredentialGateDialogState extends ConsumerState<_CredentialGateDialog> {
  bool _busy = false;
  bool _closing = false;

  Future<void> _retry() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(credentialGateRepositoryProvider).retry(widget.blockId);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _cancel() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(credentialGateRepositoryProvider).cancel(widget.blockId);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Closes on the next frame once the block leaves the stream — the credential
  /// works and the run has already resumed, so there is nothing left to ask.
  void _closeWhenResolved() {
    if (_closing) {
      return;
    }
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final blocked =
        ref.watch(blockedRunsProvider).asData?.value ??
        const <RunCredentialBlockDto>[];
    final block = blocked.where((b) => b.id == widget.blockId).firstOrNull;
    if (block == null) {
      _closeWhenResolved();
      return CcDialog(
        title: l10n.credentialGateWaitingTitle,
        content: Text(l10n.credentialGateWatching),
      );
    }

    return CcDialog(
      maxWidth: 560,
      title: _title(l10n, block),
      content: CredentialGateBody(block: block, onConnected: _retry),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          onPressed: _busy ? null : _cancel,
          child: Text(l10n.credentialGateCancelRun),
        ),
        const SizedBox(width: AppSpacing.sm),
        CcButton(
          size: CcButtonSize.sm,
          loading: _busy,
          onPressed: _busy ? null : _retry,
          child: Text(l10n.credentialGateCheckAgain),
        ),
      ],
    );
  }

  /// The headline names the SPECIFIC problem, never "a credential problem".
  /// The four reasons have four different fixes, and a title that does not say
  /// which one leaves the operator to guess between signing in, waiting and
  /// pasting a key.
  String _title(AppLocalizations l10n, RunCredentialBlockDto block) =>
      switch (block.reason) {
        RunCredentialReason.planSpent => l10n.credentialGatePlanSpentTitle,
        RunCredentialReason.signedOut => l10n.credentialGateSignedOutTitle,
        RunCredentialReason.credentialExpired =>
          l10n.credentialGateExpiredTitle,
        RunCredentialReason.noCredential =>
          block.lane == RunCredentialLane.harness
              ? l10n.credentialGateHarnessTitle(
                  block.providerId ?? l10n.credentialGateWaitingTitle,
                )
              : l10n.credentialGateSignedOutTitle,
      };
}
