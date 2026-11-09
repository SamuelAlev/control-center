/// Leaf library for `CcPaths` — the on-disk layout resolver — and on-disk
/// ownership protection.
///
/// Import this instead of `package:cc_infra/cc_infra.dart` when the caller
/// only needs path layout, file permissions or owner-only file writes.
library;

export 'src/util/cc_paths.dart';
export 'src/util/file_protection.dart';
export 'src/util/private_file.dart';
