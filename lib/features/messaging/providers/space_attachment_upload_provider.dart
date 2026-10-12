import 'dart:convert';

import 'package:control_center/core/providers/media_proxy_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/shared/widgets/attachments/local_media.dart';
import 'package:control_center/shared/widgets/composer/attachment_upload_controller.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Uploads user-selected bytes via the authenticated encrypted resource lane.
/// The server owns logical file ids; local paths never become sent metadata.
class SpaceAttachmentUploadService {
  /// Captures a workspace and its authenticated resource transport.
  const SpaceAttachmentUploadService({
    required this.workspaceId,
    required this.uploadUrl,
    required this.discardFile,
    required this.post,
  });

  /// Matches the server's per-blob upload ceiling.
  static const maxBytes = 24 * 1024 * 1024;

  /// Workspace that owns every upload and discard through this service.
  final String workspaceId;

  /// Signed upload URL on the client's encrypted resource facade.
  final String uploadUrl;

  /// Sends the workspace-scoped discard operation.
  final Future<void> Function(String workspaceId, String fileId) discardFile;

  /// HTTP transport for the local resource facade.
  final Future<http.Response> Function(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  })
  post;

  /// Reads bounded local bytes and waits for a durable server receipt.
  Future<UploadedAttachment> upload(ComposerAttachment attachment) async {
    if (attachment.sizeBytes != null && attachment.sizeBytes! > maxBytes) {
      throw const AttachmentUploadException(AttachmentUploadError.tooLarge);
    }
    List<int>? bytes = attachment.bytes;
    if (bytes == null) {
      final path = attachment.path;
      if (path == null || path.isEmpty) {
        throw const AttachmentUploadException(AttachmentUploadError.unreadable);
      }
      if (attachment.sizeBytes == null) {
        final size = await localFileSize(path);
        if (size != null && size > maxBytes) {
          throw const AttachmentUploadException(AttachmentUploadError.tooLarge);
        }
      }
      bytes = await readLocalBytes(path, maxBytes: maxBytes);
      if (bytes == null && (await localFileSize(path) ?? 0) > maxBytes) {
        throw const AttachmentUploadException(AttachmentUploadError.tooLarge);
      }
    }
    if (bytes == null) {
      throw const AttachmentUploadException(AttachmentUploadError.unreadable);
    }
    if (bytes.length > maxBytes) {
      throw const AttachmentUploadException(AttachmentUploadError.tooLarge);
    }
    final mediaType = attachment.mimeType ?? 'application/octet-stream';
    try {
      final response = await post(
        Uri.parse(uploadUrl),
        headers: {
          'content-type': mediaType,
          'x-cc-file-name': Uri.encodeComponent(attachment.label),
        },
        body: bytes,
      );
      if (response.statusCode != 200) {
        throw const AttachmentUploadException(AttachmentUploadError.transfer);
      }
      final result = jsonDecode(response.body);
      if (result is! Map ||
          result['file_id'] is! String ||
          result['ref'] is! String ||
          result['bytes'] is! int ||
          result['media_type'] is! String) {
        throw const AttachmentUploadException(AttachmentUploadError.transfer);
      }
      final uploaded = UploadedAttachment(
        fileId: result['file_id'] as String,
        blobRef: result['ref'] as String,
        bytes: result['bytes'] as int,
        mediaType: result['media_type'] as String,
      );
      if (!uploaded.isValid) {
        throw const AttachmentUploadException(AttachmentUploadError.transfer);
      }
      return uploaded;
    } on AttachmentUploadException {
      rethrow;
    } on Object {
      throw const AttachmentUploadException(AttachmentUploadError.transfer);
    }
  }

  /// Releases an unclaimed catalog file without deleting shared content.
  Future<void> discard(String fileId) => discardFile(workspaceId, fileId);
}

/// Creates the transport while Riverpod resources are alive, before late
/// upload/discard completions can outlive a composer widget.
final spaceAttachmentUploadServiceProvider =
    Provider.family<SpaceAttachmentUploadService, String>((ref, workspaceId) {
      final proxy = ref.watch(mediaProxyConfigProvider);
      final rpc = ref.watch(rpcClientProvider);
      return SpaceAttachmentUploadService(
        workspaceId: workspaceId,
        uploadUrl: proxy?.blobUploadUrl(workspaceId: workspaceId) ?? '',
        discardFile: (workspaceId, fileId) async {
          await rpc.call('files.discard', {
            'workspace_id': workspaceId,
            'file_id': fileId,
          });
        },
        post: http.post,
      );
    });
