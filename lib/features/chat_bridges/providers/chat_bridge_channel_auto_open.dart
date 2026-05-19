import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Picks the chat-bridge channel that should open on its own when the desktop
/// is in the background (the operator is in Slack, not looking at this window).
///
/// [current] is newest-`updatedAt`-first. Returns null when the app is
/// foregrounded (never steal the conversation the operator is already in) or
/// when nothing new is a bridged chat thread.
Channel? chatBridgeChannelToAutoOpen({
  required Set<String> previouslyKnownIds,
  required List<Channel> current,
  required bool isForeground,
}) {
  if (isForeground) {
    return null;
  }
  for (final channel in current) {
    if (!previouslyKnownIds.contains(channel.id) &&
        channel.origin.isExternalChat) {
      return channel;
    }
  }
  return null;
}

/// Opens a newly minted chat-bridge channel without bringing the window
/// forward, so the conversation is on screen the moment the operator glances
/// at Control Center.
///
/// The first emission is treated as a snapshot of channels that already
/// existed (startup, workspace switch) and is not opened. Keep this provider
/// watched from the sidebar so it lives for the shell's lifetime.
final chatBridgeChannelAutoOpenProvider = Provider<void>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return;
  }
  var seeded = false;
  var knownIds = <String>{};
  ref.listen<List<Channel>>(workspaceVisibleChannelsProvider(workspaceId), (
    _,
    next,
  ) {
    if (!seeded) {
      knownIds = {for (final channel in next) channel.id};
      seeded = true;
      return;
    }
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final isForeground =
        lifecycle == null || lifecycle == AppLifecycleState.resumed;
    final target = chatBridgeChannelToAutoOpen(
      previouslyKnownIds: knownIds,
      current: next,
      isForeground: isForeground,
    );
    knownIds = {for (final channel in next) channel.id};
    if (!isForeground) {
      // A single visual update, not a ticker: ForegroundTickerGate mutes
      // repeating animations while unfocused, but a new row still has to
      // paint if the window is visible beside Slack.
      WidgetsBinding.instance.ensureVisualUpdate();
    }
    if (target == null) {
      return;
    }
    ref.read(routerProvider).go(channelRoute(workspaceId, target.id));
  });
});
