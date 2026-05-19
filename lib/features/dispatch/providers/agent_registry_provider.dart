import 'dart:async';

import 'package:cc_domain/features/dispatch/domain/irc/irc_bus.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_lifecycle.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_registry.dart';
import 'package:cc_infra/cc_infra.dart' show AgentRegistryImpl, IrcBusImpl;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The process-global [AgentRegistry] — the single source of truth for which
/// agents are alive and what they are doing right now.
///
/// Returns the same instance the dispatch service writes to
/// (`AgentDispatchService` is constructed with `AgentRegistryImpl.global()`),
/// so the UI observes live dispatch activity without any extra plumbing.
final agentRegistryProvider = Provider<AgentRegistry>(
  (ref) => AgentRegistryImpl.global(),
);

/// Streams the work-aware roster for a single workspace: every agent owned by
/// `workspaceId`, re-emitted whenever that workspace's roster changes.
///
/// Workspace-scoped — never surfaces agents from another workspace, honoring
/// the workspace-isolation invariant for this process-global registry.
final workspaceAgentRosterProvider =
    StreamProvider.family<List<AgentRef>, String>((ref, workspaceId) {
  final registry = ref.watch(agentRegistryProvider);
  return registry.watchWorkspaceRoster(workspaceId);
});

/// Process-global [AgentLifecycleManager] bound to the registry. Owns the
/// idle → parked → revived lifecycle of adopted agents (TTL parking, on-demand
/// revival). Kept alive for the app's lifetime; disposed with the container.
///
/// The runtime hooks — the persisted cold-revive factory (Feature #3) and an
/// agent reviver — are installed by the dispatch integration; this provider
/// just owns the singleton bound to the shared registry.
final agentLifecycleManagerProvider = Provider<AgentLifecycleManager>((ref) {
  final manager = AgentLifecycleManager(ref.watch(agentRegistryProvider));
  ref.onDispose(() => unawaited(manager.dispose()));
  return manager;
});

/// Process-global [IrcBus] for peer-to-peer agent messaging, bound to the
/// registry + lifecycle so a parked recipient is revived on delivery. Sends are
/// workspace-scoped. The live-session sink (the in-process delivery hook for the
/// CC Harness, PRD 13) is left unset; delivery falls back to mailbox buffering,
/// which a `wait`/`inbox` drains.
final ircBusProvider = Provider<IrcBus>((ref) {
  return IrcBusImpl(
    ref.watch(agentRegistryProvider),
    lifecycle: ref.watch(agentLifecycleManagerProvider),
  );
});
