// Web bindings for the "VM-backed but UI-read" providers declared in
// `providers.dart`.
//
// The host-resident capabilities the web client reads — adapter / ACP-model /
// gh-CLI probing (Settings → Adapters + auth status) and agent process
// detection (the "active processes" surface) — are served over RPC:
// each binding resolves a cc_data `RpcX` adapter that calls the connected host's
// catalog ops (`adapter.*`, `acp.listModels`, `process.*`),
// so the web client drives the SERVER host's real behavior rather than a stub.
// A host that wires no detector leaves the op absent (default-deny) and the
// adapter degrades gracefully (empty / "not found").
//
// The one remaining honest stub is [ProcessControlPort]: its `isPidAlive` is
// synchronous (no remote round trip) and the port is only driven by host-side
// reconcilers that never run on web, so it stays a loud `UnsupportedError` stub.
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
import 'package:cc_infra/cc_infra_web.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/meetings/data/web/web_audio_capture.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared honest failure for a desktop-only capability invoked on web.
Never _unsupported(String capability) => throw UnsupportedError(
  '$capability is not available on web (a desktop-only capability with no '
  'web equivalent).',
);

/// Mixin that fails loudly for any unimplemented member of a stubbed interface.
mixin _WebUnavailable {
  String get _capability;

  @override
  dynamic noSuchMethod(Invocation invocation) => _unsupported(_capability);
}

class _WebProcessControl with _WebUnavailable implements ProcessControlPort {
  @override
  String get _capability => 'Local agent process control (kill)';
}

/// Workspace filesystem over RPC: the agents/skills/conversation directory tree
/// lives on the SERVER's machine, so the web client resolves its server-side
/// paths (opaque tokens it hands back to other server ops) + writes through them
/// over the host catalog's `fs.*` ops. Real desktop/web parity for the workspace
/// on-disk layout.
WorkspaceFilesystemPort buildWorkspaceFilesystemPort(Ref ref) =>
    RpcWorkspaceFilesystemPort(ref.watch(rpcClientProvider));

/// Bootstrap workspace list for active-id reconciliation.
///
/// On web there is no in-process host (and thus no rpcClient → activeWorkspaceId
/// cycle), so this safely reads the same RPC-flipped public workspace repository
/// the UI uses. The web client has no local Drift `dao*` to read instead.
Stream<List<Workspace>> buildBootstrapWorkspacesStream(Ref ref) =>
    RpcWorkspaceRepository(ref.watch(rpcClientProvider)).watchAll();

/// Process detection over RPC: the "active agent processes" surface reads
/// the SERVER host's process table — and stops a process there — through
/// the host catalog's `process.detect` / `process.kill` ops.
ProcessDetectionPort buildProcessDetectionService(Ref ref) =>
    RpcProcessDetectionPort(ref.watch(rpcClientProvider));

/// Honest stub: killing a local agent process by pid has no web equivalent.
/// `ProcessControlPort.isPidAlive` is synchronous (it cannot be an async RPC
/// round trip) and the port is only driven by host-side reconcilers that never
/// run on web, so this stays a loud stub rather than an RPC seam.
ProcessControlPort buildProcessControlPort(Ref ref) => _WebProcessControl();

/// Adapter detection over RPC: Settings → Adapters probes the agent-runner CLIs
/// installed on the SERVER host through the catalog's `adapter.detectOne` /
/// `adapter.detectAll` ops.
AdapterRepository buildAdapterRepository(Ref ref) =>
    RpcAdapterRepository(ref.watch(rpcClientProvider));

/// ACP-model listing over RPC: the models an adapter advertises are resolved on
/// the SERVER host through the catalog's `acp.listModels` op.
AcpModelRepository buildAcpModelRepository(Ref ref) =>
    RpcAcpModelRepository(ref.watch(rpcClientProvider));

/// Model catalog on web (PRD 05): served from the bundled models.dev snapshot
/// (no disk, no network — both are unavailable in the browser sandbox). The
/// catalog is global reference data, so the snapshot is a faithful read-only
/// view; provider enablement defaults to disabled (the browser has no provider
/// env keys).
ModelCatalogService buildModelCatalogService(Ref ref) =>
    ModelCatalogService(source: InMemoryModelsDevSource());

/// Calendar over RPC: the calendar screens READ synced events + connected
/// accounts from the host catalog's `calendar.*` ops/watches. The writes
/// (account connect/disconnect, RSVP, the sync reconciler, the alert sweep and
/// meeting linking) all depend on the host-resident OAuth tokens + Google API
/// client, so the Rpc repo throws for them (never reached from the web UI).
CalendarRepository buildCalendarRepository(Ref ref) =>
    RpcCalendarRepository(ref.watch(rpcClientProvider));

/// Weather over RPC: the soundscapes panel READS the latest snapshot for the
/// active workspace from the host catalog's `weather.*` ops/watch. The live
/// Open-Meteo fetch + persistence run host-side, so refresh / set-location /
/// clear-location forward to the server (the web client holds no location or
/// network of its own).
WeatherRepository buildWeatherRepository(Ref ref) =>
    RpcWeatherRepository(ref.watch(rpcClientProvider));

/// The font catalogue over RPC: the host fetches and caches it, because a client
/// cannot obtain a Skia-decodable font file from an upstream at all (see
/// `installHostFontLoader`). Identical to desktop.
FontCatalogRepository buildFontCatalogRepository(Ref ref) =>
    RpcFontCatalogRepository(ref.watch(rpcClientProvider));

/// Meetings over RPC: reads + the user-facing edits the meeting screens reach
/// route through the host catalog's `meeting.*` ops/watches. Live recording +
/// summarization stay device-only on the host (the inert web recorder never
/// records), so the recorder-only writes throw [UnsupportedError].
MeetingRepository buildMeetingRepository(Ref ref) =>
    RpcMeetingRepository(ref.watch(rpcClientProvider));

/// Meeting recording control over RPC: the web recorder streams browser-captured
/// mic + system audio to the host's `meeting.startRecording`/`ingestAudio`/
/// `stopRecording` ops through this adapter.
MeetingRecordingControlPort buildMeetingRecordingControl(Ref ref) =>
    RpcMeetingRecordingControl(ref.watch(rpcClientProvider));

/// Dictation control over RPC: the composer streams browser-captured mic PCM
/// (`package:record`'s AudioWorklet backend) to the host's `dictation.start`/
/// `ingestAudio`/`stop` ops and watches finalized windows over
/// `dictation.watchPartials` (PRD 25 §2).
DictationControlPort buildDictationControl(Ref ref) =>
    RpcDictationControl(ref.watch(rpcClientProvider));

/// Factory for a fresh browser audio capture (one per recording). The web
/// recorder pumps its mic + system frames to the host over the control port.
MeetingAudioCapturePort Function() buildMeetingAudioCaptureFactory(Ref ref) =>
    WebAudioCapture.new;

/// PR lifecycle over RPC: the compose-PR screen READS the draft list/by-id AND
/// WRITES (create / update / publish-to-GitHub / delete a draft) through the
/// host catalog's `pr_lifecycle.*` ops/watch. Publishing runs server-side
/// against the host-resident GitHub token (the web client holds none), so it
/// works against a desktop GUI host and surfaces the GitHub failure against a
/// token-less headless server.
PrLifecycleRepository buildPrLifecycleRepository(Ref ref) =>
    RpcPrLifecycleRepository(ref.watch(rpcClientProvider));

/// Sandbox detection over RPC: the OS-native sandbox runs on the SERVER host, so
/// the web client asks the connected `cc_server` what backends are available
/// (and the recommended one) through the catalog's `sandbox.detect` op rather
/// than probing the browser (impossible — `dart:io` is unavailable on web).
SandboxDetectorPort buildSandboxDetector(Ref ref) =>
    RemoteSandboxDetector(ref.watch(rpcClientProvider));

/// Activity log over RPC: the audit trail is workspace-scoped and lives on the
/// host, so the entity-timeline view subscribes to the host catalog's
/// `activity.watchForEntity` and decodes the real `ActivityEntryDto` stream
/// (the host injects the bound workspace; [workspaceId] is the bound one the
/// client refills the entity with). No more empty-stream stub.
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
