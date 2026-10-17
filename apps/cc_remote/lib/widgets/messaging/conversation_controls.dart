import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/conversation_drafts.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/messaging/steering_queue.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConversationControls extends ConsumerStatefulWidget {
  const ConversationControls({
    super.key,
    required this.scope,
    required this.runs,
    required this.queued,
    required this.canWrite,
  });
  final RemoteConversationKey scope;
  final AsyncValue<List<AgentRunLogDto>> runs;
  final List<MessageDto> queued;
  final bool canWrite;
  @override
  ConsumerState<ConversationControls> createState() => _ControlsState();
}

class _ControlsState extends ConsumerState<ConversationControls> {
  bool _expanded = false;
  bool _acting = false;
  Object? _error;
  String? _notice;

  Future<void> _control(AgentRunLogDto run, String action) async {
    final l10n = AppLocalizations.of(context);
    if (action == 'stopRun') {
      final confirm = await showCcDialog<bool>(
        context: context,
        builder: (dialog) => CcDialog(
          title: l10n.mobileStopRun,
          content: Text(l10n.mobileStopRunConfirm),
          actions: [
            CcButton(
              size: CcButtonSize.lg,
              variant: CcButtonVariant.secondary,
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(l10n.cancel),
            ),
            CcButton(
              size: CcButtonSize.lg,
              variant: CcButtonVariant.destructive,
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(l10n.mobileStopRun),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }
    if (!widget.canWrite ||
        _acting ||
        ref.read(activeWorkspaceIdProvider).value != widget.scope.workspaceId) {
      return;
    }
    final client = ref.read(rpcClientProvider).value;
    if (client == null) return;
    setState(() {
      _acting = true;
      _error = null;
      _notice = null;
    });
    try {
      // These RPCs return authority from the live dispatch, not guessed adapter capability.
      final result = await client.call('dispatch.$action', {
        'workspace_id': widget.scope.workspaceId,
        'run_id': run.id,
      });
      final accepted =
          action == 'stopRun' ||
          result[action == 'pauseRun' ? 'paused' : 'resumed'] == true;
      if (mounted) {
        setState(
          () => _notice = !accepted
              ? l10n.mobileControlUnsupported
              : action == 'pauseRun'
              ? l10n.mobilePauseRequested
              : action == 'resumeRun'
              ? l10n.mobileResumed
              : l10n.mobileStopRequested,
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = (widget.runs.value ?? const <AgentRunLogDto>[])
        .where(
          (run) => const ['running', 'pending', 'paused'].contains(run.status),
        )
        .toList();
    if (active.isEmpty &&
        widget.queued.isEmpty &&
        !widget.runs.hasError &&
        _error == null &&
        _notice == null) {
      return const SizedBox.shrink();
    }
    final agents = ref.watch(agentsProvider).value ?? const <AgentDto>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcButton(
          size: CcButtonSize.lg,
          variant: CcButtonVariant.secondary,
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(
            widget.queued.isNotEmpty
                ? l10n.mobileQueuedMessages
                : l10n.agentWorking,
          ),
        ),
        if (_error != null || widget.runs.hasError)
          CcAlert(
            title: l10n.mobileActionFailed,
            variant: CcAlertVariant.danger,
            description: Text('${_error ?? widget.runs.error}'),
            action: CcButton(
              onPressed: () => ref.invalidate(
                activeRunLogsProvider(widget.scope.conversationId),
              ),
              child: Text(l10n.retry),
            ),
          ),
        if (_notice != null) CcAlert(title: _notice!),
        if (_expanded)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final run in active)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            agents
                                    .where((agent) => agent.id == run.agentId)
                                    .firstOrNull
                                    ?.name ??
                                l10n.agent,
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              CcButton(
                                size: CcButtonSize.lg,
                                variant: CcButtonVariant.secondary,
                                onPressed: !widget.canWrite || _acting
                                    ? null
                                    : () => _control(run, 'pauseRun'),
                                child: Text(l10n.mobilePauseRun),
                              ),
                              CcButton(
                                size: CcButtonSize.lg,
                                variant: CcButtonVariant.secondary,
                                onPressed: !widget.canWrite || _acting
                                    ? null
                                    : () => _control(run, 'resumeRun'),
                                child: Text(l10n.mobileResumeRun),
                              ),
                              CcButton(
                                size: CcButtonSize.lg,
                                variant: CcButtonVariant.destructive,
                                onPressed: !widget.canWrite || _acting
                                    ? null
                                    : () => _control(run, 'stopRun'),
                                child: Text(l10n.mobileStopRun),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  SteeringQueue(
                    scope: widget.scope,
                    messages: widget.queued,
                    canWrite: widget.canWrite,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
