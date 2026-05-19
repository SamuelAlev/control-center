import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action_result.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_state.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_capabilities.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_file_transfer.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';

/// A live frame stream from a rig, plus what the backend actually settled on.
///
/// The negotiated fields are not the requested ones: a viewer asks, the
/// backend clamps, and the viewer must draw its canvas from what came back.
class RigStream {
  /// Creates a [RigStream].
  const RigStream({
    required this.bytes,
    required this.negotiated,
    required this.displaySize,
  });

  /// The raw encoded byte stream. The server relays these without decoding —
  /// it is a pipe, not a transcoder.
  final Stream<List<int>> bytes;

  /// What the backend settled on (codec, fps, quality, size).
  final RigWatchRequest negotiated;

  /// The guest's display size behind the stream, which may differ from the
  /// stream size when the backend is scaling rather than mode-setting.
  final RigDisplaySize displaySize;
}

/// A watch lane cannot be opened, and the host knows exactly why.
///
/// Distinct from "no such rig" (a null [RigPort.watchStream]) because the two
/// need different words in front of a person: one is a machine that has gone,
/// the other is a machine that is fine and a HOST that is missing a tool. The
/// mobile lane transcodes Android's H.264 to JPEG through the host's ffmpeg,
/// so an ffmpeg-less host has a perfectly healthy device it cannot show.
///
/// [code] is a stable token the relay puts on the wire and the viewer maps to
/// a localized line; [message] is the operator-facing sentence for logs.
class RigStreamUnavailable implements Exception {
  /// Creates a [RigStreamUnavailable].
  const RigStreamUnavailable({required this.code, required this.message});

  /// A stable, machine-readable reason (e.g. `ffmpeg-missing`).
  final String code;

  /// What is missing and how to fix it, in one sentence.
  final String message;

  @override
  String toString() => 'RigStreamUnavailable($code): $message';
}

/// The enclosure control surface: probe, open, drive, watch, close.
///
/// One implementation per backend: local QEMU for the desktop surface, the
/// smolvm microVM for exec and browser. Everything workspace-scoped takes a
/// required `workspaceId` — it is both the isolation boundary and what picks
/// the database file.
abstract interface class RigPort {
  /// What this host can host, right now. Cheap: a PATH probe and a stat, never
  /// a download, because settings calls it on open.
  Future<RigCapabilities> probe();

  /// Boots a rig in [workspaceId] per [spec], attributed to [openedBy].
  ///
  /// Returns as soon as the session exists — normally in
  /// [RigProvisioning](../value_objects/rig_status.dart), not ready. Callers
  /// await readiness through [watch] rather than blocking, so a slow boot
  /// shows progress instead of a frozen panel.
  Future<Rig> open({
    required String workspaceId,
    required RigSpec spec,
    required Principal openedBy,
  });

  /// Every rig in [workspaceId], live and recently closed.
  Future<List<Rig>> list(String workspaceId);

  /// One rig by id within [workspaceId], or null when it does not exist there.
  ///
  /// An id alone never identifies a rig: a foreign id must read as absent, not
  /// as someone else's machine.
  Future<Rig?> get(String workspaceId, String rigId);

  /// Live updates for every rig in [workspaceId].
  Stream<List<Rig>> watch(String workspaceId);

  /// Performs [action] on a rig as [actor].
  ///
  /// Enforces take-over exclusivity at this chokepoint: when a human holds
  /// control, an agent's mutating action is refused (observation still
  /// works). That check lives here rather than in a prompt because a prompt
  /// is a request and this is a rule.
  Future<RigActionResult> act({
    required String workspaceId,
    required String rigId,
    required RigAction action,
    required Principal actor,
  });

  // ── The clipboard and file lanes ────────────────────────────────────────
  //
  // Both directions of "copy/paste and drag files in and out of a machine",
  // and both are deliberately OUTSIDE [act] even though they pass through the
  // same take-over chokepoint. The reason is bytes: an image or a dropped
  // file is orders of magnitude larger than any other action's arguments, and
  // an action's arguments are persisted in `rig_action_log`. These carry the
  // bytes and log only the SHAPE (how many files, how many characters, an
  // image or not) — a clipboard is exactly where credentials live, so the
  // audit trail records that a paste happened and never what was in it.
  //
  // They also serve the enclosed TERMINAL, which has no driver and therefore
  // no actions at all: dropping a file into a shell is the same operation as
  // dropping one onto a desktop, and it would be absurd for it to be reachable
  // through a completely different port.

  /// Reads [selection] from the rig's clipboard, as [actor].
  ///
  /// Observation: allowed while a human holds control, like a screenshot.
  /// An empty [RigClipboardData] means the selection has no owner — a normal
  /// state (nothing has been copied, no drag is in flight), never an error.
  ///
  /// Throws nothing for a missing rig: an absent machine reads as an empty
  /// clipboard would be a lie, so callers get a [RigClipboardData] only when
  /// there was a machine to ask. Implementations return
  /// [RigClipboardData.empty] for an unknown or foreign id — the same answer a
  /// foreign id gets everywhere else, so ids cannot be enumerated.
  Future<RigClipboardData> readClipboard({
    required String workspaceId,
    required String rigId,
    required Principal actor,
    RigClipboardSelection selection = RigClipboardSelection.clipboard,
  });

  /// Puts [data] on the rig's clipboard, as [actor]. Mutating: refused while
  /// someone else holds control.
  ///
  /// [data] may carry text, an image, or both. Files are NOT written here —
  /// putting a file on a guest's clipboard means the file has to exist inside
  /// the guest first, which is [dropFiles]' job.
  Future<RigActionResult> writeClipboard({
    required String workspaceId,
    required String rigId,
    required RigClipboardData data,
    required Principal actor,
  });

  /// Transfers [request]'s files INTO the rig and offers them to the guest.
  ///
  /// What "offers" means is the surface's business and the result says which
  /// happened ([RigDropResult.deliveredAsDrop]): a browser page gets a real
  /// drop event at the requested point, a desktop gets the files in its drop
  /// folder with their URIs on the clipboard (no host can synthesize an XDND
  /// drag into an arbitrary toolkit), and a terminal gets the files and their
  /// paths back for the caller to type.
  Future<RigDropResult> dropFiles({
    required String workspaceId,
    required String rigId,
    required RigDropRequest request,
    required Principal actor,
  });

  /// Reads one file back OUT of the rig, by its guest path.
  ///
  /// The other half of drag-out: the clipboard/XDND read names paths, this
  /// fetches the bytes behind one. Null when the rig is absent or the path
  /// does not resolve to a readable regular file inside it.
  ///
  /// [guestPath] is untrusted (it round-tripped through a client), so
  /// implementations re-validate it rather than trusting that it came from a
  /// listing they produced.
  Future<RigFileBytes?> readFile({
    required String workspaceId,
    required String rigId,
    required String guestPath,
    required Principal actor,
  });

  /// The live navigation state of a browser rig in [workspaceId], read from
  /// the page's own session history.
  ///
  /// Null when the rig is absent, not a browser, or not live — the address
  /// bar distinguishes none of those from "no page". Back/forward
  /// reachability is deliberately NOT persisted: it is a property of the live
  /// session history and dies with it. (The URL alone is also on [Rig], so
  /// watchers see navigations pushed rather than asking.)
  Future<RigBrowserState?> browserState({
    required String workspaceId,
    required String rigId,
  });

  /// Opens the human watch lane. [request] is clamped by the backend; read
  /// [RigStream.negotiated] for what was actually granted — including its
  /// CODEC, which the driver declares and the request cannot influence.
  ///
  /// Null means "no such live rig here". A host that has the rig but cannot
  /// serve its lane throws [RigStreamUnavailable] instead, so the viewer can
  /// say which of the two it is.
  Future<RigStream?> watchStream({
    required String workspaceId,
    required String rigId,
    required RigWatchRequest request,
  });

  /// Takes exclusive input control for [actor], suspending the agent's input.
  ///
  /// Idempotent for the same holder. Returns the updated rig.
  Future<Rig> takeControl({
    required String workspaceId,
    required String rigId,
    required Principal actor,
  });

  /// Releases control held by [actor]. A different principal's hold is not
  /// released — that would make the lock advisory.
  Future<Rig> releaseControl({
    required String workspaceId,
    required String rigId,
    required Principal actor,
  });

  /// Destroys the rig and discards its overlay. Idempotent.
  ///
  /// [reason] is the TYPED vocabulary, not a free string: it is recorded on
  /// the row, published on the close event and read back by the panel, and
  /// "it disappeared" has to stay answerable from a closed set of answers.
  /// Wire strings are parsed at the RPC edge, where an unknown one can be
  /// reported as a validation error instead of silently becoming
  /// `requested`.
  Future<void> close({
    required String workspaceId,
    required String rigId,
    RigCloseReason? reason,
  });

  /// The status of every base image this host knows about.
  ///
  /// Wire-shaped rather than typed: the client renders a list and the store's
  /// own types are `cc_infra`'s, which the domain must not reach for.
  List<Map<String, dynamic>> imageStatuses();

  /// Downloads the base image [imageId], verifying its pinned checksum.
  ///
  /// Throws when the image has not been published — the catalogue ships
  /// entries whose artifacts do not exist yet, and refusing beats installing
  /// an unverified operating system.
  Future<void> downloadImage(String imageId);

  /// Adopts an existing disk image at [sourcePath] as [imageId].
  ///
  /// The path that works before anything is published: build an image locally
  /// and hand it over.
  Future<void> importImage({
    required String imageId,
    required String sourcePath,
  });

  /// Tears down every rig this port owns (host shutdown).
  ///
  /// Not optional the way a PTY's teardown was: an orphaned QEMU process
  /// survives the server, holds gigabytes of RAM and its disk overlay, and
  /// nothing left running knows it exists.
  Future<void> disposeAll();
}
