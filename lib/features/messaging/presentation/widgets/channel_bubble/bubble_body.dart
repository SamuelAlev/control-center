import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/shared/utils/format_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart' as sm;

class BubbleBody extends StatelessWidget {
  const BubbleBody({super.key, 
    required this.content,
    required this.createdAt,
    required this.codeFont,
    required this.tokens,
    required this.theme,
    this.textStream,
    this.isLive = false,
  });

  final String content;
  final DateTime createdAt;
  final String codeFont;
  final DesignSystemTokens tokens;
  final ThemeData theme;
  final Stream<String>? textStream;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLive && textStream != null)
          sm.StreamMarkdown(
            stream: textStream!,
            styleSheet: _buildSmStyleSheet(),
            plugins: chatPlugins,
            builderRegistry: chatBuilders,
            useEnhancedComponents: true,
          )
        else if (content.isNotEmpty)
          sm.SmoothMarkdown(
            data: content,
            selectable: true,
            styleSheet: _buildSmStyleSheet(),
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

  sm.MarkdownStyleSheet _buildSmStyleSheet() {
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: tokens.textTertiary,
      height: bodyLineHeight,
    );
    return sm.MarkdownStyleSheet.fromTheme(theme).copyWith(
      textStyle: bodyStyle,
      h1Style: theme.textTheme.titleLarge?.copyWith(
        color: tokens.textPrimary,
        height: 1.3,
      ),
      h2Style: theme.textTheme.titleMedium?.copyWith(
        color: tokens.textPrimary,
        height: 1.3,
      ),
      h3Style: theme.textTheme.titleSmall?.copyWith(
        color: tokens.textPrimary,
        height: 1.4,
      ),
      codeBlockStyle: AppFonts.codeDynamic(
        codeFont,
        textStyle: theme.textTheme.bodySmall?.copyWith(
          color: tokens.textTertiary,
          height: bodyLineHeight,
        ),
      ),
      inlineCodeStyle: AppFonts.codeDynamic(
        codeFont,
        textStyle: theme.textTheme.bodySmall?.copyWith(
          color: tokens.textBrandTertiary,
          backgroundColor: tokens.bgSecondary,
          height: bodyLineHeight,
        ),
      ),
      linkStyle: theme.textTheme.bodyMedium?.copyWith(
        color: tokens.textBrandPrimary,
        decoration: TextDecoration.underline,
        height: bodyLineHeight,
      ),
      blockquoteStyle: theme.textTheme.bodyMedium?.copyWith(
        color: tokens.textQuaternary,
        height: bodyLineHeight,
      ),
      blockquoteDecoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: tokens.borderSecondary, width: 3),
        ),
      ),
      tableHeaderStyle: theme.textTheme.labelSmall?.copyWith(
        color: tokens.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      tableCellStyle: theme.textTheme.bodySmall?.copyWith(
        color: tokens.textTertiary,
      ),
      tableBorder: TableBorder.all(
        color: tokens.borderSecondary,
        width: 0.5,
      ),
      tableHeaderDecoration: BoxDecoration(color: tokens.bgSecondary),
      horizontalRuleColor: tokens.borderSecondary,
    );
  }
}
