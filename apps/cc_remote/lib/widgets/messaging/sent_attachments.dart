import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/attachments.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What a message carried, under its text.
///
/// Pictures resolve through the host's `/blob` endpoint, signed with the device
/// PSK and gated on workspace membership — the phone can no more read the
/// sender's disk than the server can, so there is nowhere else for the bytes to
/// come from. On a relayed session there is no HTTP origin at all, and the
/// strip says the picture is unavailable rather than showing an empty frame.
class SentAttachments extends ConsumerWidget {
  const SentAttachments({
    super.key,
    required this.attachments,
    required this.alignEnd,
  });

  final List<MessageAttachment> attachments;
  final bool alignEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    final endpoint = ref.watch(mediaEndpointProvider).value;
    final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
    String? urlFor(MessageAttachment a) {
      if (endpoint == null || workspaceId == null || !a.isUploaded) {
        return null;
      }
      final url = endpoint.blobUrl(workspaceId: workspaceId, ref: a.path);
      return url.isEmpty ? null : url;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
        children: [
          for (final attachment in attachments)
            _SentAttachment(
              attachment: attachment,
              url: urlFor(attachment),
              tokens: t,
            ),
        ],
      ),
    );
  }
}

class _SentAttachment extends StatelessWidget {
  const _SentAttachment({
    required this.attachment,
    required this.url,
    required this.tokens,
  });

  final MessageAttachment attachment;
  final String? url;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(8));
    final resolved = url;
    if (attachment.isImage && resolved != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          resolved,
          height: 140,
          fit: BoxFit.contain,
          errorBuilder: (context, _, _) => _chip(unavailable: true),
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const SizedBox(
                  height: 140,
                  width: 200,
                  child: Center(child: CcSpinner(size: 14)),
                ),
        ),
      );
    }
    return _chip(unavailable: attachment.isImage && resolved == null);
  }

  Widget _chip({required bool unavailable}) => DecoratedBox(
    decoration: BoxDecoration(
      color: tokens.bgSecondary,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      border: Border.all(color: tokens.borderSoft),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unavailable
                ? AppIcons.imageOff
                : (attachment.isImage ? AppIcons.image : AppIcons.file),
            size: 14,
            color: tokens.fgTertiary,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              attachment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: tokens.textPrimary),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A picked-but-not-yet-sent attachment, removable before it goes.
class PendingChip extends StatelessWidget {
  const PendingChip({
    super.key,
    required this.attachment,
    required this.onRemove,
  });

  final PickedAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        border: Border.all(color: t.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 0, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              attachment.isImage ? AppIcons.image : AppIcons.file,
              size: 14,
              color: t.fgTertiary,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                attachment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: t.textPrimary),
              ),
            ),
            const SizedBox(width: 4),
            PhoneIconButton(
              icon: AppIcons.x,
              iconSize: 14,
              semanticLabel: AppLocalizations.of(
                context,
              ).removeAttachment(attachment.name),
              color: t.fgTertiary,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
