import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/infrastructure/speech/speech_transcriber_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/domain/ports/messaging_port.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_input_bar.dart';
import 'package:control_center/features/messaging/presentation/widgets/mode_dropdown.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/agent_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/channel_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/file_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/scratchpad_mention_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full Composer wrapper for thread replies with mentions, mode dropdown.
class ThreadReplyBar extends ConsumerWidget {
  const ThreadReplyBar({
    super.key,
    required this.channelId,
    required this.parentMessageId,
  });

  final String channelId;
  final String parentMessageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final agents = workspaceId != null
        ? ref.watch(workspaceAgentsProvider(workspaceId)).value ?? const []
        : ref.watch(agentsProvider).value ?? const [];
    final channels = workspaceId != null
        ? ref.watch(workspaceChannelsProvider(workspaceId)).value ?? const []
        : ref.watch(channelsProvider).value ?? const [];
    final List<Repo> repos = workspaceId == null
        ? const []
        : ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];

    final fileSearch = ref.watch(fileSearchProvider);
    final sources = <MentionSource>[
      AgentMentionSource(agents),
      ChannelMentionSource([
        for (final c in channels)
          ChannelMentionItem(id: c.id, name: c.name, isDm: c.isDm),
      ]),
      if (workspaceId != null)
        ScratchpadMentionSource(workspaceId: workspaceId),
      if (repos.isNotEmpty)
        FileMentionSource(
          search: fileSearch,
          roots: [for (final r in repos) r.path],
        ),
    ];

    final transcriber = ref.watch(speechTranscriberProvider);
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
