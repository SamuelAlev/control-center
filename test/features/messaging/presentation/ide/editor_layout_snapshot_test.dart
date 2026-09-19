import 'package:control_center/features/messaging/presentation/ide/editor/agent_activity_tab.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/artifact_tab.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/context_explorer_tab.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/editor_layout_snapshot.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/plan_tab.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/host/editor_layout_codec.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

EditorTab _chat(String spaceId) => EditorTab(
  kind: MessagingTabKinds.chat,
  label: 'Chat',
  args: {'spaceId': spaceId},
);

EditorLayoutController _single(List<EditorTab> tabs) {
  final c = EditorTabGroupController();
  for (final t in tabs) {
    c.insert(c.tabs.length, t);
  }
  return EditorLayoutController.single(controller: c);
}

List<EditorTab> _tabsOf(EditorNode n) => (n as EditorLeafNode).controller.tabs;

void main() {
  group('round-trip', () {
    test(
      'preserves a split tree and tab kinds/args, opening on the first leaf',
      () {
        final chat = _chat('chan-1');
        const term = EditorTab(
          kind: MessagingTabKinds.terminal,
          label: 'Terminal',
        );
        const browser = EditorTab(
          kind: MessagingTabKinds.browser,
          label: 'Browser',
        );
        final ctl = _single([chat, term, browser]);
        // Split the browser into a right pane (now active).
        ctl.splitWithTab(
          'leaf-0',
          DropEdge.bottom,
          const TabDragData(sourceLeafId: 'leaf-0', tabIndex: 2, tab: browser),
        );

        final restored = messagingLayoutCodec.decode(messagingLayoutCodec.encode(ctl));
        expect(restored, isNotNull);

        final root = restored!.root;
        expect(root, isA<EditorSplitNode>());
        final split = root as EditorSplitNode;
        expect(split.axis, Axis.vertical);
        expect(split.children.length, 2);

        // First pane keeps chat + terminal in order.
        final first = _tabsOf(split.children[0]);
        expect(first.map((t) => t.kind), [
          MessagingTabKinds.chat,
          MessagingTabKinds.terminal,
        ]);
        expect(first.first.args['spaceId'], 'chan-1');

        // Second pane is the moved browser — but focus is not persisted, so the
        // restore lands on the FIRST leaf's first tab, not on the pane that was
        // active when the layout was saved.
        final second = _tabsOf(split.children[1]);
        expect(second.single.kind, MessagingTabKinds.browser);
        expect(restored.activeLeaf, same(split.children[0]));
        expect(
          restored
              .activeLeaf
              .controller
              .tabs[restored.activeLeaf.controller.selectedIndex]
              .kind,
          MessagingTabKinds.chat,
        );
      },
    );

    test('a plan tab survives with its plan identity intact', () {
      final ctl = _single([
        _chat('c'),
        planStudioTab(
          kind: PlanTabKind.document,
          id: 'plan-9',
          label: 'Ship the importer',
        ),
      ]);

      final tabs = _tabsOf(messagingLayoutCodec.decode(messagingLayoutCodec.encode(ctl))!.root);
      expect(tabs.map((t) => t.kind), [
        MessagingTabKinds.chat,
        MessagingTabKinds.plan,
      ]);
      expect(tabs.last.args['planKind'], 'document');
      expect(tabs.last.args['planId'], 'plan-9');
      expect(tabs.last.dedupKey, 'plan:document:plan-9');
      expect(tabs.last.label, 'Ship the importer');
    });

    test('does not persist the selection — a restore opens the first tab', () {
      final ctl = _single([
        _chat('c'),
        const EditorTab(kind: MessagingTabKinds.terminal, label: 'Terminal'),
        const EditorTab(kind: MessagingTabKinds.browser, label: 'Browser'),
      ]);
      (ctl.root as EditorLeafNode).controller.selectedIndex = 2;

      final encoded = messagingLayoutCodec.encode(ctl);
      expect(encoded, isNot(contains('"sel"')));
      expect(encoded, isNot(contains('"active"')));

      final restored = messagingLayoutCodec.decode(encoded)!;
      expect((restored.root as EditorLeafNode).controller.selectedIndex, 0);
    });

    test('an iOS rig restores as start-deferred', () {
      final ctl = _single([
        const EditorTab(
          kind: MessagingTabKinds.rig,
          label: 'iOS Simulator',
          args: {'surface': 'ios', 'slot': 's2'},
        ),
      ]);

      final restored = messagingLayoutCodec.decode(messagingLayoutCodec.encode(ctl));
      final tab = restored!.activeLeaf.controller.tabs.single;
      expect(tab.args['surface'], 'ios');
      expect(tab.args['slot'], 's2');
      expect(tab.args[EditorLayoutCodec.deferStartArg], isTrue);
    });
  });

  group('fileDiff omission', () {
    test('fileDiff tabs are dropped but siblings survive', () {
      final ctl = _single([
        _chat('c'),
        const EditorTab(kind: MessagingTabKinds.fileDiff, label: 'diff'),
      ]);
      final restored = messagingLayoutCodec.decode(messagingLayoutCodec.encode(ctl))!;
      final tabs = _tabsOf(restored.root);
      expect(tabs.map((t) => t.kind), [MessagingTabKinds.chat]);
    });

    test('a layout with only fileDiff tabs decodes to null', () {
      final ctl = _single([
        const EditorTab(kind: MessagingTabKinds.fileDiff, label: 'diff'),
      ]);
      expect(messagingLayoutCodec.decode(messagingLayoutCodec.encode(ctl)), isNull);
    });
  });

  group('robust decode', () {
    test('garbage input returns null', () {
      expect(messagingLayoutCodec.decode('not json'), isNull);
      expect(messagingLayoutCodec.decode('{}'), isNull);
      expect(messagingLayoutCodec.decode('{"v": 999, "root": {}}'), isNull);
      expect(messagingLayoutCodec.decode('[]'), isNull);
    });

    test('a chat tab missing its spaceId is dropped', () {
      const json =
          '{"v":1,"root":{"t":"leaf","tabs":['
          '{"kind":"chat","label":"Chat","args":{}}]}}';
      expect(messagingLayoutCodec.decode(json), isNull);
    });
  });

  group('agentActivity restoration', () {
    EditorTab activity({
      String workspaceId = 'ws-1',
      String spaceId = 'c-1',
      String runId = 'run-1',
    }) => agentActivityTab(
      workspaceId: workspaceId,
      spaceId: spaceId,
      runId: runId,
      agentId: 'agent-1',
      label: 'scout',
      fallbackLabel: 'Agent activity',
    );

    test('round-trips the kind, every arg and the dedupe key', () {
      final ctl = _single([activity()]);

      final restored = messagingLayoutCodec.decode(messagingLayoutCodec.encode(ctl))!;
      final tab = _tabsOf(restored.root).single;

      expect(tab.kind, MessagingTabKinds.agentActivity);
      expect(tab.dedupKey, 'agentActivity:run-1');
      expect(tab.args['workspaceId'], 'ws-1');
      expect(tab.args['spaceId'], 'c-1');
      expect(tab.args['runId'], 'run-1');
      expect(tab.args['agentId'], 'agent-1');
      expect(tab.args['label'], 'scout');
    });

    test('survives alongside a dropped fileDiff sibling', () {
      final ctl = _single([
        const EditorTab(kind: MessagingTabKinds.fileDiff, label: 'diff'),
        activity(),
      ]);

      final restored = messagingLayoutCodec.decode(messagingLayoutCodec.encode(ctl))!;

      expect(_tabsOf(restored.root).map((t) => t.kind), [
        MessagingTabKinds.agentActivity,
      ]);
    });

    test('a tab missing its runId is dropped', () {
      const json =
          '{"v":1,"root":{"t":"leaf","tabs":['
          '{"kind":"agentActivity","label":"scout","args":'
          '{"workspaceId":"ws-1","spaceId":"c-1"}}]}}';

      expect(messagingLayoutCodec.decode(json), isNull);
    });

    test('a tab missing its workspaceId is dropped', () {
      const json =
          '{"v":1,"root":{"t":"leaf","tabs":['
          '{"kind":"agentActivity","label":"scout","args":'
          '{"spaceId":"c-1","runId":"run-1"}}]}}';

      expect(messagingLayoutCodec.decode(json), isNull);
    });

    test('a tab missing its spaceId is dropped', () {
      const json =
          '{"v":1,"root":{"t":"leaf","tabs":['
          '{"kind":"agentActivity","label":"scout","args":'
          '{"workspaceId":"ws-1","runId":"run-1"}}]}}';

      expect(messagingLayoutCodec.decode(json), isNull);
    });
  });

  group('artifact restoration', () {
    test('round-trips the kind, its args and the dedupe key', () {
      final ctl = _single([
        artifactTab(
          workspaceId: 'ws-1',
          workProductId: 'wp-1',
          label: 'Rollout plan',
        ),
      ]);

      final restored = messagingLayoutCodec.decode(messagingLayoutCodec.encode(ctl))!;
      final tab = _tabsOf(restored.root).single;

      expect(tab.kind, MessagingTabKinds.artifact);
      expect(tab.dedupKey, 'artifact:wp-1');
      expect(tab.args['workspaceId'], 'ws-1');
      expect(tab.args['workProductId'], 'wp-1');
      expect(tab.label, 'Rollout plan');
    });

    test('a tab missing its workProductId is dropped', () {
      const json =
          '{"v":1,"root":{"t":"leaf","tabs":['
          '{"kind":"artifact","label":"Rollout plan","args":'
          '{"workspaceId":"ws-1"}}]}}';

      expect(messagingLayoutCodec.decode(json), isNull);
    });

    test('a tab missing its workspaceId is dropped', () {
      // The pane refuses to render without a workspace to check against, so a
      // payload without one must not come back as a tab at all.
      const json =
          '{"v":1,"root":{"t":"leaf","tabs":['
          '{"kind":"artifact","label":"Rollout plan","args":'
          '{"workProductId":"wp-1"}}]}}';

      expect(messagingLayoutCodec.decode(json), isNull);
    });
  });

  group('contextExplorer restoration', () {
    test('round-trips the kind, its args and the dedupe key', () {
      final ctl = _single([
        contextExplorerTab(
          workspaceId: 'ws-1',
          spaceId: 'sp-1',
          agentId: 'ag-1',
          label: 'Context',
        ),
      ]);

      final restored = messagingLayoutCodec.decode(messagingLayoutCodec.encode(ctl))!;
      final tab = _tabsOf(restored.root).single;

      expect(tab.kind, MessagingTabKinds.contextExplorer);
      expect(tab.dedupKey, 'contextExplorer:sp-1:ag-1');
      expect(tab.args['workspaceId'], 'ws-1');
      expect(tab.args['spaceId'], 'sp-1');
      expect(tab.args['agentId'], 'ag-1');
      expect(tab.label, 'Context');
    });

    test('a tab missing its agentId is dropped', () {
      const json =
          '{"v":1,"root":{"t":"leaf","tabs":['
          '{"kind":"contextExplorer","label":"Context","args":'
          '{"workspaceId":"ws-1","spaceId":"sp-1"}}]}}';

      expect(messagingLayoutCodec.decode(json), isNull);
    });

    test('a tab missing its workspaceId is dropped', () {
      // The pane refuses to render without a workspace to check against, so a
      // payload without one must not come back as a tab at all.
      const json =
          '{"v":1,"root":{"t":"leaf","tabs":['
          '{"kind":"contextExplorer","label":"Context","args":'
          '{"spaceId":"sp-1","agentId":"ag-1"}}]}}';

      expect(messagingLayoutCodec.decode(json), isNull);
    });
  });
}
