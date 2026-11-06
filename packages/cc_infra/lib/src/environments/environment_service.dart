import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, ValidationException, WorkspaceMismatchException;
import 'package:cc_domain/core/domain/events/environment_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_lease.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/ports/worktree_task_port.dart';
import 'package:cc_domain/features/environments/domain/services/environment_definition_draft.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_glob.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_naming.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_template.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart'
    show resolvesInsideRoots;
import 'package:cc_infra/src/dispatch/agent_environment_gateway.dart';
import 'package:cc_infra/src/environments/cli_driver.dart';
import 'package:cc_infra/src/environments/compose_driver.dart';
import 'package:cc_infra/src/environments/compose_plan.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/environments/environment_contract.dart';
import 'package:cc_infra/src/environments/environment_lease_allocator.dart';
import 'package:cc_infra/src/environments/environment_log_ring.dart';
import 'package:cc_infra/src/environments/environment_process_supervisor.dart';
import 'package:cc_infra/src/environments/environment_service_ports.dart';
import 'package:cc_infra/src/environments/worktree_seed_files.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/rig_ports.dart' show RigEnvironmentRoute;
import 'package:cc_natives/cc_natives.dart' show RigWorktreeGuard;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

part 'environment_service_components.dart';
part 'environment_service_definitions.dart';
part 'environment_service_ensure.dart';
part 'environment_service_lifecycle.dart';
part 'environment_service_operations.dart';
part 'environment_service_setup.dart';
part 'environment_service_stack.dart';
part 'environment_service_worktree.dart';

/// A definition that passed read-time validation.
class _Loaded {
  const _Loaded(this.record, this.definition);

  final EnvironmentDefinitionRecord record;
  final EnvironmentDefinition definition;

  String get id => record.id;
}

/// One role resolved against a space.
class _BoundRole {
  const _BoundRole(this.role, this.repo, {this.isSource = false});

  final EnvironmentRole role;
  final EnvironmentContractRepo repo;

  /// Whether it is the registered checkout rather than a worktree.
  final bool isSource;
}

/// Everything needed to act on one environment.
class _Stack {
  const _Stack({
    required this.space,
    required this.loaded,
    required this.roles,
    required this.contract,
    required this.stateDir,
  });

  final EnvironmentSpaceInfo space;
  final _Loaded loaded;
  final List<_BoundRole> roles;
  final EnvironmentContract contract;
  final String stateDir;

  EnvironmentDefinition get definition => loaded.definition;

  List<String> get worktrees => [
    for (final role in roles)
      if (!role.isSource) role.repo.path,
  ];

  bool isEnabled(EnvironmentComponent component) {
    final condition = component.enabledWhen;
    return condition == null || contract.values.evaluate(condition);
  }
}

/// What started this bring-up.
enum _StartMode {
  /// The first start, or the first after the tool lost it.
  create,

  /// A start of something that exists.
  resume,

  /// Back to the baseline.
  reset,
}

/// State and plumbing every part of the service shares.
abstract class _EnvironmentServiceBase {
  _EnvironmentServiceBase(EnvironmentServiceDependencies dependencies)
    : _d = dependencies;

  final EnvironmentServiceDependencies _d;

  /// Who automatic starts are attributed to.
  static const Principal _system = UserPrincipal('control-center');

  final Uuid _uuid = const Uuid();

  /// One chain per environment: mutations run one at a time, and different
  /// environments never wait for each other.
  final Map<String, Future<void>> _locks = {};

  /// Ensures in flight, so concurrent callers share one result.
  final Map<String, Future<SpaceEnvironment>> _ensures = {};

  /// One chain per row, so a process event can't lose a pipeline's write.
  final Map<String, Future<void>> _writes = {};

  /// Spaces starting right now, by definition, for `maxRunning`.
  final Map<String, Set<String>> _reserved = {};

  /// Compose plans by environment, then component.
  final Map<String, Map<String, ComposePlan>> _plans = {};

  /// Viewer rigs by `<environment>/<component>`.
  final Map<String, String> _appWindows = {};

  /// Spaces whose worktrees are being released, by `<workspace>/<space>`.
  final Set<String> _releasing = {};

  /// Fork spaces whose worktrees are moving to a new head, by
  /// `<workspace>/<space>`. Nothing starts there until they arrive.
  final Set<String> _movingHeads = {};

  /// Throwaway spaces of running `testDefinition`s.
  final Map<String, EnvironmentSpaceInfo> _testSpaces = {};

  final StreamController<({String workspaceId, String spaceId})> _changes =
      StreamController.broadcast();

  /// Open `watch` streams by `<workspace>/<space>`.
  final Map<String, int> _watchers = {};

  String _lockKey(String workspaceId, String spaceId, String definitionId) =>
      '$workspaceId/$spaceId/$definitionId';

  String _lockOf(SpaceEnvironment env) =>
      _lockKey(env.workspaceId, env.spaceId, env.definitionId);

  Future<T> _exclusive<T>(String key, Future<T> Function() action) {
    final previous = _locks[key] ?? Future<void>.value();
    final run = previous.then((_) => action());
    final Future<void> tail = run.then<void>((_) {}, onError: (Object _) {});
    _locks[key] = tail;
    unawaited(
      tail.whenComplete(() {
        if (identical(_locks[key], tail)) {
          _locks.remove(key);
        }
      }),
    );
    return run;
  }

  /// The space, proving it belongs to [workspaceId].
  Future<EnvironmentSpaceInfo> _space(
    String workspaceId,
    String spaceId,
  ) async {
    final test = _testSpaces[spaceId];
    if (test != null) {
      if (test.workspaceId != workspaceId) {
        throw const WorkspaceMismatchException(
          'Space belongs to a different workspace',
        );
      }
      return test;
    }
    return _d.directory.space(workspaceId, spaceId);
  }

  /// Applies [change] to the stored row, in order with every other write.
  Future<SpaceEnvironment?> _update(
    String workspaceId,
    String id,
    SpaceEnvironment Function(SpaceEnvironment row) change,
  ) {
    final key = '$workspaceId/$id';
    final previous = _writes[key] ?? Future<void>.value();
    final run = previous.then((_) async {
      final row = await _d.environments.get(workspaceId, id);
      if (row == null) {
        return null;
      }
      final updated = change(row);
      await _d.environments.save(updated);
      _announce(row, updated);
      return updated;
    });
    final Future<void> tail = run.then<void>((_) {}, onError: (Object _) {});
    _writes[key] = tail;
    unawaited(
      tail.whenComplete(() {
        if (identical(_writes[key], tail)) {
          _writes.remove(key);
        }
      }),
    );
    return run;
  }

  void _announce(SpaceEnvironment? before, SpaceEnvironment after) {
    if (before?.status != after.status) {
      _d.events.publish(
        EnvironmentStatusChanged(
          workspaceId: after.workspaceId,
          spaceId: after.spaceId,
          environmentId: after.id,
          status: after.status.wire,
          occurredAt: _d.now(),
        ),
      );
    }
    _spaceChanged(after.workspaceId, after.spaceId);
  }

  void _spaceChanged(String workspaceId, String spaceId) {
    if (!_changes.isClosed) {
      _changes.add((workspaceId: workspaceId, spaceId: spaceId));
    }
  }

  Future<void> _setComponent(
    SpaceEnvironment env,
    String id,
    EnvironmentComponentState Function(EnvironmentComponentState state) change,
  ) => _update(
    env.workspaceId,
    env.id,
    (row) => row.copyWith(
      components: [
        for (final state in row.components)
          state.id == id ? change(state) : state,
      ],
    ),
  );

  Future<String> _stateDir(String workspaceId, String id) async {
    final directory = Directory(_d.stateDirFor(workspaceId, id));
    await directory.create(recursive: true);
    // Some tools insist on a canonical path, and `/tmp`-style links aren't one.
    return directory.resolveSymbolicLinksSync();
  }

  static EnvironmentDriverException _failure(
    String code,
    String message, {
    String? hint,
  }) => EnvironmentDriverException(
    EnvironmentError(code: code, message: message, hint: hint),
  );

  static EnvironmentError _errorOf(Object error) => switch (error) {
    EnvironmentDriverException(:final error) => error,
    EnvironmentTemplateException(:final message) => EnvironmentError(
      code: 'template',
      message: message,
    ),
    EnvironmentLeaseException(:final message) => EnvironmentError(
      code: 'lease',
      message: message,
    ),
    WorktreeSeedException(:final message) => EnvironmentError(
      code: 'seed-files',
      message: message,
    ),
    _ => EnvironmentError(code: 'failed', message: '$error'),
  };
}

/// Runs space environments: the orchestration over the drivers.
///
/// Every public operation derives the environment from the space, and resolves
/// the space first, so a space of another workspace fails before anything else
/// happens. Authorization is the caller's: RPC, tools and the gateway check
/// roles and action policy, this checks scope.
class EnvironmentService extends _EnvironmentServiceBase
    with
        _DefinitionOps,
        _ComponentOps,
        _StackOps,
        _EnsureOps,
        _SetupOps,
        _OperationOps,
        _WorktreeOps,
        _LifecycleOps
    implements EnvironmentPort, WorktreeTaskPort, AgentEnvironmentContext {
  /// Creates an [EnvironmentService]. Nothing runs until [start].
  EnvironmentService(super.dependencies) {
    _d.supervisor.respawnGate = _admitRespawn;
  }
}
