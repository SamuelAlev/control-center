import 'package:cc_domain/core/domain/ports/session_diff_port.dart';

/// Web binding: the worktree lives on a remote server, so there is no local
/// `git` to shell out to. Session review is unavailable on web until the diff
/// is surfaced over RPC; return null so callers degrade honestly.
SessionDiffPort? createSessionDiffPort() => null;
