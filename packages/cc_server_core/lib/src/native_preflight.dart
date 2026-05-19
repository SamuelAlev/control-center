import 'dart:io';

/// One boot-required native library.
///
/// `description` names the file AND the feature it backs, because the failure
/// message is often the only thing an operator sees: "libfff_c (fuzzy file
/// search)" tells them what broke and what stopped working.
///
/// `probe` returns true when the library loads / resolves. Probes are cheap by
/// contract — a `dlopen` or a `stat`, never a download — because they all run
/// inside boot's synchronous "loading native libraries" stretch.
///
/// `requiredOnWindows` is false only for the documented Windows carve-outs. Keep
/// the `TODO(windows)` comment on the entry that owns the gap so the reason
/// travels with the exemption rather than living in a separate table.
typedef NativeRequirement = ({
  String description,
  bool requiredOnWindows,
  Future<bool> Function() probe,
});

/// Builds a [NativeRequirement]. Defaults to required on every platform —
/// exemptions must be spelled out at the call site.
NativeRequirement nativeRequirement(
  String description,
  Future<bool> Function() probe, {
  bool requiredOnWindows = true,
}) => (
  description: description,
  requiredOnWindows: requiredOnWindows,
  probe: probe,
);

/// The `NativeRequirement.description`s of every library that is required on
/// this platform but did not resolve. Empty means the preflight passed.
///
/// `isWindows` is a test seam; it defaults to the real platform.
Future<List<String>> missingRequiredNatives(
  List<NativeRequirement> requirements, {
  bool? isWindows,
}) async {
  final onWindows = isWindows ?? Platform.isWindows;
  final missing = <String>[];
  for (final requirement in requirements) {
    if (onWindows && !requirement.requiredOnWindows) {
      continue;
    }
    if (!await requirement.probe()) {
      missing.add(requirement.description);
    }
  }
  return missing;
}
