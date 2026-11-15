import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_conversation_tabs.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_rig_host.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_terminal_sessions.dart';
import 'package:control_center/features/messaging/presentation/ide/messaging_ide_tabs.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_group.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/attachments/attachment_preview_pane.dart'
    show attachmentIconForName;
import 'package:flutter/widgets.dart';

/// The messaging chrome injected into the shared editor: kind icons, live
/// labels and activity marks, the close guard, the per-tab context menu, the
/// `[+]` new-tab menu ([messagingNewTabMenu]) and the sidebar toggle.
EditorChrome messagingIdeChrome({
  required AppLocalizations l10n,
  required IdeConversationView conversations,
  required IdeTerminalSessions terminals,
  required bool Function(EditorTab tab) isDirty,
  required Future<bool> Function(EditorTab tab) confirmClose,
  required List<CcMenuItem> Function(EditorTab tab) contextMenuExtras,
  required List<CcMenuItem> Function(String leafId) newTabMenuItems,
  required VoidCallback onUntitledDraft,
  required VoidCallback onToggleSidebar,
  required bool sidebarVisible,
}) => EditorChrome(
  // A thread's chat tab gets the branch glyph the conversation switcher
  // uses, so the badge reads the same in both places.
  iconFor: (tab) {
    if (conversations.isThreadTab(tab)) {
      return AppIcons.gitBranch;
    }
    // Kind-only maps cannot see a rig's surface, so they paint every machine
    // as a desktop. The surface lives in args — the same place the `[+]` menu
    // already looked when it opened the tab.
    if (tab.kind == MessagingTabKinds.rig) {
      return RigTabSurfaces.iconForArgs(tab.args);
    }
    // Same for an attachment: a pasted .txt is not a picture. The file name
    // rides in the persisted args, so a restored layout gets it right too.
    if (tab.kind == MessagingTabKinds.attachment) {
      return attachmentIconForName(tab.args['label'] as String?);
    }
    return MessagingTabKinds.iconFor(tab.kind);
  },
  leadingFor: (tab) =>
      conversations.activityLeading(tab) ?? IdeRigHost.leadingFor(tab),
  trailingFor: IdeRigHost.trailingFor,
  // A terminal with a live title — an OSC 0/2 the shell set, or the
  // server-polled foreground process ("pnpm dev serve") — shows that instead
  // of its default label: wezterm/ghostty/iTerm tab behaviour.
  labelFor: (tab) => switch (tab.kind) {
    MessagingTabKinds.terminal => terminals.label(tab, l10n),
    MessagingTabKinds.chat => conversations.chatLabel(tab, l10n),
    _ => tab.label,
  },
  scramblingFor: conversations.isScrambling,
  dirtyFor: isDirty,
  confirmClose: confirmClose,
  tabContextMenuExtras: contextMenuExtras,
  onUntitledDraft: onUntitledDraft,
  onToggleSidebar: onToggleSidebar,
  sidebarVisible: sidebarVisible,
  newTabMenuItems: newTabMenuItems,
);

/// The `[+]` menu of pane [leafId]: a new conversation, the host tools
/// (terminal, web browser) and the machines the connected server can boot.
///
/// [openNextFrame] opens a tab once the menu's overlay has torn down;
/// [onNewConversation] creates and opens the next conversation. [spaceId] is
/// the conversation the IDE shows (entries that need one are disabled
/// without it).
List<CcMenuItem> messagingNewTabMenu({
  required AppLocalizations l10n,
  required String leafId,
  required String? spaceId,
  required IdeRigCapabilities capabilities,
  required IdeRigHost rigs,
  required bool Function() mounted,
  required void Function(String leafId, EditorTab tab) openNextFrame,
  required VoidCallback onNewConversation,
}) => [
  // Conversations are tabs and every one of them opens with the space, so
  // there is no "Open chat" entry — only the affordance to create the next
  // conversation. First in the menu: the conversation is the surface every
  // other entry opens something beside.
  CcMenuItem(
    label: l10n.newConversation,
    icon: AppIcons.messagesSquare,
    enabled: spaceId != null,
    onSelected: onNewConversation,
  ),
  // Deliberately ABOVE the first heading rather than inside a group of its
  // own: it is the one row that makes the thing the others open something
  // beside, and a one-row section would be a heading pretending to organize.
  CcMenuItem.section(l10n.ideMenuSectionTools),
  CcMenuItem(
    label: l10n.terminal,
    icon: AppIcons.terminal,
    onSelected: () => openNextFrame(leafId, MessagingIdeTabs.newTerminal()),
  ),
  CcMenuItem(
    label: MessagingIdeTabs.browserLabel(l10n),
    icon: AppIcons.globe,
    onSelected: () => openNextFrame(leafId, MessagingIdeTabs.newBrowser(l10n)),
  ),
  const CcMenuItem.divider(),
  // The heading is what lets every row under it drop the "(VM)" its label
  // used to carry, and it puts the in-app webview (above) and a browser rig
  // in visibly different groups.
  CcMenuItem.section(l10n.ideMenuSectionMachines),
  // A shell inside the conversation's enclosed VM. Offered only when the
  // connected server can actually host one (QEMU + the exec image); otherwise
  // the entry would be a button whose only outcome is an error three minutes
  // later.
  if (capabilities.hostsVmTerminals)
    CcMenuItem(
      label: l10n.terminal,
      icon: AppIcons.terminal,
      searchText: RigTabSurfaces.menuSearchKeywords(l10n),
      enabled: spaceId != null,
      onSelected: () => openNextFrame(
        leafId,
        MessagingIdeTabs.newTerminal(backend: 'microvm'),
      ),
    ),
  // One entry per machine an agent can drive, and one per BROWSER: a rig runs
  // exactly one engine for its whole life, so which browser is a choice made
  // here or not at all. Scoped to this conversation, so the tab and the
  // agent's `computer_use` / `browser_use` / `mobile_use` / `ios_use` calls
  // address the same default machine.
  for (final kind in RigTabSurfaces.targets(
    capabilities.browserEngines,
    advertisedSurfaces: capabilities.surfaces,
  ))
    rigs.menuItem(
      l10n,
      leafId,
      kind,
      enabled: spaceId != null,
      mounted: mounted,
    ),
];
