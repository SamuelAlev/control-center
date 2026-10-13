import 'package:cc_domain/core/domain/entities/agent_shell_process.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/agent_activity_tab.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/agent_shell_output_tab.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/artifact_tab.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/context_explorer_tab.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/editor_layout_snapshot.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/plan_tab.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/host/editor_layout_codec.dart';
import 'package:control_center/shared/editor/host/editor_tab_url_sync.dart';
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
    test('preserves a split tree and tab kinds/args', () {
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

      final restored = messagingLayoutCodec.decode(
        messagingLayoutCodec.encode(ctl),
      );
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

      final second = _tabsOf(split.children[1]);
      expect(second.single.kind, MessagingTabKinds.browser);
    });

    test('a plan tab survives with its plan identity intact', () {
      final ctl = _single([
        _chat('c'),
        planStudioTab(
          kind: PlanTabKind.document,
          id: 'plan-9',
          label: 'Ship the importer',
        ),
      ]);

      final tabs = _tabsOf(
        messagingLayoutCodec.decode(messagingLayoutCodec.encode(ctl))!.root,
      );
      expect(tabs.map((t) => t.kind), [
        MessagingTabKinds.chat,
        MessagingTabKinds.plan,
      ]);
      expect(tabs.last.args['planKind'], 'document');
      expect(tabs.last.args['planId'], 'plan-9');
      expect(tabs.last.dedupKey, 'plan:document:plan-9');
      expect(tabs.last.label, 'Ship the importer');
    });

    test('an iOS rig restores as start-deferred', () {
      final ctl = _single([
        const EditorTab(
          kind: MessagingTabKinds.rig,
          label: 'iOS Simulator',
          args: {'surface': 'ios', 'slot': 's2'},
        ),
      ]);

      final restored = messagingLayoutCodec.decode(
        messagingLayoutCodec.encode(ctl),
      );
      final tab = restored!.activeLeaf.controller.tabs.single;
      expect(tab.args['surface'], 'ios');
      expect(tab.args['slot'], 's2');
      expect(tab.args[EditorLayoutCodec.deferStartArg], isTrue);
    });
  });

  group('space tab focus', () {
    EditorLayoutController reopen(EditorLayoutController layout) {
      final restored = messagingLayoutCodec.decode(
        messagingLayoutCodec.encode(layout),
      )!;
      addTearDown(restored.dispose);
      return restored;
    }

    const conversation = EditorTab(
      kind: MessagingTabKinds.chat,
      label: 'Second conversation',
      args: {'spaceId': 'space-1', 'conversationId': 'conversation-2'},
      dedupKey: 'chat:conversation-2',
    );
    const terminal = EditorTab(
      kind: MessagingTabKinds.terminal,
      label: 'Terminal',
      dedupKey: 'terminal:one',
    );
    const otherTerminal = EditorTab(
      kind: MessagingTabKinds.terminal,
      label: 'Terminal',
      dedupKey: 'terminal:two',
    );
    const transient = EditorTab(
      kind: MessagingTabKinds.fileDiff,
      label: 'Transient diff',
    );

    test('reopens the last selected conversation, not the standing chat', () {
      final layout = _single([_chat('space-1'), conversation, terminal]);
      addTearDown(layout.dispose);
      layout.activeLeaf.controller.selectedIndex = 1;

      expect(activeEditorTabKey(reopen(layout)), 'chat:conversation-2');
    });

    test('restores the focused terminal pane and each pane selection', () {
      final layout = _single([_chat('space-1'), conversation, terminal]);
      addTearDown(layout.dispose);
      layout.activeLeaf.controller.selectedIndex = 1;
      layout.splitWithTab(
        'leaf-0',
        DropEdge.right,
        const TabDragData(sourceLeafId: 'leaf-0', tabIndex: 2, tab: terminal),
      );
      layout.openInActiveLeaf(otherTerminal);
      layout.activeLeaf.controller.selectedIndex = 0;

      final restored = reopen(layout);
      final split = restored.root as EditorSplitNode;
      expect(restored.activeLeaf, same(split.children[1]));
      expect(activeEditorTabKey(restored), 'terminal:one');
      final first = (split.children.first as EditorLeafNode).controller;
      expect(first.tabs[first.selectedIndex].dedupKey, 'chat:conversation-2');
    });

    test('omitting an earlier transient tab does not shift focus', () {
      final layout = _single([
        _chat('space-1'),
        transient,
        terminal,
        otherTerminal,
      ]);
      addTearDown(layout.dispose);
      layout.activeLeaf.controller.selectedIndex = 2;

      expect(activeEditorTabKey(reopen(layout)), 'terminal:one');
    });

    test('skipping an invalid cached tab does not shift focus', () {
      const payload = '''
        {"v":1,"root":{"t":"leaf","sel":2,"active":true,"tabs":[
          {"kind":"chat","label":"Chat","args":{"spaceId":"space-1"}},
          {"kind":"chat","label":"Invalid","args":{}},
          {"kind":"terminal","label":"Terminal","dedup":"terminal:one"},
          {"kind":"terminal","label":"Terminal","dedup":"terminal:two"}
        ]}}
      ''';
      final restored = messagingLayoutCodec.decode(payload)!;
      addTearDown(restored.dispose);

      expect(activeEditorTabKey(restored), 'terminal:one');
    });

    test('a dropped selection falls back to a surviving tab', () {
      final layout = _single([_chat('space-1'), transient, terminal]);
      addTearDown(layout.dispose);
      layout.activeLeaf.controller.selectedIndex = 1;

      expect(activeEditorTabKey(reopen(layout)), MessagingTabKinds.chat);
    });

    test('an unrestorable focused pane falls back to a populated pane', () {
      final layout = _single([transient, terminal]);
      addTearDown(layout.dispose);
      layout.splitWithTab(
        'leaf-0',
        DropEdge.right,
        const TabDragData(sourceLeafId: 'leaf-0', tabIndex: 1, tab: terminal),
      );
      layout.setActiveLeaf('leaf-0');

      expect(activeEditorTabKey(reopen(layout)), 'terminal:one');
    });

    test('layouts saved without focus still open a usable tab', () {
      const payload = '''
        {"v":1,"root":{"t":"leaf","tabs":[
          {"kind":"chat","label":"Chat","args":{"spaceId":"space-1"}},
          {"kind":"terminal","label":"Terminal","dedup":"terminal:one"}
        ]}}
      ''';
      final restored = messagingLayoutCodec.decode(payload)!;
      addTearDown(restored.dispose);

      expect(activeEditorTabKey(restored), MessagingTabKinds.chat);
    });
  });

  test('command output is scoped, deduplicated, and never restored', () {
    AgentShellProcess process(String workspaceId, String spaceId, String id) =>
        AgentShellProcess(
          pid: 7,
          outputId: id,
          workspaceId: workspaceId,
          spaceId: spaceId,
          agentId: 'agent',
          command: 'echo ready\nsleep 10',
          startedAt: DateTime.utc(2026),
          origin: AgentShellOrigin.cli,
        );
    final a = agentShellOutputTab(
      process: process('ws-1', 'space-1', 'out-1'),
      fallbackLabel: 'Output',
    );
    final repeat = agentShellOutputTab(
      process: process('ws-1', 'space-1', 'out-1'),
      fallbackLabel: 'Output',
    );
    final otherSpace = agentShellOutputTab(
      process: process('ws-1', 'space-2', 'out-1'),
      fallbackLabel: 'Output',
    );
    final otherWorkspace = agentShellOutputTab(
      process: process('ws-2', 'space-1', 'out-1'),
      fallbackLabel: 'Output',
    );
    final otherOutput = agentShellOutputTab(
      process: process('ws-1', 'space-1', 'out-2'),
      fallbackLabel: 'Output',
    );
    expect(a.label, 'echo ready');
    expect(a.dedupKey, repeat.dedupKey);
    expect(a.dedupKey, isNot(otherSpace.dedupKey));
    expect(a.dedupKey, isNot(otherWorkspace.dedupKey));
    expect(a.dedupKey, isNot(otherOutput.dedupKey));
    final layout = _single([_chat('space-1'), a]);
    expect(layout.focusTab((tab) => tab.dedupKey == repeat.dedupKey), isTrue);
    expect(layout.activeLeaf.controller.tabs.length, 2);
    final restored = messagingLayoutCodec.decode(
      messagingLayoutCodec.encode(layout),
    )!;
    expect(_tabsOf(restored.root).map((tab) => tab.kind), [
      MessagingTabKinds.chat,
    ]);
  });

  group('fileDiff omission', () {
    test('fileDiff tabs are dropped but siblings survive', () {
      final ctl = _single([
        _chat('c'),
        const EditorTab(kind: MessagingTabKinds.fileDiff, label: 'diff'),
      ]);
      final restored = messagingLayoutCodec.decode(
        messagingLayoutCodec.encode(ctl),
      )!;
      final tabs = _tabsOf(restored.root);
      expect(tabs.map((t) => t.kind), [MessagingTabKinds.chat]);
    });

    test('a layout with only fileDiff tabs decodes to null', () {
      final ctl = _single([
        const EditorTab(kind: MessagingTabKinds.fileDiff, label: 'diff'),
      ]);
      expect(
        messagingLayoutCodec.decode(messagingLayoutCodec.encode(ctl)),
        isNull,
      );
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

      final restored = messagingLayoutCodec.decode(
        messagingLayoutCodec.encode(ctl),
      )!;
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

      final restored = messagingLayoutCodec.decode(
        messagingLayoutCodec.encode(ctl),
      )!;

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

      final restored = messagingLayoutCodec.decode(
        messagingLayoutCodec.encode(ctl),
      )!;
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
    test('keeps explorers for two conversations distinct after restore', () {
      final first = contextExplorerTab(
        workspaceId: 'ws-1',
        spaceId: 'sp-1',
        conversationId: 'cv-1',
        agentId: 'ag-1',
        label: 'Context',
      );
      final second = contextExplorerTab(
        workspaceId: 'ws-1',
        spaceId: 'sp-1',
        conversationId: 'cv-2',
        agentId: 'ag-1',
        label: 'Context',
      );
      final ctl = _single([first]);
      ctl.openInActiveLeaf(second);
      ctl.openInActiveLeaf(first);
      expect(_tabsOf(ctl.root), hasLength(2));

      final restored = messagingLayoutCodec.decode(
        messagingLayoutCodec.encode(ctl),
      )!;
      final tabs = _tabsOf(restored.root);
      expect(tabs, hasLength(2));
      expect(tabs.map((tab) => tab.dedupKey), [
        'contextExplorer:sp-1:cv-1:ag-1',
        'contextExplorer:sp-1:cv-2:ag-1',
      ]);
      expect(tabs.map((tab) => tab.args['conversationId']), ['cv-1', 'cv-2']);
      expect(tabs.map((tab) => tab.args['workspaceId']), ['ws-1', 'ws-1']);
      expect(tabs.map((tab) => tab.args['spaceId']), ['sp-1', 'sp-1']);
      expect(tabs.map((tab) => tab.args['agentId']), ['ag-1', 'ag-1']);
    });

    test('an older tab missing its conversationId is dropped', () {
      const json =
          '{"v":1,"root":{"t":"leaf","tabs":['
          '{"kind":"contextExplorer","label":"Context","args":'
          '{"workspaceId":"ws-1","spaceId":"sp-1","agentId":"ag-1"}}]}}';

      expect(messagingLayoutCodec.decode(json), isNull);
    });

    test('a tab missing its agentId is dropped', () {
      const json =
          '{"v":1,"root":{"t":"leaf","tabs":['
          '{"kind":"contextExplorer","label":"Context","args":'
          '{"workspaceId":"ws-1","spaceId":"sp-1",'
          '"conversationId":"cv-1"}}]}}';

      expect(messagingLayoutCodec.decode(json), isNull);
    });

    test('a tab missing its workspaceId is dropped', () {
      // The pane refuses to render without a workspace to check against, so a
      // payload without one must not come back as a tab at all.
      const json =
          '{"v":1,"root":{"t":"leaf","tabs":['
          '{"kind":"contextExplorer","label":"Context","args":'
          '{"spaceId":"sp-1","conversationId":"cv-1",'
          '"agentId":"ag-1"}}]}}';

      expect(messagingLayoutCodec.decode(json), isNull);
    });
  });
}
