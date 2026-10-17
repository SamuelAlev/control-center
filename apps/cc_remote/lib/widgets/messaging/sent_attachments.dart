import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/attachments.dart';
import 'package:cc_remote/external_link.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/media_proxy.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'sent_attachment_chip.dart';

/// What a message carried, under its text. The message's own workspace,
/// rather than the currently selected workspace, scopes every signed URL.
class SentAttachments extends ConsumerWidget {
  const SentAttachments({
    super.key,
    required this.attachments,
    required this.workspaceId,
    required this.alignEnd,
  });

  final List<MessageAttachment> attachments;
  final String workspaceId;
  final bool alignEnd;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    final endpoint = ref.watch(mediaEndpointProvider).value;
    final client = ref.watch(rpcClientProvider).value;
    String? downloadUrlFor(MessageAttachment a) {
      if (endpoint == null || workspaceId.isEmpty || !a.isUploaded) {
        return null;
      }
      final url = endpoint.blobUrl(
        workspaceId: workspaceId,
        ref: a.path,
        downloadName: a.name,
      );
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
              key: ValueKey(attachment.id),
              attachment: attachment,
              workspaceId: workspaceId,
              endpoint: endpoint,
              client: client,
              downloadUrl: attachment.isImage
                  ? null
                  : downloadUrlFor(attachment),
              tokens: t,
            ),
        ],
      ),
    );
  }
}

class _SentAttachment extends StatefulWidget {
  const _SentAttachment({
    super.key,
    required this.attachment,
    required this.workspaceId,
    required this.endpoint,
    required this.client,
    required this.downloadUrl,
    required this.tokens,
  });

  final MessageAttachment attachment;
  final String workspaceId;
  final RemoteMediaEndpoint? endpoint;
  final RemoteRpcClient? client;
  final String? downloadUrl;
  final DesignSystemTokens tokens;

  @override
  State<_SentAttachment> createState() => _SentAttachmentState();
}

class _SentAttachmentState extends State<_SentAttachment> {
  Future<Uint8List>? _image;
  bool _decodeFailed = false;

  @override
  void initState() {
    super.initState();
    _image = _fetch();
  }

  Future<Uint8List>? _fetch() {
    final client = widget.client;
    final endpoint = widget.endpoint;
    if (!widget.attachment.isImage ||
        !widget.attachment.isUploaded ||
        widget.workspaceId.isEmpty ||
        client == null ||
        endpoint == null) {
      return null;
    }
    return fetchAttachmentImage(
      endpoint: endpoint,
      resources: client.resources,
      workspaceId: widget.workspaceId,
      attachment: widget.attachment,
    );
  }

  @override
  void didUpdateWidget(_SentAttachment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client != widget.client ||
        oldWidget.endpoint != widget.endpoint ||
        oldWidget.workspaceId != widget.workspaceId ||
        oldWidget.attachment.path != widget.attachment.path) {
      _decodeFailed = false;
      _image = _fetch();
    }
  }

  void _retry() {
    setState(() {
      _decodeFailed = false;
      _image = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachment;
    final l10n = AppLocalizations.of(context);
    if (!attachment.isImage) {
      final available = widget.downloadUrl != null;
      return GestureDetector(
        onTap: available ? () => openExternal(widget.downloadUrl) : null,
        child: Semantics(
          button: available,
          label: available
              ? l10n.progressOpenAttachment(attachment.name)
              : attachment.name,
          child: _chip(
            unavailable: !available,
            status: available ? null : l10n.sentAttachmentUnavailable,
          ),
        ),
      );
    }
    final image = _image;
    if (image == null) {
      return _chip(unavailable: true, status: l10n.sentAttachmentUnavailable);
    }
    return FutureBuilder<Uint8List>(
      future: image,
      builder: (context, snapshot) {
        if (snapshot.hasError || _decodeFailed) {
          return GestureDetector(
            onTap: _retry,
            child: Semantics(
              button: true,
              label:
                  '${attachment.name}, ${l10n.sentAttachmentLoadFailed}, ${l10n.retry}',
              child: _chip(
                unavailable: true,
                status: l10n.sentAttachmentLoadFailed,
                retry: l10n.retry,
              ),
            ),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null) {
          return const SizedBox(
            height: 140,
            width: 220,
            child: Center(child: CcSpinner(size: 14)),
          );
        }
        Widget imageView({required bool thumbnail}) => Image.memory(
          bytes,
          width: thumbnail ? 220 : null,
          height: thumbnail ? 140 : null,
          fit: BoxFit.contain,
          errorBuilder: (context, _, _) {
            if (!_decodeFailed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _image == image) {
                  setState(() => _decodeFailed = true);
                }
              });
            }
            return _chip(
              unavailable: true,
              status: l10n.sentAttachmentLoadFailed,
              retry: l10n.retry,
            );
          },
        );
        return CcExpandableImage(
          labels: CcImageViewerLabels(
            expand: l10n.expand,
            zoomIn: l10n.zoomIn,
            zoomOut: l10n.zoomOut,
            resetZoom: l10n.resetZoom,
            close: l10n.close,
          ),
          title: attachment.name,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          viewerBuilder: (_) => imageView(thumbnail: false),
          child: imageView(thumbnail: true),
        );
      },
    );
  }
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
