import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/attachments/attachment_preview_pane.dart'
    show kAttachmentPreviewTabKind;
import 'package:flutter/widgets.dart';

/// The messaging IDE's editor tab-kind vocabulary — the opaque [EditorTab.kind]
/// strings this feature uses. The shared editor engine never interprets these;
/// only messaging's body builder and snapshot codec do.
// ignore: avoid_classes_with_only_static_members
abstract final class MessagingTabKinds {
  /// The active conversation (chat) surface.
  static const String chat = 'chat';

  /// An interactive sandbox terminal.
  static const String terminal = 'terminal';

  /// An in-app webview browser.
  static const String browser = 'browser';

  /// A live view of an enclosed VM (a rig) the agents in this conversation
  /// drive: a desktop, a headless browser or a phone. The `surface` arg names
  /// which. Distinct from [browser], which is a webview in THIS app rather
  /// than a machine somewhere else.
  static const String rig = 'rig';

  /// An embedded code-server (VS Code in the browser) IDE on the conversation's
  /// isolated worktree.
  static const String codeServer = 'codeServer';

  /// A read-only repo file.
  static const String file = 'file';

  /// A single file's working-tree diff (a changed file).
  static const String fileDiff = 'fileDiff';

  /// A multi-file branch review surface (Zed-style).
  static const String review = 'review';

  /// Plan Studio for one plan (a plan document or an orchestration proposal).
  static const String plan = 'plan';

  /// One published artifact (work product) at full size, with its revisions.
  static const String artifact = 'artifact';

  /// One agent RUN's activity timeline: the ordered tool calls, reasoning, text
  /// and errors it produced, plus its run metadata. One tab per run id.
  ///
  /// The surface a spawned subagent otherwise has nowhere to live: its work
  /// never becomes chat messages, so the conversation cannot show it.
  static const String agentActivity = 'agentActivity';

  /// The context explorer: the full per-category, per-part breakdown of one
  /// agent's context window in a conversation, opened from the context meter.
  static const String contextExplorer = 'contextExplorer';

  /// A preview of one composer attachment — the picture, video, PDF or source
  /// file behind an `@[file:…]` reference in the prompt.
  ///
  /// The constant is OWNED by the shared composer (which is where a preview is
  /// asked for) and merely bound into this vocabulary, so a shared widget never
  /// has to import a feature's presentation layer to name a tab.
  static const String attachment = kAttachmentPreviewTabKind;

  /// Whether [kind] is a heavyweight webview pane (code-server / browser) that
  /// participates in the hidden-webview suspension LRU.
  static bool isWebview(String kind) => kind == codeServer || kind == browser;

  /// Dedup key (and thus `?tab=` URL key) of the chat tab showing
  /// [conversationId]. The one identity scheme for conversation tabs — the
  /// IDE layout builds tabs with it and the global sidebar deep-links with it.
  static String chatTabKey(String conversationId) => 'chat:$conversationId';

  /// Dedup key of the SEEDED chat tab of [spaceId] — the tab that carries no
  /// conversation arg and renders whatever the space's standing conversation
  /// resolves to. Focus-by-key treats it as equivalent to
  /// [chatTabKey] of the standing conversation.
  static String chatSpaceTabKey(String spaceId) => 'chat:space:$spaceId';

  /// The conversation id a [chatTabKey] names, or null for any other key —
  /// including [chatSpaceTabKey], whose `space:<id>` payload is a space id,
  /// not a conversation id.
  static String? conversationIdFromChatTabKey(String key) {
    if (!key.startsWith('chat:') || key.startsWith('chat:space:')) {
      return null;
    }
    return key.substring('chat:'.length);
  }

  /// The tab-strip icon for a messaging [kind].
  static IconData iconFor(String kind) {
    switch (kind) {
      case chat:
        return AppIcons.messageSquareText;
      case terminal:
        return AppIcons.terminal;
      case browser:
        return AppIcons.globe;
      case rig:
        return AppIcons.monitor;
      case codeServer:
        return AppIcons.code;
      case file:
        return AppIcons.fileCode;
      case fileDiff:
        return AppIcons.fileDiff;
      case review:
        return AppIcons.gitCompareArrows;
      case plan:
        return AppIcons.network;
      case artifact:
        return AppIcons.layoutTemplate;
      case agentActivity:
        return AppIcons.activity;
      case contextExplorer:
        return AppIcons.gauge;
      case attachment:
        return AppIcons.image;
      default:
        return AppIcons.fileCode;
    }
  }
}
