part of 'sent_attachments.dart';

extension _SentAttachmentChip on _SentAttachmentState {
  Widget _chip({required bool unavailable, String? status, String? retry}) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: widget.tokens.bgSecondary,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(color: widget.tokens.borderSoft),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  unavailable && widget.attachment.isImage
                      ? AppIcons.imageOff
                      : (widget.attachment.isImage
                            ? AppIcons.image
                            : AppIcons.file),
                  size: 14,
                  color: widget.tokens.fgTertiary,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.tokens.textPrimary,
                        ),
                      ),
                      if (status != null)
                        Text(
                          status,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.tokens.fgTertiary,
                          ),
                        ),
                      if (retry != null)
                        Text(
                          retry,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.tokens.accent,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
