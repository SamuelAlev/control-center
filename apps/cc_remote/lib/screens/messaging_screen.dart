import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/agent_transcript.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Messaging tab: live channels (`messaging.watchChannels`), each pushing a
/// realtime thread route.
class MessagingScreen extends ConsumerWidget {
  /// Creates a [MessagingScreen].
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final async = ref.watch(channelsProvider);

    return ColoredBox(
      color: t.canvas,
      child: async.when(
        loading: () => const Center(child: CcSpinner(size: 24)),
        error: (e, _) => CcEmptyState(
          icon: AppIcons.triangleAlert,
          message: "Couldn't load channels",
          description: e.toString(),
        ),
        data: (channels) {
          if (channels.isEmpty) {
            return const CcEmptyState(
              icon: AppIcons.messageCircle,
              message: 'No channels',
              description: 'Channels in this workspace appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: channels.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _channelCard(context, t, channels[i]),
          );
        },
      ),
    );
  }

  Widget _channelCard(
    BuildContext context,
    DesignSystemTokens t,
    ChannelDto channel,
  ) {
    return CcCard(
      interactive: true,
      semanticLabel: channel.name,
      onPressed: () => context.push('/thread/${channel.id}'),
      child: Row(
        children: [
          Icon(
            channel.isDm ? AppIcons.user : AppIcons.hash,
            size: 18,
            color: t.fgSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              channel.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: t.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `/thread/:channelId` — a realtime conversation. Messages stream live
/// (`messaging.watchMessages`); an agent turn renders its transcript (reasoning,
/// tool calls, results) as it happens. The composer dispatches the channel's
/// agents (`dispatch.sendAndDispatch`) so a reply streams back.
class MessagingThreadScreen extends ConsumerStatefulWidget {
  /// Creates a [MessagingThreadScreen].
  const MessagingThreadScreen({required this.channelId, super.key});

  /// The channel id from the route.
  final String channelId;

  @override
  ConsumerState<MessagingThreadScreen> createState() =>
      _MessagingThreadScreenState();
}

class _MessagingThreadScreenState extends ConsumerState<MessagingThreadScreen> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty) {
      return;
    }
    final client = ref.read(rpcClientProvider).value;
    if (client == null) {
      return;
    }
    setState(() => _sending = true);
    try {
      _composer.clear();
      // sendAndDispatch posts the user message AND wakes the channel's agents;
      // the reply streams back over the live messages subscription.
      await RemoteMessagingDispatch(client)
          .sendAndDispatch(widget.channelId, text);
    } catch (_) {
      // The live stream reconciles state; a transient failure is non-fatal.
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final messagesAsync = ref.watch(channelMessagesProvider(widget.channelId));
    final runsAsync = ref.watch(activeRunLogsProvider(widget.channelId));
    final messages = messagesAsync.value ?? const <MessageDto>[];

    final hasActiveRun =
        (runsAsync.value ?? const <AgentRunLogDto>[]).any(
      (r) => r.status == 'running' || r.status == 'pending',
    );

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          children: [
            const _DetailHeader(title: 'Thread'),
            if (hasActiveRun) _activeBanner(t),
            _PendingApprovals(channelId: widget.channelId),
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CcSpinner(size: 24)),
                error: (e, _) => CcEmptyState(
                  icon: AppIcons.triangleAlert,
                  message: "Couldn't load messages",
                  description: e.toString(),
                ),
                data: (_) {
                  if (messages.isEmpty) {
                    return const CcEmptyState(
                      icon: AppIcons.messageCircle,
                      message: 'No messages yet',
                      description: 'Send a message to start the conversation.',
                    );
                  }
                  _jumpToBottom();
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, i) =>
                        _messageTile(t, messages[i]),
                  );
                },
              ),
            ),
            _composerBar(t),
          ],
        ),
      ),
    );
  }

  Widget _activeBanner(DesignSystemTokens t) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.accentSoft,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(AppIcons.loader, size: 14, color: t.accent),
            const SizedBox(width: 8),
            Text(
              'Agent is working',
              style: TextStyle(fontSize: 13, color: t.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageTile(DesignSystemTokens t, MessageDto m) {
    final isMine = m.senderType == 'user';
    final meta = m.metadata is Map ? m.metadata as Map : null;
    final segments = decodeTranscript(meta?['segments']);
    final isAgentTurn = !isMine && segments.isNotEmpty;
    final streamComplete = (meta?['streamComplete'] as bool?) ?? !isAgentTurn;
    final agentName = (meta?['agentName'] as String?) ?? m.senderType;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.bot, size: 12, color: t.fgTertiary),
                        const SizedBox(width: 4),
                        Text(
                          (agentName.isEmpty ? 'Agent' : agentName),
                          style: TextStyle(
                            fontSize: 11,
                            color: t.fgTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isAgentTurn)
                  _agentBubble(t, m, segments, streamComplete)
                else
                  _textBubble(t, m.content, isMine),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textBubble(DesignSystemTokens t, String content, bool isMine) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isMine ? t.accentSoft : t.bgSecondary,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          content,
          style: TextStyle(fontSize: 14, height: 1.4, color: t.textPrimary),
        ),
      ),
    );
  }

  Widget _agentBubble(
    DesignSystemTokens t,
    MessageDto m,
    List<TranscriptSegment> segments,
    bool streamComplete,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.bgSecondary,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          // The transcript now renders the answer text inline at its
          // chronological position, so there is no separate trailing answer.
          child: AgentTranscript(
            segments: segments,
            isLive: !streamComplete,
          ),
        ),
      ),
    );
  }

  Widget _composerBar(DesignSystemTokens t) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(top: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CcTextField(
                controller: _composer,
                hintText: 'Message',
                keyboardType: TextInputType.multiline,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            CcButton(
              icon: AppIcons.send,
              loading: _sending,
              onPressed: _send,
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            CcTappable(
              onPressed: () => context.pop(),
              semanticLabel: 'Back',
              builder: (context, _) => Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(AppIcons.arrowLeft, color: t.fgSecondary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline approve/decline surface for destructive agent commands awaiting a
/// human decision. Streams `confirmation.watchPending` for this conversation;
/// each card resolves its request via `confirmation.respond`.
class _PendingApprovals extends ConsumerStatefulWidget {
  const _PendingApprovals({required this.channelId});

  final String channelId;

  @override
  ConsumerState<_PendingApprovals> createState() => _PendingApprovalsState();
}

class _PendingApprovalsState extends ConsumerState<_PendingApprovals> {
  final Set<String> _responding = {};

  Future<void> _respond(String id, bool approved) async {
    setState(() => _responding.add(id));
    try {
      final client = ref.read(rpcClientProvider).value;
      if (client != null) {
        await RemoteConfirmationRepository(client)
            .respond(id, approved: approved);
      }
    } catch (_) {
      // The live subscription reconciles state on failure.
    } finally {
      if (mounted) {
        setState(() => _responding.remove(id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final pending = ref
            .watch(pendingConfirmationsProvider(widget.channelId))
            .value ??
        const <ConfirmationRequestDto>[];
    if (pending.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [for (final p in pending) _card(t, p)],
    );
  }

  Widget _card(DesignSystemTokens t, ConfirmationRequestDto p) {
    final destructive = p.severity == 'destructive';
    final bg = destructive ? t.dangerSoft : t.warnSoft;
    final fg = destructive ? t.textErrorPrimary : t.textWarningPrimary;
    final busy = _responding.contains(p.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(AppIcons.triangleAlert, size: 16, color: fg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (p.detail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  p.detail,
                  style: TextStyle(fontSize: 13, color: t.textSecondary),
                ),
              ],
              if (p.command != null) ...[
                const SizedBox(height: 6),
                Text(
                  p.command!,
                  style: CcFonts.code(
                    textStyle: TextStyle(fontSize: 12, color: t.textSecondary),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CcButton(
                      variant: CcButtonVariant.destructive,
                      size: CcButtonSize.sm,
                      loading: busy,
                      onPressed: busy ? null : () => _respond(p.id, false),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CcButton(
                      variant: CcButtonVariant.primary,
                      size: CcButtonSize.sm,
                      loading: busy,
                      onPressed: busy ? null : () => _respond(p.id, true),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
