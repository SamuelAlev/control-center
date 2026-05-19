/// Turns a standalone `assets/browser_logos/<engine>_color.svg` file into the
/// inline `<svg>` fragment a rig's guest page can carry.
///
/// A browser rig's new-tab page is written INTO a VM, so it cannot read a
/// Flutter asset — the artwork has to exist as a Dart string as well. Two
/// hand-maintained copies of a logo is precisely how the boot screen and the
/// page it settles into end up showing different marks, so the string is
/// derived from the file by this one function: `tool/gen_browser_marks.dart`
/// bakes the result into `browser_engine_marks.dart`, and
/// `browser_logo_assets_test.dart` re-derives it to prove the two still agree.
library;

/// Rewrites [svgFile] — the bytes of a standalone `.svg` — as the fragment
/// the generated `browser_engine_marks.dart` consts hold.
///
/// Three things go: the XML declaration and comments (a file's provenance
/// header is not artwork), the `xmlns`/`xmlns:xlink` attributes, and the
/// whitespace between tags. The namespaces are not cosmetic — inside an HTML
/// document the parser namespaces `<svg>` itself, and an `xmlns` is an `http`
/// substring, which is what a test uses to prove the guest page depends on
/// nothing external.
///
/// Throws [FormatException] when the result still reaches outside itself, so
/// dropping in a logo that references a CDN font or a remote image fails at
/// generation time rather than as a blank rectangle inside a VM with the
/// egress gate shut.
String inlineBrowserMark(String svgFile) {
  var svg = svgFile
      .replaceAll(RegExp(r'<\?xml[^>]*\?>'), '')
      .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
  final open = svg.indexOf('<svg');
  if (open < 0) {
    throw const FormatException('not an SVG document');
  }
  svg = svg
      .substring(open)
      .replaceAll(RegExp(r'\s+xmlns(:\w+)?="[^"]*"'), '')
      .replaceAll(RegExp(r'>\s+<'), '><')
      .trim();
  if (svg.contains('http')) {
    throw FormatException(
      'a rig guest page must depend on nothing external, but this mark still '
      'contains an "http" substring',
      svg,
    );
  }
  return svg;
}
