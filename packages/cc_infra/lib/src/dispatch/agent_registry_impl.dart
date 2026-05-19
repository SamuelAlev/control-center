import 'dart:async';

import 'package:cc_domain/core/utils/string_utils.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_ref.dart';
import 'package:cc_domain/features/dispatch/domain/registry/agent_registry.dart';
import 'package:cc_domain/features/dispatch/domain/registry/registry_event.dart';

/// Process-global, in-memory implementation of [AgentRegistry].
///
/// A single instance is shared across the whole process via [global] so the
/// dispatch service, MCP tools (which never receive a `Ref`), and the UI all
/// observe the same roster. The UI watches it through a Riverpod provider that
/// returns [global]; non-`Ref` call sites read [global] directly.
///
/// Refs are stored as immutable snapshots and replaced wholesale on mutation,
/// so [changes] always carries the post-change ref and consumers can compare
/// cheaply. Listener delivery uses a broadcast stream, so one slow or throwing
/// consumer can never wedge the dispatch loop.
class AgentRegistryImpl implements AgentRegistry {
  /// Creates an isolated registry. Most code should use [global]; this
  /// constructor exists for tests and for explicit dependency injection.
  AgentRegistryImpl();

  static AgentRegistryImpl? _global;

  /// The process-global registry instance.
  static AgentRegistryImpl global() => _global ??= AgentRegistryImpl();

  /// Replaces the global instance with a fresh one. Test-only.
  static void resetGlobalForTests() {
    _global?._dispose();
    _global = AgentRegistryImpl();
  }

  final Map<String, AgentRef> _refs = {};
  final StreamController<RegistryEvent> _changes =
      StreamController<RegistryEvent>.broadcast();

  @override
  AgentRef register(RegisterAgentInput input) {
    final now = DateTime.now();
    final existing = _refs[input.id];
    final isRunning = input.status == AgentStatus.running;
    final ref = AgentRef(
      id: input.id,
      // A re-dispatch of a known agent keeps its original first-seen time so
      // the roster's "alive since" reflects the agent, not the latest run.
      createdAt: existing?.createdAt ?? now,
      lastActivity: now,
      displayName: oneLineLabel(input.displayName),
      kind: input.kind,
      workspaceId: input.workspaceId,
      status: input.status,
      parentId: input.parentId ?? existing?.parentId,
      conversationId: input.conversationId ?? existing?.conversationId,
      dispatchId: input.dispatchId,
      sessionFile: input.sessionFile ?? existing?.sessionFile,
      // Activity describes current work; a fresh registration only carries it
      // forward while still running.
      activity: isRunning ? existing?.activity : null,
    );
    _refs[input.id] = ref;
    _emit(existing == null ? AgentRegistered(ref) : AgentStatusChanged(ref));
    return ref;
  }

  @override
  void setStatus(String id, AgentStatus status) {
    final ref = _refs[id];
    if (ref == null || ref.status == status) {
      return;
    }
    final updated = ref.copyWith(
      status: status,
      lastActivity: DateTime.now(),
      // A non-running agent has no current work and no live dispatch: drop both
      // so the roster never shows stale activity or a dangling dispatch id.
      clearActivity: status != AgentStatus.running,
      clearDispatchId: status != AgentStatus.running,
    );
    _refs[id] = updated;
    _emit(AgentStatusChanged(updated));
  }

  @override
  void setActivity(String id, String activity) {
    final ref = _refs[id];
    if (ref == null) {
      return;
    }
    // Only a running agent has current work: dropping a heartbeat for any other
    // status stops a late progress flush from resurrecting activity on a ref
    // that setStatus just cleared.
    if (ref.status != AgentStatus.running) {
      return;
    }
    final gist = oneLineLabel(activity);
    // Every running heartbeat refreshes lastActivity — even when the gist is
    // unchanged — so the roster's recency tracks real work, not just status
    // changes. Display-only, so no event is emitted.
    _refs[id] = ref.copyWith(
      lastActivity: DateTime.now(),
      activity: gist,
    );
  }

  @override
  void attachDispatch(String id, String dispatchId, {String? sessionFile}) {
    final ref = _refs[id];
    if (ref == null) {
      return;
    }
    _refs[id] = ref.copyWith(
      dispatchId: dispatchId,
      sessionFile: sessionFile,
      lastActivity: DateTime.now(),
    );
  }

  @override
  void detachDispatch(String id) {
    final ref = _refs[id];
    if (ref == null) {
      return;
    }
    _refs[id] = ref.copyWith(clearDispatchId: true);
  }

  @override
  void unregister(String id) {
    final ref = _refs.remove(id);
    if (ref == null) {
      return;
    }
    _emit(AgentRemoved(ref));
  }

  @override
  AgentRef? get(String id) => _refs[id];

  @override
  List<AgentRef> list() => List.unmodifiable(_refs.values);

  @override
  List<AgentRef> listForWorkspace(String workspaceId) => List.unmodifiable(
        _refs.values.where((ref) => ref.workspaceId == workspaceId),
      );

  @override
  List<AgentRef> listVisibleTo(String id) {
    final caller = _refs[id];
    if (caller == null) {
      return const [];
    }
    return List.unmodifiable(
      _refs.values.where(
        (ref) =>
            ref.id != id &&
            ref.workspaceId == caller.workspaceId &&
            ref.kind != AgentKind.advisor &&
            ref.isAlive,
      ),
    );
  }

  @override
  Stream<RegistryEvent> get changes => _changes.stream;

  @override
  Stream<List<AgentRef>> watchWorkspaceRoster(String workspaceId) {
    late final StreamController<List<AgentRef>> controller;
    StreamSubscription<RegistryEvent>? sub;
    controller = StreamController<List<AgentRef>>(
      onListen: () {
        // Seed with the current snapshot, then forward a fresh snapshot on
        // every change that touches this workspace. The seed + subscribe run
        // synchronously with no await between them, so no change is missed.
        controller.add(listForWorkspace(workspaceId));
        sub = _changes.stream
            .where((event) => event.ref.workspaceId == workspaceId)
            .listen((_) => controller.add(listForWorkspace(workspaceId)));
      },
      onCancel: () async {
        await sub?.cancel();
        sub = null;
        await controller.close();
      },
    );
    return controller.stream;
  }

  void _emit(RegistryEvent event) {
    if (!_changes.isClosed) {
      _changes.add(event);
    }
  }

  void _dispose() {
    _refs.clear();
    unawaited(_changes.close());
  }
}
