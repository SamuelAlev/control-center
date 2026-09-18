import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/messaging/ask_user_card.dart';
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          for (final p in pending) ...[
            _card(context, p),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _card(BuildContext context, ConfirmationRequestDto p) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final command = p.command;
    return AskUserCard(
      question: p.title.isEmpty ? l10n.agentApprovalRequired : p.title,
      contextText: p.detail.isEmpty ? null : p.detail,
      caption: l10n.agentApprovalRequired,
      allowSkip: false,
      submitting: _responding.contains(p.id),
      extraBody: command == null || command.isEmpty
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: t.bgSecondary,
                border: Border.all(color: t.borderSecondary),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  command,
                  style: CcFonts.code(
                    textStyle: CcTypography.bodySm.copyWith(
                      color: t.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
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
