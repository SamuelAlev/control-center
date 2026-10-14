import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
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

  static const int _rememberSeconds = 8 * 60 * 60;

  Future<void> _respond(
    String id, {
    required bool approved,
    bool remember = false,
  }) async {
    setState(() => _responding.add(id));
    try {
      final client = ref.read(rpcClientProvider).value;
      if (client != null) {
        await RemoteConfirmationRepository(client).respond(
          id,
          approved: approved,
          rememberForSeconds: remember ? _rememberSeconds : null,
        );
      }
    } catch (_) {
      // The live subscription reconciles state on failure.
    } finally {
      if (mounted) {
        setState(() => _responding.remove(id));
      }
    }
  }

  void _onAnswer(ConfirmationRequestDto request, AgentQuestionAnswer answer) {
    final value = answer.selectedLabels.firstOrNull;
    switch (value) {
      case 'deny':
        unawaited(_respond(request.id, approved: false));
      case 'remember':
        unawaited(_respond(request.id, approved: true, remember: true));
      case 'approve':
        unawaited(_respond(request.id, approved: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending =
        ref.watch(pendingConfirmationsProvider(widget.spaceId)).value ??
        const <ConfirmationRequestDto>[];
    if (pending.isEmpty) {
      return const SizedBox.shrink();
    }
    // Show the oldest request first; leaving every request inline can bury the
    // conversation and its composer beneath an unbounded stack of approvals.
    final first = pending.reduce(
      (a, b) => a.createdAt.compareTo(b.createdAt) <= 0 ? a : b,
    );
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          _card(context, first),
          if (pending.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.tabWaitingCount(
                  l10n.agentApprovalRequired,
                  pending.length - 1,
                ),
                style: CcTypography.caption.copyWith(
                  color: (context.designSystem ?? DesignSystemTokens.light())
                      .textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, ConfirmationRequestDto p) {
    final l10n = AppLocalizations.of(context);
    final command = p.command;
    return AskUserCard(
      key: ValueKey(p.id),
      question: p.title.isEmpty ? l10n.agentApprovalRequired : p.title,
      contextText: p.detail.isEmpty ? null : p.detail,
      caption: l10n.agentApprovalRequired,
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
