import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/composer/messaging_mention_sources.dart';
import 'package:control_center/features/messaging/presentation/widgets/composer/space_message_composer.dart';
import 'package:control_center/features/messaging/presentation/widgets/mode_dropdown.dart';
import 'package:control_center/features/messaging/presentation/widgets/mode_enforcement_badge.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/space_composer_submit.dart';
import 'package:control_center/features/messaging/providers/steering_queue_providers.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:flutter/widgets.dart';
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
  /// `Composer`), which fires this same listener and clears it again — no
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

    return SpaceMessageComposer(
      spaceId: spaceId,
      conversationId: conversationId,
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
      onSubmit: (submission) => submitSpaceComposer(
        ref: ref,
        context: context,
        spaceId: spaceId,
        conversationId: conversationId,
        submission: submission,
      ),
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
}
