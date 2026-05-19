import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/checkbox_list_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart' as sm;
import 'package:forui/forui.dart';

/// Default avatar diameter for bubble rows.
const double avatarSize = 28;
/// Corner radius for message bubbles.
const double bubbleRadius = 14;
/// Corner radius for the tail edge of message bubbles.
const double tailRadius = 4;
/// Inner padding for message bubbles.
const EdgeInsets bubblePadding = EdgeInsets.symmetric(
  horizontal: 14,
  vertical: 10,
);
/// Line height multiplier for bubble body text.
const double bodyLineHeight = 1.5;
/// Maximum bubble width as fraction of viewport.
const double maxBubbleFraction = 0.75;

/// Parser plugin registry for chat markdown.
final sm.ParserPluginRegistry chatPlugins = sm.ParserPluginRegistry()
  ..register(const sm.ThinkingPlugin())
  ..register(const sm.ArtifactPlugin())
  ..register(const sm.ToolCallPlugin());

/// Builder registry for chat markdown widgets.
final sm.BuilderRegistry chatBuilders = sm.BuilderRegistry()
  ..register('list', const FCheckboxListBuilder());

/// Resolves [DesignSystemTokens] from the given [context].
DesignSystemTokens resolveTokens(BuildContext context) {
  final tokens = context.designSystem;
  if (tokens != null) {
    return tokens;
  }
  final colors = FTheme.of(context).colors;
  final isDark = colors.brightness == Brightness.dark;
  return isDark ? DesignSystemTokens.dark() : DesignSystemTokens.light();
}
