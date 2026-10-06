import 'package:control_center/features/messaging/presentation/ide/editor/code_server_window_pool.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter_test/flutter_test.dart';

const _kind = 'codeServer';

EditorTab _file(String path, {String space = 's1', String? repo}) => EditorTab(
  kind: _kind,
  label: path,
  args: {'spaceId': space, 'repoId': ?repo, 'path': path},
);

EditorTab _other(String label) => EditorTab(kind: 'chat', label: label);

CodeServerTarget? _targetOf(EditorTab tab) => tab.kind == _kind
    ? CodeServerTarget(
        spaceId: tab.args['spaceId']! as String,
        repoId: tab.args['repoId'] as String?,
        path: tab.args['path'] as String?,
      )
    : null;

class _Harness {
  _Harness(List<EditorTab> tabs) {
    final group = EditorTabGroupController();
    for (final t in tabs) {
      group.insert(group.tabs.length, t);
    }
    group.selectedIndex = 0;
    layout = EditorLayoutController.single(controller: group);
    pool = CodeServerWindowPool(
      targetOf: _targetOf,
      openFile: (worktree, windowId, path, line) async =>
          opens.add('$windowId:$path'),
      closeFile: (worktree, path) async => closes.add(path),
    )..attach(layout);
  }

  late final EditorLayoutController layout;
  late final CodeServerWindowPool pool;
  final opens = <String>[];
  final closes = <String>[];

  EditorTabGroupController get leaf0 =>
      (layout.root is EditorLeafNode
              ? layout.root as EditorLeafNode
              : (layout.root as EditorSplitNode).children.first
                    as EditorLeafNode)
          .controller;

  void select(EditorTab tab) {
    final leafId = layout.leafIdContaining(tab)!;
    layout.focusOrOpenInLeaf(leafId, (t) => identical(t, tab), () => tab);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a tab switch moves the one window and switches its file', () {
    final a = _file('lib/a.dart');
    final b = _file('lib/b.dart');
    final h = _Harness([a, b]);

    final window = h.pool.windowOf(a)!;
    expect(window.boot.path, 'lib/a.dart');
    h.pool.bridgeReady(window, 'w1');
    expect(h.opens, isEmpty, reason: 'the window booted on a.dart');

    h.select(b);
    expect(h.pool.windowOf(b), same(window));
    expect(h.pool.windowOf(a), isNull);
    expect(h.pool.parked, isEmpty);
    expect(h.opens, ['w1:lib/b.dart']);

    h.select(a);
    expect(h.pool.windowOf(a), same(window));
    expect(h.opens, ['w1:lib/b.dart', 'w1:lib/a.dart']);
  });

  test('a switch before the bridge is up waits for it', () {
    final a = _file('lib/a.dart');
    final b = _file('lib/b.dart');
    final c = _file('lib/c.dart');
    final h = _Harness([a, b, c]);
    final window = h.pool.windowOf(a)!;

    h
      ..select(b)
      ..select(c);
    expect(h.opens, isEmpty);

    h.pool.bridgeReady(window, 'w1');
    expect(h.opens, ['w1:lib/c.dart']);
  });

  test('a remounted window re-requests its owner file on the new bridge', () {
    final a = _file('lib/a.dart');
    final b = _file('lib/b.dart');
    final h = _Harness([a, b]);
    final window = h.pool.windowOf(a)!;
    h.pool.bridgeReady(window, 'w1');
    h.select(b);

    h.pool.windowBooting(window);
    expect(window.shownPath, 'lib/a.dart');
    h.pool.bridgeReady(window, 'w2');
    expect(h.opens.last, 'w2:lib/b.dart');
  });

  test(
    'a non-editor tab parks the window and the next editor tab takes it',
    () {
      final a = _file('lib/a.dart');
      final chat = _other('chat');
      final b = _file('lib/b.dart');
      final h = _Harness([a, chat, b]);
      final window = h.pool.windowOf(a)!;

      h.select(chat);
      expect(h.pool.parked, [window]);

      h.select(b);
      expect(h.pool.windowOf(b), same(window));
      expect(h.pool.parked, isEmpty);
    },
  );

  test('side-by-side tabs of one worktree get a window each', () {
    final a = _file('lib/a.dart');
    final b = _file('lib/b.dart');
    final h = _Harness([a]);
    h.layout.openInSplit(h.layout.activeLeafId, b, DropEdge.right);

    final wa = h.pool.windowOf(a)!;
    final wb = h.pool.windowOf(b)!;
    expect(wa, isNot(same(wb)));

    // The right pane switches to a chat: its window parks, and comes back for
    // the next editor tab there.
    final chat = _other('chat');
    final rightLeaf = h.layout.leafIdContaining(b)!;
    h.layout.focusOrOpenInLeaf(rightLeaf, (_) => false, () => chat);
    expect(h.pool.parked, [wb]);

    final c = _file('lib/c.dart');
    h.layout.focusOrOpenInLeaf(rightLeaf, (_) => false, () => c);
    expect(h.pool.windowOf(c), same(wb));
    expect(h.pool.windowOf(a), same(wa));
  });

  test('worktrees never share a window', () {
    final a = _file('lib/a.dart');
    final other = _file('lib/a.dart', space: 's2');
    final h = _Harness([a, other]);
    final wa = h.pool.windowOf(a)!;

    h.select(other);
    final wo = h.pool.windowOf(other)!;
    expect(wo, isNot(same(wa)));
    expect(wo.boot.spaceId, 's2');
    // a's window stays warm for its worktree.
    expect(h.pool.parked, [wa]);
  });

  test('closing a tab closes its file unless another tab still shows it', () {
    final a = _file('lib/a.dart');
    final b = _file('lib/b.dart');
    final b2 = _file('lib/b.dart');
    final h = _Harness([a, b, b2]);

    h.layout.closeTabByIdentity(b);
    expect(h.closes, isEmpty);
    h.layout.closeTabByIdentity(b2);
    expect(h.closes, ['lib/b.dart']);
  });

  test('a worktree with no tab left drops its window', () {
    final a = _file('lib/a.dart');
    final chat = _other('chat');
    final h = _Harness([a, chat]);

    h.layout.closeTabByIdentity(a);
    expect(h.pool.windowOf(a), isNull);
    expect(h.pool.parked, isEmpty);
    expect(h.closes, ['lib/a.dart']);
  });

  test('an in-editor navigation needs no open when its tab takes over', () {
    final a = _file('lib/a.dart');
    final h = _Harness([a]);
    final window = h.pool.windowOf(a)!;
    h.pool.bridgeReady(window, 'w1');

    expect(h.pool.ownerOfBridge('w1'), same(a));
    h.pool.noteNavigated('w1', 'lib/target.dart');
    final target = _file('lib/target.dart');
    h.leaf0.openTab(target);

    expect(h.pool.windowOf(target), same(window));
    expect(h.opens, isEmpty);
  });

  test('swapping in another layout closes no files', () {
    final a = _file('lib/a.dart');
    final h = _Harness([a]);
    final next = EditorLayoutController.single();

    h.pool.attach(next);
    expect(h.closes, isEmpty);
    expect(h.pool.windowOf(a), isNull);
  });
}
