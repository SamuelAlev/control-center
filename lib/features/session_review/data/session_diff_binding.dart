/// Resolves the `SessionDiffPort` binding per platform: the real local-git
/// adapter on the VM, an honest null on web (the worktree is remote there).
library;

export 'session_diff_binding_io.dart'
    if (dart.library.js_interop) 'session_diff_binding_web.dart';
