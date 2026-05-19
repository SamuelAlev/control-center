import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/checkbox_list_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart' as sm;
import 'package:forui/forui.dart';

const double avatarSize = 28;
const double bubbleRadius = 14;
const double tailRadius = 4;
const EdgeInsets bubblePadding = EdgeInsets.symmetric(
  horizontal: 14,
  vertical: 10,
);
const double bodyLineHeight = 1.5;
const double maxBubbleFraction = 0.75;

final sm.ParserPluginRegistry chatPlugins = sm.ParserPluginRegistry()
  ..register(const sm.ThinkingPlugin())
  ..register(const sm.ArtifactPlugin())
  ..register(const sm.ToolCallPlugin());

final sm.BuilderRegistry chatBuilders = sm.BuilderRegistry()
  ..register('list', const FCheckboxListBuilder());

DesignSystemTokens resolveTokens(BuildContext context) {
  final tokens = context.designSystem;
  if (tokens != null) {
    return tokens;
  }
  final colors = FTheme.of(context).colors;
  final isDark = colors.brightness == Brightness.dark;
  return isDark ? DesignSystemTokens.dark() : DesignSystemTokens.light();
}
