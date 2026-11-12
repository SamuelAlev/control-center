// Web-safe composition root.
//
// Every provider here talks to the active `rpcClientProvider`: a connected
// `RemoteRpcClient` on both desktop and web (the desktop spawns or connects to
// `cc_server`, web connects directly), so both targets resolve the SAME
// `cc_data` RPC adapters. The one genuine platform divergence — browser audio
// capture for the web meeting recorder — goes through
// `audio_capture_bindings.dart`.
library;

import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/entities/activity_entry.dart';
import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_domain/core/domain/ports/audit_log_port.dart';
import 'package:cc_domain/core/domain/ports/import_hold_review.dart';
import 'package:cc_domain/core/domain/ports/notification_preferences_port.dart';
import 'package:cc_domain/core/domain/ports/process_detection_port.dart';
import 'package:cc_domain/core/domain/ports/run_transcript_relay_port.dart';
import 'package:cc_domain/core/domain/ports/schema_validator_port.dart';
import 'package:cc_domain/core/domain/ports/server_notice_feed.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/commit_signing_key_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/services/agent_mention_parser.dart';
import 'package:cc_domain/core/domain/services/json_schema_validator.dart';
import 'package:cc_domain/core/domain/value_objects/repo_path_issue.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_graph_lookup_port.dart';
import 'package:cc_domain/features/connect/domain/repositories/workspace_connect_repository.dart';
import 'package:cc_domain/features/dictation/domain/dictation_control_port.dart';
import 'package:cc_domain/features/fonts/fonts.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/repositories/voice_profile_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_audio_capture_port.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_recording_control_port.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/messaging/domain/ports/conversation_title_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_summaries_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/space_turn_relay_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_read_repository.dart';
import 'package:cc_domain/features/model_routing/domain/services/model_catalog_service.dart';
import 'package:cc_domain/features/notifications/domain/repositories/notification_feed_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_domain/features/sandboxing/domain/ports/sandbox_detector_port.dart';
import 'package:cc_domain/features/settings/domain/repositories/acp_model_repository.dart';
import 'package:cc_domain/features/settings/domain/repositories/adapter_repository.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_domain/features/weather/domain/repositories/weather_repository.dart';
import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
import 'package:control_center/core/notifications/notification_preferences.dart';
import 'package:control_center/core/notifications/notification_sound_service.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/audio_capture_bindings.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/settings/data/privacy_preferences.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart'
    show activeWorkspaceIdProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Domain repository interfaces and value objects are pure Dart and web-safe.
// Desktop notification rendering lives in `core/notifications/`; its events
// arrive over RPC through `RpcNotificationMapper`.

/// Provides the shared [SchemaValidatorPort] used by ticketing, dispatch and
/// pipelines to validate structured agent output against declared contracts.
final schemaValidatorProvider = Provider<SchemaValidatorPort>((ref) {
  return const JsonSchemaValidator();
});

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

/// Provides the durable-goal (`AgentGoalRun`, `/goal` + `/loop`) read/control
/// surface — the `agentGoalRuns.*` ops. Standalone like
/// [agentPresenceReaderProvider]: the domain port is the host supervisor's,
/// so the concrete adapter type is what consumers bind to.
final agentGoalRunRepositoryProvider = Provider<RpcAgentGoalRunRepository>((
  ref,
) {
  return RpcAgentGoalRunRepository(ref.watch(rpcClientProvider));
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

/// Each linked repository's path issue in one workspace, by repo id: the
/// server keeps listing such a repository but does not serve its checkout
/// until it is linked again.
///
/// Read off the same live list as the repositories (each one's
/// `path_issue`), never kept on the `Repo` entity: it is the server's verdict
/// on the stored path, re-sent when a relink clears it.
final repoPathIssuesProvider =
    StreamProvider.family<Map<String, RepoPathIssue>, String>(
      (ref, workspaceId) => ref
          .watch(rpcClientProvider)
          .subscribe('workspace.watchReposForWorkspace', {
            'workspace_id': workspaceId,
          })
          .map(
            (frame) => {
              for (final repo in (frame['repos'] as List? ?? const []))
                if (repo is Map && repo['id'] is String)
                  repo['id'] as String: ?RepoPathIssue.fromWire(
                    repo['path_issue'],
                  ),
            },
          ),
    );

/// Provides one workspace's Control Center Connect choice
/// (`workspaceConnect.*`).
final workspaceConnectRepositoryProvider = Provider<WorkspaceConnectRepository>(
  (ref) => RpcWorkspaceConnectRepository(ref.watch(rpcClientProvider)),
);

/// Provides the [RepoRepository] the UI reads through.
final repoRepositoryProvider = Provider<RepoRepository>((ref) {
  return RpcRepoRepository(ref.watch(rpcClientProvider));
});

/// Slim code-graph lookup for the PR-diff symbol popover (`codeGraph.symbolLookup`).
final codeGraphLookupProvider = Provider<CodeGraphLookupPort>((ref) {
  return RpcCodeGraphLookupRepository(ref.watch(rpcClientProvider));
});

/// Provides the environment client: definitions, live state and actions. The
/// server owns persistence and execution; the client renders and forwards.
final environmentRepositoryProvider = Provider<RpcEnvironmentRepository>((ref) {
  return RpcEnvironmentRepository(ref.watch(rpcClientProvider));
});

/// Provides the [MessagingRepository] the UI reads through.
final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return RpcMessagingRepository(ref.watch(rpcClientProvider));
});

/// Provides the [SpaceTurnRelayPort] — the live turn relay a conversation
/// view subscribes to per open space (`messaging.watchSpaceTurns`).
final spaceTurnRelayPortProvider = Provider<SpaceTurnRelayPort>((ref) {
  return RpcMessagingRepository(ref.watch(rpcClientProvider));
});

/// Provides the [MessagingSummariesPort] — server-computed per-space
/// activity signals (the sidebar read model).
final messagingSummariesPortProvider = Provider<MessagingSummariesPort>((ref) {
  return RpcMessagingRepository(ref.watch(rpcClientProvider));
});

/// Provides the [ConversationRepository] — parallel conversations ("paren-
/// theses") inside a space, backed by the `conversation.*` ops.
final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return RpcConversationRepository(ref.watch(rpcClientProvider));
});

/// Provides the [ConversationTitlePort] — title suggestions on the
/// workspace's content synthesizer (`conversation.suggestTitle`) and the live
/// "title being generated" flags (`conversation.watchTitleGenerating`).
final conversationTitlePortProvider = Provider<ConversationTitlePort>((ref) {
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

/// Provides the [AgentMentionParser] instance.
final agentMentionParserProvider = Provider<AgentMentionParser>((ref) {
  return const AgentMentionParser();
});

// The connected server's host capabilities and host-owned data. Each is the
// same `cc_data` RPC adapter on desktop and web: the server's machine is the
// one that has the filesystem, processes, adapters and sandbox, never this
// client's.

/// The workspace on-disk layout (agents/skills/conversation dirs) on the
/// SERVER's machine: server-side paths are opaque tokens handed back to other
/// `fs.*` ops.
final workspaceFilesystemPortProvider = Provider<WorkspaceFilesystemPort>(
  (ref) => RpcWorkspaceFilesystemPort(ref.watch(rpcClientProvider)),
);

/// The server host's agent process table (`process.detect` / `process.kill`).
final processDetectionServiceProvider = Provider<ProcessDetectionPort>(
  (ref) => RpcProcessDetectionPort(ref.watch(rpcClientProvider)),
);

/// The agent-runner CLIs installed on the server host (Settings → Adapters,
/// `adapter.detectOne` / `adapter.detectAll`).
final adapterRepositoryProvider = Provider<AdapterRepository>(
  (ref) => RpcAdapterRepository(ref.watch(rpcClientProvider)),
);

/// The models an adapter advertises, resolved on the server host
/// (`acp.listModels`).
final acpModelRepositoryProvider = Provider<AcpModelRepository>(
  (ref) => RpcAcpModelRepository(ref.watch(rpcClientProvider)),
);

/// The [ModelCatalogService] (PRD 05). The host fetches models.dev and caches
/// it under its data dir; clients read that document over `models.catalog`.
/// The catalog is global reference data, so it is not workspace-scoped — only
/// governance policy (workspace-scoped) is.
final modelCatalogServiceProvider = Provider<ModelCatalogService>(
  (ref) => ModelCatalogService(
    source: RpcModelsDevSource(ref.watch(rpcClientProvider)),
  ),
);

/// Synced calendar events and connected accounts (`calendar.*`). Account
/// connection, RSVP, the sync reconciler, the alert sweep and meeting linking
/// run inside the server; the RPC repository refuses them.
final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => RpcCalendarRepository(ref.watch(rpcClientProvider)),
);

/// The signed-in person's own commit signing key (`credentials.*`
/// CommitSigningKey ops): only its public half ever reaches a client.
final commitSigningKeyRepositoryProvider = Provider<CommitSigningKeyRepository>(
  (ref) => RpcCommitSigningKeyRepository(ref.watch(rpcClientProvider)),
);

/// The latest weather snapshot for the active workspace (`weather.*`). The
/// live Open-Meteo fetch and persistence run host-side, so refresh and
/// location changes forward to the server.
final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => RpcWeatherRepository(ref.watch(rpcClientProvider)),
);

/// The font catalogue: the host fetches and caches it, because a client cannot
/// obtain a Skia-decodable font file from an upstream at all (see
/// `installHostFontLoader`). Feeds the settings font picker.
final fontCatalogRepositoryProvider = Provider<FontCatalogRepository>(
  (ref) => RpcFontCatalogRepository(ref.watch(rpcClientProvider)),
);

/// Meetings (`meeting.*`). Recording, transcription and summaries run on the
/// server; clients only capture audio.
final meetingRepositoryProvider = Provider<MeetingRepository>(
  (ref) => RpcMeetingRepository(ref.watch(rpcClientProvider)),
);

/// Streams captured mic/system audio to the host (`meeting.startRecording` /
/// `ingestAudio` / `stopRecording`): natively captured on desktop,
/// browser-captured on web.
final meetingRecordingControlProvider = Provider<MeetingRecordingControlPort>(
  (ref) => RpcMeetingRecordingControl(ref.watch(rpcClientProvider)),
);

/// Drives the composer's server-backed voice dictation: streams mic PCM to the
/// host and watches finalized transcript windows (PRD 25 §2).
final dictationControlProvider = Provider<DictationControlPort>(
  (ref) => RpcDictationControl(ref.watch(rpcClientProvider)),
);

/// A factory for a fresh [MeetingAudioCapturePort] per recording. On web this
/// builds a browser `WebAudioCapture`; on desktop it throws (the native
/// recorder captures itself and never reads this).
final meetingAudioCaptureFactoryProvider =
    Provider<MeetingAudioCapturePort Function()>(
      buildMeetingAudioCaptureFactory,
    );

/// PR drafts (`pr_lifecycle.*`): the compose-PR screen reads and writes them;
/// publishing runs host-side under the server's forge credentials.
final prLifecycleRepositoryProvider = Provider<PrLifecycleRepository>(
  (ref) => RpcPrLifecycleRepository(ref.watch(rpcClientProvider)),
);

/// OS-native sandbox detection. The sandbox runs on the HOST that executes
/// agents, so detection asks the connected `cc_server` (`sandbox.detect`).
final sandboxDetectorPortProvider = Provider<SandboxDetectorPort>(
  (ref) => RemoteSandboxDetector(ref.watch(rpcClientProvider)),
);

/// The audit log (`audit.watchLog`): the server trail and every workspace
/// trail the caller administers, as one live table.
final auditLogPortProvider = Provider<AuditLogPort>(
  (ref) => RemoteAuditLog(ref.watch(rpcClientProvider)),
);

/// The server owner's open notices (`server.notices`). Owner-only on the
/// server, so only an owner's surface reads it.
final serverNoticeFeedProvider = Provider<ServerNoticeFeed>(
  (ref) => RemoteServerNotices(ref.watch(rpcClientProvider)),
);

/// The grants a restored workspace file carried, held for the server owner
/// (`workspace.importHolds.*`).
final importHoldReviewProvider = Provider<ImportHoldReview>(
  (ref) => RemoteImportHolds(ref.watch(rpcClientProvider)),
);

/// Watches the audit trail for one entity, mapped to domain [ActivityEntry]s
/// so presentation never touches the data layer. Streamed over RPC from the
/// server that owns the audit trail.
final entityActivityProvider = StreamProvider.autoDispose
    .family<
      List<ActivityEntry>,
      ({String workspaceId, String entityType, String entityId})
    >(
      (ref, args) => RemoteActivityLog(
        ref.watch(rpcClientProvider),
      ).watchForEntity(args.workspaceId, args.entityType, args.entityId),
    );

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
///
/// Held by a provider that is only ever READ, never watched: the identity
/// provider is rebuilt by each retry, so per-build state would reset the
/// backoff on every attempt — which is how a backoff silently becomes a flat
/// interval. Scoped to the container rather than the isolate, so two sessions
/// (or two tests) never share one count.
final _githubIdentityAttemptsProvider = Provider<_AttemptCounter>(
  (ref) => _AttemptCounter(),
);

class _AttemptCounter {
  int value = 0;
}

/// The raw `github.currentUser` answer (`{user, teams}`) for the active
/// workspace, retried until a user resolves.
///
/// GitHub auth lives on the HOST, not this thin client. One fetch backs both
/// [githubUserProvider] and [viewerGitHubTeamsProvider] so the two never
/// double-call the op. Never completes with an error: a failure resolves empty
/// and schedules a retry, so downstream consumers keep their
/// "unresolved reads as absent" contract. Invalidated with the rest of the
/// forge identity by `invalidateForgeState`.
final viewerGitHubIdentityProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final attempts = ref.read(_githubIdentityAttemptsProvider);
  void retryLater() {
    // Exponential, capped. `1 << n` doubles per consecutive failure and the
    // clamp holds it at the ceiling.
    final n = attempts.value;
    attempts.value = n + 1;
    final scaled = kGitHubIdentityRetryInterval * (1 << (n > 4 ? 4 : n));
    final delay = scaled > kGitHubIdentityRetryMaxInterval
        ? kGitHubIdentityRetryMaxInterval
        : scaled;
    final timer = Timer(delay, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }

  final demo = ref.watch(demoGitHubIdentityProvider);
  if (demo != null) {
    return demo;
  }

  // The identity is the person's GitHub sign-in IN this workspace (a
  // workspace on its own App signs them in as a different grant), so a
  // workspace switch re-reads it. No workspace, no identity to ask about.
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return const {};
  }

  try {
    final data = await ref.watch(rpcClientProvider).call('github.currentUser', {
      'workspace_id': workspaceId,
    });
    if (data['user'] is! Map) {
      // No viewer yet: the host holds no token, or its own lookup is inside
      // the cool-down it entered after a GitHub failure. Ask again rather than
      // settling into a permanent empty identity.
      retryLater();
    } else {
      // Resolved: reset the backoff so a LATER failure starts fast again.
      attempts.value = 0;
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
/// one (see [viewerGitHubIdentityProvider] for the retry).
final githubUserProvider = FutureProvider<GitHubUser?>((ref) async {
  final data = await ref.watch(viewerGitHubIdentityProvider.future);
  final user = data['user'];
  return user is Map ? GitHubUser.fromJson(user.cast<String, dynamic>()) : null;
});

/// The server user's GitHub teams, keyed by lower-case org login. Empty when
/// the lookup failed or the user belongs to no teams — inbox matching then
/// stays user-only.
final viewerGitHubTeamsProvider = FutureProvider<Map<String, Set<String>>>((
  ref,
) async {
  final data = await ref.watch(viewerGitHubIdentityProvider.future);
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

// There is no client credentials repository. Provider sign-ins belong to the
// USER and live on the server (`oauth.*`), never in this machine's keychain.

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
    playbackAvailable: ref.watch(mediaPlaybackAvailableProvider),
  );
});
