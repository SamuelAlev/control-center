// Web-safe composition root.
//
// This half of the app's DI holds ONLY web-safe providers:
//
//  - the `RpcX` data repositories (from `cc_data`) the UI reads through — they
//    talk to the active `rpcClientProvider`, a connected `RemoteRpcClient` on
//    both desktop and web (the desktop spawns/connects to `cc_server`, web
//    connects directly — both flip through the same RPC adapters);
//  - pure UI-domain helpers typed against `cc_domain` (schema validator, mention
//    parser, memory-access policy);
//  - the GitHub identity + calendar reads (over RPC — the host owns tokens) and the
//    keychain-backed credential/preference providers;
//  - the "VM-capable but UI-read" providers (process detection, the model
//    catalog, …) — DECLARED here but RESOLVED through the
//    `provider_bindings.dart` seam (`build*`), which on the VM resolves to RPC
//    adapters (same as web) and on web resolves to the web seam directly.
//
// Every import below must stay web-safe (cc_data, cc_domain interfaces, cc_rpc,
// flutter, the rpc_client + storage seams). `cc_server` is the
// sole owner of the database, MCP registry and execution — the desktop links
// no `cc_persistence`/`cc_server_core`/`cc_host`/`cc_mcp` package, so there is
// no VM-only provider half left to import here.
library;

import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/entities/activity_entry.dart';
import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_domain/core/domain/ports/notification_preferences_port.dart';
import 'package:cc_domain/core/domain/ports/process_control_port.dart';
import 'package:cc_domain/core/domain/ports/process_detection_port.dart';
import 'package:cc_domain/core/domain/ports/run_transcript_relay_port.dart';
import 'package:cc_domain/core/domain/ports/schema_validator_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_script_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/services/activity_logger.dart';
import 'package:cc_domain/core/domain/services/agent_mention_parser.dart';
import 'package:cc_domain/core/domain/services/memory_access_policy.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/dictation/domain/dictation_control_port.dart';
import 'package:cc_domain/features/fonts/fonts.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/goal_repository.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/repositories/voice_profile_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_audio_capture_port.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_recording_control_port.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_summaries_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/space_turn_relay_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_read_repository.dart';
import 'package:cc_domain/features/notifications/domain/repositories/notification_feed_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_domain/features/sandboxing/domain/ports/sandbox_detector_port.dart';
import 'package:cc_domain/features/settings/domain/repositories/acp_model_repository.dart';
import 'package:cc_domain/features/settings/domain/repositories/adapter_repository.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_domain/features/weather/domain/repositories/weather_repository.dart';
import 'package:cc_infra/cc_infra_web.dart';
import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
import 'package:control_center/core/notifications/notification_preferences.dart';
import 'package:control_center/core/notifications/notification_sound_service.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/providers/sync_engine_provider.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/di/provider_bindings.dart';
import 'package:control_center/features/demo/demo_world.dart';

import 'package:control_center/features/settings/data/privacy_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// NOTE: cc_domain repository interfaces / value objects are pure-Dart and
// web-safe. The credentials/notification/calendar service classes named below
// are likewise web-safe (keychain + dio); the desktop notification delivery
// lives in `core/notifications/` (pure client-side rendering, no server
// dependency — the events it renders come over RPC via `RpcNotificationMapper`).

/// Provides the shared [SchemaValidatorPort] used by ticketing, dispatch and
/// pipelines to validate structured agent output against declared contracts.
final schemaValidatorProvider = Provider<SchemaValidatorPort>((ref) {
  return const JsonSchemaValidator();
});

// ── Data repositories the UI reads through (RPC-flipped, web-safe) ───────────
//
// Each resolves to a `cc_data` `RpcX` adapter over the active
// `rpcClientProvider` — a connected `RemoteRpcClient` talking to `cc_server`,
// identically on desktop and web. `cc_server` owns the database and all
// execution; the client never reaches a DAO/repository implementation directly.

/// Provides the [AgentRepository] the UI reads through.
final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return RpcAgentRepository(ref.watch(rpcClientProvider));
});

/// Provides the [AgentRunLogRepository] the UI reads through.
final agentRunLogRepositoryProvider = Provider<AgentRunLogRepository>((ref) {
  return RpcAgentRunLogRepository(ref.watch(rpcClientProvider));
});

/// Provides the [RunTranscriptRelayPort] — one run's activity relay
/// (`agent_run_log.watchRunTranscript`), which a subagent's activity tab
/// subscribes to. Seeds live from the server's registry while the run streams,
/// else replays the persisted transcript.
final runTranscriptRelayPortProvider = Provider<RunTranscriptRelayPort>((ref) {
  return RpcAgentRunLogRepository(ref.watch(rpcClientProvider));
});

/// Provides the governance [GoalRepository] the UI reads through (read-only;
/// goal writes run server-side via the MCP tools — PRD 09).
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return RpcGoalRepository(ref.watch(rpcClientProvider));
});

/// Provides the durable-goal (`AgentGoalRun`, `/goal` + `/loop`) read/control
/// surface — the `agentGoalRuns.*` ops. Standalone like
/// [agentPresenceReaderProvider]: the domain port is the host supervisor's,
/// so the concrete adapter type is what consumers bind to.
final agentGoalRunRepositoryProvider = Provider<RpcAgentGoalRunRepository>((
  ref,
) {
  return RpcAgentGoalRunRepository(ref.watch(rpcClientProvider));
});

/// Provides the governance [ApprovalRepository] the UI reads through (read-only;
/// decisions run server-side via the MCP tools — PRD 09).
final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) {
  return RpcApprovalRepository(ref.watch(rpcClientProvider));
});

/// Reads computed agent presence (availability × workload) over RPC, keyed by
/// agent id — the `agent_presence.forWorkspace` op (PRD 09).
final agentPresenceReaderProvider = Provider<RpcAgentPresenceReader>((ref) {
  return RpcAgentPresenceReader(ref.watch(rpcClientProvider));
});

/// Provides the per-conversation [TodoRepository] the UI reads and mutates
/// through (the `todos.*` ops + `todos.watch`). Agent-facing writes flow
/// through the MCP `todo_write` tool server-side; both persist the same store.
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return RpcTodoRepository(ref.watch(rpcClientProvider));
});

/// Provides the [NotificationFeedRepository] the notification center reads
/// (`notifications.watch` + the per-user read mark) and acknowledges through.
/// The feed itself is written only server-side (`NotificationFeedRecorder`).
final notificationFeedRepositoryProvider = Provider<NotificationFeedRepository>(
  (ref) {
    return RpcNotificationFeedRepository(ref.watch(rpcClientProvider));
  },
);

/// Provides the [WorkspaceRepository] the UI reads through.
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return RpcWorkspaceRepository(ref.watch(rpcClientProvider));
});

/// Provides the [RepoRepository] the UI reads through.
final repoRepositoryProvider = Provider<RepoRepository>((ref) {
  return RpcRepoRepository(ref.watch(rpcClientProvider));
});

/// Provides the [RepoScriptRepository] the UI reads through — per-repo
/// lifecycle scripts (setup/archive) and their recorded runs. The server
/// owns both persistence and execution; the client only reads config and
/// watches run rows.
final repoScriptRepositoryProvider = Provider<RepoScriptRepository>((ref) {
  return RpcRepoScriptRepository(ref.watch(rpcClientProvider));
});

/// Provides the [MessagingRepository] the UI reads through.
///
/// Wired to the deterministic sync engine (PRD 16 §6): when the `messaging`
/// kill-switch is on, `watchSpaces`/`watchSpacesByWorkspace`/
/// `watchParticipants` adopt the live delta feed instead of re-querying their
/// legacy full-snapshot subscriptions on every change.
final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return RpcMessagingRepository(
    ref.watch(rpcClientProvider),
    sync: ref.watch(syncEngineProvider),
  );
});

/// Provides the [SpaceTurnRelayPort] — the live turn relay a conversation
/// view subscribes to per open space (`messaging.watchSpaceTurns`).
final spaceTurnRelayPortProvider = Provider<SpaceTurnRelayPort>((ref) {
  return RpcMessagingRepository(
    ref.watch(rpcClientProvider),
    sync: ref.watch(syncEngineProvider),
  );
});

/// Provides the [MessagingSummariesPort] — server-computed per-space
/// activity signals (the sidebar read model).
final messagingSummariesPortProvider = Provider<MessagingSummariesPort>((ref) {
  return RpcMessagingRepository(
    ref.watch(rpcClientProvider),
    sync: ref.watch(syncEngineProvider),
  );
});

/// Provides the [ConversationRepository] — parallel conversations ("paren-
/// theses") inside a space, backed by the `conversation.*` ops.
final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return RpcConversationRepository(ref.watch(rpcClientProvider));
});

/// Provides the [SpaceReadRepository] the UI reads through — the sidebar's
/// read-cursor port.
final spaceReadRepositoryProvider = Provider<SpaceReadRepository>((ref) {
  return RpcSpaceReadRepository(ref.watch(rpcClientProvider));
});

/// Provides the [IsolatedRepoRepository] the UI reads through.
final isolatedRepoRepositoryProvider = Provider<IsolatedRepoRepository>((ref) {
  return RpcIsolatedRepoRepository(ref.watch(rpcClientProvider));
});

/// Provides the [ReviewSpaceRepository] the UI reads through.
final reviewSpaceRepositoryProvider = Provider<ReviewSpaceRepository>((ref) {
  return RpcReviewSpaceRepository(ref.watch(rpcClientProvider));
});

/// Provides the [AgentWorkingMemoryRepository] the UI reads through.
final agentWorkingMemoryRepositoryProvider =
    Provider<AgentWorkingMemoryRepository>((ref) {
      return RpcAgentWorkingMemoryRepository(ref.watch(rpcClientProvider));
    });

/// Provides the [MemoryFactRepository] the UI reads through.
final memoryFactRepositoryProvider = Provider<MemoryFactRepository>((ref) {
  return RpcMemoryFactRepository(ref.watch(rpcClientProvider));
});

/// Provides the [MemoryPolicyRepository] the UI reads through.
final memoryPolicyRepositoryProvider = Provider<MemoryPolicyRepository>((ref) {
  return RpcMemoryPolicyRepository(ref.watch(rpcClientProvider));
});

/// Provides the [MemoryDomainRepository] the UI reads through.
final memoryDomainRepositoryProvider = Provider<MemoryDomainRepository>((ref) {
  return RpcMemoryDomainRepository(ref.watch(rpcClientProvider));
});

/// Provides the [MemoryAccessGrantRepository] the UI reads through.
final memoryAccessGrantRepositoryProvider =
    Provider<MemoryAccessGrantRepository>((ref) {
      return RpcMemoryAccessGrantRepository(ref.watch(rpcClientProvider));
    });

/// Provides the [VoiceProfileRepository] the UI reads through.
final voiceProfileRepositoryProvider = Provider<VoiceProfileRepository>((ref) {
  return RpcVoiceProfileRepository(ref.watch(rpcClientProvider));
});

// ── Pure UI-domain helpers (web-safe, cc_domain) ─────────────────────────────

/// Provides the [MemoryAccessPolicy] instance.
final memoryAccessPolicyProvider = Provider<MemoryAccessPolicy>((ref) {
  return const MemoryAccessPolicy();
});

/// Provides the [AgentMentionParser] instance.
final agentMentionParserProvider = Provider<AgentMentionParser>((ref) {
  return const AgentMentionParser();
});

/// Provides the [ActivityLogger] instance (event-bus driven, web-safe).
final activityLoggerProvider = Provider<ActivityLogger>((ref) {
  return ActivityLogger(eventBus: ref.watch(domainEventBusProvider));
});

// ── VM-backed but UI-read (seamed via provider_bindings.dart) ────────────────
//
// DECLARED here so the screens that read them compile on web; RESOLVED through
// the `build*` factories from `provider_bindings.dart` — the real desktop
// implementation on the VM, an honest "not available on web" stub on web.

/// Provides the [WorkspaceFilesystemPort] — the local workspace on-disk layout
/// (agents/skills/conversation dirs). DECLARED here so the agent/skill/PR
/// screens that read it compile on web; on the VM it resolves to the real
/// `WorkspaceFilesystemService`, on web to an honest "not available" stub.
final workspaceFilesystemPortProvider = Provider<WorkspaceFilesystemPort>(
  buildWorkspaceFilesystemPort,
);

/// Provides the [ProcessDetectionPort] (kill-agent on desktop).
final processDetectionServiceProvider = Provider<ProcessDetectionPort>(
  buildProcessDetectionService,
);

/// Provides the [ProcessControlPort] (kill a local agent process on desktop).
final processControlPortProvider = Provider<ProcessControlPort>(
  buildProcessControlPort,
);

/// Provides the [AdapterRepository] (settings → adapters; desktop detection).
final adapterRepositoryProvider = Provider<AdapterRepository>(
  buildAdapterRepository,
);

/// Provides the [AcpModelRepository] (settings → adapters; desktop detection).
final acpModelRepositoryProvider = Provider<AcpModelRepository>(
  buildAcpModelRepository,
);

/// Provides the [ModelCatalogService] (PRD 05). Desktop assembles the models.dev
/// catalog in-process (disk cache → snapshot → network); web serves the bundled
/// snapshot. The catalog is global reference data, so it is not workspace- or
/// DB-scoped — only governance policy (workspace-scoped) flows over RPC.
final modelCatalogServiceProvider = Provider<ModelCatalogService>(
  buildModelCatalogService,
);

/// Provides the [CalendarRepository] (over RPC; the cc_server owns the DB).
final calendarRepositoryProvider = Provider<CalendarRepository>(
  buildCalendarRepository,
);

/// Provides the [WeatherRepository] (over RPC; the cc_server owns the DB). The
/// soundscapes panel reads the latest snapshot for the active workspace and
/// forwards refresh / set-location to the host.
final weatherRepositoryProvider = Provider<WeatherRepository>(
  buildWeatherRepository,
);

/// Provides the [FontCatalogRepository] (over RPC; the host owns the upstream
/// fetch and its cache). Feeds the settings font picker.
final fontCatalogRepositoryProvider = Provider<FontCatalogRepository>(
  buildFontCatalogRepository,
);

/// Provides the [MeetingRepository] (over RPC; the cc_server owns the DB).
final meetingRepositoryProvider = Provider<MeetingRepository>(
  buildMeetingRepository,
);

/// Provides the [MeetingRecordingControlPort] (over RPC). Used by the web
/// recorder to stream browser-captured audio to the host; unused on desktop
/// self-serve (the local native recorder captures in-process).
final meetingRecordingControlProvider = Provider<MeetingRecordingControlPort>(
  buildMeetingRecordingControl,
);

/// Provides the [DictationControlPort] (over RPC). Drives the composer's
/// server-backed voice dictation: streams mic PCM to the host and watches
/// finalized transcript windows (PRD 25 §2).
final dictationControlProvider = Provider<DictationControlPort>(
  buildDictationControl,
);

/// Provides a factory for a fresh [MeetingAudioCapturePort] per recording. On
/// web this builds a browser `WebAudioCapture`; on desktop it throws (the local
/// native recorder captures in-process and never reads this).
final meetingAudioCaptureFactoryProvider =
    Provider<MeetingAudioCapturePort Function()>(
      buildMeetingAudioCaptureFactory,
    );

/// Provides the [PrLifecycleRepository] (over RPC; the cc_server owns the DB).
final prLifecycleRepositoryProvider = Provider<PrLifecycleRepository>(
  buildPrLifecycleRepository,
);

/// Provides the [SandboxDetectorPort] — OS-native sandbox detection. The
/// sandbox runs on the HOST that executes agents, so detection reflects that
/// host: on the desktop self-serve build it probes the local machine; on a
/// thin/web client it asks the connected `cc_server` over the `sandbox.detect`
/// RPC op. DECLARED here so the Settings → Sandboxing page compiles on web (it
/// must never `import 'dart:io'`); RESOLVED via the `build*` seam.
final sandboxDetectorPortProvider = Provider<SandboxDetectorPort>(
  buildSandboxDetector,
);

/// Watches the audit trail for one entity, mapped to domain [ActivityEntry]s
/// so presentation never touches the database layer. Streamed over RPC from the
/// server that owns the audit trail (on both desktop and web thin clients).
final entityActivityProvider = StreamProvider.autoDispose
    .family<
      List<ActivityEntry>,
      ({String workspaceId, String entityType, String entityId})
    >((ref, args) {
      return watchEntityActivity(
        ref,
        workspaceId: args.workspaceId,
        entityType: args.entityType,
        entityId: args.entityId,
      );
    });

// ── GitHub identity (read over RPC — the HOST owns every forge token) ────────

/// How often the viewer lookup is retried while no user has resolved.
///
/// This is an RPC to the host, not a GitHub call — the server's own identity
/// cache is what bounds requests to GitHub — so a short interval is cheap.
/// Retrying at all is the point: every inbox section is classified relative to
/// this login (`ClassifyPrInboxUseCase` returns an all-empty inbox for an
/// empty one), so a lookup that failed once and stuck left the operator's
/// inbox empty, and claiming they were all caught up, for the whole session.
const Duration kGitHubIdentityRetryInterval = Duration(seconds: 30);

/// Ceiling for the identity retry's exponential backoff.
///
/// The retry used to be a FLAT 30s forever: an unauthenticated session (no
/// host token — a state that does not resolve itself) re-ran the lookup twice
/// a minute for the whole session, and each attempt invalidates this provider,
/// which cascades a rebuild through `githubUserProvider` and
/// `viewerGitHubTeamsProvider` — both watched per avatar. Backing off to a
/// five-minute ceiling keeps the "recovers on its own" property that matters
/// (a token pasted into Settings is picked up without a restart) while making
/// the steady state of a genuinely token-less host nearly free.
const Duration kGitHubIdentityRetryMaxInterval = Duration(minutes: 5);

/// Consecutive failed/empty identity lookups, driving the backoff above.
/// Module-level because the provider is rebuilt by each retry, so per-build
/// state would reset the backoff on every attempt — which is how a backoff
/// silently becomes a flat interval.
int _githubIdentityAttempts = 0;

/// The raw `github.currentUser` answer (`{user, teams}`), retried until a user
/// resolves.
///
/// GitHub auth lives on the HOST, not this thin client. One fetch backs both
/// [githubUserProvider] and [viewerGitHubTeamsProvider] so the two never
/// double-call the op. Never completes with an error: a failure resolves empty
/// and schedules a retry, so downstream consumers keep their
/// "unresolved reads as absent" contract.
final _viewerGitHubIdentityProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  void retryLater() {
    // Exponential, capped. `1 << n` doubles per consecutive failure and the
    // clamp holds it at the ceiling.
    final n = _githubIdentityAttempts;
    _githubIdentityAttempts = n + 1;
    final scaled = kGitHubIdentityRetryInterval * (1 << (n > 4 ? 4 : n));
    final delay = scaled > kGitHubIdentityRetryMaxInterval
        ? kGitHubIdentityRetryMaxInterval
        : scaled;
    final timer = Timer(delay, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }

  // The demo has no forge credential, so this op is absent from its registry
  // and no amount of retrying will change that. Answer with the fixture
  // viewer instead: the team membership is what routes PR #414's TEAM review
  // request into the visitor's queue. See `kDemoViewerLogin`.
  if (ref.watch(isDemoServerProvider)) {
    return const {
      'user': {'login': kDemoViewerLogin, 'name': 'Maya Okonkwo'},
      'teams': [
        {'org': kDemoViewerOrg, 'slug': kDemoViewerTeamSlug},
      ],
    };
  }

  try {
    final data = await ref
        .watch(rpcClientProvider)
        .call('github.currentUser', const {});
    if (data['user'] is! Map) {
      // No viewer yet: the host holds no token, or its own lookup is inside
      // the cool-down it entered after a GitHub failure. Ask again rather than
      // settling into a permanent empty identity.
      retryLater();
    } else {
      // Resolved: reset the backoff so a LATER failure starts fast again.
      _githubIdentityAttempts = 0;
    }
    return data;
  } on Object catch (e) {
    // Never rethrow (consumers rely on "unresolved reads as absent"), but never
    // silent either: a persistently failing lookup used to retry every 30s
    // forever with zero diagnostics while every inbox section rendered empty.
    AppLog.w('Identity', 'github.currentUser lookup failed: $e');
    retryLater();
    return const {};
  }
});

/// Fetches the authenticated GitHub user profile. Null until the host resolves
/// one (see [_viewerGitHubIdentityProvider] for the retry).
final githubUserProvider = FutureProvider<GitHubUser?>((ref) async {
  final data = await ref.watch(_viewerGitHubIdentityProvider.future);
  final user = data['user'];
  return user is Map ? GitHubUser.fromJson(user.cast<String, dynamic>()) : null;
});

/// The server user's GitHub teams, keyed by lower-case org login. Empty when
/// the lookup failed or the user belongs to no teams — inbox matching then
/// stays user-only.
final viewerGitHubTeamsProvider = FutureProvider<Map<String, Set<String>>>((
  ref,
) async {
  final data = await ref.watch(_viewerGitHubIdentityProvider.future);
  return parseViewerGitHubTeams(data['teams']);
});

/// Parses the `teams` array from `github.currentUser` (`[{org, slug}, …]`).
Map<String, Set<String>> parseViewerGitHubTeams(Object? raw) {
  if (raw is! List) {
    return const {};
  }
  final byOrg = <String, Set<String>>{};
  for (final entry in raw.whereType<Map>()) {
    final org = (entry['org'] as String?)?.toLowerCase() ?? '';
    final slug = (entry['slug'] as String?)?.toLowerCase() ?? '';
    if (org.isEmpty || slug.isEmpty) {
      continue;
    }
    (byOrg[org] ??= <String>{}).add(slug);
  }
  return byOrg;
}

// ── Credentials / preferences (keychain + shared_preferences; web-safe) ──────

// There is no client credentials repository any more. Provider tokens belong
// to the USER and live on the server (`credentials.*` / `oauth.*`), not in this
// machine's keychain — see `features/auth/providers/credential_migration.dart`,
// which hands over what an older build stored here.

/// Provides the [NotificationPreferencesPort] implementation.
final notificationPreferencesProvider = Provider<NotificationPreferencesPort>((
  ref,
) {
  return SharedPreferencesNotificationPreferences(
    ref.watch(appPreferencesProvider),
  );
});

/// Provides [PrivacyPreferences].
final privacyPreferencesProvider = Provider<PrivacyPreferences>((ref) {
  return PrivacyPreferences(ref.watch(appPreferencesProvider));
});

/// Provides the [NotificationSoundService] singleton.
///
/// The output device is read per play (not watched) so changing it never
/// rebuilds — and so disposes — the player mid-chime; the service re-routes on
/// the next sound.
final notificationSoundServiceProvider = Provider<NotificationSoundService>((
  ref,
) {
  return NotificationSoundService(
    outputDeviceName: () => ref.read(audioOutputDeviceProvider),
  );
});
