// Desktop (VM) bindings for the "VM-backed but UI-read" providers declared in
// `providers.dart`.
//
// These providers are typed as a `cc_domain` interface (or service) so the
// symbol is web-nameable, but their concrete implementation is desktop-only
// (Drift repos, process detection, the OS GitHub CLI, the audit-log DAO, …).
// `providers.dart` resolves each one through a conditional import: this file on
// the VM (returns the real `server_providers.dart` implementation),
// `provider_bindings_web.dart` on web (returns an honest "not available on web"
// stub). The `server_providers.dart` import keeps cc_infra/cc_persistence/
// cc_natives strictly on the VM side of the seam.
library;

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/entities/activity_entry.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/ports/process_control_port.dart';
import 'package:cc_domain/core/domain/ports/process_detection_port.dart';
import 'package:cc_domain/features/analytics/domain/repositories/achievement_repository.dart';
import 'package:cc_domain/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:cc_domain/features/analytics/domain/repositories/streak_repository.dart';
import 'package:cc_domain/features/analytics/domain/services/xp_engine.dart';
import 'package:cc_domain/features/auth/domain/ports/github_cli_port.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_audio_capture_port.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_recording_control_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_domain/features/sandboxing/domain/ports/sandbox_detector_port.dart';
import 'package:cc_domain/features/settings/domain/repositories/acp_model_repository.dart';
import 'package:cc_domain/features/settings/domain/repositories/adapter_repository.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_infra/src/process/process_control_service.dart';
import 'package:cc_infra/src/workspaces/workspace_filesystem_service.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/di/server_providers.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers_server.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Desktop local-filesystem workspace layout (agents/skills/conversation dirs).
WorkspaceFilesystemPort buildWorkspaceFilesystemPort(Ref ref) =>
    WorkspaceFilesystemService(appCcPaths);

/// Bootstrap workspace list for active-id reconciliation, read over RPC.
///
/// The desktop is a thin client — it opens no local database — so the active-id
/// bootstrap reads the connected `cc_server`'s workspace list rather than a
/// Drift DAO (which now throws on the DB-less desktop). `workspace.watchAll` is
/// cross-workspace (NOT session-scoped), so it does not depend on the bound /
/// active workspace and the active-id resolution stays acyclic. The session is
/// bound to the active workspace explicitly during boot (see
/// `bootstrap_io.dart`), not via this stream.
Stream<List<Workspace>> buildBootstrapWorkspacesStream(Ref ref) =>
    RpcWorkspaceRepository(ref.watch(rpcClientProvider)).watchAll();

/// Desktop process-detection (dashboard "active processes" + kill-agent).
ProcessDetectionPort buildProcessDetectionService(Ref ref) =>
    ref.watch(processDetectionServiceProvider);

/// Desktop process control (kill a local agent process by pid).
ProcessControlPort buildProcessControlPort(Ref ref) =>
    const ProcessControlService();

/// Desktop adapter-detection repository (settings → adapters).
AdapterRepository buildAdapterRepository(Ref ref) =>
    ref.watch(adapterRepositoryProvider);

/// Desktop ACP-model repository (settings → adapters).
AcpModelRepository buildAcpModelRepository(Ref ref) =>
    ref.watch(acpModelRepositoryProvider);

/// Calendar over RPC: the desktop is a thin client (it opens no local DB), so
/// the calendar screens read synced events + connected accounts from the
/// connected `cc_server`'s `calendar.*` ops/watches. Host-resident writes
/// (account connect/disconnect, RSVP, the sync reconciler, the alert sweep,
/// meeting linking) throw on the Rpc repo — they run inside the server.
CalendarRepository buildCalendarRepository(Ref ref) =>
    RpcCalendarRepository(ref.watch(rpcClientProvider));

/// Meetings over RPC: reads + the user-facing edits the meeting screens reach
/// route through the server's `meeting.*` ops/watches. Live recording +
/// summarization stay host-side, so the recorder-only writes throw on the Rpc
/// repo (the desktop-host capture slice is re-wired separately).
MeetingRepository buildMeetingRepository(Ref ref) =>
    RpcMeetingRepository(ref.watch(rpcClientProvider));

/// Meeting recording control over RPC. Unused on desktop self-serve (the local
/// native recorder captures + transcribes in-process), but wired symmetrically
/// so the provider resolves on both targets.
MeetingRecordingControlPort buildMeetingRecordingControl(Ref ref) =>
    RpcMeetingRecordingControl(ref.watch(rpcClientProvider));

/// Browser audio capture is web-only; the desktop recorder captures natively
/// in-process, so this factory is never invoked here. Kept so the provider
/// resolves on both targets (and deliberately does NOT import the web impl,
/// which would pull `package:web` into the VM build).
MeetingAudioCapturePort Function() buildMeetingAudioCaptureFactory(Ref ref) =>
    () => throw UnsupportedError(
          'Browser audio capture is only available on web.',
        );

/// Analytics over RPC: the analytics screens read scorecards/leaderboard/daily
/// stats/workspace health from the server's `analytics.*` ops/watches. The
/// maintenance reconcilers (rebuild/backfill) run host-side, so the Rpc repo
/// throws for them.
AnalyticsRepository buildAnalyticsRepository(Ref ref) =>
    RpcAnalyticsRepository(ref.watch(rpcClientProvider));

/// Achievements over RPC: the analytics screens read unlocked badges from the
/// server's `achievements.*` ops/watches. Unlocking is host-side via the
/// XpEngine, so the Rpc repo throws for `unlock`.
AchievementRepository buildAchievementRepository(Ref ref) =>
    RpcAchievementRepository(ref.watch(rpcClientProvider));

/// Streaks over RPC: the analytics screens read streaks from the server's
/// `streaks.*` ops/watches. Updating a streak is host-side via the XpEngine,
/// so the Rpc repo throws for `updateStreak`.
StreakRepository buildStreakRepository(Ref ref) =>
    RpcStreakRepository(ref.watch(rpcClientProvider));

/// XP engine backed by the RPC analytics repos. On the thin-client desktop the
/// XpEngine only reacts to local `PrMerged` domain events to keep the analytics
/// screen's watch alive; the actual XP writes happen host-side, so its repos'
/// write methods throw if ever reached.
XpEngine buildXpEngine(Ref ref) => XpEngine(
      ref.watch(domainEventBusProvider),
      RpcAnalyticsRepository(ref.watch(rpcClientProvider)),
      RpcAchievementRepository(ref.watch(rpcClientProvider)),
      RpcStreakRepository(ref.watch(rpcClientProvider)),
    );

/// PR lifecycle over RPC: the compose-PR screen reads the draft list/by-id and
/// writes (create / update / publish-to-GitHub / delete a draft) through the
/// server's `pr_lifecycle.*` ops/watch. Publishing runs host-side against the
/// server-resident GitHub token.
PrLifecycleRepository buildPrLifecycleRepository(Ref ref) =>
    RpcPrLifecycleRepository(ref.watch(rpcClientProvider));

/// Desktop OS-level GitHub CLI port (`gh`).
GitHubCliPort buildGitHubCliService(Ref ref) =>
    ref.watch(githubCliServiceProvider);

/// Desktop sandbox detection: probes the LOCAL machine's OS-native sandbox
/// backends (`sandbox-exec` on macOS, `bubblewrap`/`socat` on Linux/WSL2) via
/// the in-process `SandboxBackendDetector`. The desktop self-serve build runs
/// agents on this same machine, so the local detector is authoritative.
SandboxDetectorPort buildSandboxDetector(Ref ref) =>
    ref.watch(localSandboxDetectorProvider);

/// Activity log over RPC: the audit trail is workspace-scoped and lives on the
/// server, so the entity-timeline view subscribes to the server's
/// `activity.watchForEntity` and decodes the real `ActivityEntryDto` stream (the
/// host injects the bound workspace; [workspaceId] is the bound one the client
/// refills the entity with).
Stream<List<ActivityEntry>> watchEntityActivity(
  Ref ref, {
  required String workspaceId,
  required String entityType,
  required String entityId,
}) {
  return RemoteActivityLog(
    ref.watch(rpcClientProvider),
  ).watchForEntity(workspaceId, entityType, entityId);
}
