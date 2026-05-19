import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/context_usage_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A compact live context-window gauge — "145k / 200k" with a thin fill bar
/// that warms from neutral → amber (≥75%) → red (≥90%) as the conversation
/// approaches the model's window. Mirrors the estimate that drives
/// auto-compaction, so a full bar means a compaction pass is imminent.
class ContextMeterChip extends ConsumerWidget {
  /// Creates a [ContextMeterChip] for the [channelId] / [agentId] pair.
  const ContextMeterChip({
    super.key,
    required this.channelId,
    required this.agentId,
  });

  /// The channel whose usage to show.
  final String channelId;

  /// The agent whose context window bounds the meter.
  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final usage = ref.watch(
      conversationContextUsageProvider((channelId: channelId, agentId: agentId)),
    );
    if (usage.windowTokens <= 0 || usage.usedTokens <= 0) {
      return const SizedBox.shrink();
    }

    final fillColor = usage.isCritical
        ? tokens.bgErrorSolid
        : usage.isWarning
            ? tokens.bgWarningSolid
            : tokens.bgSuccessSolid;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${_fmt(usage.usedTokens)} / ${_fmt(usage.windowTokens)}',
            style: TextStyle(
              fontFamily: CcFonts.codeFamily,
              fontSize: 11,
              height: 1.1,
              color: usage.isWarning ? fillColor : tokens.textTertiary,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: 64,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  Container(height: 3, color: tokens.bgTertiary),
                  FractionallySizedBox(
                    widthFactor: usage.fraction.clamp(0.02, 1.0),
                    child: Container(height: 3, color: fillColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a token count compactly: 145000 → "145k", 263000 → "263k",
  /// 900 → "900".
  String _fmt(int tokens) {
    if (tokens >= 1000) {
      return '${(tokens / 1000).round()}k';
    }
    return '$tokens';
  }
}
