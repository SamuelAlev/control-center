import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart' show RemoteForgeConnections;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/forge_urls.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:control_center/core/offline/offline_queue_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/providers.dart'
    show viewerGitHubIdentityProvider;
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

/// How often the forge-connection lookup is retried while it is failing or
/// nothing has resolved.
///
/// This is an RPC to the host, not a forge call — the server's own identity
/// cache bounds requests to each forge — so a short interval is cheap. Retrying
/// at all is the point: every inbox section is classified relative to the
/// viewer's login on each forge, so a lookup that failed once and stuck left
/// the operator's inbox empty while claiming they were all caught up.
const Duration kForgeConnectionRetryInterval = Duration(seconds: 30);

/// How often a resolved, connected list is re-read, so a credential that
/// lapses while connected (revoked, expired, a rotated Connect key) shows up
/// without a restart.
const Duration kForgeConnectionRefreshInterval = Duration(minutes: 2);

/// The forge-connection reads, bound once (the demo binds a fixture in
/// [demoForgeConnectionsProvider] instead).
final forgeConnectionsRepositoryProvider = Provider<RemoteForgeConnections>(
  (ref) => RemoteForgeConnections(ref.watch(rpcClientProvider)),
);

/// Every supported forge's connection state, as reported by the server.
///
/// Never carries a token — the credential stays server-side. A failed read is
/// an [AsyncError] that KEEPS the previous list (Riverpod carries it): an
/// unreachable host is not "signed out", and consumers reading `.value` keep
/// their last answer while the retry runs. Consumers that gate on it (the
/// onboarding gate) treat an error with no previous value as unresolved.
final forgeConnectionsProvider = FutureProvider<List<ForgeConnection>>((
  ref,
) async {
  void refreshIn(Duration delay) {
    final timer = Timer(delay, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }

  final demo = ref.watch(demoForgeConnectionsProvider);
  if (demo != null) {
    return demo;
  }

  // Switching workspace must re-read: a workspace on its own GitHub App and
  // one on the server's lane are different identities. Watching the id also
  // keeps the RPC args honest if the client's injected `activeWorkspaceId`
  // has not caught up yet.
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  // A GitHub sign-in that lands — from any dialog, or from a deep link after
  // its dialog closed — is a new identity for every "is this mine?" test.
  ref.watch(
    providerSignInControllerProvider.select(
      (s) => s.successesFor(ConnectOAuthLane.github),
    ),
  );

  final List<ForgeConnection> connections;
  try {
    connections = await ref
        .watch(forgeConnectionsRepositoryProvider)
        .list(workspaceId: workspaceId);
  } on Object {
    refreshIn(kForgeConnectionRetryInterval);
    rethrow;
  }
  // Nothing connected yet: the host may still be resolving credentials, or
  // the operator has not connected a forge. Ask again soon rather than
  // settling into a permanently empty identity; a connected list is re-read on
  // the slower cadence so a lapse is noticed.
  refreshIn(
    connections.any((c) => c.isUsable)
        ? kForgeConnectionRefreshInterval
        : kForgeConnectionRetryInterval,
  );
  return connections;
});

/// Re-reads every view of "who is signed in to which forge" after something
/// changed it: a sign-in or sign-out, a Connect mode change or key rotation,
/// a workspace switching between the server's GitHub lane and its own App.
///
/// Takes the caller's `invalidate` (a [WidgetRef]'s or a [Ref]'s) so widgets
/// and notifiers share one list instead of each keeping a partial copy.
void invalidateForgeState(void Function(ProviderOrFamily) invalidate) {
  invalidate(forgeConnectionsProvider);
  invalidate(oauthConnectionsProvider);
  invalidate(oauthLanesProvider);
  invalidate(viewerGitHubIdentityProvider);
}

/// The operator's account name on each forge, lower-cased.
///
/// This is the multi-forge replacement for a single "current user login": the
/// same human is `octocat` on GitHub and something else entirely on GitLab, so
/// every "is this mine?" test resolves through the forge of the repo in hand.
/// A forge with no connection is absent from the map, which reads as "none of
/// its PRs are mine" rather than matching everything.
final viewerLoginsProvider = Provider<Map<ForgeHost, String>>((ref) {
  final connections = ref.watch(forgeConnectionsProvider).value ?? const [];
  return RemoteForgeConnections.viewerLogins(connections);
});

/// The one "no forge in hand" rule: a surface that is not about a specific
/// repo (a profile chip, a reference with no registered repo) takes the only
/// connected forge, and GitHub when there are several or none.
ForgeHost forgeWithoutRepo(Iterable<ForgeHost> connected) {
  final set = connected.toSet();
  if (set.length == 1) {
    return set.first;
  }
  return ForgeHost.github;
}

/// [logins]' entry for [forgeWithoutRepo] — the viewer's login on a surface
/// with no repo in hand. Empty when nothing is connected.
String loginWithoutRepo(Map<ForgeHost, String> logins) =>
    logins[forgeWithoutRepo(logins.keys)] ?? logins.values.firstOrNull ?? '';

/// The forges that currently hold a usable credential.
final connectedForgesProvider = Provider<Set<ForgeHost>>((ref) {
  final connections = ref.watch(forgeConnectionsProvider).value ?? const [];
  return {
    for (final c in connections)
      if (c.isUsable) c.forge,
  };
});

/// Whether at least one forge is connected.
///
/// The onboarding gate's test. Deliberately "any", not "GitHub": an operator
/// who works only on GitLab has a complete setup.
final hasAnyForgeConnectedProvider = Provider<bool>((ref) {
  return ref.watch(connectedForgesProvider).isNotEmpty;
});

/// What each forge can do, served by the host so no client hardcodes a forge's
/// abilities.
///
/// Falls back to the compiled-in table when the op has not answered yet, so a
/// first frame renders with correct affordances rather than hiding everything.
final forgeCapabilitiesProvider =
    FutureProvider<Map<ForgeHost, ForgeCapabilities>>((ref) async {
      try {
        final data = await ref
            .watch(rpcClientProvider)
            .call('forge.capabilities', const {});
        final raw = data['forges'];
        if (raw is! List) {
          return kForgeCapabilities;
        }
        final parsed = <ForgeHost, ForgeCapabilities>{};
        for (final entry in raw.whereType<Map<String, dynamic>>()) {
          final caps = ForgeCapabilities.fromJson(entry);
          parsed[caps.forge] = caps;
        }
        return parsed.isEmpty ? kForgeCapabilities : parsed;
      } on Object {
        return kForgeCapabilities;
      }
    });

/// The capabilities of one forge, for gating an affordance.
///
/// Use this — never a `forge == ForgeHost.github` check — so adding a forge is
/// a table edit rather than a hunt through the UI.
final capabilitiesForProvider = Provider.family<ForgeCapabilities, ForgeHost>((
  ref,
  forge,
) {
  final all = ref.watch(forgeCapabilitiesProvider).value ?? kForgeCapabilities;
  return all[forge] ?? capabilitiesOf(forge);
});

/// The forge hosting `owner/name` in the active workspace.
///
/// Surfaces that hold only a repo coordinate — a `#123` chip in a chat message,
/// a cross-repo PR reference — need a forge before they can build a link. They
/// resolve it here rather than assuming GitHub, which would send a GitLab merge
/// request's chip to a github.com URL that does not exist.
///
/// Falls back to the workspace's only connected forge when the repo is not
/// registered (a reference to somewhere the operator has not added), and to
/// GitHub when even that is ambiguous — a wrong guess degrades to a dead link,
/// which is what the pre-multi-forge behavior already was.
final forgeForRepoProvider =
    Provider.family<ForgeHost, ({String owner, String name})>((ref, coord) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId != null) {
        final repos =
            ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];
        for (final repo in repos) {
          if (repo.remoteOwner.toLowerCase() == coord.owner.toLowerCase() &&
              repo.remoteName.toLowerCase() == coord.name.toLowerCase()) {
            return repo.forge;
          }
        }
      }
      return forgeWithoutRepo(ref.watch(connectedForgesProvider));
    });

/// The forges the active workspace's repos live on.
///
/// For chrome about one forge (GitHub's status banner): a workspace with no
/// repo on that forge has nothing the forge's health can degrade.
final workspaceForgesProvider = Provider<Set<ForgeHost>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return const {};
  }
  final repos =
      ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];
  return {
    for (final repo in repos)
      if (repo.hasForgeRemote) repo.forge,
  };
});

/// [ForgeUrls] for the forge hosting `owner/name`.
final forgeUrlsForRepoProvider =
    Provider.family<ForgeUrls, ({String owner, String name})>(
      (ref, coord) => ForgeUrls(ref.watch(forgeForRepoProvider(coord))),
    );

/// The sign-in lane behind [forge], or null for a forge that is token-only
/// (GitLab, Bitbucket).
ConnectOAuthLane? signInLaneForForge(ForgeHost forge) =>
    ConnectOAuthLane.fromWire(forge.wire);

/// Stores [token] as the caller's own credential for [forge], used in every
/// workspace on this server, and returns the resulting connection.
/// Token-only forges (GitLab, Bitbucket): GitHub is sign-in only and the
/// server refuses a GitHub token.
///
/// Takes effect on the very next forge request: the server reads the token per
/// call, so there is no restart and no stale interceptor.
Future<ForgeConnection> setForgeToken(
  WidgetRef ref,
  ForgeHost forge,
  String token,
) async {
  final data = await ref.read(rpcClientProvider).call(
    'credentials.setForgeToken',
    {'forge': forge.wire, 'token': token},
  );
  invalidateForgeState(ref.invalidate);
  final connection = ForgeConnection.fromJson(data);
  if (connection.isUsable) {
    // A token-only forge's lane is its wire name: changes the server refused
    // for want of this token run now.
    unawaited(
      ref
          .read(offlineQueueControllerProvider.notifier)
          .resumeAfterSignIn(forge.wire),
    );
  }
  return connection;
}

/// Clears the caller's pasted token for the token-only [forge], in every
/// workspace. A GitHub grant is revoked through `oauth.disconnect` instead.
Future<void> clearForgeToken(WidgetRef ref, ForgeHost forge) async {
  await ref.read(rpcClientProvider).call('credentials.clearForgeToken', {
    'forge': forge.wire,
  });
  invalidateForgeState(ref.invalidate);
}
