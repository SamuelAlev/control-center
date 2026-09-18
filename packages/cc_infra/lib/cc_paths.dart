/// Leaf library for [CcPaths] — the on-disk layout resolver.
///
/// Import this instead of `package:cc_infra/cc_infra.dart` or
/// `cc_infra_web.dart` when the caller only needs path layout. The web barrel
/// re-exports Linear/GitHub adapters; this leaf does not.
library;

export 'src/util/cc_paths.dart';
