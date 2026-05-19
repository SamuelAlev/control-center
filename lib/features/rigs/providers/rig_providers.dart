import 'package:cc_data/cc_data.dart'
    show
        RemoteRigRepository,
        RigBackendView,
        RigImageView,
        RigPortsView,
        RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';

import 'package:control_center/di/demo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The client adapter for server-hosted enclosures.
final rigRepositoryProvider = Provider<RemoteRigRepository>(
  (ref) => RemoteRigRepository(ref.watch(rpcClientProvider)),
);

/// What the connected server can host.
///
/// A server with no hypervisor answers with an empty list rather than an
/// error, so every rig surface degrades to an honest "not available here"
/// state instead of a failure banner.
final rigCapabilitiesProvider = FutureProvider<List<RigBackendView>>(
  (ref) => ref.watch(rigRepositoryProvider).detect(),
);

/// The base images this host knows about and their state.
///
/// Re-read (invalidated) rather than streamed: a download's progress is the
/// partial size on disk, so polling this while one is in flight is the whole
/// progress mechanism. `rig.downloadImage` deliberately returns as soon as the
/// server accepts the transfer — a base image is hundreds of megabytes, and
/// holding an RPC call open for minutes times the client out on a download
/// that is working fine.
final rigImagesProvider = FutureProvider<List<RigImageView>>(
  (ref) => ref.watch(rigRepositoryProvider).images(),
);

/// Live rigs in a workspace, pushed on every status change.
///
/// On a DEMO server this yields an empty list without subscribing. The demo
/// wires no rig port, so `rig.watchSessions` is absent from the watch registry
/// and a subscription resolves to `Unknown query` — which every consumer then
/// rendered as a raw transport error (the settings "running now" panel showed
/// one where it should have shown "no machines"). Five consumers read this
/// provider, so answering empty HERE fixes all of them at once.
final rigSessionsProvider = StreamProvider.family<List<RigView>, String>(
  (ref, workspaceId) => ref.watch(isDemoServerProvider)
      ? Stream.value(const <RigView>[])
      : ref.watch(rigRepositoryProvider).watch(workspaceId),
);

/// The rig attached to this conversation in ANY non-closed state.
///
/// Whether [rig] is the machine a tab asking for [engine] meant.
///
/// A tab that names no engine takes any rig on its surface — that is the
/// desktop and phone tabs, which have no engine, and a client talking to a
/// server too old to report one. A tab that DOES name an engine takes only
/// that engine's machine: three browser rigs can share one conversation, and
/// showing a Firefox tab the Chromium machine is the one failure this whole
/// feature exists to prevent.
bool _matchesEngine(RigView rig, RigBrowserEngine? engine) =>
    engine == null ||
    rig.browserEngine == engine ||
    // An older server reports no engine at all and only ever ran Chromium.
    (rig.browserEngine == null && engine == RigBrowserEngine.chromium);

/// Whether [rig] is the machine a tab addressing [slotId] meant.
///
/// Exact, both ways round. A tab on the conversation's DEFAULT machine
/// (`slotId == null`) must not match the second machine someone opened beside
/// it, and a tab on that second machine must not fall back to the default when
/// its own is not up yet — either way round the tab would show a machine
/// someone else is driving while claiming to be its own.
bool _matchesSlot(RigView rig, String? slotId) => rig.slotId == slotId;

/// Separate from [conversationRigProvider], which is deliberately live-only
/// because the viewer can only stream a running machine. A rig spends 20–60
/// seconds provisioning and can end up failed, and the tab has to show both:
/// filtering those out is what made "Start the machine" look like it did
/// nothing at all for two minutes and then quietly gave up.
final conversationPendingRigProvider =
    Provider.family<
      RigView?,
      ({
        String workspaceId,
        String conversationId,
        String surface,
        RigBrowserEngine? engine,
        String? slotId,
      })
    >((ref, key) {
      final sessions = ref.watch(rigSessionsProvider(key.workspaceId));
      return sessions.maybeWhen(
        data: (rigs) {
          for (final rig in rigs) {
            if (rig.conversationId == key.conversationId &&
                rig.surface == key.surface &&
                _matchesEngine(rig, key.engine) &&
                _matchesSlot(rig, key.slotId) &&
                rig.phaseKind != RigPhase.closed) {
              return rig;
            }
          }
          return null;
        },
        orElse: () => null,
      );
    });

/// The live rig for one conversation and surface, or null.
///
/// Reads from [rigSessionsProvider] rather than querying, so a panel that is
/// already watching the roster does not open a second subscription for the one
/// row it cares about.
///
/// Excludes exec (terminal) rigs: they share the `computer` surface with a
/// `computer_use` rig, and the panels that ask for the `computer` surface want
/// the drivable one — the terminal's rig is reached through
/// [conversationExecRigProvider] instead.
final conversationRigProvider =
    Provider.family<
      RigView?,
      ({
        String workspaceId,
        String conversationId,
        String surface,
        RigBrowserEngine? engine,
        String? slotId,
      })
    >((ref, key) {
      final sessions = ref.watch(rigSessionsProvider(key.workspaceId));
      return sessions.maybeWhen(
        data: (rigs) {
          for (final rig in rigs) {
            if (rig.conversationId == key.conversationId &&
                rig.surface == key.surface &&
                _matchesEngine(rig, key.engine) &&
                _matchesSlot(rig, key.slotId) &&
                !rig.isExec &&
                rig.isLive) {
              return rig;
            }
          }
          return null;
        },
        orElse: () => null,
      );
    });

/// The live EXEC (terminal) rig for a conversation, or null.
///
/// This is the machine the Terminal (VM) SSHes into, and the one whose ports
/// the ports panel shows. Keyed on the conversation because one conversation
/// reuses one terminal machine.
final conversationExecRigProvider =
    Provider.family<RigView?, ({String workspaceId, String conversationId})>((
      ref,
      key,
    ) {
      final sessions = ref.watch(rigSessionsProvider(key.workspaceId));
      return sessions.maybeWhen(
        data: (rigs) {
          for (final rig in rigs) {
            if (rig.conversationId == key.conversationId &&
                rig.isExec &&
                rig.isLive) {
              return rig;
            }
          }
          return null;
        },
        orElse: () => null,
      );
    });

/// Live forwarded ports for one exec rig, pushed on every change.
///
/// The discovery poll runs on the server; this stream carries only the result.
final rigPortsProvider =
    StreamProvider.family<RigPortsView, ({String workspaceId, String rigId})>(
      (ref, key) => ref
          .watch(rigRepositoryProvider)
          .watchPorts(key.workspaceId, key.rigId),
    );
