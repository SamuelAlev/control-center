// The HOST's clipboard, in the flavours a rig can carry.
//
// Flutter's own `Clipboard` is text-only, which covers roughly half of what
// "copy and paste between my machine and the VM" means. `super_clipboard`
// reaches the rest: images (as PNG) and file lists, on desktop and web.
//
// Deliberately a small, total surface. Every read answers with a snapshot
// (possibly empty) and never throws, because both callers are keystroke
// handlers: a ctrl+V that throws out of a key event leaves the user with a
// machine that silently did nothing.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:control_center/core/infrastructure/clipboard/host_file_staging.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:super_clipboard/super_clipboard.dart';

/// One file read off the host's clipboard (or a drop), with its bytes.
class HostFile {
  /// Creates a [HostFile].
  const HostFile({required this.name, required this.bytes, this.mediaType});

  /// The file's name.
  final String name;

  /// Its contents.
  final Uint8List bytes;

  /// MIME type when the platform reported one.
  final String? mediaType;
}

/// What is on the host's clipboard.
class HostClipboardSnapshot {
  /// Creates a [HostClipboardSnapshot].
  const HostClipboardSnapshot({
    this.text,
    this.imageBytes,
    this.imageMediaType,
    this.files = const [],
  });

  /// Nothing on it (or nothing readable).
  static const HostClipboardSnapshot empty = HostClipboardSnapshot();

  /// Plain text.
  final String? text;

  /// Image bytes, PNG unless [imageMediaType] says otherwise.
  final Uint8List? imageBytes;

  /// The image's MIME type.
  final String? imageMediaType;

  /// Files named on the clipboard, with their bytes already read.
  final List<HostFile> files;

  /// Whether there is anything to send.
  bool get isEmpty =>
      (text == null || text!.isEmpty) &&
      (imageBytes == null || imageBytes!.isEmpty) &&
      files.isEmpty;
}

/// The most a clipboard image may be before it is left behind.
///
/// Matches the server's ceiling on the same value. Above it the paste reports
/// that it could not carry the image, which is a better outcome than silently
/// downscaling something the user expected to arrive intact.
const int kMaxHostClipboardImageBytes = 16 * 1024 * 1024;

/// Reads the host clipboard.
///
/// Returns [HostClipboardSnapshot.empty] when the platform has no clipboard
/// API (Firefox disables it) or the user declined the permission prompt some
/// platforms raise. An empty snapshot and a refusal look the same to the
/// caller on purpose: both mean "there is nothing to paste from here", and
/// the alternative is an error dialog for a keystroke.
Future<HostClipboardSnapshot> readHostClipboard() async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) {
    return HostClipboardSnapshot.empty;
  }
  try {
    final reader = await clipboard.read();
    return await snapshotFromReader(reader.items);
  } on Object catch (e) {
    AppLog.d('rig-clipboard', 'reading the host clipboard failed: $e');
    return HostClipboardSnapshot.empty;
  }
}

/// Builds a snapshot from clipboard or drop-session readers.
///
/// Shared by the clipboard and by a file drop, because a drop session's items
/// expose exactly the same reader interface — and treating them the same is
/// what makes "paste a file" and "drag a file in" one code path.
Future<HostClipboardSnapshot> snapshotFromReader(List<DataReader> items) async {
  String? text;
  Uint8List? image;
  String? imageType;
  final files = <HostFile>[];

  for (final item in items) {
    // FILES FIRST, and the order is load-bearing. A file dragged out of
    // Finder also offers its NAME as plain text; reading text first would
    // turn every file drop into a paste of the string "report.pdf".
    final asFile = _fileFormatFor(item);
    if (asFile.isFile) {
      final file = await _readFile(item, asFile.format);
      if (file != null) {
        files.add(file);
        continue;
      }
    }
    if (image == null) {
      for (final (format, mimeType) in _imageFormats) {
        if (!item.canProvide(format)) {
          continue;
        }
        final read = await _readFile(item, format);
        if (read != null && read.bytes.length <= kMaxHostClipboardImageBytes) {
          image = read.bytes;
          imageType = mimeType;
        }
        break;
      }
      if (image != null) {
        continue;
      }
    }
    if (text == null && item.canProvide(Formats.plainText)) {
      text = await _readValue(item, Formats.plainText);
    }
  }
  return HostClipboardSnapshot(
    text: text,
    imageBytes: image,
    imageMediaType: imageType,
    files: files,
  );
}

/// Puts [text] on the host clipboard.
Future<bool> writeHostClipboardText(String text) async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) {
    return false;
  }
  try {
    await clipboard.write([DataWriterItem()..add(Formats.plainText(text))]);
    return true;
  } on Object catch (e) {
    AppLog.d('rig-clipboard', 'writing text to the host clipboard failed: $e');
    return false;
  }
}

/// Puts an image on the host clipboard.
///
/// PNG is the only flavour written. It is lossless, every platform accepts it,
/// and it is what each of the three guest surfaces can produce — a second
/// format would be a second thing to keep working for no gain.
Future<bool> writeHostClipboardImage(Uint8List png) async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) {
    return false;
  }
  try {
    await clipboard.write([DataWriterItem()..add(Formats.png(png))]);
    return true;
  } on Object catch (e) {
    AppLog.d('rig-clipboard', 'writing an image to the host clipboard: $e');
    return false;
  }
}

/// Stages [files] on this host and puts their URIs on the clipboard, so a
/// paste in a file manager produces real files.
///
/// Returns false on web, where there is no filesystem to stage into — see
/// [hostFileStagingAvailable]. The caller says so rather than reporting a
/// copy that did not happen.
Future<bool> writeHostClipboardFiles(
  List<({String name, Uint8List bytes})> files,
) async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null || !hostFileStagingAvailable || files.isEmpty) {
    return false;
  }
  final staged = await stageFilesOnHost(files);
  if (staged.files.isEmpty) {
    return false;
  }
  try {
    await clipboard.write([
      // ONE item per file: a file manager reads a multi-file paste as a list
      // of items, and folding them into one item pastes a single file.
      for (final uri in staged.files)
        DataWriterItem()..add(Formats.fileUri(uri)),
    ]);
    return true;
  } on Object catch (e) {
    AppLog.d('rig-clipboard', 'writing files to the host clipboard: $e');
    return false;
  }
}

/// The image formats read off a clipboard, best first, with the MIME type
/// each one becomes on the wire.
const List<(SimpleFileFormat, String)> _imageFormats = [
  (Formats.png, 'image/png'),
  (Formats.jpeg, 'image/jpeg'),
];

/// Whether [item] is a FILE, and in which format to read it.
///
/// Two answers, not one, because "not a file" and "a file in whatever format
/// the platform prefers" are both expressible as a null format — and folding
/// them together is how every file drop silently became a text paste of the
/// file's name. `isFile` carries the first question; `format` carries the
/// second, where null legitimately means "ask for the highest-priority file
/// format on this item".
({bool isFile, FileFormat? format}) _fileFormatFor(DataReader item) {
  // `fileUri` is the desktop signal: a real file dragged or copied out of a
  // file manager. super_clipboard synthesizes a readable file from the URI,
  // so the URI itself is never the payload — a null format asks for that
  // synthesized file.
  if (item.canProvide(Formats.fileUri)) {
    return (isFile: true, format: null);
  }
  // The platforms that offer bytes with no path behind them. Not exhaustive
  // and does not need to be: anything not listed falls through to the image
  // and text branches, which is the right answer for a copied image or a
  // copied string.
  for (final format in const <FileFormat>[
    Formats.pdf,
    Formats.plainTextFile,
    Formats.csv,
    Formats.zip,
  ]) {
    if (item.canProvide(format)) {
      return (isFile: true, format: format);
    }
  }
  return (isFile: false, format: null);
}

/// Whether [item] carries a real file (rather than an image or a string), and
/// in which format to read it.
///
/// Exposed for callers that need to decide what to do with a dropped item
/// BEFORE paying to read it — the composer reads a dropped picture's bytes but
/// keeps a dropped video as a path, and it cannot make that choice after
/// [snapshotFromReader] has already loaded four gigabytes into memory.
({bool isFile, FileFormat? format}) hostFileFormatFor(DataReader item) =>
    _fileFormatFor(item);

/// Reads one item as a file, or null when it has none. See [readHostValue] for
/// why the callback form is wrapped.
Future<HostFile?> readHostFile(DataReader item, {FileFormat? format}) =>
    _readFile(item, format);

/// Reads one value (text, a URI) off an item, or null when it has none.
Future<T?> readHostValue<T extends Object>(
  DataReader item,
  ValueFormat<T> format,
) => _readValue(item, format);

/// Reads one value off an item, or null when it has none.
///
/// `DataReader` (which a DROP session hands out) has only the callback form;
/// `readValue` is a convenience on the clipboard's own subtype. Wrapping the
/// callback here is what lets one snapshot function serve both.
Future<T?> _readValue<T extends Object>(
  DataReader item,
  ValueFormat<T> format,
) async {
  final completer = Completer<T?>();
  final progress = item.getValue<T>(
    format,
    (value) {
      if (!completer.isCompleted) {
        completer.complete(value);
      }
    },
    onError: (error) {
      AppLog.d('rig-clipboard', 'clipboard value error: $error');
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    },
  );
  if (progress == null) {
    return null;
  }
  return completer.future.timeout(
    const Duration(seconds: 10),
    onTimeout: () => null,
  );
}

/// Reads one item as a file, or null when it has none.
Future<HostFile?> _readFile(DataReader item, FileFormat? format) async {
  final completer = Completer<HostFile?>();
  final progress = item.getFile(
    format,
    (file) async {
      try {
        final bytes = await file.readAll();
        if (!completer.isCompleted) {
          completer.complete(
            HostFile(
              name: file.fileName ?? await item.getSuggestedName() ?? 'file',
              bytes: bytes,
            ),
          );
        }
      } on Object catch (e) {
        AppLog.d('rig-clipboard', 'reading a clipboard file failed: $e');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
    },
    onError: (error) {
      AppLog.d('rig-clipboard', 'clipboard file error: $error');
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    },
  );
  if (progress == null) {
    return null;
  }
  // Bounded: `getFile` is asynchronous and a VIRTUAL file (an image being
  // downloaded from a phone, say) may never arrive. Without a deadline a
  // paste would hang with no way for the user to tell it had.
  return completer.future.timeout(
    const Duration(seconds: 30),
    onTimeout: () => null,
  );
}
