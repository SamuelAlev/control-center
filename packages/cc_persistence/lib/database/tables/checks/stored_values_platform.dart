import 'package:cc_domain/core/domain/entities/catalog_file.dart'
    show CatalogFileSource, CatalogFileState;
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/entities/sso_connection.dart';
import 'package:cc_domain/core/domain/repositories/server_notice_repository.dart';
import 'package:cc_domain/core/domain/services/cache_kind_registry.dart';
import 'package:cc_domain/core/domain/value_objects/editor_layout_cache_kinds.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_connect_mode.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart'
    show EnvironmentPlacement;
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/job_spec.dart'
    show JobKind;
import 'package:cc_domain/features/fleet/domain/value_objects/job_status.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/placement_decision.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_status.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart'
    show EnforcementLevel;
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart'
    show ActionDecision;
import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/agent_pull_request_requester_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/lockfile_diff.dart'
    show LockfileEcosystem;
import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart'
    show CohortDerivation;
import 'package:cc_domain/features/pr_review/domain/value_objects/visual_diff.dart'
    show VisualDiffStatus;
import 'package:cc_domain/features/rigs/domain/value_objects/enclosure_backend.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart'
    show RigCloseReason, RigPhase;
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_persistence/database/daos/paired_device_dao.dart'
    show PairedDeviceStatus;
import 'package:cc_persistence/database/tables/workspace_routes_table.dart'
    show WorkspaceRouteKind;

/// The closed sets of values stored in text columns of these tables:
/// Repository, review, environment, membership, settings and server-global tables.
///
/// Each list is built from the Dart enum that owns the values, with the same
/// accessor the mapper writes (`name`, `wire`, …), so a `CHECK` on the
/// column cannot disagree with the code. A column check reads
/// `text().check(status.isIn(PlatformStoredValues.someStatus))()`.
///
/// Adding a value to one of those enums changes the declared schema: bump the
/// database's schema version so existing files converge to the wider check.
// A namespace the column checks read; it is never instantiated.
// ignore: avoid_classes_with_only_static_members
abstract final class PlatformStoredValues {
  /// `editor_layouts.surface`.
  static final List<String> editorLayoutSurface = [
    for (final surface in EditorLayoutSurface.values) surface.wire,
  ];

  /// `agent_pull_request_requesters.state`.
  static final List<String> agentPullRequestRecordState = [
    for (final state in AgentPullRequestRecordState.values) state.wire,
  ];

  /// `server_notices.kind`.
  static final List<String> serverNoticeKind = [
    for (final kind in ServerNoticeKind.values) kind.wire,
  ];

  // --- repositories and reviews ---

  /// `repos.forge`.
  static final List<String> forgeHost = [
    for (final forge in ForgeHost.values) forge.wire,
  ];

  /// `isolated_repos.backend`.
  static final List<String> repoIsolationBackend = [
    for (final backend in RepoIsolationBackend.values) backend.name,
  ];

  /// `pull_requests.status`.
  static final List<String> prGenerationStatus = [
    for (final status in PrGenerationStatus.values) status.name,
  ];

  /// `review_spaces.status`.
  static final List<String> reviewSpaceStatus = [
    for (final status in ReviewSpaceStatus.values) status.wire,
  ];

  /// `review_cohorts.derivation`.
  static final List<String> cohortDerivation = [
    for (final derivation in CohortDerivation.values) derivation.wireName,
  ];

  /// `visual_diff_snapshots.status`.
  static final List<String> visualDiffStatus = [
    for (final status in VisualDiffStatus.values) status.wireName,
  ];

  /// `review_axis_results.axis`.
  static final List<String> reviewAxis = [
    for (final axis in ReviewAxis.values) axis.wireName,
  ];

  /// `review_axis_results.verdict`.
  static final List<String> reviewAxisVerdict = [
    for (final verdict in ReviewAxisVerdict.values) verdict.wireName,
  ];

  /// `review_dependency_diffs.ecosystem`.
  static final List<String> lockfileEcosystem = [
    for (final ecosystem in LockfileEcosystem.values) ecosystem.wireName,
  ];

  // --- rigs and environments ---

  /// `rig_sessions.surface`.
  static final List<String> rigSurface = [
    for (final surface in RigSurface.values) surface.wire,
  ];

  /// `rig_sessions.backend`.
  static final List<String> enclosureBackend = [
    for (final backend in EnclosureBackend.values) backend.wire,
  ];

  /// `rig_sessions.phase`.
  static final List<String> rigPhase = [
    for (final phase in RigPhase.values) phase.wire,
  ];

  /// `rig_sessions.close_reason`.
  static final List<String> rigCloseReason = [
    for (final reason in RigCloseReason.values) reason.wire,
  ];

  /// `environment_runs.kind`.
  static final List<String> environmentRunKind = [
    for (final kind in EnvironmentRunKind.values) kind.name,
  ];

  /// `environment_runs.status`.
  static final List<String> environmentRunStatus = [
    for (final status in EnvironmentRunStatus.values) status.name,
  ];

  /// `space_environments.status`.
  static final List<String> environmentStatus = [
    for (final status in EnvironmentStatus.values) status.wire,
  ];

  /// `space_environments.placement`.
  static final List<String> environmentPlacement = [
    for (final placement in EnvironmentPlacement.values) placement.name,
  ];

  // --- files, caches and authority ---

  /// `caches.kind`: only the kinds the registry declares, so state that
  /// needs a table of its own cannot be parked in the cache.
  static final List<String> cacheKind = [
    for (final kind in CacheKindRegistry.declared) kind.name,
  ];

  /// `catalog_files.source`.
  static final List<String> catalogFileSource = [
    for (final source in CatalogFileSource.values) source.name,
  ];

  /// `catalog_files.state`.
  static final List<String> catalogFileState = [
    for (final state in CatalogFileState.values) state.name,
  ];

  // --- membership ---

  /// The preset roles a workspace may grant without making someone its
  /// owner: `workspace_invites.role`, `workspace_roles.base_preset`.
  static final List<String> grantableWorkspaceRole = [
    for (final role in WorkspaceRole.values)
      if (role != WorkspaceRole.owner) role.wireName,
  ];

  /// Every preset role: `workspace_members.role` (beside a custom role's
  /// `custom:<id>`), `sso_connections.default_role`.
  static final List<String> workspaceRole = [
    for (final role in WorkspaceRole.values) role.wireName,
  ];

  /// The prefix of a custom role's wire form, `custom:<id>`.
  static const String customRolePrefix = 'custom:';

  /// `workspace_member_repo_grants.level`. `none` is never stored: it is the
  /// absence of a row.
  static final List<String> repoGrantLevel = [
    for (final level in RepoGrantLevel.values)
      if (level != RepoGrantLevel.none) level.wireName,
  ];

  // --- server-global ---

  /// `workspace_routes.kind`.
  static final List<String> workspaceRouteKind = [
    for (final kind in WorkspaceRouteKind.values) kind.wireName,
  ];

  /// `workspaces.connect_mode`.
  static final List<String> workspaceConnectMode = [
    for (final mode in WorkspaceConnectMode.values) mode.wireName,
  ];

  /// `workers.status`.
  static final List<String> workerStatus = [
    for (final status in WorkerStatus.values) status.wire,
  ];

  /// `jobs.kind`.
  static final List<String> jobKind = [
    for (final kind in JobKind.values) kind.wire,
  ];

  /// `jobs.status`.
  static final List<String> jobStatus = [
    for (final status in JobStatus.values) status.wire,
  ];

  /// `placement_log.decision`.
  static final List<String> placementCode = [
    for (final code in PlacementCode.values) code.wire,
  ];

  /// `paired_devices.status`.
  static const List<String> pairedDeviceStatus = PairedDeviceStatus.values;

  /// `server_audit.outcome`.
  static final List<String> auditOutcome = [
    for (final outcome in AuditOutcome.values) outcome.name,
  ];

  /// `sso_connections.kind` (and its id, the kind's slug).
  static final List<String> ssoProviderKind = [
    for (final kind in SsoProviderKind.values) kind.wireName,
  ];

  /// `managed_action_policies.action_class`.
  static final List<String> actionClass = [
    for (final actionClass in ActionClass.values) actionClass.wire,
  ];

  /// `managed_action_policies.decision`.
  static final List<String> actionDecision = [
    for (final decision in ActionDecision.values) decision.wire,
  ];

  /// `managed_action_policies.enforcement`.
  static final List<String> enforcementLevel = [
    for (final level in EnforcementLevel.values) level.wire,
  ];
}
