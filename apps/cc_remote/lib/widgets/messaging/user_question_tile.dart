import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/features/messaging/domain/services/agent_question_service.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/messaging/ask_user_card.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders a `user_question` space message as an [AskUserCard] and persists
/// the answer through `messaging.updateMessage`.
class UserQuestionTile extends ConsumerStatefulWidget {
  /// Creates a [UserQuestionTile].
  const UserQuestionTile({super.key, required this.message, this.workspaceId});

  /// The question message.
  final MessageDto message;

  /// Inbox scope captured before any asynchronous answer; null inline.
  final String? workspaceId;

  @override
  ConsumerState<UserQuestionTile> createState() => _UserQuestionTileState();
}

class _UserQuestionTileState extends ConsumerState<UserQuestionTile> {
  bool _submitting = false;
  String? _error;

  Map<String, dynamic> get _meta {
    final raw = widget.message.metadata;
    return raw is Map ? raw.cast<String, dynamic>() : const {};
  }

  List<AgentQuestionOption> get _options {
    final raw = _meta['options'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final o in raw)
        if (o is Map) AgentQuestionOption.fromJson(o.cast<String, dynamic>()),
    ];
  }

  AgentQuestionAnswer? get _answered {
    if (_meta[kQuestionAnsweredKey] != true) {
      return null;
    }
    final raw = _meta[kQuestionAnswerKey];
    return raw is Map
        ? AgentQuestionAnswer.fromJson(raw.cast<String, dynamic>())
        : const AgentQuestionAnswer();
  }

  Future<void> _submit(AgentQuestionAnswer answer) async {
    if (_submitting) {
      return;
    }
    final client = ref.read(rpcClientProvider).value;
    final workspaceId =
        widget.workspaceId ?? ref.read(activeWorkspaceIdProvider).value;
    if (client == null ||
        workspaceId == null ||
        workspaceId != ref.read(activeWorkspaceIdProvider).value) {
      setState(() => _error = AppLocalizations.of(context).requestUnavailable);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await RemoteMessagingRepository(client).updateMessage(
        workspaceId,
        widget.message.id,
        metadata: {
          ..._meta,
          kQuestionAnsweredKey: true,
          kQuestionAnswerKey: answer.toJson(),
        },
      );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: TextStyle(color: t.textErrorPrimary)),
          ),
        AskUserCard(
          question: (_meta['question'] as String?) ?? widget.message.content,
          contextText: _meta['context'] as String?,
          options: _options,
          allowFreeText: _meta['allowFreeText'] == true,
          multiSelect: _meta['multiSelect'] == true,
          caption: l10n.agentQuestionHeader,
          answered: _answered,
          submitting: _submitting,
          onSubmit: _answered == null ? _submit : null,
        ),
      ],
    );
  }
}
