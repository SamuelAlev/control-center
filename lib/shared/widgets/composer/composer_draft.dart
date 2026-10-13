import 'package:control_center/shared/widgets/composer/attachment_upload_controller.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:flutter/foundation.dart';

/// The unsent content of one composer, owned outside its widget lifecycle.
class ComposerDraft extends ChangeNotifier {
  /// Text and selection, including the attachment reference tokens.
  final controller = ComposerTextController();

  /// Files and server-side references selected for this message.
  final List<ComposerAttachment> attachments = [];

  /// Entity identities that cannot be reconstructed from their display tokens.
  final List<({ResolvedMention mention, String token})> mentions = [];

  /// Stable upload identity; callbacks may refresh after reconnecting.
  AttachmentUploadConfiguration? uploadConfiguration;

  /// Monotonic IDs keep restored picker and paste attachments distinct.
  int nextAttachmentId = 0;

  bool _sending = false;
  bool _disposed = false;

  /// Prevents a remounted composer from submitting the same draft twice.
  bool get sending => _sending;

  /// Whether the owning client session has ended.
  bool get disposed => _disposed;

  /// Changes send state for every mounted view of this draft.
  set sending(bool value) {
    if (_disposed || _sending == value) {
      return;
    }
    _sending = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    controller.dispose();
    super.dispose();
  }
}
