import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_remote/media_proxy.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders markdown at phone body scale, themed from the design-system tokens.
///
/// PR descriptions, review bodies and conversation comments are markdown. On a
/// phone the fixed cost of that is small — the headings shrink to something a
/// narrow column can hold and code blocks scroll sideways instead of forcing
/// the page to — but the alternative is showing `## Summary` and `- [ ]` as
/// literal text, which is what "plain text is fine on mobile" actually means
/// in practice.
///
/// There is deliberately no syntax highlighting: the highlighter is a grammar
/// registry the desktop ships and the phone should not download to colour a
/// four-line snippet inside a PR body.
class PhoneMarkdown extends ConsumerWidget {
  /// Creates a [PhoneMarkdown] rendering [data].
  const PhoneMarkdown({super.key, required this.data, this.fontSize = 14});

  /// The markdown source.
  final String data;

  /// Base body size; headings scale off it.
  final double fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    if (data.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final endpoint = ref.watch(mediaEndpointProvider).value;
    return CcMarkdown(
      data: data,
      style: phoneMarkdownStyle(t, fontSize),
      imageBuilder: (url, alt, title) =>
          _PhoneMarkdownImage(url: url, alt: alt, endpoint: endpoint),
    );
  }
}

/// The phone rendition of an embedded image: proxied through the server, capped
/// to the column, and tappable into the same fullscreen viewer the desktop
/// uses.
///
/// A screenshot in a PR body is the case that makes this worth having at all —
/// at phone-column width it is unreadable, and the phone has no second window
/// to open it in.
class _PhoneMarkdownImage extends StatelessWidget {
  const _PhoneMarkdownImage({
    required this.url,
    required this.alt,
    required this.endpoint,
  });

  final String url;
  final String? alt;
  final RemoteMediaEndpoint? endpoint;

  static const _labels = CcImageViewerLabels(
    expand: 'Expand',
    zoomIn: 'Zoom in',
    zoomOut: 'Zoom out',
    resetZoom: 'Reset zoom',
    close: 'Close',
  );

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final endpoint = this.endpoint;
    // A broker-relayed session has no HTTP origin, so there is no proxy to
    // fetch through and the phone must not dial the upstream itself. The alt
    // text is the honest degradation — the same one the avatars take.
    if (endpoint == null || !url.startsWith('http')) {
      return Text(
        alt?.isNotEmpty == true ? alt! : url,
        style: CcTypography.caption.copyWith(color: t.textTertiary),
      );
    }
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final width = MediaQuery.sizeOf(context).width;
    Widget image({required int maxWidth, required BoxFit fit}) => Image.network(
      endpoint.resolve(url, maxWidth: maxWidth),
      fit: fit,
      errorBuilder: (context, error, stack) => Text(
        alt?.isNotEmpty == true ? alt! : url,
        style: CcTypography.caption.copyWith(color: t.textTertiary),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: CcExpandableImage(
        labels: _labels,
        title: alt?.isNotEmpty == true ? alt : null,
        borderRadius: BorderRadius.circular(6),
        // The viewer asks for a desktop-class raster: the whole point of
        // expanding is to read detail the column-width fetch threw away.
        viewerBuilder: (_) => image(maxWidth: 2048, fit: BoxFit.contain),
        child: image(maxWidth: (width * dpr).round(), fit: BoxFit.contain),
      ),
    );
  }
}

/// The phone's markdown stylesheet.
CcMarkdownStyle phoneMarkdownStyle(DesignSystemTokens t, [double base = 14]) {
  // Resolved through CcFonts, never a raw family string: the bundled families
  // are package-scoped (`packages/cc_ui/Manrope`) and a literal name silently
  // falls back to the engine default.
  final body = CcFonts.ui(
    textStyle: TextStyle(fontSize: base, height: 1.5, color: t.textSecondary),
  );
  TextStyle heading(double size) => CcFonts.ui(
    textStyle: TextStyle(
      fontSize: size,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: t.textPrimary,
    ),
  );
  final mono = CcFonts.code(
    textStyle: TextStyle(
      fontSize: base - 1,
      height: 1.45,
      color: t.textPrimary,
    ),
  );
  return CcMarkdownStyle(
    paragraph: body,
    h1: heading(base + 5),
    h2: heading(base + 3),
    h3: heading(base + 1),
    h4: heading(base),
    h5: heading(base),
    h6: heading(base),
    code: mono,
    inlineCode: mono.copyWith(fontSize: base - 1.5),
    link: body.copyWith(color: t.accent),
    blockquote: body.copyWith(color: t.textTertiary),
    bold: TextStyle(fontWeight: FontWeight.w600, color: t.textPrimary),
    italic: const TextStyle(fontStyle: FontStyle.italic),
    listBullet: body,
    tableHead: body.copyWith(fontWeight: FontWeight.w600, color: t.textPrimary),
    tableBody: body,
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: t.borderSecondary, width: 3)),
    ),
    blockquotePadding: const EdgeInsets.only(left: 12),
    codeblockDecoration: BoxDecoration(
      color: t.bgTertiary,
      borderRadius: BorderRadius.circular(6),
    ),
    codeblockPadding: const EdgeInsets.all(10),
    inlineCodePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    inlineCodeRadius: 3,
    tableBorder: TableBorder.all(color: t.borderSoft),
    tableCellPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    horizontalRuleColor: t.borderSoft,
    // A phone column is ~44 characters wide. Treating every newline as a hard
    // break is what makes a GitHub PR body wrap the way its author saw it —
    // CommonMark's paragraph-joining reflows their line breaks away.
    softBreakMode: CcSoftBreakMode.newline,
    blockSpacing: 10,
    listIndent: 18,
  );
}
