/// Leaf library for `CcPaths` — the on-disk layout resolver — and on-disk
/// ownership protection.
///
/// Import this instead of `package:cc_infra/cc_infra.dart` when the caller
/// only needs path layout or file permissions.
library;

export 'src/util/cc_paths.dart';
export 'src/util/file_protection.dart';
