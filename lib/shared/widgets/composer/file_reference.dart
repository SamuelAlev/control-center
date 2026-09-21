// Composer `@[file:<name>]` naming helpers (`package:path`).
//
// Grammar/expansion live in `cc_domain` (shared with the server). Keep as
// styled text, not `WidgetSpan` — span length ≠ controller length breaks caret/
// selection/undo. [ellipsizeFileRefName] on the name; full path in the registry
// until submit.
library;

import 'package:path/path.dart' as p;

export 'package:cc_domain/core/domain/value_objects/file_reference.dart';

/// Longest display name a reference token carries before it is ellipsized.
///
/// Sized against the composer's own measure rather than a round number: at the
/// body size the input uses, ~28 characters is a little under half of a
/// comfortable line, so two references still read as a sentence rather than as
/// a wall of path.
const int kFileRefMaxNameChars = 28;

/// Shortens [name] to at most [max] characters, keeping the extension.
///
/// The extension is preserved because it carries the only information the
/// middle of a long name usually does not: what kind of file this is. A head
/// and a tail are kept around the ellipsis so two files from the same
/// generated-name family (`agent_run_log_repository_impl.dart` and
/// `agent_run_log_repository_test.dart`) stay distinguishable — truncating from
/// the right would render both identically.
String ellipsizeFileRefName(String name, {int max = kFileRefMaxNameChars}) {
  final cleaned = name.replaceAll(RegExp(r'[\r\n\]]'), '').trim();
  if (cleaned.isEmpty) {
    return 'file';
  }
  if (cleaned.length <= max) {
    return cleaned;
  }
  final ext = p.extension(cleaned);
  // A "." far from the end is part of the name (`app_en.arb.bak`, `v1.2.3`),
  // not a type marker worth spending the budget on.
  final keepExt = ext.length > 1 && ext.length <= 8;
  final stem = keepExt
      ? cleaned.substring(0, cleaned.length - ext.length)
      : cleaned;
  final suffix = keepExt ? ext : '';
  // One character for the ellipsis itself.
  final stemBudget = max - suffix.length - 1;
  if (stemBudget < 4) {
    // The extension alone eats the budget — degrade to a plain right trim
    // rather than returning something longer than asked for.
    return '${cleaned.substring(0, max - 1)}…';
  }
  final head = (stemBudget * 3 / 5).round();
  final tail = stemBudget - head;
  return '${stem.substring(0, head)}…${stem.substring(stem.length - tail)}$suffix';
}

/// A display name for [source] that is not already in [taken].
///
/// [source] is a filename or a path; only its basename is used — a reference is
/// read at a glance and `lib/features/messaging/.../composer.dart` is not.
///
/// Collisions are real (two `index.ts` from different packages) and resolving
/// them by silently reusing one token would point both references at whichever
/// file was attached second. The counter goes AFTER the ellipsis so it survives
/// shortening, at the cost of a few characters over [kFileRefMaxNameChars] —
/// the cap exists to stop a path dominating the line, and " 2" does not.
String uniqueFileRefName(String source, Set<String> taken) {
  final base = ellipsizeFileRefName(p.basename(source.replaceAll(r'\', '/')));
  if (!taken.contains(base)) {
    return base;
  }
  for (var i = 2; i < 1000; i++) {
    final candidate = '$base $i';
    if (!taken.contains(candidate)) {
      return candidate;
    }
  }
  return base;
}
