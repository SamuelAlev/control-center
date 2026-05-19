// Moves clipboard content and files between this host and one rig.
//
// The seam between the two clipboards, and the only place that knows both
// sides exist. Kept out of the widgets because BOTH of them need it — the rig
// canvas (copy/paste/drag over a live screen) and the enclosed terminal (paste
// a path, drop a file at the prompt) — and because a copy that behaves
// differently depending on which panel you were looking at is a bug nobody
// would think to look for.
//
// It knows nothing about keystrokes. Telling the guest to paste is the
// caller's job, because "the paste chord" is a property of the surface: ctrl+V
// on a Linux desktop, an inserted string in a browser, a write to a pty in a
// terminal.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_file_transfer.dart';
import 'package:control_center/core/infrastructure/clipboard/host_clipboard.dart';
import 'package:control_center/core/infrastructure/clipboard/host_file_staging.dart';
import 'package:control_center/features/rigs/data/rig_transfer_client.dart';

/// What crossing the boundary produced, in one line and a verdict.
///
/// Every operation answers with one of these because every one of them has a
/// partial outcome that is neither success nor failure: an image too big to
/// carry, files copied into a machine that had no drop target, a clipboard
/// with nothing on it. A bool would collapse all three into "it did not
/// work", which is not what happened and not what to tell someone.
class RigClipboardOutcome {
  /// Creates a [RigClipboardOutcome].
  const RigClipboardOutcome({
    required this.ok,
    required this.summary,
    this.wasEmpty = false,
  });

  /// It worked; [summary] says what moved.
  factory RigClipboardOutcome.ok(String summary) =>
      RigClipboardOutcome(ok: true, summary: summary);

  /// It did not work; [summary] says why, in a sentence for a person.
  factory RigClipboardOutcome.failed(String summary) =>
      RigClipboardOutcome(ok: false, summary: summary);

  /// There was nothing to move. Not a failure — a copy with an empty
  /// selection is a no-op, and an error toast for one is noise.
  factory RigClipboardOutcome.empty(String summary) =>
      RigClipboardOutcome(ok: true, summary: summary, wasEmpty: true);

  /// Whether the operation did what was asked.
  final bool ok;

  /// One line, written for a person.
  final String summary;

  /// Whether there was simply nothing to carry.
  final bool wasEmpty;
}

/// Carries clipboard content and files between this host and one rig.
class RigClipboardBridge {
  /// Creates a [RigClipboardBridge] for [rigId] in [workspaceId].
  RigClipboardBridge({
    required this.transfer,
    required this.workspaceId,
    required this.rigId,
  });

  /// The transport to the server's rig lanes.
  final RigTransferClient transfer;

  /// The owning workspace.
  final String workspaceId;

  /// The rig being copied to and from.
  final String rigId;

  /// The most a single file may be on its way out of a machine.
  ///
  /// Below the server's own per-file ceiling: this is the interactive path,
  /// where the bytes are held in the client's heap and the user is waiting
  /// with a mouse button down.
  static const int _maxDragOutBytes = 64 * 1024 * 1024;

  /// A cheap identity for the last content this bridge carried, in either
  /// direction. See [pullToHost].
  String? _lastCarried;

  /// Reads the guest's clipboard and puts it on this host's.
  ///
  /// The caller is expected to have told the guest to COPY first (a ctrl+C it
  /// understands); this reads the result. Splitting the two is deliberate —
  /// the chord differs per surface, and this half does not.
  ///
  /// **Unchanged content is not carried across**, and that is what makes a
  /// bare ctrl+C safe on a Windows or Linux host. There the crossing chord IS
  /// the guest's own chord, and in a guest terminal it means INTERRUPT, not
  /// copy — so the guest's clipboard still holds whatever it held before.
  /// Publishing that would overwrite what the user had copied on their own
  /// machine with something they never asked for. Comparing against the last
  /// thing this bridge carried turns "read the clipboard" into "did the guest
  /// copy something new?".
  Future<RigClipboardOutcome> pullToHost({
    RigClipboardSelection selection = RigClipboardSelection.clipboard,
  }) async {
    final data = await transfer.readClipboard(
      workspaceId: workspaceId,
      rigId: rigId,
      selection: selection,
    );
    if (data == null) {
      return RigClipboardOutcome.failed(
        'The machine did not answer when asked for its clipboard.',
      );
    }
    if (data.isEmpty) {
      return RigClipboardOutcome.empty(
        data.imageSkippedBytes != null
            ? 'The machine copied an image too large to carry.'
            : 'Nothing was copied in the machine.',
      );
    }
    final fingerprint = fingerprintOf(data);
    if (fingerprint == _lastCarried) {
      return RigClipboardOutcome.empty('Nothing new was copied.');
    }
    _lastCarried = fingerprint;
    return publishToHost(data);
  }

  /// A cheap identity for clipboard content, for change detection only.
  ///
  /// Deliberately not a hash of the bytes: an image can be tens of megabytes
  /// and this runs on every copy chord. Length plus a short prefix separates
  /// "the guest copied something new" from "the guest is still holding what
  /// we already carried", which is all it has to decide.
  static String fingerprintOf(RigClipboardData data) {
    final text = data.text ?? '';
    final head = text.length <= 64 ? text : text.substring(0, 64);
    return '${text.length}:${data.imageBase64?.length ?? 0}:'
        '${data.files.map((f) => f.guestPath).join(",")}:$head';
  }

  /// Writes [data] onto this host's clipboard, fetching any files it names.
  ///
  /// One flavour wins, in the order files → image → text, because a system
  /// clipboard holds one thing: writing text after an image replaces it. The
  /// order is by specificity — files are the least ambiguous thing a guest can
  /// have copied, and a file manager's copy always ALSO offers the file's name
  /// as text.
  Future<RigClipboardOutcome> publishToHost(RigClipboardData data) async {
    if (data.files.isNotEmpty) {
      if (!hostFileStagingAvailable) {
        return RigClipboardOutcome.failed(
          'Files copied inside a machine can only be pasted out on the '
          'desktop app — a browser tab has nowhere to put them.',
        );
      }
      final fetched = await _fetchGuestFiles(data.files);
      if (fetched.isEmpty) {
        return RigClipboardOutcome.failed(
          'The files on the machine\'s clipboard could not be read out of it.',
        );
      }
      final wrote = await writeHostClipboardFiles(fetched);
      if (!wrote) {
        return RigClipboardOutcome.failed(
          'The files could not be put on this computer\'s clipboard.',
        );
      }
      return RigClipboardOutcome.ok(
        fetched.length == 1
            ? 'Copied "${fetched.single.name}" out of the machine.'
            : 'Copied ${fetched.length} files out of the machine.',
      );
    }
    if (data.hasImage) {
      final bytes = _decodeImage(data.imageBase64!);
      if (bytes != null && await writeHostClipboardImage(bytes)) {
        return RigClipboardOutcome.ok('Copied an image out of the machine.');
      }
      // Fall through to the text branch rather than failing: a copy out of a
      // browser routinely carries both, and losing the image is better than
      // losing everything.
    }
    final text = data.text;
    if (text != null && text.isNotEmpty) {
      if (await writeHostClipboardText(text)) {
        return RigClipboardOutcome.ok(
          'Copied ${text.length} characters out of the machine.',
        );
      }
      return RigClipboardOutcome.failed(
        'This computer\'s clipboard could not be written to.',
      );
    }
    return RigClipboardOutcome.failed(
      'Nothing on the machine\'s clipboard could be carried across.',
    );
  }

  /// Reads this host's clipboard, for a caller about to paste into the guest.
  Future<HostClipboardSnapshot> readHost() => readHostClipboard();

  /// Puts [snapshot]'s text and image on the guest's clipboard.
  ///
  /// Files are NOT sent here — they are a [dropFiles] call, because putting a
  /// file on a guest's clipboard means the file has to exist inside the guest
  /// first, and that is a copy, not a clipboard write.
  Future<RigClipboardOutcome> pushToGuest(
    HostClipboardSnapshot snapshot,
  ) async {
    final data = RigClipboardData(
      text: snapshot.text,
      imageBase64: snapshot.imageBytes == null
          ? null
          : _encodeImage(snapshot.imageBytes!),
      imageMediaType: snapshot.imageBytes == null
          ? null
          : (snapshot.imageMediaType ?? 'image/png'),
    );
    if (data.isEmpty) {
      return RigClipboardOutcome.empty('There is nothing to paste.');
    }
    final ack = await transfer.writeClipboard(
      workspaceId: workspaceId,
      rigId: rigId,
      data: data,
    );
    if (!ack.ok) {
      return RigClipboardOutcome.failed(ack.summary);
    }
    // Remembered so the NEXT copy chord does not carry this straight back:
    // the guest is now holding exactly what the host already has.
    _lastCarried = fingerprintOf(data);
    return RigClipboardOutcome.ok(ack.summary);
  }

  /// Copies [files] into the guest, as a drop at ([x], [y]) where the surface
  /// supports one.
  Future<RigDropResult> dropFiles(List<HostFile> files, {int? x, int? y}) =>
      transfer.dropFiles(
        workspaceId: workspaceId,
        rigId: rigId,
        files: [
          for (final f in files)
            RigOutgoingFile(
              name: f.name,
              bytes: f.bytes,
              mediaType: f.mediaType,
            ),
        ],
        x: x,
        y: y,
      );

  /// What the guest is DRAGGING right now, or null when it is not dragging.
  ///
  /// The whole of drag-out rests on this. While an X application drags
  /// something it owns the `XdndSelection`, so asking for that selection is
  /// how the host finds out what is in flight — there is no event, no
  /// notification and nothing in the frame stream that says a drag started.
  ///
  /// Null is the normal answer, returned constantly: most presses are not
  /// drags. It has to be cheap and it has to be silent.
  Future<RigClipboardData?> peekDragPayload() async {
    final data = await transfer.readClipboard(
      workspaceId: workspaceId,
      rigId: rigId,
      selection: RigClipboardSelection.xdnd,
    );
    if (data == null || data.isEmpty) {
      return null;
    }
    return data;
  }

  /// Stages the files [data] names on this host and returns what a native
  /// drag should carry: one URI.
  ///
  /// One, because a native drag session carries a single item and building a
  /// multi-item one needs a snapshot per item that this caller has no way to
  /// render. Several files therefore leave as their containing FOLDER, which
  /// is a normal thing to drop somewhere and loses nothing — as opposed to
  /// silently dragging the first file and dropping the rest.
  Future<({Uri uri, String name})?> stageForDrag(RigClipboardData data) async {
    if (!hostFileStagingAvailable || data.files.isEmpty) {
      return null;
    }
    final fetched = await _fetchGuestFiles(data.files);
    if (fetched.isEmpty) {
      return null;
    }
    final staged = await stageFilesOnHost(fetched);
    if (staged.files.isEmpty) {
      return null;
    }
    if (staged.files.length == 1) {
      return (uri: staged.files.single, name: fetched.single.name);
    }
    final directory = staged.directory;
    if (directory == null) {
      return (uri: staged.files.first, name: fetched.first.name);
    }
    return (uri: directory, name: '${fetched.length} files');
  }

  /// Fetches the bytes behind [files], skipping anything unreadable or
  /// oversized.
  ///
  /// Sequential rather than concurrent: each fetch runs a `cat` inside the
  /// guest over the machine's single control channel, and firing ten at once
  /// would queue them there anyway while making the failure modes harder to
  /// read.
  Future<List<({String name, Uint8List bytes})>> _fetchGuestFiles(
    List<RigGuestFile> files,
  ) async {
    final out = <({String name, Uint8List bytes})>[];
    for (final file in files) {
      if ((file.sizeBytes ?? 0) > _maxDragOutBytes) {
        continue;
      }
      final bytes = await transfer.readFile(
        workspaceId: workspaceId,
        rigId: rigId,
        guestPath: file.guestPath,
      );
      if (bytes != null && bytes.length <= _maxDragOutBytes) {
        out.add((name: file.name, bytes: bytes));
      }
    }
    return out;
  }

  static Uint8List? _decodeImage(String base64Bytes) {
    try {
      return base64Decode(base64Bytes);
    } on FormatException {
      return null;
    }
  }

  static String _encodeImage(Uint8List bytes) => base64Encode(bytes);
}
