import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_input_bar.dart';
import 'package:control_center/features/messaging/presentation/widgets/file_mention_bindings.dart';
import 'package:control_center/features/messaging/presentation/widgets/mode_dropdown.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full Composer wrapper for thread replies with mentions, mode dropdown.
class ThreadReplyBar extends ConsumerWidget {
  /// Creates a [ThreadReplyBar].
  const ThreadReplyBar({
    super.key,
    required this.channelId,
    required this.parentMessageId,
  });

  /// The channel ID.
  final String channelId;
  /// The parent message ID being replied to.
  final String parentMessageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final sources = buildMessagingMentionSources(ref, workspaceId);
    final transcriber = composerTranscriber(ref);
    final currentMode = ref.watch(activeChannelModeProvider);
    final l10n = AppLocalizations.of(context);

    return Composer(
      sources: sources,
      hint: l10n.replyEllipsis,
      transcriber: transcriber,
      leading: ModeDropdown(
        currentMode: currentMode,
        onChanged: (mode) =>
            ref.read(activeChannelModeProvider.notifier).setMode(mode),
      ),
      onSubmit: (submission) => _handleSubmit(ref, submission),
    );
  }

  Future<void> _handleSubmit(WidgetRef ref, ComposerSubmission s) async {
    final content = _renderContent(s);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    final structured = <StructuredMention>[
      for (final m in s.mentions.where((m) => m.kind == 'agent'))
        if (m.payload?['agentId'] != null)
          StructuredMention(
            agentId: m.payload!['agentId'] as String,
            raw: '@${m.label}',
          ),
    ];
    await ref.read(channelMessageSendProvider.notifier).send(
          content: content,
          channelId: channelId,
          workspaceId: workspaceId,
          structuredMentions: structured,
          entityRefs: entityRefsFromMentions(s.mentions),
          parentMessageId: parentMessageId,
        );
  }

  String _renderContent(ComposerSubmission s) {
    final buffer = StringBuffer(s.text.trim());
    for (final a in s.attachments) {
      if (a.kind == 'file' && a.path != null) {
        if (buffer.isNotEmpty) {
          buffer.write('\n');
        }
        buffer.write(a.path);
      }
    }
    return buffer.toString();
  }
}
