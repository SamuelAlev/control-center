part of '../cached_pr_review_repository.dart';

// Pure helpers for the patches a forge withholds from oversized files.

/// Whether the forge reported changed lines for [f] but sent no patch — the
/// shape a file takes when its diff exceeded the forge's per-file cap. A
/// pure rename (no changed lines) has no patch to withhold.
bool _isPatchWithheld(PrFile f) =>
    f.patch.isEmpty && (f.additions + f.deletions) > 0;

int _totalChurn(List<PrFile> files) =>
    files.fold(0, (n, f) => n + f.additions + f.deletions);

/// Splices [sections] onto files whose patch the forge withheld.
///
/// Returns null when nothing could be filled so the caller keeps the list
/// it already has instead of re-emitting it unchanged.
List<PrFile>? _applyWithheldPatches(
  List<PrFile> files,
  Map<String, String> sections,
) {
  var filled = 0;
  final out = <PrFile>[];
  for (final f in files) {
    final patch = _isPatchWithheld(f)
        ? (sections[f.filename] ?? sections[f.previousFilename ?? ''])
        : null;
    if (patch == null || patch.isEmpty) {
      out.add(f);
      continue;
    }
    filled++;
    out.add(f.copyWith(patch: patch));
  }
  if (filled == 0) {
    return null;
  }
  return List<PrFile>.unmodifiable(out);
}

List<PrFile>? _spliceWithheldPatches(
  List<PrFile> files,
  List<PrFile> localFiles,
) {
  if (localFiles.isEmpty) {
    return null;
  }
  final patches = <String, String>{
    for (final f in localFiles)
      if (f.patch.isNotEmpty) f.filename: f.patch,
  };
  if (patches.isEmpty) {
    return null;
  }
  return _applyWithheldPatches(files, patches);
}
