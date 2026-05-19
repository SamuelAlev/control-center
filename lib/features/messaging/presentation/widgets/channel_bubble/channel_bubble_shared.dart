import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/checkbox_list_builder.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart' as sm;

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

/// Centered document column shared by messages and composer, so the
/// conversation reads like a continuous doc on wide panes. Feed items and the input bar are capped at this width
/// and centered within the conversation pane.
const double conversationColumnWidth = 760;

/// Parser plugin registry for chat markdown.
final sm.ParserPluginRegistry chatPlugins = sm.ParserPluginRegistry()
  ..register(const sm.ThinkingPlugin())
  ..register(const sm.ArtifactPlugin())
  ..register(const sm.ToolCallPlugin());

/// Builder registry for chat markdown widgets.
///
/// Registers the canonical inline-code chip ([SmInlineCodeBuilder]) so chat
/// inline `code` matches the PR/ticket look exactly, alongside the task-list
/// checkbox builder. Fenced code blocks render through [buildSharedCodeBlock]
/// via each widget's `codeBuilder` callback.
final sm.BuilderRegistry chatBuilders = sm.BuilderRegistry()
  ..register('list', const CcCheckboxListBuilder())
  ..register('inline_code', const SmInlineCodeBuilder());

/// Resolves [DesignSystemTokens] from the given [context].
DesignSystemTokens resolveTokens(BuildContext context) {
  final tokens = context.designSystem;
  if (tokens != null) {
    return tokens;
  }
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DesignSystemTokens.dark() : DesignSystemTokens.light();
}
