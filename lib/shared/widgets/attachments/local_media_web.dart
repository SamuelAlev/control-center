import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// The web build has no filesystem, so nothing here can be served from a path.
/// Drops on web carry bytes, which every caller already handles.
const bool localMediaAvailable = false;

/// Always null on web — there is no path to read.
Future<Uint8List?> readLocalBytes(String path, {required int maxBytes}) async =>
    null;

/// Always null on web.
Future<int?> localFileSize(String path) async => null;

/// Always null on web.
ImageProvider? localImageProvider(String path) => null;

/// Always null on web.
VideoPlayerController? localVideoController(String path) => null;
