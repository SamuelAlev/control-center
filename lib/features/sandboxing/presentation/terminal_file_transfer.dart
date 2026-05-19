// Files and rich clipboard content across a terminal's boundary.
//
// A terminal has no coordinate space and no drop target, so "drag a file in"
// and "paste an image" both mean the same thing here: put the thing where the
// shell can reach it and type its PATH at the prompt. That is what a person
// dropping a CSV onto a shell actually wants — a path to pass to a command —
// and it is the only reading that survives the terminal being INSIDE a VM,
// where the host's own path means nothing.
//
// Two destinations, and the difference is the whole reason this file exists:
//
//  * A host-shell terminal already shares this computer's filesystem, so a
//    dropped file needs no transfer at all. Its own path is typed, and
//    nothing is copied anywhere.
//  * An enclosed (`microvm`) terminal is a different machine. The bytes are
//    copied into it and the GUEST's path is typed. Typing the host path there
//    would produce a command that fails with "no such file", which is a
//    worse outcome than not supporting the drop.
library;

import 'dart:typed_data';

import 'package:control_center/core/infrastructure/clipboard/host_clipboard.dart';
import 'package:control_center/features/rigs/providers/rig_transfer_providers.dart';
import 'package:super_clipboard/super_clipboard.dart';

/// Single-quotes [value] for a POSIX shell.
///
/// Every path typed at a prompt goes through this. A dropped file's name comes
/// from wherever the user dragged it, and a space, a quote or a `$` in it
/// would otherwise turn one argument into several — or, with a `;`, into a
/// second command. Single quotes are total in POSIX sh: the only character
/// that needs handling inside them is the quote itself.
String shellQuoteForPrompt(String value) =>
    "'${value.replaceAll("'", r"'\''")}'";

/// The local filesystem paths [items] name, without reading their contents.
///
/// The cheap half of a drop: a host-shell terminal only needs the path, and
/// reading a 4 GB video into memory to type its name would be absurd.
Future<List<String>> readDroppedPaths(List<DataReader> items) async {
  final paths = <String>[];
  for (final item in items) {
    if (!item.canProvide(Formats.fileUri)) {
      continue;
    }
    final uri = await _readUri(item);
    if (uri == null || !uri.isScheme('file')) {
      continue;
    }
    try {
      paths.add(uri.toFilePath());
    } on Object {
      // A URI that is well-formed but not a path on this platform. Skipped
      // rather than typed: a broken path at a prompt is a command that fails.
    }
  }
  return paths;
}

/// What to type at the prompt for a drop, and what to tell the user.
class TerminalDropResult {
  /// Creates a [TerminalDropResult].
  const TerminalDropResult({
    required this.toType,
    this.notice,
    this.isError = false,
  });

  /// Nothing usable came out of the drop.
  static const TerminalDropResult nothing = TerminalDropResult(toType: '');

  /// The text to insert at the prompt (already shell-quoted), or empty.
  final String toType;

  /// A line to show the user, or null when the typed paths speak for
  /// themselves.
  final String? notice;

  /// Whether [notice] is a failure.
  final bool isError;
}

/// Copies [files] into the machine behind [bridge] and returns their guest
/// paths, ready to type.
Future<TerminalDropResult> sendFilesToGuest(
  RigClipboardBridge bridge,
  List<HostFile> files,
) async {
  if (files.isEmpty) {
    return TerminalDropResult.nothing;
  }
  // No coordinates: a terminal has no drop point, so the files land in the
  // machine's drop directory and the caller types where they went.
  final result = await bridge.dropFiles(files);
  if (result.isError || result.files.isEmpty) {
    return TerminalDropResult(
      toType: '',
      notice: result.summary,
      isError: true,
    );
  }
  return TerminalDropResult(
    toType: result.files.map((f) => shellQuoteForPrompt(f.guestPath)).join(' '),
  );
}

/// Turns a clipboard image into a file inside the machine and returns its
/// path, ready to type.
///
/// Pasting an image into a terminal has no other sensible meaning — a shell
/// cannot display one — and a path is what every tool that DOES understand an
/// image wants as an argument.
Future<TerminalDropResult> sendImageToGuest(
  RigClipboardBridge bridge,
  Uint8List bytes, {
  required String name,
  String mediaType = 'image/png',
}) => sendFilesToGuest(bridge, [
  HostFile(name: name, bytes: bytes, mediaType: mediaType),
]);

/// A name for a pasted image, stable within a second and distinct across
/// them.
///
/// Distinct matters more than pretty: pasting three screenshots in a row must
/// produce three files. The machine's drop directory also refuses to
/// overwrite, so a repeat within the same second still lands beside its
/// predecessor rather than replacing it.
String pastedImageName(DateTime now) {
  String two(int v) => v.toString().padLeft(2, '0');
  return 'pasted-${now.year}${two(now.month)}${two(now.day)}'
      '-${two(now.hour)}${two(now.minute)}${two(now.second)}.png';
}

/// Reads a URI value off [item], or null.
Future<Uri?> _readUri(DataReader item) async {
  if (item is ClipboardDataReader) {
    return item.readValue(Formats.fileUri);
  }
  // A DROP session's reader has only the callback form.
  Uri? found;
  final progress = item.getValue<Uri>(
    Formats.fileUri,
    (value) => found = value,
    onError: (_) {},
  );
  if (progress == null) {
    return null;
  }
  // getValue resolves synchronously often enough that a microtask hop is
  // usually all this needs; the poll bounds the case where it does not.
  for (var i = 0; i < 40 && found == null; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
  return found;
}
