import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/forge_urls.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How often the forge-connection lookup is retried while nothing has
/// resolved.
///
/// This is an RPC to the host, not a forge call — the server's own identity
/// cache bounds requests to each forge — so a short interval is cheap. Retrying
/// at all is the point: every inbox section is classified relative to the
/// viewer's login on each forge, so a lookup that failed once and stuck left
/// the operator's inbox empty while claiming they were all caught up.
const Duration kForgeConnectionRetryInterval = Duration(seconds: 30);

/// Every supported forge's connection state, as reported by the server.
///
/// Never carries a token — the credential stays server-side. Never completes
/// with an error either: a failure resolves to an all-disconnected list and
/// schedules a retry, so downstream consumers keep their "unresolved reads as
/// absent" contract.
final forgeConnectionsProvider = FutureProvider<List<ForgeConnection>>((
  ref,
) async {
  void retryLater() {
    final timer = Timer(kForgeConnectionRetryInterval, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }

  try {
    final data = await ref
        .watch(rpcClientProvider)
        .call('forge.listConnections', const {});
    final raw = data['connections'];
    if (raw is! List) {
      retryLater();
      return const [];
    }
    final connections = [
      for (final c in raw.whereType<Map<String, dynamic>>())
        ForgeConnection.fromJson(c),
    ];
    // Nothing connected yet: the host may still be resolving credentials, or
    // the operator has not connected a forge. Ask again rather than settling
    // into a permanently empty identity.
    if (!connections.any((c) => c.authenticated)) {
      retryLater();
    }
    return connections;
  } on Object {
    retryLater();
    return const [];
  }
});

/// The operator's account name on each forge, lower-cased.
///
/// This is the multi-forge replacement for a single "current user login": the
/// same human is `octocat` on GitHub and something else entirely on GitLab, so
/// every "is this mine?" test resolves through the forge of the repo in hand.
/// A forge with no connection is absent from the map, which reads as "none of
/// its PRs are mine" rather than matching everything.
final viewerLoginsProvider = Provider<Map<ForgeHost, String>>((ref) {
  final connections = ref.watch(forgeConnectionsProvider).value ?? const [];
  return {
    for (final c in connections)
      if (c.authenticated && c.username.isNotEmpty)
        c.forge: c.username.toLowerCase(),
  };
});

/// The forges that currently hold a usable credential.
final connectedForgesProvider = Provider<Set<ForgeHost>>((ref) {
  final connections = ref.watch(forgeConnectionsProvider).value ?? const [];
  return {
    for (final c in connections)
      if (c.authenticated) c.forge,
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
final forgeForRepoProvider = Provider.family<ForgeHost, ({String owner, String name})>((
  ref,
  coord,
) {
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
  final connected = ref.watch(connectedForgesProvider);
  return connected.length == 1 ? connected.first : ForgeHost.github;
});

/// [ForgeUrls] for the forge hosting `owner/name`.
final forgeUrlsForRepoProvider =
    Provider.family<ForgeUrls, ({String owner, String name})>(
      (ref, coord) => ForgeUrls(ref.watch(forgeForRepoProvider(coord))),
    );

/// Stores [token] as [forge]'s credential and returns the resulting connection.
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
  ref.invalidate(forgeConnectionsProvider);
  return ForgeConnection.fromJson(data);
}

/// Clears [forge]'s stored credential.
Future<void> clearForgeToken(WidgetRef ref, ForgeHost forge) async {
  await ref.read(rpcClientProvider).call('credentials.clearForgeToken', {
    'forge': forge.wire,
  });
  ref.invalidate(forgeConnectionsProvider);
}

/// Re-probes [forge] and returns its refreshed connection state.
Future<ForgeConnection> testForgeConnection(
  WidgetRef ref,
  ForgeHost forge,
) async {
  final data = await ref.read(rpcClientProvider).call('forge.testConnection', {
    'forge': forge.wire,
  });
  ref.invalidate(forgeConnectionsProvider);
  return ForgeConnection.fromJson(data);
}
