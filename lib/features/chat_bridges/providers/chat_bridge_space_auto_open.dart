import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Picks the chat-bridge space that should open on its own when the desktop
/// is in the background (the operator is in Slack, not looking at this window).
///
/// [current] is newest-`updatedAt`-first. Returns null when the app is
/// foregrounded (never steal the conversation the operator is already in) or
/// when nothing new is a bridged chat thread.
Space? chatBridgeSpaceToAutoOpen({
  required Set<String> previouslyKnownIds,
  required List<Space> current,
  required bool isForeground,
}) {
  if (isForeground) {
    return null;
  }
  for (final space in current) {
    if (!previouslyKnownIds.contains(space.id) && space.kind.isExternalChat) {
      return space;
    }
  }
  return null;
}

/// Opens a newly minted chat-bridge space without bringing the window
/// forward, so the conversation is on screen the moment the operator glances
/// at Control Center.
///
/// The first emission is treated as a snapshot of spaces that already
/// existed (startup, workspace switch) and is not opened. Keep this provider
/// watched from the sidebar so it lives for the shell's lifetime.
final chatBridgeSpaceAutoOpenProvider = Provider<void>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return;
  }
  var seeded = false;
  var knownIds = <String>{};
  ref.listen<List<Space>>(workspaceVisibleSpacesProvider(workspaceId), (
    _,
    next,
  ) {
    if (!seeded) {
      knownIds = {for (final space in next) space.id};
      seeded = true;
      return;
    }
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final isForeground =
        lifecycle == null || lifecycle == AppLifecycleState.resumed;
    final target = chatBridgeSpaceToAutoOpen(
      previouslyKnownIds: knownIds,
      current: next,
      isForeground: isForeground,
    );
    knownIds = {for (final space in next) space.id};
    if (!isForeground) {
      // A single visual update, not a ticker: ForegroundTickerGate mutes
      // repeating animations while unfocused, but a new row still has to
      // paint if the window is visible beside Slack.
      WidgetsBinding.instance.ensureVisualUpdate();
    }
    if (target == null) {
      return;
    }
    ref.read(routerProvider).go(spaceRoute(workspaceId, target.id));
  });
});
