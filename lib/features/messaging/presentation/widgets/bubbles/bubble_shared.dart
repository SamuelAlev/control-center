import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/material.dart';

/// Default avatar diameter for bubble rows.
const double avatarSize = 28;

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

/// Resolves [DesignSystemTokens] from the given [context].
DesignSystemTokens resolveTokens(BuildContext context) {
  final tokens = context.designSystem;
  if (tokens != null) {
    return tokens;
  }
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DesignSystemTokens.dark() : DesignSystemTokens.light();
}
