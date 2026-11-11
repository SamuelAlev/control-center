import 'dart:ffi';

/// Shared dylib *loader* for the runtime-loaded natives.
///
/// Every native (rift, fff, tree-sitter + its grammars, aec, lame, pty,
/// cc_watcher, onnxruntime, sherpa-onnx) is a loose shared library found at
/// runtime — never linked into the app. The *path policy* (where the libraries
/// might live) is the FFI-free `native_library_paths.dart`; this file owns only
/// the `dart:ffi` part: opening the first candidate that loads.

/// Opens the first [candidates] entry that loads, or returns `null` when none
/// resolve.
///
/// `null` is a PROBE RESULT, not a licence to degrade: every native is
/// required, so callers must convert it into a thrown
/// `NativeLibraryUnavailable` (or, for the boot preflight, a refusal to start).
/// See `native_unavailable.dart` for the contract and the two
/// environment-driven fallbacks that legitimately remain.
///
/// Empty candidates are skipped; an absent path (`ArgumentError`) or any other
/// load failure (wrong arch, missing symbols) moves on to the next candidate.
DynamicLibrary? tryOpenFirst(Iterable<String> candidates) {
  for (final candidate in candidates) {
    if (candidate.isEmpty) {
      continue;
    }
    try {
      return DynamicLibrary.open(candidate);
    } on ArgumentError {
      continue;
    } catch (_) {
      continue;
    }
  }
  return null;
}
