import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/host/editor_layout_codec.dart';

/// The messaging IDE's [EditorLayoutCodec] configuration.
///
/// The generic codec lives in `shared/editor/host`; this binds it to the
/// messaging tab vocabulary. `fileDiff` carries a non-primitive `PrFile` and
/// `review` is anchored to a transient working-tree changeset, so neither
/// round-trips — both are dropped on encode. Restored terminal/browser tabs
/// come back blank (their live state is never persisted).
const EditorLayoutCodec messagingLayoutCodec = EditorLayoutCodec(
  restorableKinds: {
    MessagingTabKinds.chat,
    MessagingTabKinds.terminal,
    MessagingTabKinds.browser,
    MessagingTabKinds.codeServer,
    MessagingTabKinds.file,
    MessagingTabKinds.plan,
    // An artifact is a durable, server-held document keyed by id — exactly the
    // kind of tab an operator expects to still be open tomorrow. A deleted one
    // degrades to the pane's "unavailable" state, which is one closeable tab.
    MessagingTabKinds.artifact,
    // A finished run's activity is an audit artifact — cost, tokens, the tool
    // sequence, the failure reason — so it is exactly what an operator reopens
    // the next morning. A run the server has since pruned degrades to the tab's
    // own "no longer available" state, which is one closeable tab; silently
    // dropping it would lose that context on every restart instead.
    MessagingTabKinds.agentActivity,
  },
  dropOnEncode: {MessagingTabKinds.fileDiff, MessagingTabKinds.review},
  requiredStringArgs: {
    MessagingTabKinds.chat: ['channelId'],
    MessagingTabKinds.codeServer: ['channelId'],
    MessagingTabKinds.file: ['repoId', 'path'],
    MessagingTabKinds.plan: ['planKind', 'planId'],
    MessagingTabKinds.artifact: ['workspaceId', 'workProductId'],
    MessagingTabKinds.agentActivity: ['workspaceId', 'channelId', 'runId'],
  },
  iconFor: MessagingTabKinds.iconFor,
);

/// Serialises [controller]'s tree to a JSON string for the cache.
String encodeEditorLayout(EditorLayoutController controller) =>
    messagingLayoutCodec.encode(controller);

/// Rebuilds an [EditorLayoutController] from [json], or returns null when the
/// payload is missing, malformed, an unknown schema version, or contains no
/// restorable tabs.
EditorLayoutController? decodeEditorLayout(String json) =>
    messagingLayoutCodec.decode(json);
