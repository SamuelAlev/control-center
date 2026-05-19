import 'package:intl/intl.dart';

/// A byte count in the reader's own locale.
///
/// Through `intl` rather than hand-formatted: `1.5 GB` and `1,5 GB` are
/// different numbers to different readers, and every surface that shows a size
/// should agree on which one this install writes.
///
/// Shared rather than per-feature because the second copy is where the two
/// start disagreeing — one rounding at 1024, the other at 1000, both correct
/// looking and describing the same file.
String humanBytes(int bytes) {
  final format = NumberFormat.decimalPatternDigits(decimalDigits: 1);
  final whole = NumberFormat.decimalPattern();
  if (bytes < 1024 * 1024) {
    return '${whole.format((bytes / 1024).round())} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${whole.format((bytes / (1024 * 1024)).round())} MB';
  }
  return '${format.format(bytes / (1024 * 1024 * 1024))} GB';
}
