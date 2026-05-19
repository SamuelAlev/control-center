import 'dart:io';
import 'dart:typed_data';

import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// Whether this platform can read and play a file by path.
const bool localMediaAvailable = true;

/// Reads at most [maxBytes] of the file at [path].
///
/// Returns null when the file is missing, unreadable, or larger than
/// [maxBytes] — a preview refusing a two-gigabyte log is the correct outcome,
/// and the caller reports the size rather than freezing on a decode.
Future<Uint8List?> readLocalBytes(String path, {required int maxBytes}) async {
  try {
    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }
    if (await file.length() > maxBytes) {
      return null;
    }
    return await file.readAsBytes();
  } on Object catch (e) {
    AppLog.d('attachment-preview', 'reading $path failed: $e');
    return null;
  }
}

/// The size of the file at [path], or null when it cannot be stat-ed.
Future<int?> localFileSize(String path) async {
  try {
    final file = File(path);
    return file.existsSync() ? await file.length() : null;
  } on Object {
    return null;
  }
}

/// An [ImageProvider] for a picture already on disk, so a 20 MP photo is
/// decoded straight off the file instead of being read into a byte list first.
ImageProvider? localImageProvider(String path) => FileImage(File(path));

/// A player for the media file at [path].
VideoPlayerController? localVideoController(String path) =>
    VideoPlayerController.file(File(path));
