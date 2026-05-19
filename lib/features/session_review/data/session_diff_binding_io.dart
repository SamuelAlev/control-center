import 'package:cc_domain/core/domain/ports/session_diff_port.dart';
import 'package:cc_infra/cc_infra.dart';

/// VM binding: session diffs are computed by shelling out to the local `git`.
/// The worktree is on this machine, so a read-only diff needs no server hop.
SessionDiffPort? createSessionDiffPort() => const ProcessSessionDiffAdapter();
