import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/shared/utils/format_utils.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart' as sm;

/// Renders a message body with markdown and timestamp.
class BubbleBody extends StatelessWidget {
  /// Creates a [BubbleBody].
  const BubbleBody({super.key, 
    required this.content,
    required this.createdAt,
    required this.codeFont,
    required this.tokens,
    required this.theme,
    this.textStream,
    this.isLive = false,
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

  @override
  Widget build(BuildContext context) {
    Widget codeBlockBuilder(String code, String? language) =>
        buildSharedCodeBlock(
          context,
          code,
          language,
          codeFontFamily: codeFont,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLive && textStream != null)
          sm.StreamMarkdown(
            stream: textStream!,
            styleSheet: smMarkdownStyleSheet(
              context,
              codeFontFamily: codeFont,
            ),
            codeBuilder: codeBlockBuilder,
            plugins: chatPlugins,
            builderRegistry: chatBuilders,
            useEnhancedComponents: true,
          )
        else if (content.isNotEmpty)
          sm.SmoothMarkdown(
            data: content,
            selectable: true,
            styleSheet: smMarkdownStyleSheet(
              context,
              codeFontFamily: codeFont,
            ),
            codeBuilder: codeBlockBuilder,
            plugins: chatPlugins,
            builderRegistry: chatBuilders,
            useEnhancedComponents: true,
          ),
        const SizedBox(height: 6),
        Text(
          formatTime(createdAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: tokens.textQuaternary,
          ),
        ),
      ],
    );
  }
}
