import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_browser_tabs.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_conversation_tabs.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_rig_host.dart';
import 'package:control_center/features/messaging/presentation/ide/messaging_ide_tabs.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter_test/flutter_test.dart';

final _l10n = AppLocalizationsEn();

EditorTab _selected(EditorLayoutController layout) {
  final group = layout.activeLeaf.controller;
  return group.tabs[group.selectedIndex];
}

EditorLayoutController _layoutOf(List<EditorTab> tabs) {
  final group = EditorTabGroupController();
  for (final t in tabs) {
    group.insert(group.tabs.length, t);
  }
  return EditorLayoutController.single(controller: group);
}

Conversation _conversation(
  String id, {
  ConversationStatus status = ConversationStatus.active,
}) => Conversation(
  id: id,
  workspaceId: 'ws',
  spaceId: 'space',
  title: 'Conversation $id',
  status: status,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

List<String?> _chatIds(EditorLayoutController layout) => [
  for (final t in layout.allTabs())
    if (t.kind == MessagingTabKinds.chat) t.args['conversationId'] as String?,
];

void main() {
  group('mirrorConversationTabs', () {
    test('opens every active conversation after the standing one', () {
      final layout = _layoutOf([MessagingIdeTabs.chat('space')]);
      addTearDown(layout.dispose);
      final conversations = [
        _conversation('standing'),
        _conversation('a'),
        _conversation('b'),
        _conversation('old', status: ConversationStatus.archived),
      ];

      mirrorConversationTabs(
        layout,
        spaceId: 'space',
        standingId: 'standing',
        conversations: conversations,
        view: IdeConversationView(
          byId: {for (final c in conversations) c.id: c},
          standingId: 'standing',
        ),
      );

      // The seeded no-arg tab already shows the standing conversation.
      expect(_chatIds(layout), [null, 'a', 'b']);
    });

    test('closes a restored tab whose conversation was archived', () {
      final archived = _conversation(
        'gone',
        status: ConversationStatus.archived,
      );
      final layout = _layoutOf([
        MessagingIdeTabs.chat('space'),
        MessagingIdeTabs.chat('space', conversationId: 'gone'),
      ]);
      addTearDown(layout.dispose);
      final view = IdeConversationView(
        byId: {'gone': archived, 'standing': _conversation('standing')},
        standingId: 'standing',
      );
      expect(view.archivedTabs(layout.allTabs()), hasLength(1));

      mirrorConversationTabs(
        layout,
        spaceId: 'space',
        standingId: 'standing',
        conversations: view.byId.values.toList(),
        view: view,
      );

      expect(_chatIds(layout), [null]);
    });
  });

  group('IdeConversationView', () {
    test('a no-arg chat tab names the standing conversation', () {
      final view = IdeConversationView(
        byId: {'s': _conversation('s')},
        standingId: 's',
        busyIds: const {'s'},
      );
      final tab = MessagingIdeTabs.chat('space');
      expect(view.conversationOf(tab)?.id, 's');
      expect(view.chatLabel(tab, _l10n), 'Conversation s');
      expect(view.activityLeading(tab), isNotNull);
      expect(view.conversationOf(MessagingIdeTabs.newTerminal()), isNull);
    });

    test('an unresolved chat tab keeps its own label and no mark', () {
      const view = IdeConversationView();
      final tab = MessagingIdeTabs.chat('space', title: 'Draft');
      expect(view.chatLabel(tab, _l10n), 'Draft');
      expect(view.activityLeading(tab), isNull);
      expect(view.isScrambling(tab), isFalse);
    });
  });

  group('focusIdeTabByKey', () {
    test('the space key and the standing conversation key are one tab', () {
      final seeded = MessagingIdeTabs.chat('space');
      final other = MessagingIdeTabs.chat('space', conversationId: 'a');
      final layout = _layoutOf([seeded, other]);
      addTearDown(layout.dispose);
      final view = IdeConversationView(
        byId: {'s': _conversation('s'), 'a': _conversation('a')},
        standingId: 's',
      );
      final opened = <String>[];

      focusIdeTabByKey(
        layout,
        MessagingTabKinds.chatTabKey('s'),
        spaceId: 'space',
        view: view,
        openConversation: (_, id) => opened.add(id),
      );

      expect(_selected(layout), same(seeded));
      expect(opened, isEmpty);
    });

    test('a closed conversation reopens; an archived one does not', () {
      final layout = _layoutOf([MessagingIdeTabs.chat('space')]);
      addTearDown(layout.dispose);
      final view = IdeConversationView(
        byId: {
          'a': _conversation('a'),
          'old': _conversation('old', status: ConversationStatus.archived),
        },
        standingId: 's',
      );
      final opened = <String>[];
      void focus(String key) => focusIdeTabByKey(
        layout,
        key,
        spaceId: 'space',
        view: view,
        openConversation: (_, id) => opened.add(id),
      );

      focus(MessagingTabKinds.chatTabKey('a'));
      focus(MessagingTabKinds.chatTabKey('old'));
      focus(MessagingTabKinds.chatTabKey('unknown'));

      expect(opened, ['a']);
    });
  });

  group('IdeBrowserTabs', () {
    test('ids are stable, numbered and pruned with their tabs', () {
      final first = MessagingIdeTabs.newBrowser(_l10n);
      final second = MessagingIdeTabs.newBrowser(_l10n);
      final layout = _layoutOf([first, MessagingIdeTabs.newTerminal(), second]);
      addTearDown(layout.dispose);
      final tabs = IdeBrowserTabs(layout: () => layout);

      final mirrors = tabs.sync(_l10n);
      expect(mirrors, hasLength(2));
      expect(mirrors[0].label, first.label);
      expect(mirrors[1].label, _l10n.rigLabelNumbered(second.label, '2'));
      expect(tabs.sync(_l10n).map((m) => m.tabId), mirrors.map((m) => m.tabId));

      tabs.close(mirrors[0].tabId);
      final after = tabs.sync(_l10n);
      expect(after.single.tabId, mirrors[1].tabId);
    });

    test('a stale row opens a fresh browser', () {
      final layout = _layoutOf([MessagingIdeTabs.newTerminal()]);
      addTearDown(layout.dispose);
      IdeBrowserTabs(layout: () => layout).focus('ide-browser-404', _l10n);
      expect(
        layout.allTabs().where((t) => t.kind == MessagingTabKinds.browser),
        hasLength(1),
      );
    });
  });

  group('IdeRigHost', () {
    const chromium = RigTabTarget(
      RigTabSurfaces.browser,
      engine: RigBrowserEngine.chromium,
    );

    test('a machine row focuses its own tab, never the one beside it', () {
      final layout = _layoutOf([MessagingIdeTabs.chat('space')]);
      addTearDown(layout.dispose);
      final rigs = IdeRigHost(layout: () => layout);

      rigs.focusOrOpen(_l10n, chromium);
      final opened = layout.allTabs().last;
      expect(opened.kind, MessagingTabKinds.rig);
      expect(opened.args, chromium.args);

      // Focus the chat, then ask for the machine again: no second tab.
      layout.focusTab((t) => t.kind == MessagingTabKinds.chat);
      rigs.focusOrOpen(_l10n, chromium);
      expect(layout.allTabs(), hasLength(2));
      expect(_selected(layout), same(opened));

      // `[+]` asks for one not open yet: the next slot.
      final next = rigs.nextTarget(chromium);
      expect(next.slotId, isNotNull);
      rigs.focusOrOpen(_l10n, next);
      expect(layout.allTabs(), hasLength(3));
    });

    test('a browser rig tab leads with its engine; others do not', () {
      final rig = IdeRigHost.tabFor(_l10n, chromium);
      expect(IdeRigHost.leadingFor(rig), isNotNull);
      expect(IdeRigHost.trailingFor(rig), isNotNull);
      final chat = MessagingIdeTabs.chat('space');
      expect(IdeRigHost.leadingFor(chat), isNull);
      expect(IdeRigHost.trailingFor(chat), isNull);
    });
  });
}
