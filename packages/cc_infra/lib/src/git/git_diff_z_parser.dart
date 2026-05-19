import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';

/// Parsers for `git diff -z` machine-readable output: NUL-delimited records with
/// verbatim, unabbreviated paths and an explicit old/new pair for renames.
///
/// Using `-z` is essential. WITHOUT it, git compacts a rename into a single
/// `prefix{old => new}suffix` path that matches neither the `--name-status`
/// full paths nor the patch headers — so a rename renders as a "modified" file
/// with a mangled path and no content.

/// Parses `git diff --name-status -z` output into a map keyed by the (new) path.
///
/// Each record is `status \0 path \0`, or for renames/copies
/// `R|C<score> \0 oldPath \0 newPath \0`.
Map<String, (PrFileStatus, String?)> parseGitNameStatusZ(String out) {
  final tokens = out.split('\x00');
  final statusMap = <String, (PrFileStatus, String?)>{};
  for (var i = 0; i < tokens.length;) {
    final status = tokens[i];
    if (status.isEmpty) {
      i++;
      continue;
    }
    final isRename = status.startsWith('R');
    final isCopy = status.startsWith('C');
    if (isRename || isCopy) {
      if (i + 2 >= tokens.length) {
        break;
      }
      final oldPath = tokens[i + 1];
      final newPath = tokens[i + 2];
      // A copy leaves the original in place, so it's a new file with no rename
      // source; a rename carries its previous path.
      statusMap[newPath] = isRename
          ? (PrFileStatus.renamed, oldPath)
          : (PrFileStatus.added, null);
      i += 3;
    } else {
      if (i + 1 >= tokens.length) {
        break;
      }
      statusMap[tokens[i + 1]] = (parseGitFileStatus(status), null);
      i += 2;
    }
  }
  return statusMap;
}

/// Parses `git diff --numstat -z` output into [PrFile]s (with empty patches),
/// joining each file's status/rename info from [statusMap] (keyed by new path).
///
/// Each record is `added \t deleted \t path \0`, or for renames/copies
/// `added \t deleted \t \0 oldPath \0 newPath \0` — the path field is empty,
/// followed by the old and new paths as separate NUL-delimited tokens.
List<PrFile> parseGitNumstatZ(
  String out,
  Map<String, (PrFileStatus, String?)> statusMap,
) {
  final tokens = out.split('\x00');
  final files = <PrFile>[];
  for (var i = 0; i < tokens.length;) {
    final record = tokens[i];
    if (record.isEmpty) {
      i++;
      continue;
    }
    final tab = record.split('\t');
    if (tab.length < 3) {
      i++;
      continue;
    }
    // Binary files are shown as `-` instead of a number.
    final additions = int.tryParse(tab[0]) ?? 0;
    final deletions = int.tryParse(tab[1]) ?? 0;
    // Paths never contain a tab in -z output, but join defensively.
    final pathField = tab.sublist(2).join('\t');
    String filename;
    if (pathField.isEmpty) {
      // Rename/copy: the next two tokens are the old and new paths.
      if (i + 2 >= tokens.length) {
        break;
      }
      filename = tokens[i + 2];
      i += 3;
    } else {
      filename = pathField;
      i += 1;
    }
    final (status, previousFilename) =
        statusMap[filename] ?? (PrFileStatus.modified, null);
    files.add(
      PrFile(
        filename: filename,
        status: status,
        additions: additions,
        deletions: deletions,
        patch: '',
        previousFilename: previousFilename,
      ),
    );
  }
  return files;
}

/// Maps a single-letter `git diff` status (`A`/`D`/`M`/…) to a [PrFileStatus].
PrFileStatus parseGitFileStatus(String s) {
  switch (s) {
    case 'A':
      return PrFileStatus.added;
    case 'D':
      return PrFileStatus.removed;
    case 'M':
      return PrFileStatus.modified;
    default:
      return PrFileStatus.modified;
  }
}
