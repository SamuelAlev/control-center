/// Platform seam for the composer's file/folder mention source.
///
/// File mentions are backed by the native `FileSearch` (cc_natives) over local
/// repo checkouts — desktop-only. `buildFileMentionSource` returns the real
/// source on the VM and null on web (the composer omits it), keeping cc_natives
/// off the web compile graph.
library;

export 'file_mention_bindings_io.dart'
    if (dart.library.js_interop) 'file_mention_bindings_web.dart';
