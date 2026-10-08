import 'dart:typed_data';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/attachments/attachment_preview_pane.dart'
    show attachmentIcon;
import 'package:control_center/shared/widgets/attachments/local_media.dart';
import 'package:control_center/shared/widgets/composer/attachments/attachment_media.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/file_reference.dart';
import 'package:flutter/gestures.dart'
    show
        GestureBinding,
        PointerDeviceKind,
        PointerScrollEvent,
        PointerSignalEvent;
import 'package:flutter/widgets.dart';

/// Height of one attachment card, and of the strip that holds them.
///
/// Tall enough for a picture to read as a picture: a 36px chip could only ever
/// show a glyph, which made "did the screenshot attach?" a question the strip
/// could not answer.
const double kAttachmentStripHeight = 60;

/// Horizontal row of removable cards for the composer's attached files,
/// pictures and scratchpads. Hidden when the list is empty.
///
/// A card is the same reference as the `@[file:…]` token in the prompt, seen
/// from the other side: both open the preview, and removing either removes
/// both.
///
/// Overflowing cards scroll: a mouse can drag the row (desktop scrollables
/// ignore mouse drags by default) and a vertical wheel scrolls it sideways, so
/// the fourth attachment is reachable without a trackpad. The edges fade while
/// cards remain beyond them.
class AttachmentStrip extends StatefulWidget {
  /// Creates a new [AttachmentStrip].
  const AttachmentStrip({
    super.key,
    required this.attachments,
    required this.onRemove,
    this.onOpen,
  });

  /// Attachments to display as removable cards.
  final List<ComposerAttachment> attachments;

  /// Called when the user removes an attachment.
  final void Function(ComposerAttachment) onRemove;

  /// Called when the user opens an attachment's preview. Null makes the cards
  /// non-interactive apart from their remove button.
  final void Function(ComposerAttachment)? onOpen;

  @override
  State<AttachmentStrip> createState() => _AttachmentStripState();
}

class _AttachmentStripState extends State<AttachmentStrip> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Turns a plain vertical wheel into a sideways scroll. Horizontal and
  /// shift-wheel signals already reach the list's own [Scrollable], which
  /// claims them first; this only sees the vertical ones it ignores. Claimed
  /// through the resolver so the composer's text field does not scroll too.
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent ||
        event.scrollDelta.dx != 0 ||
        event.scrollDelta.dy == 0 ||
        !_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    if (position.maxScrollExtent <= position.minScrollExtent) {
      return;
    }
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      final delta = (event as PointerScrollEvent).scrollDelta.dy;
      final target = (position.pixels + delta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (target != position.pixels) {
        position.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final attachments = widget.attachments;
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    final onOpen = widget.onOpen;
    return SizedBox(
      height: kAttachmentStripHeight,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        child: CcScrollArea(
          axis: Axis.horizontal,
          fadeColor: t.bgPrimary,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
            child: ListView.separated(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: attachments.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) => _AttachmentCard(
                attachment: attachments[i],
                onRemove: () => widget.onRemove(attachments[i]),
                onOpen: onOpen == null ? null : () => onOpen(attachments[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatefulWidget {
  const _AttachmentCard({
    required this.attachment,
    required this.onRemove,
    required this.onOpen,
  });

  final ComposerAttachment attachment;
  final VoidCallback onRemove;
  final VoidCallback? onOpen;

  @override
  State<_AttachmentCard> createState() => _AttachmentCardState();
}

class _AttachmentCardState extends State<_AttachmentCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final attachment = widget.attachment;
    // The REFERENCE name, not the raw filename: it is what the prompt says,
    // and a card labelled differently from the token beside it reads as a
    // second, unrelated attachment.
    final label =
        attachment.refName ?? ellipsizeFileRefName(attachment.label, max: 24);
    final size = formatAttachmentSize(attachment.sizeBytes);
    final open = widget.onOpen;

    final card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 232),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _hovering ? t.bgSecondaryHover : t.bgSecondary,
          borderRadius: AppRadii.brSm,
          border: Border.all(
            color: _hovering ? t.borderPrimary : t.borderSecondary,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 4, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Thumbnail(attachment: attachment, tokens: t),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.caption.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    if (size != null)
                      Text(
                        size,
                        maxLines: 1,
                        style: CcTypography.caption.copyWith(
                          color: t.textTertiary,
                          fontSize: 10,
                          decoration: TextDecoration.none,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              CcIconButton(
                icon: AppIcons.x,
                size: CcButtonSize.sm,
                tooltip: AppLocalizations.of(context).remove,
                onPressed: widget.onRemove,
              ),
            ],
          ),
        ),
      ),
    );

    return MouseRegion(
      cursor: open == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: open,
        child: Semantics(button: open != null, label: label, child: card),
      ),
    );
  }
}

/// A picture's own thumbnail, or its kind's glyph.
class _Thumbnail extends StatefulWidget {
  const _Thumbnail({required this.attachment, required this.tokens});

  final ComposerAttachment attachment;
  final DesignSystemTokens tokens;

  static const double _size = 36;

  @override
  State<_Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends State<_Thumbnail> {
  static const double _size = _Thumbnail._size;

  // Held across rebuilds: a MemoryImage is keyed by its byte list's identity,
  // so a fresh copy per build (every hover) missed the image cache and blanked
  // the picture while it decoded again.
  ImageProvider? _provider;

  @override
  void initState() {
    super.initState();
    _provider = _imageProvider();
  }

  @override
  void didUpdateWidget(_Thumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final a = widget.attachment;
    final b = oldWidget.attachment;
    if (!identical(a.bytes, b.bytes) ||
        a.path != b.path ||
        a.mimeType != b.mimeType ||
        a.label != b.label) {
      _provider = _imageProvider();
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachment;
    final tokens = widget.tokens;
    final provider = _provider;
    if (provider == null) {
      return SizedBox(
        width: _size,
        height: _size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.bgTertiary,
            borderRadius: AppRadii.brXs,
          ),
          child: Icon(
            attachmentIcon(attachment),
            size: 16,
            color: tokens.textTertiary,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: AppRadii.brXs,
      child: Image(
        image: provider,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        // Decoded at display size: a 4000px screenshot resampled to 36px would
        // otherwise sit in the image cache at full resolution for a chip.
        errorBuilder: (context, _, _) => SizedBox(
          width: _size,
          height: _size,
          child: Icon(AppIcons.imageOff, size: 16, color: tokens.textTertiary),
        ),
      ),
    );
  }

  ImageProvider? _imageProvider() {
    final attachment = widget.attachment;
    if (attachmentMediaKind(
          mimeType: attachment.mimeType,
          name: attachment.label,
        ) !=
        AttachmentMediaKind.image) {
      return null;
    }
    final bytes = attachment.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return ResizeImage(
        MemoryImage(Uint8List.fromList(bytes)),
        width: (_size * 3).round(),
        allowUpscaling: false,
      );
    }
    final path = attachment.path;
    if (path == null) {
      return null;
    }
    final provider = localImageProvider(path);
    return provider == null
        ? null
        : ResizeImage(
            provider,
            width: (_size * 3).round(),
            allowUpscaling: false,
          );
  }
}
