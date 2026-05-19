import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_harness/slash_command.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/composer/messaging_mention_sources.dart';
import 'package:control_center/features/messaging/presentation/widgets/composer/space_local_command_dispatch.dart';
import 'package:control_center/features/messaging/presentation/widgets/mode_dropdown.dart';
import 'package:control_center/features/messaging/presentation/widgets/mode_enforcement_badge.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/pending_space_sends_provider.dart';
import 'package:control_center/features/messaging/providers/space_message_send_provider.dart';
import 'package:control_center/features/messaging/providers/steering_queue_providers.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:control_center/shared/widgets/composer/file_reference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The mention-source factory and its `#` token helper moved out so this file
// is the input bar and nothing else. Re-exported rather than relocated in
// every caller: they are the same public surface, just no longer written here.
export 'package:control_center/features/messaging/presentation/widgets/composer/messaging_mention_sources.dart'
    show
        buildMessagingMentionSources,
        entityMentionToken,
        entityRefsFromMentions;

/// Composer bar with mode selector for sending space messages.
class SpaceInputBar extends ConsumerStatefulWidget {
  /// Creates a [SpaceInputBar].
  const SpaceInputBar({
    super.key,
    required this.spaceId,
    required this.conversationId,
  });

  /// The space ID this bar sends to.
  final String spaceId;

  /// The conversation (stream) inside the space this bar sends to. Required:
  /// a conversation owns its own uuid, so there is no space-id fallback to
  /// send against — the host resolves the standing conversation before this
  /// bar is built.
  final String conversationId;

  @override
  ConsumerState<SpaceInputBar> createState() => _SpaceInputBarState();
}

class _SpaceInputBarState extends ConsumerState<SpaceInputBar> {
  // A ComposerTextController, not a plain one: it is what paints the
  // `@[file:…]` references in the draft as pills.
  late final ComposerTextController _controller;
  // Captured once (not re-read via `ref` in dispose): `ref.read`/`ref.watch`
  // are unsafe once this widget's own element is unmounting, but calling a
  // plain method on an already-resolved notifier instance is not — it never
  // touches this widget's `ref`/`BuildContext`.
  late final MyPresenceNotifier _presence;

  @override
  void initState() {
    super.initState();
    _presence = ref.read(myPresenceProvider.notifier);
    _controller = ComposerTextController()..addListener(_onDraftChanged);
  }

  @override
  void dispose() {
    // Leaving the composer (space switch/unmount) clears any "typing"
    // presence for this space rather than waiting out the 5s timer.
    _presence.setTyping(null);
    _controller.removeListener(_onDraftChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Typing presence (PRD 16 §1): a non-empty draft in this space publishes
  /// `typingInSpaceId`. The composer clears its own text on submit (see
  /// [Composer]), which fires this same listener and clears it again — no
  /// separate "clear on send" wiring needed.
  void _onDraftChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    _presence.setTyping(hasText ? widget.spaceId : null);
  }

  @override
  Widget build(BuildContext context) {
    final spaceId = widget.spaceId;
    final conversationId = widget.conversationId;
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final l10n = AppLocalizations.of(context);
    final sources = buildMessagingMentionSources(
      ref,
      workspaceId,
      spaceId: spaceId,
    );
    final currentMode = ref.watch(activeSpaceModeProvider);

    // Live agent runs in THIS conversation — a run log id equals its agent
    // turn's message id. Drives the composer's stop affordance: while any agent
    // is working, the send button becomes a stop button (when the input is
    // empty). Keyed by the pane's conversation, not the space: a composer in a
    // side conversation that watched the wrong stream showed no "running" state for the runs
    // right above it (so no stop button) and would have stopped somebody else's.
    final activeRunIds = workspaceId == null
        ? const <String>[]
        : (ref
                  .watch(
                    conversationActiveRunsProvider((
                      workspaceId: workspaceId,
                      conversationId: conversationId,
                    )),
                  )
                  .asData
                  ?.value
                  .map((r) => r.id)
                  .toList() ??
              const <String>[]);

    // ↑/↓ recall (terminal-style prompt history) feeds on this pane's OWN
    // conversation — the standing-conversation watch would offer the main
    // thread's prompts to a side thread's composer.
    final historyAsync = ref.watch(
      conversationUserHistoryProvider((
        spaceId: spaceId,
        conversationId: conversationId,
      )),
    );

    // The steering strip renders directly above this bar and draws down onto
    // its top border, so the box drops its top margin while the queue holds
    // anything. Read from the same derived provider the strip renders (itself
    // a projection of the feed window this pane already watches), so the two
    // cannot disagree about whether there is something up there.
    final steeringAttached = ref
        .watch(
          steeringQueueProvider((
            spaceId: spaceId,
            conversationId: conversationId,
          )),
        )
        .isNotEmpty;

    return Composer(
      attachedTop: steeringAttached,
      controller: _controller,
      sources: sources,
      // While agents work, a submit becomes a queued steering card, not a
      // turn — the hint says what Enter will do.
      hint: activeRunIds.isNotEmpty
          ? l10n.messageQueueHint
          : l10n.messagePlaceholder,
      minLines: 3,
      history: historyAsync.value,
      historyKey: conversationId,
      // Shift+Tab toggles plan mode (PRD 17 §8). It flips `spaces.mode` —
      // the authority every enforcement layer reads — rather than typing a
      // `/plan ` prefix, which the server never saw.
      onPlanToggle: () => ref
          .read(activeSpaceModeProvider.notifier)
          .setMode(currentMode == Mode.plan ? Mode.chat : Mode.plan),
      isBusy: activeRunIds.isNotEmpty,
      onStop: activeRunIds.isEmpty
          ? null
          : () => _handleStop(ref, activeRunIds),
      // The mode selector states a guarantee; the badge beside it discloses when
      // the space's adapter cannot keep it (PRD 24 §3). It renders nothing on
      // the common path, so the toolbar is unchanged for chat mode and for a
      // fully-enforcing adapter.
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModeDropdown(
            currentMode: currentMode,
            onChanged: (mode) =>
                ref.read(activeSpaceModeProvider.notifier).setMode(mode),
          ),
          ModeEnforcementBadge(spaceId: spaceId, currentMode: currentMode),
        ],
      ),
      onSubmit: (submission) => _handleSubmit(ref, context, submission),
    );
  }

  /// Stops every agent currently working in this space. Multi-agent rooms can
  /// have several live runs, so all are stopped (each run log id == its agent
  /// turn's message id).
  Future<void> _handleStop(WidgetRef ref, List<String> runLogIds) async {
    final port = ref.read(messagingServiceProvider);
    final workspaceId = ref.requireWorkspaceId();
    for (final id in runLogIds) {
      await port.stopRun(workspaceId, id);
    }
  }

  Future<void> _handleSubmit(
    WidgetRef ref,
    BuildContext context,
    ComposerSubmission s,
  ) async {
    final spaceId = widget.spaceId;
    final rawContent = _renderContent(s);
    final workspaceId = ref.requireWorkspaceId();

    final parsedCommand = parseSlashCommand(rawContent.trim());
    final dispatched = await dispatchLocalSlashCommand(
      ref: ref,
      context: context,
      parsed: parsedCommand,
      rawContent: rawContent,
      spaceId: spaceId,
      conversationId: widget.conversationId,
      workspaceId: workspaceId,
    );
    if (dispatched == null) {
      return;
    }
    final content = dispatched;

    // Mid-run steering: if agents are already working in this conversation and
    // the user submits plain conversational text (no @agent, no slash command),
    // the submission becomes a QUEUED STEERING CARD (the strip below the
    // trail) instead of a new turn — the server persists it as a conversation
    // row, live harness runs inject it at their next turn boundary, and
    // anything still queued when the last run ends is converted to a normal
    // message. No toast: the card appearing in the strip IS the feedback.
    // Scoped to this pane's conversation for the same reason as the stop
    // affordance: steering must reach the runs the user is looking at.
    //
    // ATTACHMENTS ARE NEVER STEERED. The queue carries a String and nothing
    // else, all the way down to the loop's steering inbox — there is no lane
    // for an image on it. Steering a submission that had pictures attached
    // delivered the words and silently dropped the pictures, so the agent was
    // told to "look at these screenshots" and given four filenames. A message
    // with something attached is a real turn: it falls through to the normal
    // send, which uploads the blobs and puts them on the agent's user turn.
    final hasAgentMention = s.mentions.any((m) => m.kind == 'agent');
    if (!parsedCommand.isCommand &&
        !hasAgentMention &&
        s.attachments.isEmpty &&
        content.trim().isNotEmpty) {
      final activeRuns =
          ref
              .read(
                conversationActiveRunsProvider((
                  workspaceId: workspaceId,
                  conversationId: widget.conversationId,
                )),
              )
              .asData
              ?.value ??
          const [];
      if (activeRuns.isNotEmpty) {
        final port = ref.read(messagingServiceProvider);
        final queued = await port.enqueueSteering(
          workspaceId: workspaceId,
          spaceId: spaceId,
          conversationId: widget.conversationId,
          content: content,
        );
        if (queued != null) {
          // Remember whether ANY live run can inject mid-run: the strip's
          // "steer now" button is hidden for external-CLI transports (their
          // cards wait for run end), and this is the one moment the answer is
          // authoritative.
          ref
              .read(
                steeringSteerableProvider((
                  spaceId: spaceId,
                  conversationId: widget.conversationId,
                )).notifier,
              )
              .set(queued.steerable);
          return;
        }
        // The run ended between the read above and the enqueue — fall
        // through to a normal send.
      }
    }

    final structured = <StructuredMention>[
      for (final m in s.mentions.where((m) => m.kind == 'agent'))
        if (m.payload?['agentId'] != null)
          StructuredMention(
            agentId: m.payload!['agentId'] as String,
            raw: '@${m.label}',
          ),
    ];
    final entityRefs = entityRefsFromMentions(s.mentions);

    // Gate on provisioning: send now when ready, otherwise park the submission
    // until the background workspace setup completes. The queue auto-flushes on
    // the provisioning → ready transition.
    final status = ref.read(spaceProvisioningStatusProvider(spaceId));
    if (status != SpaceProvisioningStatus.ready) {
      ref
          .read(pendingSpaceSendsProvider(spaceId).notifier)
          .enqueue(
            content: content,
            structuredMentions: structured,
            entityRefs: entityRefs,
            attachments: s.attachments,
          );
      return;
    }

    await ref
        .read(spaceMessageSendProvider.notifier)
        .send(
          content: content,
          spaceId: spaceId,
          workspaceId: workspaceId,
          conversationId: widget.conversationId,
          structuredMentions: structured,
          entityRefs: entityRefs,
          attachments: s.attachments,
        );
  }

  /// The message text as it is STORED — references intact.
  ///
  /// A `@[file:<name>]` token is not expanded here, and that is the point. This
  /// client is routinely not the machine the agent runs on, so its paths mean
  /// nothing on the far side; the bytes travel instead, and the server replaces
  /// each token IN PLACE with the path it wrote them to. In place matters: the
  /// position is the meaning — "compare ⟦before.png⟧ with ⟦after.png⟧"
  /// collapses into nonsense if the paths are appended as a list at the end.
  /// Keeping the token is also what makes the sent bubble read like the
  /// composer did: the transcript draws it as the same chip.
  ///
  /// Attachments carrying no reference — a scratchpad, or a picture attached by
  /// a composer that inserts no token — keep the old trailing-line behaviour,
  /// so nothing that used to reach the agent stops doing so.
  String _renderContent(ComposerSubmission s) {
    final text = s.text.trim();
    final named = {for (final match in findFileRefs(text)) match.name};
    final buffer = StringBuffer(text);
    for (final a in s.attachments) {
      if (a.kind == 'file' && a.path != null && !named.contains(a.refName)) {
        if (buffer.isNotEmpty) {
          buffer.write('\n');
        }
        buffer.write(a.path);
      }
    }
    return buffer.toString();
  }
}
