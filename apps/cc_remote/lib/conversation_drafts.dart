import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_remote/attachments.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Stable identities, never the currently selected workspace or standing stream.
typedef RemoteConversationKey = ({
  String workspaceId,
  String spaceId,
  String conversationId,
});

class DraftAttachment {
  DraftAttachment(this.picked);
  final PickedAttachment picked;
  MessageAttachment? stored;
  Object? error;
  bool uploading = false;
}

/// Session-memory drafts survive navigation, not forgetting a paired server.
class ConversationDraft extends ChangeNotifier {
  final controller = TextEditingController();
  final attachments = <DraftAttachment>[];
  bool sending = false;
  Object? error;
  String? _intentKey;
  String? _intentContent;
  bool? _queueIntent;
  bool _disposed = false;

  bool get ready =>
      !sending &&
      attachments.every((file) => file.stored != null && !file.uploading);

  /// Reuse the same logical mutation key after an ambiguous transport failure.
  String intentKey(String content) {
    if (_intentContent != content) {
      _intentContent = content;
      _intentKey = const Uuid().v4();
      _queueIntent = null;
    }
    return _intentKey ??= const Uuid().v4();
  }

  bool queueForIntent(bool runIsActive) => _queueIntent ??= runIsActive;

  void changed() {
    if (!_disposed) notifyListeners();
  }

  void sent() {
    if (_disposed) return;
    controller.clear();
    attachments.clear();
    _intentKey = null;
    _intentContent = null;
    _queueIntent = null;
    error = null;
    changed();
  }

  @override
  void dispose() {
    _disposed = true;
    controller.dispose();
    super.dispose();
  }
}

final conversationDraftsProvider = Provider((ref) {
  // A new pairing must never inherit bytes or text from the previous server.
  ref.watch(rpcClientProvider.select((client) => client.value));
  final unpaired = ref.watch(
    remoteUiStateProvider.select((state) => state.value?.isNotPaired ?? false),
  );
  if (unpaired) return <RemoteConversationKey, ConversationDraft>{};
  final drafts = <RemoteConversationKey, ConversationDraft>{};
  ref.onDispose(() {
    for (final draft in drafts.values) {
      draft.dispose();
    }
  });
  return drafts;
});
