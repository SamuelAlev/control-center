import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/message_attachment_refs.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/attachments/attachment_preview_pane.dart'
    show attachmentIcon;
import 'package:control_center/shared/widgets/attachments/open_attachment_preview.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_media.dart'
    show formatAttachmentSize;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What a person attached to their message, under its text — still openable
/// after the message is gone from the composer.
///
/// **Why this exists.** A pasted or dropped screenshot has always reached the
/// agent — the composer uploads it and the dispatch path puts it on the user
/// turn — but the transcript never showed it, and a dropped FILE left no trace
/// at all beyond a bare path expanded into the sentence. So the conversation
/// read as somebody asking "what is wrong with this?" about nothing, and there
/// was no way to look again at what you had sent.
///
/// Bytes are never inline: a picture is a `blob:sha256:<hex>` reference the
/// host serves over `/blob`, signed with the device PSK and gated on workspace
/// membership — the same lane the agent's own screenshots ride. A file is its
/// path, read straight off the disk both ends share.
class MessageAttachmentStrip extends ConsumerWidget {
  /// Creates a [MessageAttachmentStrip].
  const MessageAttachmentStrip({
    super.key,
    required this.attachments,
    required this.tokens,
    this.thumbnailHeight = 112,
  });

  /// The message's attachments, in send order.
  final List<MessageAttachment> attachments;

  /// Resolved design tokens (the bubble resolves them once).
  final DesignSystemTokens tokens;

  /// Height of each picture thumbnail; width follows its aspect ratio.
  final double thumbnailHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    String? urlFor(MessageAttachment attachment) => messageAttachmentUrl(
      context,
      attachment: attachment,
      workspaceId: workspaceId,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final attachment in attachments)
            if (attachment.isImage)
              _Thumbnail(
                attachment: attachment,
                url: urlFor(attachment),
                height: thumbnailHeight,
                tokens: tokens,
              )
            else
              _FileChip(
                attachment: attachment,
                url: urlFor(attachment),
                tokens: tokens,
              ),
        ],
      ),
    );
  }
}

class _Thumbnail extends ConsumerWidget {
  const _Thumbnail({
    required this.attachment,
    required this.url,
    required this.height,
    required this.tokens,
  });

  final MessageAttachment attachment;
  final String? url;
  final double height;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = url;
    if (resolved == null || resolved.isEmpty) {
      return _Unavailable(count: 1, tokens: tokens);
    }
    const radius = BorderRadius.all(Radius.circular(6));
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // The same gesture as the composer's chip and its inline reference:
        // one thing to click, one place it opens.
        onTap: () => unawaited(
          openAttachmentPreview(
            context,
            ref,
            sentAttachmentAsComposerAttachment(attachment, url: resolved),
          ),
        ),
        child: Semantics(
          label: attachment.name,
          image: true,
          button: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: tokens.borderSecondary),
              color: tokens.bgSecondary,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Image.network(
                resolved,
                height: height,
                fit: BoxFit.contain,
                errorBuilder: (context, _, _) =>
                    _Unavailable(count: 1, tokens: tokens),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : SizedBox(
                        height: height,
                        // Landscape placeholder: a screenshot is wider than it
                        // is tall far more often than not, so a square box
                        // would make every load visibly reflow.
                        width: height * 1.6,
                        child: const Center(child: CcSpinner(size: 14)),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A non-picture attachment: named, sized, and openable.
class _FileChip extends ConsumerWidget {
  const _FileChip({
    required this.attachment,
    required this.url,
    required this.tokens,
  });

  final MessageAttachment attachment;
  final String? url;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final replay = sentAttachmentAsComposerAttachment(attachment, url: url);
    final size = formatAttachmentSize(attachment.size);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => unawaited(openAttachmentPreview(context, ref, replay)),
        child: Semantics(
          button: true,
          label: attachment.name,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadii.brSm,
              border: Border.all(color: tokens.borderSecondary),
              color: tokens.bgSecondary,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    attachmentIcon(replay),
                    size: 14,
                    color: tokens.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(
                      attachment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.caption.copyWith(
                        color: tokens.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  if (size != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      size,
                      style: CcTypography.caption.copyWith(
                        color: tokens.textTertiary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when a picture cannot be resolved — no proxy, no workspace, a missing
/// blob, or a failed load. Explicit rather than an empty gap, so an attachment
/// that did not arrive is distinguishable from a message that carried none.
class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.count, required this.tokens});

  final int count;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.borderSecondary),
        color: tokens.bgSecondary,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.imageOff, size: 13, color: tokens.textTertiary),
            const SizedBox(width: 6),
            Text(
              count == 1
                  ? l10n.toolImageUnavailable
                  : l10n.toolImagesUnavailable(count),
              style: CcTypography.caption.copyWith(
                color: tokens.textTertiary,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
