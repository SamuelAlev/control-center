import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_remote/analytics.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/messaging/ask_user_card.dart';
import 'package:cc_remote/widgets/phone_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inline approve/decline surface for destructive agent commands awaiting a
/// human decision. Streams `confirmation.watchPending` for this conversation;
/// each card resolves its request via `confirmation.respond`.
class PendingApprovals extends ConsumerStatefulWidget {
  /// Creates [PendingApprovals].
  const PendingApprovals({super.key, required this.spaceId});

  /// The space whose blocked actions this lists.
  final String spaceId;

  @override
  ConsumerState<PendingApprovals> createState() => _PendingApprovalsState();
}

class _PendingApprovalsState extends ConsumerState<PendingApprovals> {
  final Set<String> _responding = {};
  final Map<String, String> _errors = {};

  static const int _rememberSeconds = 8 * 60 * 60;

  Future<void> _respond(
    ConfirmationRequestDto request, {
    required bool approved,
    bool remember = false,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (_responding.contains(request.id)) return;
    setState(() {
      _responding.add(request.id);
      _errors.remove(request.id);
    });
    try {
      final client = ref.read(rpcClientProvider).value;
      final workspaceId = ref.read(activeWorkspaceIdProvider).value;
      if (client == null ||
          workspaceId == null ||
          (request.workspaceId != null && request.workspaceId != workspaceId)) {
        throw StateError(l10n.requestUnavailable);
      }
      final ok = await RemoteConfirmationRepository(client).respond(
        request.id,
        approved: approved,
        rememberForSeconds: remember ? _rememberSeconds : null,
      );
      if (!ok) {
        throw StateError(l10n.requestAlreadyResolved);
      }
      if (mounted) {
        trackApprovalDecision(
          ref,
          request,
          approved: approved,
          remembered: remember,
          surface: 'conversation',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _errors[request.id] = '$e');
    } finally {
      if (mounted) setState(() => _responding.remove(request.id));
    }
  }

  void _onAnswer(ConfirmationRequestDto request, AgentQuestionAnswer answer) {
    final value = answer.selectedLabels.firstOrNull;
    switch (value) {
      case 'deny':
        unawaited(_respond(request, approved: false));
      case 'remember':
        unawaited(_respond(request, approved: true, remember: true));
      case 'approve':
        unawaited(_respond(request, approved: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingState = ref.watch(
      pendingConfirmationsProvider(widget.spaceId),
    );
    final pending = [...?pendingState.value]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (pending.isEmpty && !pendingState.hasError) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          if (pendingState.hasError)
            Text(
              '${l10n.inboxLoadFailed}: ${pendingState.error}',
              style: TextStyle(
                color: (context.designSystem ?? DesignSystemTokens.light())
                    .textErrorPrimary,
              ),
            ),
          for (final request in pending.take(1)) ...[
            _card(context, request, pending.length),
            if (_errors[request.id] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _errors[request.id]!,
                  style: TextStyle(
                    color: (context.designSystem ?? DesignSystemTokens.light())
                        .textErrorPrimary,
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _card(BuildContext context, ConfirmationRequestDto p, int waiting) {
    final l10n = AppLocalizations.of(context);
    final command = p.command;
    return AskUserCard(
      key: ValueKey(p.id),
      question: p.title.isEmpty ? l10n.agentApprovalRequired : p.title,
      contextText: p.detail.isEmpty ? null : p.detail,
      caption: waiting == 1
          ? l10n.agentApprovalRequired
          : l10n.tabWaitingCount(l10n.agentApprovalRequired, waiting),
      allowSkip: false,
      submitting: _responding.contains(p.id),
      scrollableBody: true,
      extraBody: command == null || command.isEmpty
          ? null
          : PhoneApprovalCodeBlock(source: command),
      options: [
        AgentQuestionOption(label: l10n.deny, value: 'deny'),
        AgentQuestionOption(label: l10n.approve, value: 'approve'),
        if (p.isRememberable)
          AgentQuestionOption(
            label: l10n.approveAndRemember,
            value: 'remember',
          ),
      ],
      onSubmit: _responding.contains(p.id) ? null : (a) => _onAnswer(p, a),
    );
  }
}
