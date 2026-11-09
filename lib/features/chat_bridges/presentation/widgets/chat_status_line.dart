import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The live state of one chat connection: a tag, the last error beside it,
/// and the caveats that change what the admin can do or what members see —
/// whose app it runs on, and whether replies stream.
class ChatStatusLine extends StatelessWidget {
  /// Creates a [ChatStatusLine].
  const ChatStatusLine({
    super.key,
    required this.status,
    required this.providerName,
  });

  /// The connection being described.
  final ChatConnectionStatus status;

  /// The provider's product name, for the copy that names it.
  final String providerName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem;
    final (label, tone) = switch (status.state) {
      ChatConnectionState.connected => (
        l10n.chatStateLive,
        CcStatusTone.positive,
      ),
      ChatConnectionState.connecting => (
        l10n.chatStateConnecting,
        CcStatusTone.caution,
      ),
      ChatConnectionState.error => (l10n.chatStateError, CcStatusTone.negative),
      ChatConnectionState.disconnected => (
        l10n.chatNotConnected,
        CcStatusTone.neutral,
      ),
    };
    final caption = CcTypography.caption.copyWith(
      color: t?.textTertiary,
      height: 1.45,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CcStatusTag(label: label, tone: tone),
            if (status.lastError != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  status.lastError!,
                  style: caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        // The shared app has no tokens or bot settings here, which is why
        // the rows for them are gone; say so rather than leave a gap.
        if (status.mode == ChatConnectionMode.connect) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.chatSharedAppConnected, style: caption),
        ],
        if (status.streamingAvailable == false) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.chatStreamingUnavailable(providerName), style: caption),
        ],
      ],
    );
  }
}
