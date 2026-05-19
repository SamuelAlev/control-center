import 'dart:async';

import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/format_utils.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/markdown/markdown_image.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/material.dart';

/// Renders a message body with markdown and timestamp.
class BubbleBody extends StatelessWidget {
  /// Creates a [BubbleBody].
  const BubbleBody({
    super.key,
    required this.content,
    required this.createdAt,
    required this.codeFont,
    required this.tokens,
    required this.theme,
    this.textStream,
    this.isLive = false,
    this.isEdited = false,
  });

  /// The message content.
  final String content;

  /// When the message was created.
  final DateTime createdAt;

  /// Font family for code blocks.
  final String codeFont;

  /// Design system tokens for theming.
  final DesignSystemTokens tokens;

  /// Current theme data.
  final ThemeData theme;

  /// Live text stream (for streaming messages).
  final Stream<String>? textStream;

  /// Whether the message is streaming live.
  final bool isLive;

  /// Whether to show an "(edited)" marker next to the timestamp.
  final bool isEdited;

  @override
  Widget build(BuildContext context) {
    Widget codeBuilder(String code, String? language, {required bool cache}) =>
        buildSharedCodeBlock(
          context,
          code,
          language,
          codeFontFamily: codeFont,
          cache: cache,
        );
    final style = appMarkdownStyle(context, codeFontFamily: codeFont);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLive && textStream != null)
          _StreamingBody(
            textStream: textStream!,
            style: style,
            codeBuilder: codeBuilder,
          )
        else if (content.isNotEmpty)
          CcMarkdown(
            data: content,
            selectable: true,
            style: style,
            plugins: chatMarkdownPlugins,
            options: chatMarkdownOptions,
            builders: chatMarkdownBuilders,
            imageBuilder: appMarkdownImageBuilder,
            codeBuilder: codeBuilder,
          ),
        const SizedBox(height: 6),
        AppTimestamp(
          dateTime: createdAt,
          child: Text(
            isEdited
                ? '${formatTime(createdAt)} · ${AppLocalizations.of(context).edited}'
                : formatTime(createdAt),
            style: CcTypography.caption.copyWith(color: tokens.textQuaternary),
          ),
        ),
      ],
    );
  }
}

/// Accumulates a live text [Stream] into the incremental streaming renderer.
class _StreamingBody extends StatefulWidget {
  const _StreamingBody({
    required this.textStream,
    required this.style,
    required this.codeBuilder,
  });

  final Stream<String> textStream;
  final CcMarkdownStyle style;
  final CcCodeBuilder codeBuilder;

  @override
  State<_StreamingBody> createState() => _StreamingBodyState();
}

class _StreamingBodyState extends State<_StreamingBody> {
  late final CcMarkdownStreamController _controller =
      CcMarkdownStreamController(
        plugins: chatMarkdownPlugins,
        options: chatMarkdownOptions,
      );
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant _StreamingBody old) {
    super.didUpdateWidget(old);
    if (old.textStream != widget.textStream) {
      _sub?.cancel();
      _controller.reset();
      _subscribe();
    }
  }

  void _subscribe() {
    _sub = widget.textStream.listen(
      _controller.append,
      onDone: _controller.complete,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CcStreamingMarkdown(
      controller: _controller,
      style: widget.style,
      builders: chatMarkdownBuilders,
      imageBuilder: appMarkdownImageBuilder,
      codeBuilder: widget.codeBuilder,
      selectable: true,
    );
  }
}
