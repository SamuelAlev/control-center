import 'dart:async';

import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A failure that the composer can explain without exposing transport details.
class AttachmentUploadException implements Exception {
  /// Creates a user-facing failure category without transport details.
  const AttachmentUploadException(this.reason);

  /// Selects the localized explanation on the attachment card.
  final AttachmentUploadError reason;
}

/// Uploads bytes and returns their durable server identity.
typedef UploadComposerAttachment =
    Future<UploadedAttachment> Function(ComposerAttachment attachment);

/// Releases an unclaimed file from the draft's workspace.
typedef DiscardComposerAttachment = Future<void> Function(String fileId);

/// Owns one draft's uploads. An operation retains its own identity so a late
/// completion cannot revive a removed attachment (or a replacement with its id).
class AttachmentUploadController
    extends Notifier<Map<String, ComposerAttachment>> {
  /// Binds one draft to its captured upload and discard operations.
  AttachmentUploadController(this.config);

  /// Transport callbacks captured for this draft's destination.
  final AttachmentUploadConfiguration config;
  final Map<String, Object> _operations = {};
  final Set<String> _readyFileIds = {};
  bool _closed = false;

  @override
  Map<String, ComposerAttachment> build() {
    if (config.retainOnUnmount) {
      ref.keepAlive();
    }
    ref.onDispose(() {
      _closed = true;
      for (final fileId in _readyFileIds) {
        _discardSafely(fileId);
      }
      _readyFileIds.clear();
      _operations.clear();
    });
    return const {};
  }

  /// Starts uploading a newly inserted local attachment.
  void add(ComposerAttachment attachment) {
    if (_closed || state.containsKey(attachment.id)) {
      return;
    }
    _start(attachment);
  }

  /// Retries a failed attachment, keeping its inline reference.
  void retry(String id) {
    if (_closed) {
      return;
    }
    final attachment = state[id];
    if (attachment?.uploadState != AttachmentUploadState.failed) {
      return;
    }
    _start(attachment!);
  }

  void _start(ComposerAttachment attachment) {
    final operation = Object();
    _operations[attachment.id] = operation;
    state = {
      ...state,
      attachment.id: attachment.copyWith(
        uploadState: AttachmentUploadState.uploading,
      ),
    };
    unawaited(_run(attachment, operation));
  }

  Future<void> _run(ComposerAttachment attachment, Object operation) async {
    try {
      final uploaded = await config.upload(attachment);
      if (!uploaded.isValid) {
        throw const AttachmentUploadException(AttachmentUploadError.transfer);
      }
      if (_closed || !identical(_operations[attachment.id], operation)) {
        _discardSafely(uploaded.fileId);
        return;
      }
      _readyFileIds.add(uploaded.fileId);
      state = {
        ...state,
        attachment.id: attachment.copyWith(
          fileId: uploaded.fileId,
          blobRef: uploaded.blobRef,
          mimeType: uploaded.mediaType,
          sizeBytes: uploaded.bytes,
          uploadState: AttachmentUploadState.ready,
        ),
      };
    } on Object catch (error) {
      if (_closed || !identical(_operations[attachment.id], operation)) {
        return;
      }
      state = {
        ...state,
        attachment.id: attachment.copyWith(
          uploadState: AttachmentUploadState.failed,
          uploadError: error is AttachmentUploadException
              ? error.reason
              : AttachmentUploadError.transfer,
        ),
      };
    }
  }

  /// Removing a draft file discards an uploaded catalog entry, if any.
  void remove(String id) => _forget(id, discard: true);

  /// Sending transfers catalog ownership to the message; never discard it.
  void release(String id) => _forget(id, discard: false);

  void _forget(String id, {required bool discard}) {
    if (_closed) {
      return;
    }
    final attachment = state[id];
    if (attachment == null) {
      return;
    }
    _operations.remove(id);
    if (attachment.fileId != null) {
      _readyFileIds.remove(attachment.fileId);
    }
    state = {...state}..remove(id);
    if (discard && attachment.fileId != null) {
      _discardSafely(attachment.fileId!);
    }
  }

  void _discardSafely(String fileId) {
    // A failed best-effort discard cannot resurrect a removed chip.
    unawaited(
      Future.sync(() => config.discard(fileId)).catchError((Object _) {}),
    );
  }
}

/// Identity of one draft. Callback refreshes after reconnect do not change its
/// provider-family identity or move files into a different destination.
class AttachmentUploadConfiguration {
  /// Captures callbacks that remain usable after the widget is disposed.
  AttachmentUploadConfiguration({
    required this.upload,
    required this.discard,
    this.retainOnUnmount = false,
  });

  /// Transfers a local attachment to the server.
  UploadComposerAttachment upload;

  /// Releases an uploaded file that the user did not send.
  DiscardComposerAttachment discard;

  /// A session-owned draft keeps transfers alive while its input is absent.
  final bool retainOnUnmount;
}

/// Async draft state; retained drafts outlive their mounted composer.
final attachmentUploadControllerProvider = NotifierProvider.autoDispose
    .family<
      AttachmentUploadController,
      Map<String, ComposerAttachment>,
      AttachmentUploadConfiguration
    >(AttachmentUploadController.new);
