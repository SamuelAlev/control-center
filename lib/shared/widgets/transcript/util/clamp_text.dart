/// Default character budget for rendered tool output (64KB).
const int kToolOutputMaxChars = 64 * 1024;

/// Raw-size ceiling above which tool output is never JSON-decoded /
/// pretty-printed (256KB) — decoding megabytes just to indent them freezes
/// the build.
const int kToolOutputMaxJsonChars = 256 * 1024;

/// Clamps [s] to at most [maxChars] characters, cutting at a line boundary
/// when one exists, and reports how many characters were hidden.
///
/// Returns the input unchanged (with `hiddenChars: 0`) when it fits. Used by
/// the transcript tool bodies so a multi-megabyte tool output never reaches
/// text layout (or the ANSI-stripping regex) in full.
({String text, int hiddenChars}) clampText(
  String s, {
  int maxChars = kToolOutputMaxChars,
}) {
  if (s.length <= maxChars) {
    return (text: s, hiddenChars: 0);
  }
  var cut = s.lastIndexOf('\n', maxChars);
  if (cut <= 0) {
    cut = maxChars;
  }
  return (text: s.substring(0, cut), hiddenChars: s.length - cut);
}
