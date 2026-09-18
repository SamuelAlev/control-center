import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, WatchQuery;
import 'package:cc_infra/cc_infra.dart'
    show FleetSchedulerService, JobRunner, LocalJobExecutor, kLocalWorkerId;
import 'package:cc_persistence/cc_persistence.dart'
    show DaoEvalsRepository, DaoFleetRepository, GlobalDatabase, WorkspaceDatabaseManager;
import 'package:cc_server_core/src/evals/evals_rpc_ops.dart';
import 'package:cc_server_core/src/fleet/fleet_rpc_ops.dart';
import 'package:cc_server_core/src/fleet/remote_execution_registry.dart';

/// The assembled fleet and evals services and their RPC ops/watch queries.
typedef FleetWiringResult = ({
  FleetSchedulerService fleetScheduler,
  DaoFleetRepository fleetRepository,
  RemoteExecutionRegistry remoteExecutionRegistry,
  LocalJobExecutor localJobExecutor,
  DaoEvalsRepository evalsRepository,
  List<RepoOp> ops,
  List<WatchQuery> watchQueries,
});

/// Builds the fleet + evals layer: the scheduler, executor, evals repository
/// and the RPC ops/watch queries that splice into the catalog.
FleetWiringResult buildFleetWiring({
  required GlobalDatabase globalDb,
  required WorkspaceDatabaseManager workspaceDbs,
}) {
  final fleetRepository = DaoFleetRepository(globalDb.fleetDao);
  final remoteExecutionRegistry = RemoteExecutionRegistry();
  final localJobExecutor = LocalJobExecutor(<JobKind, JobRunner>{});
  final remoteJobExecutor = RemoteJobExecutor(remoteExecutionRegistry);
  final fleetScheduler = FleetSchedulerService(
    repository: fleetRepository,
    executorResolver: (worker) =>
        worker.id == kLocalWorkerId ? localJobExecutor : remoteJobExecutor,
  );
  final evalsRepository = DaoEvalsRepository(workspaceDbs);

  final ops = <RepoOp>[
    ...buildFleetOperatorOps(
      scheduler: fleetScheduler,
      fleetRepository: fleetRepository,
    ),
    ...buildFleetWorkerOps(
      scheduler: fleetScheduler,
      fleetRepository: fleetRepository,
      remoteRegistry: remoteExecutionRegistry,
    ),
    ...buildEvalsOps(repository: evalsRepository),
  ];
  final watchQueries = <WatchQuery>[
    ...buildFleetWatchQueries(fleetRepository: fleetRepository),
    ...buildEvalsWatchQueries(repository: evalsRepository),
  ];

  return (
    fleetScheduler: fleetScheduler,
    fleetRepository: fleetRepository,
    remoteExecutionRegistry: remoteExecutionRegistry,
    localJobExecutor: localJobExecutor,
    evalsRepository: evalsRepository,
    ops: ops,
    watchQueries: watchQueries,
  );
}
