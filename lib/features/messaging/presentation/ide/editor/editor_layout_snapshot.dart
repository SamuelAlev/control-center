import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
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
    // A rig tab restores to its START affordance, never to a running machine:
    // auto-booting one VM per restored tab on every launch would be an
    // expensive surprise for machines nobody has asked for yet.
    MessagingTabKinds.rig,
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
    // A context breakdown is re-derivable from the (space, agent) pair — the
    // explorer re-inspects on restore, so a reopened tab comes back fresh.
    MessagingTabKinds.contextExplorer,
  },
  // An attachment preview is anchored to an in-memory registry entry that a
  // restart does not survive — a dropped picture's bytes were never persisted
  // anywhere. Restoring the tab would reopen it permanently unavailable, so it
  // is dropped instead.
  dropOnEncode: {
    MessagingTabKinds.fileDiff,
    MessagingTabKinds.review,
    MessagingTabKinds.attachment,
  },
  // An ENCLOSED terminal boots a VM on first attach, so a restored one gets
  // the same treatment as a restored rig tab: the badge comes back, the
  // machine does not. Without this, launching the app with three persisted
  // `microvm` terminal tabs booted three VMs before the user touched anything
  // — the "a rig tab never auto-starts, including on layout restore"
  // invariant, defeated through the adjacent terminal path.
  rewriteArgsOnDecode: _deferResourceStart,
  transientArgs: {EditorLayoutCodec.deferStartArg},
  requiredStringArgs: {
    MessagingTabKinds.chat: ['spaceId'],
    MessagingTabKinds.codeServer: ['spaceId'],
    MessagingTabKinds.file: ['repoId', 'path'],
    // A rig tab with no surface has no machine to show.
    MessagingTabKinds.rig: ['surface'],
    MessagingTabKinds.plan: ['planKind', 'planId'],
    MessagingTabKinds.artifact: ['workspaceId', 'workProductId'],
    MessagingTabKinds.agentActivity: ['workspaceId', 'spaceId', 'runId'],
    MessagingTabKinds.contextExplorer: ['workspaceId', 'spaceId', 'agentId'],
  },
  iconFor: MessagingTabKinds.iconFor,
);

/// Stamps a restored machine-bearing tab as "start on demand".
///
/// Every rig surface is deferred, including host-managed simulators. An
/// enclosed terminal is deferred only when it names the microVM backend; a
/// host-shell terminal costs a PTY and still attaches on mount.
Map<String, Object?> _deferResourceStart(
  String kind,
  Map<String, Object?> args,
) =>
    (kind == MessagingTabKinds.rig ||
        (kind == MessagingTabKinds.terminal && args['backend'] == 'microvm'))
    ? {...args, EditorLayoutCodec.deferStartArg: true}
    : args;

