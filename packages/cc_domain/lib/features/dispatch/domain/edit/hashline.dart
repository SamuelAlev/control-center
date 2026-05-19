/// Hashline: a self-contained, pure-Dart edit-integrity subsystem.
///
/// Hashline anchors agent edits to a short content hash of the file they were
/// written against. A read mints a 4-hex tag (`computeContentHash`); a later
/// edit carries that tag in its section's `fileHash`. When the live file still
/// hashes to the tag the edit applies verbatim (`applyEdits`); when it drifted,
/// recovery (`tryRecover`) replays the edit against a cached snapshot and
/// three-way-merges it onto the live content, or rejects with a `MismatchError`.
/// The `Patcher` ties it together as an atomic multi-section preflight that
/// never touches the filesystem itself.
///
/// This barrel re-exports the entire public API. Import it as
/// `package:cc_domain/features/dispatch/domain/edit/hashline.dart`.
library;

export 'package:cc_domain/features/dispatch/domain/edit/apply_edits.dart';
export 'package:cc_domain/features/dispatch/domain/edit/block_resolver.dart';
export 'package:cc_domain/features/dispatch/domain/edit/content_hash.dart';
export 'package:cc_domain/features/dispatch/domain/edit/edit.dart';
export 'package:cc_domain/features/dispatch/domain/edit/patcher.dart';
export 'package:cc_domain/features/dispatch/domain/edit/recovery.dart';
