// Desktop (VM) bindings for the "VM-backed but UI-read" providers declared in
// `providers.dart`.
//
// The desktop is a thin client exactly like web: every host-data / execution
// capability below resolves to the SAME `cc_data` `RpcX` adapter the web
// binding uses, talking to whatever `cc_server` is connected (spawned locally
// or remote) — never a local probe of this machine. The only legitimate
// desktop-local divergence is genuine native device capture
// (`buildMeetingAudioCaptureFactory`), which has no web equivalent.
library;

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/entities/activity_entry.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/ports/process_control_port.dart';
import 'package:cc_domain/core/domain/ports/process_detection_port.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/dictation/domain/dictation_control_port.dart';
import 'package:cc_domain/features/fonts/fonts.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_audio_capture_port.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_recording_control_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:cc_domain/features/sandboxing/domain/ports/sandbox_detector_port.dart';
import 'package:cc_domain/features/settings/domain/repositories/acp_model_repository.dart';
import 'package:cc_domain/features/settings/domain/repositories/adapter_repository.dart';
import 'package:cc_domain/features/weather/domain/repositories/weather_repository.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared honest failure for a desktop-only capability invoked with no local
/// equivalent — kept symmetric with `provider_bindings_web.dart`.
class _DesktopProcessControl implements ProcessControlPort {
  @override
  bool isPidAlive(int pid) => throw UnsupportedError(
    'Local agent process control (kill) is not available — the sandbox runs '
    'on the connected cc_server, not this machine.',
  );

  @override
  Future<void> kill(int pid) => throw UnsupportedError(
    'Local agent process control (kill) is not available — the sandbox runs '
    'on the connected cc_server, not this machine.',
  );
}

/// Workspace filesystem over RPC: the agents/skills/conversation directory
/// tree lives on the SERVER's machine, so the desktop resolves its server-side
/// paths (opaque tokens it hands back to other server ops) + writes through
/// them over the host catalog's `fs.*` ops — identical to web.
WorkspaceFilesystemPort buildWorkspaceFilesystemPort(Ref ref) =>
    RpcWorkspaceFilesystemPort(ref.watch(rpcClientProvider));

/// Bootstrap workspace list for active-id reconciliation, read over RPC.
///
/// The desktop is a thin client — it opens no local database — so the active-id
/// bootstrap reads the connected `cc_server`'s workspace list. `workspace.
/// watchAll` is cross-workspace (NOT session-scoped), so it does not depend on
/// the bound / active workspace and the active-id resolution stays acyclic.
/// The session is bound to the active workspace explicitly during boot (see
/// `bootstrap_io.dart`), not via this stream.
Stream<List<Workspace>> buildBootstrapWorkspacesStream(Ref ref) =>
    RpcWorkspaceRepository(ref.watch(rpcClientProvider)).watchAll();

/// Process detection over RPC: the "active agent processes" surface reads
/// the SERVER host's process table through the host catalog's
/// `process.detect` op — identical to web.
ProcessDetectionPort buildProcessDetectionService(Ref ref) =>
    RpcProcessDetectionPort(ref.watch(rpcClientProvider));

/// Honest stub: killing a local agent process by pid has no client equivalent
/// — the sandbox runs on the connected `cc_server`, not this machine.
ProcessControlPort buildProcessControlPort(Ref ref) => _DesktopProcessControl();

/// Adapter detection over RPC: Settings → Adapters probes the agent-runner
/// CLIs installed on the SERVER host through the catalog's `adapter.detectOne`
/// / `adapter.detectAll` ops — identical to web.
AdapterRepository buildAdapterRepository(Ref ref) =>
    RpcAdapterRepository(ref.watch(rpcClientProvider));

/// ACP-model listing over RPC: the models an adapter advertises are resolved
/// on the SERVER host through the catalog's `acp.listModels` op — identical to
/// web.
AcpModelRepository buildAcpModelRepository(Ref ref) =>
    RpcAcpModelRepository(ref.watch(rpcClientProvider));

/// Model catalog (PRD 05): served from the bundled models.dev snapshot — the
/// catalog is global reference data, so the snapshot is a faithful read-only
/// view on a thin client (matches web; no per-machine disk cache to keep in
/// sync with a remote server).
ModelCatalogService buildModelCatalogService(Ref ref) =>
    ModelCatalogService(source: InMemoryModelsDevSource());

/// Calendar over RPC: the calendar screens read synced events + connected
/// accounts from the connected `cc_server`'s `calendar.*` ops/watches. Host-
/// resident writes (account connect/disconnect, RSVP, the sync reconciler, the
/// alert sweep, meeting linking) throw on the Rpc repo — they run inside the
/// server.
CalendarRepository buildCalendarRepository(Ref ref) =>
    RpcCalendarRepository(ref.watch(rpcClientProvider));

/// Weather over RPC: the soundscapes panel reads the latest snapshot for the
/// active workspace from the connected `cc_server`'s `weather.*` ops/watch. The
/// live Open-Meteo fetch + persistence run host-side, so refresh / set-location
/// / clear-location forward to the server — identical to web.
WeatherRepository buildWeatherRepository(Ref ref) =>
    RpcWeatherRepository(ref.watch(rpcClientProvider));

/// The font catalogue over RPC: the host fetches and caches it, because a client
/// cannot obtain a Skia-decodable font file from an upstream at all (see
/// `installHostFontLoader`). Identical to web.
FontCatalogRepository buildFontCatalogRepository(Ref ref) =>
    RpcFontCatalogRepository(ref.watch(rpcClientProvider));

/// Meetings over RPC: reads + the user-facing edits the meeting screens reach
/// route through the server's `meeting.*` ops/watches. Live recording +
/// transcription run server-side; the desktop only captures audio natively
/// (see `buildMeetingAudioCaptureFactory`'s doc).
MeetingRepository buildMeetingRepository(Ref ref) =>
    RpcMeetingRepository(ref.watch(rpcClientProvider));

/// Meeting recording control over RPC: streams natively-captured mic/system
/// audio to the host via `meeting.startRecording`/`ingestAudio`/
/// `stopRecording` — the desktop sibling of the web recorder, which streams
/// browser-captured audio over the same ops.
MeetingRecordingControlPort buildMeetingRecordingControl(Ref ref) =>
    RpcMeetingRecordingControl(ref.watch(rpcClientProvider));

/// Dictation control over RPC: streams natively-captured mic PCM to the host
/// via `dictation.start`/`ingestAudio`/`stop` and watches finalized windows
/// over `dictation.watchPartials` (PRD 25 §2). Identical to the web binding —
/// the mic streams through `package:record` on both targets.
DictationControlPort buildDictationControl(Ref ref) =>
    RpcDictationControl(ref.watch(rpcClientProvider));

/// Throws: the desktop recorder captures the microphone + system loopback
/// audio NATIVELY (`meeting_capture_bindings_io.dart`) and streams it to the
/// host over [MeetingRecordingControlPort] — it never asks for a
/// [MeetingAudioCapturePort] factory (that is the web recorder's browser-audio
/// seam). Kept so the provider resolves on both targets.
MeetingAudioCapturePort Function() buildMeetingAudioCaptureFactory(Ref ref) =>
    () => throw UnsupportedError(
      'Browser audio capture is only available on web — the desktop '
      'captures natively.',
    );

/// PR lifecycle over RPC: the compose-PR screen reads the draft list/by-id and
/// writes (create / update / publish-to-GitHub / delete a draft) through the
/// server's `pr_lifecycle.*` ops/watch. Publishing runs host-side against the
/// server-resident GitHub token.
PrLifecycleRepository buildPrLifecycleRepository(Ref ref) =>
    RpcPrLifecycleRepository(ref.watch(rpcClientProvider));

/// Sandbox detection over RPC: the OS-native sandbox runs on the SERVER host,
/// so the desktop asks the connected `cc_server` what backends are available
/// (and the recommended one) through the catalog's `sandbox.detect` op —
/// identical to web.
SandboxDetectorPort buildSandboxDetector(Ref ref) =>
    RemoteSandboxDetector(ref.watch(rpcClientProvider));

/// Activity log over RPC: the audit trail is workspace-scoped and lives on the
/// server, so the entity-timeline view subscribes to the server's
/// `activity.watchForEntity` and decodes the real `ActivityEntryDto` stream
/// (the host injects the bound workspace; [workspaceId] is the bound one the
/// client refills the entity with).
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
