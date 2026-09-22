import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show RunCredentialBlockDto, RunCredentialLane, RunCredentialReason;
import 'package:cc_domain/features/settings/domain/entities/adapter.dart'
    show AdapterTransport, predefinedAdapters;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/widgets/credential_gate_body.dart';
import 'package:control_center/features/dispatch/providers/credential_gate_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  /// The block whose sign-in the operator just left to do in Settings.
  ///
  /// While this is set the dialog stays down — opening it again on top of the
  /// account page would hide the login it was opened to reach. Cleared when
  /// they leave that page: a probe then either resumes the parked run or puts
  /// the dialog back.
  String? _resumeBlockId;

  GoRouter? _router;

  /// Whether the current location is the adapters page. Tracked from the
  /// router, not from this widget rebuilding: the overlay is a `const` child
  /// of the shell, so a route change does not rebuild it.
  bool _onAdapters = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = GoRouter.maybeOf(context);
    if (identical(next, _router)) {
      return;
    }
    _router?.routerDelegate.removeListener(_onRoute);
    _router = next;
    _onAdapters = _isAdaptersRoute(_router);
    _router?.routerDelegate.addListener(_onRoute);
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRoute);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<RunCredentialBlockDto>>>(
      blockedRunsProvider,
      (_, _) => _considerOpening(),
    );
    return const SizedBox.shrink();
  }

  void _onRoute() {
    final now = _isAdaptersRoute(_router);
    final blockId = _resumeBlockId;
    final left = _onAdapters && !now && blockId != null;
    _onAdapters = now;
    if (left) {
      unawaited(_resume(blockId));
    }
  }

  bool _isAdaptersRoute(GoRouter? router) {
    final path = router?.state.uri.path ?? '';
    return path.contains('/settings/server/providers');
  }

  /// One dialog at a time. Two parked runs are almost always the same missing
  /// credential, and stacking modals would ask the operator to fix it twice;
  /// the next one opens on its own once this one is done.
  void _considerOpening() {
    if (!mounted || _resumeBlockId != null) {
      return;
    }
    final blocked =
        ref.read(blockedRunsProvider).asData?.value ??
        const <RunCredentialBlockDto>[];
    final first = blocked.where((b) => !_handled.contains(b.id)).firstOrNull;
    if (first == null) {
      return;
    }
    _handled.add(first.id);
    unawaited(_open(first.id));
  }

  /// Hands back the navigation the dialog runs after it pops.
  ///
  /// Null when this overlay is not under a router or the block names no
  /// workspace — the dialog stays up rather than closing onto nowhere.
  VoidCallback? _prepareOpenSettings(RunCredentialBlockDto block) {
    final router = _router;
    if (router == null) {
      return null;
    }
    final fromBlock = block.workspaceId;
    final workspaceId = (fromBlock != null && fromBlock.isNotEmpty)
        ? fromBlock
        : router.state.pathParameters['workspaceId'];
    if (workspaceId == null || workspaceId.isEmpty) {
      return null;
    }
    final adapterId = predefinedAdapters
        .where((adapter) => adapter.transport == AdapterTransport.claudeCli)
        .map((adapter) => adapter.id)
        .firstOrNull;
    return () {
      // Forget the handled mark so a run that is still parked when they
      // come back can open again. The flag below keeps that from happening
      // while they are still on the sign-in page.
      _handled.remove(block.id);
      _resumeBlockId = block.id;
      _onAdapters = false;
      router.go(settingsAdaptersRoute(workspaceId, adapterId: adapterId));
    };
  }

  /// Re-probes [id] the moment they leave the sign-in page, then either lets
  /// the resumed run alone or puts the dialog back.
  Future<void> _resume(String id) async {
    try {
      await ref.read(credentialGateRepositoryProvider).retry(id);
    } on Object {
      // No server in reach, or the probe itself failed. The snapshot below
      // is what decides whether the dialog comes back; a thrown probe is
      // not a reason to lose the parked run.
    }
    if (!mounted || _resumeBlockId != id) {
      return;
    }
    // The resolve snapshot and the RPC response race on the same socket.
    // One turn of the event loop is enough for a snapshot that already
    // arrived to land in the provider before we read it.
    await Future<void>.delayed(Duration.zero);
    if (!mounted || _resumeBlockId != id) {
      return;
    }
    final blocked =
        ref.read(blockedRunsProvider).asData?.value ??
        const <RunCredentialBlockDto>[];
    final stillParked = blocked.any((block) => block.id == id);
    if (!stillParked) {
      _resumeBlockId = null;
      _considerOpening();
      return;
    }
    // They came back to the sign-in page before the probe finished. Keep
    // waiting; the next time they leave, this runs again.
    if (_isAdaptersRoute(_router)) {
      return;
    }
    _resumeBlockId = null;
    _considerOpening();
  }

  Future<void> _open(String id) => showCcDialog<void>(
    context: context,
    // The run is held open behind this. Dismissing by clicking away would
    // leave it parked with nothing on screen explaining why nothing is
    // happening — the two ways out are both buttons.
    barrierDismissible: false,
    builder: (_) => _CredentialGateDialog(
      blockId: id,
      prepareOpenSettings: _prepareOpenSettings,
    ),
  );
}

class _CredentialGateDialog extends ConsumerStatefulWidget {
  const _CredentialGateDialog({
    required this.blockId,
    required this.prepareOpenSettings,
  });

  final String blockId;

  /// See [CredentialGateBody.prepareOpenSettings].
  final VoidCallback? Function(RunCredentialBlockDto block) prepareOpenSettings;

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
      content: CredentialGateBody(
        block: block,
        onConnected: _retry,
        prepareOpenSettings: widget.prepareOpenSettings,
      ),
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
