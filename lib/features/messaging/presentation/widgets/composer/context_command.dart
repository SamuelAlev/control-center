/// The `/context` composer command: open one agent's context window as a tab.
///
/// Its own file because `local_slash_commands.dart` is already at its size
/// budget, and because this command is the only one that has to RESOLVE which
/// agent it is about before it can do anything — the rest act on the
/// conversation as a whole.
library;

import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/context_explorer_tab.dart';
import 'package:control_center/features/messaging/presentation/widgets/composer/context_command_target.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the context explorer for this conversation's agent as an editor tab
/// beside it. Invoked as `/context`, or `/context <agent>` to pick another.
///
/// A bare `/context` opens the agent the header's meter is reading (see
/// [spaceMeteredAgentIdProvider]) — whoever is at work here — so the command
/// and the counter always speak about the same window. Only a typed name that
/// matches nothing is refused; the match is exact, never fuzzy.
Future<void> handleContextCommand({
  required WidgetRef ref,
  required BuildContext context,
  required String args,
  required String spaceId,
  required String workspaceId,
}) async {
  final l10n = AppLocalizations.of(context);
  final toast = CcToastScope.maybeOf(context);

  // The metered agent, read while the pane that hosts this composer is still
  // mounted — the header is watching the same provider, so this is the value
  // on screen rather than a fresh resolution from a cold start.
  final currentAgentId = ref.read(spaceMeteredAgentIdProvider(spaceId));

  // Read through the repository rather than the auto-disposed stream provider:
  // the command runs from a submit handler, where nothing guarantees a live
  // listener has already resolved the participant list.
  final participants = await ref
      .read(messagingRepositoryProvider)
      .getParticipants(workspaceId, spaceId);
  if (!context.mounted) {
    return;
  }
  final agentIds = [
    for (final SpaceParticipant p in participants)
      if (p.participantType == PrincipalType.agent) p.principalId,
  ];

  // The roster is only needed to put NAMES on ids, which only matters past one
  // agent. Awaited rather than read as a snapshot: nothing guarantees the
  // stream has emitted by the time a submit handler runs, and a loading
  // snapshot reads as "no agents here" — which turns a disambiguation prompt
  // into one that lists nothing.
  var namesById = const <String, String>{};
  if (agentIds.length > 1) {
    final roster = await ref.read(workspaceAgentsProvider(workspaceId).future);
    if (!context.mounted) {
      return;
    }
    namesById = {for (final a in roster) a.id: a.name};
  }

  final target = resolveContextTarget(
    agentIdsInSpace: agentIds,
    namesById: namesById,
    args: args,
    currentAgentId: currentAgentId,
  );

  switch (target) {
    case ContextTargetResolved(:final agentId):
      openContextExplorer(
        context,
        workspaceId: workspaceId,
        spaceId: spaceId,
        agentId: agentId,
        // Past one agent the tab has to say WHOSE window it is: the command
        // now picks for the operator, and two identically-labelled tabs would
        // be two different breakdowns.
        agentName: namesById[agentId],
      );
    case ContextTargetNoAgent():
      toast?.show(l10n.contextCommandNoAgent, variant: CcToastVariant.warning);
    case ContextTargetUnknownAgent(:final choices, :final typed):
      toast?.show(
        l10n.contextCommandNoSuchAgent(typed, choices.join(', ')),
        variant: CcToastVariant.warning,
      );
  }
}
