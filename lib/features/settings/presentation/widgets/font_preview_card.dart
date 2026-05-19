import 'dart:io';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Whether the preview is for an app (UI) font or a code (monospace) font.
enum FontContext {
  /// App/UI font context.
  app,
  /// Code/monospace font context.
  code,
}

/// Renders a preview of the selected font with appropriate sample text.
///
/// For system fonts this widget loads the font file into Flutter's engine
/// via [FontLoader] the first time it is shown.
class FontPreviewCard extends StatefulWidget {
  /// Creates a new [FontPreviewCard].
  const FontPreviewCard({
    super.key,
    required this.font,
    required this.context,
    this.backgroundColor,
    this.borderColor,
  });

  /// The font to preview.
  final FontSelection font;
  /// Whether to preview as app text or code diff text.
  final FontContext context;
  /// Optional override for the preview card background.
  final Color? backgroundColor;
  /// Optional override for the preview card border color.
  final Color? borderColor;

  @override
  State<FontPreviewCard> createState() => _FontPreviewCardState();
}

class _FontPreviewCardState extends State<FontPreviewCard> {
  bool _isLoading = false;
  bool _loaded = false;

  @override
  void didUpdateWidget(covariant FontPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.font != widget.font) {
      _loaded = false;
      _maybeLoadSystemFont();
    }
  }

  @override
  void initState() {
    super.initState();
    _maybeLoadSystemFont();
  }

  Future<void> _maybeLoadSystemFont() async {
    if (widget.font.source == FontSource.system &&
        widget.font.filePath != null &&
        !_loaded) {
      setState(() => _isLoading = true);
      final file = File(widget.font.filePath!);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        final fontLoader = FontLoader(widget.font.family);
        fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
        await fontLoader.load();
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loaded = true;
        });
      }
    }
  }

  TextStyle _buildStyle(double fontSize, {FontWeight? weight, Color? color}) {
    final base = TextStyle(fontSize: fontSize, fontWeight: weight, color: color);
    // Google-source families route through google_fonts (bundled host families
    // like Manrope / Fira Code resolve verbatim, never over the network);
    // system fonts are pre-loaded via FontLoader and applied by name.
    if (widget.font.source == FontSource.google) {
      return AppFonts.uiDynamic(widget.font.family, textStyle: base);
    }
    return base.copyWith(fontFamily: widget.font.family);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg =
        widget.backgroundColor ??
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final border =
        widget.borderColor ??
        theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: const Center(
          child: CcSpinner(size: 20),
        ),
      );
    }

    final content = widget.context == FontContext.app
        ? _buildAppPreview()
        : _buildCodePreview(theme);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: content,
    );
  }

  Widget _buildAppPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The quick brown fox jumps over the lazy dog.',
          style: _buildStyle(18, weight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        Text(
          'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
          style: _buildStyle(12, weight: FontWeight.w300),
        ),
        Text(
          'abcdefghijklmnopqrstuvwxyz',
          style: _buildStyle(12, weight: FontWeight.w300),
        ),
        Text('0123456789', style: _buildStyle(12, weight: FontWeight.w300)),
      ],
    );
  }

  Widget _buildCodePreview(ThemeData theme) {
    final removedStyle = _buildStyle(13, color: Colors.red.shade400);
    final addedStyle = _buildStyle(13, color: Colors.green.shade400);
    final neutralStyle = _buildStyle(13, color: theme.colorScheme.onSurface);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DiffLine(
          prefix: '-',
          prefixColor: Colors.red.shade400,
          text: 'const oldValue = computeLegacy(input);',
          style: removedStyle,
        ),
        _DiffLine(
          prefix: '+',
          prefixColor: Colors.green.shade400,
          text: 'const newValue = computeModern(input);',
          style: addedStyle,
        ),
        _DiffLine(
          prefix: ' ',
          prefixColor: neutralStyle.color!,
          text: 'const unchanged = normalize(all);',
          style: neutralStyle,
        ),
        _DiffLine(
          prefix: ' ',
          prefixColor: neutralStyle.color!,
          text: 'return { oldValue, newValue, unchanged };',
          style: neutralStyle,
        ),
      ],
    );
  }
}

class _DiffLine extends StatelessWidget {
  const _DiffLine({
    required this.prefix,
    required this.prefixColor,
    required this.text,
    required this.style,
  });

  final String prefix;
  final Color prefixColor;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prefix, style: style.copyWith(color: prefixColor)),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

