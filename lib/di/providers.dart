// Web-safe composition root.
//
// This half of the app's DI holds ONLY web-safe providers:
//
//  - the `RpcX` data repositories (from `cc_data`) the UI reads through — they
//    talk to the active `rpcClientProvider` (in-process host on desktop, a
//    connected `RemoteRpcClient` on web);
//  - pure UI-domain helpers typed against `cc_domain` (schema validator, mention
//    parser, memory-access policy);
//  - the GitHub / Google-Calendar network clients (dio is web-safe) and the
//    keychain-backed credential/preference providers;
//  - the "VM-backed but UI-read" providers (process detection, the local
//    analytics/calendar/meeting/PR-lifecycle repos, the GitHub CLI, the audit
//    trail, …) — DECLARED here but RESOLVED through the `provider_bindings.dart`
//    seam (`build*`), which gives the real desktop implementation on the VM and
//    an honest "not available on web" stub on web.
//
// Every import below must stay web-safe (cc_data, cc_domain interfaces, cc_rpc,
// dio [web-safe], flutter, the rpc_client + storage seams). The VM-only
// providers (the `dao*` repos, cc_infra/cc_natives/cc_persistence/cc_server_core
// services, dispatch/memory/seeder use-cases) live in `server_providers.dart`,
// which is reachable only from the VM-only callers and never from the web graph.
library;

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/entities/activity_entry.dart';
import 'package:cc_domain/core/domain/ports/notification_preferences_port.dart';
import 'package:cc_domain/core/domain/ports/process_control_port.dart';
import 'package:cc_domain/core/domain/ports/process_detection_port.dart';
import 'package:cc_domain/core/domain/ports/schema_validator_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/review_channel_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/services/activity_logger.dart';
import 'package:cc_domain/core/domain/services/agent_mention_parser.dart';
import 'package:cc_domain/core/domain/services/memory_access_policy.dart';
import 'package:cc_domain/features/analytics/domain/repositories/achievement_repository.dart';
import 'package:cc_domain/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:cc_domain/features/analytics/domain/repositories/streak_repository.dart';
import 'package:cc_domain/features/analytics/domain/services/xp_engine.dart';
import 'package:cc_domain/features/auth/domain/ports/github_cli_port.dart';
import 'package:cc_domain/features/auth/domain/repositories/credentials_repository.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/dashboard/domain/services/agent_process_matcher.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/repositories/voice_profile_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_audio_capture_port.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_recording_control_port.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/channel_read_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_domain/features/sandboxing/domain/ports/sandbox_detector_port.dart';
import 'package:cc_domain/features/settings/domain/repositories/acp_model_repository.dart';
import 'package:cc_domain/features/settings/domain/repositories/adapter_repository.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:cc_infra/src/network/google_calendar_api_client.dart';
import 'package:cc_infra/src/network/models/github_user.dart';
import 'package:cc_infra/src/network/network_constants.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_infra/src/util/json_schema_validator.dart';
import 'package:control_center/core/notifications/notification_preferences.dart';
import 'package:control_center/core/notifications/notification_sound_service.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/di/provider_bindings.dart';
import 'package:control_center/features/auth/data/repositories/secure_credentials_repository.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/calendar/data/repositories/google_credentials_repository.dart';
import 'package:control_center/features/calendar/data/services/google_oauth_redirect_channel.dart';
import 'package:control_center/features/calendar/data/services/google_oauth_service.dart';
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:control_center/features/settings/data/privacy_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// NOTE: cc_domain repository interfaces / value objects are pure-Dart and
// web-safe. The credentials/notification/calendar service classes named below
// are likewise web-safe (keychain + dio); their VM-only siblings (Drift repos,
// the desktop notification delivery, the OAuth flow service) live in
// `server_providers.dart`.

/// Provides the shared [SchemaValidatorPort] used by ticketing, dispatch, and
/// pipelines to validate structured agent output against declared contracts.
final schemaValidatorProvider = Provider<SchemaValidatorPort>((ref) {
  return const JsonSchemaValidator();
});

// ── Data repositories the UI reads through (RPC-flipped, web-safe) ───────────
//
// Each resolves to a `cc_data` `RpcX` adapter over the active
// `rpcClientProvider` (the desktop's in-process host or the web client's
// connected `RemoteRpcClient`). Server-side EXECUTION reads the dedicated
// `dao*` providers in `server_providers.dart` instead, so flipping a feature
// provider to RPC never recurses back into the catalog.

/// Provides the [AgentRepository] the UI reads through.
final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return RpcAgentRepository(ref.watch(rpcClientProvider));
});

/// Provides the [AgentRunLogRepository] the UI reads through.
final agentRunLogRepositoryProvider = Provider<AgentRunLogRepository>((ref) {
  return RpcAgentRunLogRepository(ref.watch(rpcClientProvider));
});

/// Provides the [WorkspaceRepository] the UI reads through.
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return RpcWorkspaceRepository(ref.watch(rpcClientProvider));
});

/// Provides the [RepoRepository] the UI reads through.
final repoRepositoryProvider = Provider<RepoRepository>((ref) {
  return RpcRepoRepository(ref.watch(rpcClientProvider));
});

/// Provides the [MessagingRepository] the UI reads through.
final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return RpcMessagingRepository(ref.watch(rpcClientProvider));
});

/// Provides the [ChannelReadRepository] the UI reads through — the sidebar's
/// read-cursor port.
final channelReadRepositoryProvider = Provider<ChannelReadRepository>((ref) {
  return RpcChannelReadRepository(ref.watch(rpcClientProvider));
});

/// Provides the [IsolatedRepoRepository] the UI reads through.
final isolatedRepoRepositoryProvider = Provider<IsolatedRepoRepository>((ref) {
  return RpcIsolatedRepoRepository(ref.watch(rpcClientProvider));
});

/// Provides the [ReviewChannelRepository] the UI reads through.
final reviewChannelRepositoryProvider = Provider<ReviewChannelRepository>((ref) {
  return RpcReviewChannelRepository(ref.watch(rpcClientProvider));
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

/// Provides the [AgentProcessMatcher] instance.
final agentProcessMatcherProvider = Provider<AgentProcessMatcher>((ref) {
  return AgentProcessMatcher();
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

/// Provides the [ProcessDetectionPort] (dashboard + kill-agent on desktop).
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

/// Provides the [CalendarRepository] (over RPC; the cc_server owns the DB).
final calendarRepositoryProvider = Provider<CalendarRepository>(
  buildCalendarRepository,
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

/// Provides a factory for a fresh [MeetingAudioCapturePort] per recording. On
/// web this builds a browser `WebAudioCapture`; on desktop it throws (the local
/// native recorder captures in-process and never reads this).
final meetingAudioCaptureFactoryProvider =
    Provider<MeetingAudioCapturePort Function()>(
  buildMeetingAudioCaptureFactory,
);

/// Provides the [AnalyticsRepository] (over RPC; the cc_server owns the DB).
final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  buildAnalyticsRepository,
);

/// Provides the [AchievementRepository] (over RPC; the cc_server owns the DB).
final achievementRepositoryProvider = Provider<AchievementRepository>(
  buildAchievementRepository,
);

/// Provides the [StreakRepository] (over RPC; the cc_server owns the DB).
final streakRepositoryProvider = Provider<StreakRepository>(
  buildStreakRepository,
);

/// Provides the [XpEngine] keep-alive listener (inert on web).
final xpEngineProvider = Provider<XpEngine>((ref) {
  final engine = buildXpEngine(ref);
  ref.onDispose(engine.dispose);
  return engine;
});

/// Provides the [PrLifecycleRepository] (over RPC; the cc_server owns the DB).
final prLifecycleRepositoryProvider = Provider<PrLifecycleRepository>(
  buildPrLifecycleRepository,
);

/// Provides the [GitHubCliPort] (OS-level `gh` on desktop).
final githubCliServiceProvider = Provider<GitHubCliPort>(
  buildGitHubCliService,
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
final entityActivityProvider = StreamProvider.autoDispose.family<
    List<ActivityEntry>,
    ({String workspaceId, String entityType, String entityId})>((ref, args) {
  return watchEntityActivity(
    ref,
    workspaceId: args.workspaceId,
    entityType: args.entityType,
    entityId: args.entityId,
  );
});

// ── GitHub / Google-Calendar network (dio is web-safe) ───────────────────────

/// Provides a [Dio] instance configured for GitHub API calls.
/// Auth token is read lazily on each request so it picks up gh CLI tokens
/// that resolve asynchronously after app start.
final githubDioProvider = Provider<Dio>((ref) {
  final dio = createDio();
  // Mutable holder so the interceptor reads the latest token at request time,
  // not the value captured when this provider was first built.
  final tokenRef = _MutableString();
  ref.listen(githubAuthTokenProvider, (_, next) => tokenRef.value = next);
  tokenRef.value = ref.read(githubAuthTokenProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final t = tokenRef.value;
        if (t.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $t';
        }
        handler.next(options);
      },
    ),
  );
  // Dio lifecycle is tied to app lifetime — closing it would break
  // long-lived handlers that hold references (e.g. PrProtocolHandler).
  return dio;
});

/// Mutable string holder used by dio interceptors to read the current
/// auth token at request time instead of capture-at-build time.
class _MutableString {
  String value = '';
}

/// Provides a [GitHubApiClient] backed by [githubDioProvider].
final githubApiClientProvider = Provider<GitHubApiClient>((ref) {
  return GitHubApiClient(ref.watch(githubDioProvider));
});

/// Fetches the authenticated GitHub user profile.
final githubUserProvider = FutureProvider<GitHubUser?>((ref) async {
  // GitHub auth lives on the HOST, not this thin client — resolve the current
  // user over RPC (`github.currentUser`). The server answers from its own
  // gh-authenticated client; null when it holds no token.
  try {
    final data = await ref
        .watch(rpcClientProvider)
        .call('github.currentUser', const {});
    final user = data['user'];
    return user is Map
        ? GitHubUser.fromJson(user.cast<String, dynamic>())
        : null;
  } on Object {
    return null;
  }
});

// ── Google Calendar ──

/// Per-workspace Google OAuth token store (keychain-backed).
final googleCredentialsRepositoryProvider =
    Provider<GoogleCredentialsRepository>((ref) {
  return GoogleCredentialsRepository(ref.watch(secureStoreProvider));
});

/// App-scoped bus that delivers the OAuth redirect deep link (captured by the
/// startup URL handler in `main.dart`) to the in-flight authorization flow.
final googleOAuthRedirectChannelProvider =
    Provider<GoogleOAuthRedirectChannel>((ref) {
  final channel = GoogleOAuthRedirectChannel();
  ref.onDispose(channel.dispose);
  return channel;
});

/// The Google OAuth PKCE flow service for a public iOS-type client (no secret;
/// reversed-client-id custom-scheme redirect captured via the channel above).
/// Web-safe: pure dio + crypto + the seamed `open_url` launcher.
final googleOAuthServiceProvider = Provider<GoogleOAuthService>((ref) {
  final channel = ref.watch(googleOAuthRedirectChannelProvider);
  return GoogleOAuthService(
    clientId: ref.watch(googleClientIdProvider),
    awaitRedirect: channel.next,
  );
});

/// Dio for the Google Calendar API, carrying the OAuth Bearer + auto-refresh
/// interceptor. Auth state is read lazily per request so a workspace switch /
/// token refresh is picked up without rebuilding the client.
final googleCalendarDioProvider = Provider<Dio>((ref) {
  final dio = createDio(baseUrl: googleCalendarApiBaseUrl);
  // Added after createDio's built-in interceptors so retry/backoff still
  // covers 429/5xx; this interceptor only handles auth (bearer + 401 refresh).
  dio.interceptors.add(_GoogleAuthInterceptor(ref, dio));
  return dio;
});

/// Provides a [GoogleCalendarApiClient] backed by [googleCalendarDioProvider].
final googleCalendarApiClientProvider = Provider<GoogleCalendarApiClient>((ref) {
  return GoogleCalendarApiClient(ref.watch(googleCalendarDioProvider));
});

/// Injects the per-account Bearer token (refreshing proactively when within the
/// skew window of expiring), and reactively retries once on a 401. Refreshes
/// are single-flighted per account inside [GoogleTokenManager].
class _GoogleAuthInterceptor extends QueuedInterceptor {
  _GoogleAuthInterceptor(this._ref, this._dio);

  final Ref _ref;
  final Dio _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accountId = options.extra[googleAccountIdExtraKey] as String?;
    if (accountId != null) {
      try {
        final token =
            await _ref.read(googleTokenManagerProvider).accessTokenFor(accountId);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        AppLog.w('GoogleAuth', 'Could not attach Google token: $e');
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final accountId = err.requestOptions.extra[googleAccountIdExtraKey] as String?;
    final alreadyRetried = err.requestOptions.extra['googleAuthRetried'] == true;
    if (status == 401 && accountId != null && !alreadyRetried) {
      final token =
          await _ref.read(googleTokenManagerProvider).forceRefresh(accountId);
      if (token != null && token.isNotEmpty) {
        final request = err.requestOptions;
        request.extra['googleAuthRetried'] = true;
        request.headers['Authorization'] = 'Bearer $token';
        try {
          final response = await _dio.fetch<dynamic>(request);
          handler.resolve(response);
          return;
        } on DioException catch (retryError) {
          handler.next(retryError);
          return;
        }
      }
    }
    handler.next(err);
  }
}

// ── Credentials / preferences (keychain + shared_preferences; web-safe) ──────

/// Provides the [CredentialsRepository] implementation.
final credentialsRepositoryProvider = Provider<CredentialsRepository>((ref) {
  return SecureCredentialsRepository(
    ref.watch(secureStoreProvider),
    ref.watch(appPreferencesProvider),
  );
});

/// Provides the [NotificationPreferencesPort] implementation.
final notificationPreferencesProvider = Provider<NotificationPreferencesPort>((ref) {
  return SharedPreferencesNotificationPreferences(ref.watch(appPreferencesProvider));
});

/// Provides [PrivacyPreferences].
final privacyPreferencesProvider = Provider<PrivacyPreferences>((ref) {
  return PrivacyPreferences(ref.watch(appPreferencesProvider));
});

/// Provides the [NotificationSoundService] singleton.
final notificationSoundServiceProvider = Provider<NotificationSoundService>((ref) {
  return NotificationSoundService();
});
