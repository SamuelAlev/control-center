import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/host/editor_tab_url_sync.dart';
import 'package:flutter_test/flutter_test.dart';

EditorTab tab(String kind, {String? dedupKey}) =>
    EditorTab(kind: kind, label: kind, dedupKey: dedupKey);

EditorLayoutController layoutWith(List<EditorTab> tabs, {int selected = 0}) {
  final group = EditorTabGroupController();
  for (final t in tabs) {
    group.openTab(t);
  }
  group.selectedIndex = selected;
  return EditorLayoutController.single(controller: group);
}

void main() {
  group('editorTabKey', () {
    test('prefers the dedup key, falls back to the kind', () {
      expect(editorTabKey(tab('chat', dedupKey: 'chat:c1')), 'chat:c1');
      expect(editorTabKey(tab('terminal')), 'terminal');
    });
  });

  group('activeEditorTabKey', () {
    test('returns the selected tab of the active leaf', () {
      final layout = layoutWith([
        tab('chat', dedupKey: 'chat:c1'),
        tab('file', dedupKey: 'file:r1:/a.dart'),
      ], selected: 1);
      expect(activeEditorTabKey(layout), 'file:r1:/a.dart');
    });

    test('is null when the active leaf holds no tabs', () {
      expect(activeEditorTabKey(layoutWith(const [])), isNull);
    });
  });

  group('focusEditorTabByKey', () {
    test('focuses the tab whose key matches', () {
      final layout = layoutWith([
        tab('chat', dedupKey: 'chat:c1'),
        tab('review', dedupKey: 'review:c1:r1'),
      ]);
      expect(focusEditorTabByKey(layout, 'review:c1:r1'), isTrue);
      expect(activeEditorTabKey(layout), 'review:c1:r1');
    });

    test('matches a kind-only key against the first same-kind tab', () {
      final layout = layoutWith([tab('chat'), tab('terminal')]);
      expect(focusEditorTabByKey(layout, 'terminal'), isTrue);
      expect(layout.activeLeaf.controller.selectedIndex, 1);
    });

    test('returns false and keeps the selection on a stale key', () {
      final layout = layoutWith([tab('chat', dedupKey: 'chat:c1')]);
      expect(focusEditorTabByKey(layout, 'chat:gone'), isFalse);
      expect(activeEditorTabKey(layout), 'chat:c1');
    });
  });

  group('locationWithEditorTab', () {
    test('sets the tab param on a bare location', () {
      expect(
        locationWithEditorTab(
          Uri.parse('/workspaces/w1/spaces/c1'),
          'chat:c1',
        ),
        '/workspaces/w1/spaces/c1?tab=chat%3Ac1',
      );
    });

    test('replaces an existing tab param and preserves the others', () {
      expect(
        locationWithEditorTab(
          Uri.parse('/workspaces/w1/spaces/c1?m=m9&tab=chat%3Ac1'),
          'terminal',
        ),
        '/workspaces/w1/spaces/c1?m=m9&tab=terminal',
      );
    });

    test('removes the tab param (null key) without a dangling ?', () {
      expect(
        locationWithEditorTab(
          Uri.parse('/workspaces/w1/spaces/c1?tab=chat%3Ac1'),
          null,
        ),
        '/workspaces/w1/spaces/c1',
      );
    });

    test('keeps other params when removing the tab param', () {
      expect(
        locationWithEditorTab(
          Uri.parse('/workspaces/w1/spaces/c1?m=m9&tab=chat%3Ac1'),
          null,
        ),
        '/workspaces/w1/spaces/c1?m=m9',
      );
    });

    test('round-trips keys containing slashes and colons', () {
      const key = 'pr.codeServer:lib/src/main.dart';
      final location = locationWithEditorTab(
        Uri.parse('/workspaces/w1/pull-requests/o/r/42'),
        key,
      );
      expect(Uri.parse(location).queryParameters['tab'], key);
    });
  });

  group('EditorTabUrlTracker', () {
    late List<String?> written;
    late List<String> focused;
    late int defaultFocused;

    EditorTabUrlTracker tracker({
      String? initialKey,
      void Function(String key)? onFocus,
    }) {
      return EditorTabUrlTracker(
        initialKey: initialKey,
        focusKey: (key) {
          focused.add(key);
          onFocus?.call(key);
        },
        focusDefault: () => defaultFocused++,
        writeKey: written.add,
      );
    }

    setUp(() {
      written = [];
      focused = [];
      defaultFocused = 0;
    });

    test('writes when the focused key diverges, then goes quiet', () {
      final layout = layoutWith([
        tab('chat', dedupKey: 'chat:c1'),
        tab('terminal'),
      ]);
      final t = tracker(initialKey: 'chat:c1');

      layout.activeLeaf.controller.selectedIndex = 1;
      t.writeFromLayout(layout);
      expect(written, ['terminal']);
      expect(t.lastKey, 'terminal');

      // No divergence → no duplicate navigation.
      t.writeFromLayout(layout);
      expect(written, ['terminal']);
    });

    test('apply focuses the named tab without navigating', () {
      final layout = layoutWith([tab('chat'), tab('terminal')]);
      final t = tracker();

      t.apply(layout, 'terminal');
      expect(focused, ['terminal']);
      expect(t.lastKey, 'terminal');
      expect(written, isEmpty);
    });

    test(
      'apply suppresses the reentrant write its synchronous notify triggers',
      () {
        final layout = layoutWith([
          tab('chat', dedupKey: 'chat:c1'),
          tab('terminal'),
        ]);
        late EditorTabUrlTracker t;
        t = tracker(
          onFocus: (key) {
            // Simulate the host: focus mutates the layout, the listener fires
            // SYNCHRONOUSLY and calls writeFromLayout mid-apply.
            focusEditorTabByKey(layout, key);
            t.writeFromLayout(layout);
          },
        );

        t.apply(layout, 'terminal');
        expect(written, isEmpty);
        expect(t.lastKey, 'terminal');
        // …and a LATER write still works (the guard released).
        t.writeFromLayout(layout);
        expect(written, isEmpty); // already tracked — still quiet.
        layout.activeLeaf.controller.selectedIndex = 0;
        t.writeFromLayout(layout);
        expect(written, ['chat:c1']);
      },
    );

    test('apply with the same key is a no-op', () {
      final layout = layoutWith([tab('chat')]);
      final t = tracker(initialKey: 'chat');
      t.apply(layout, 'chat');
      expect(focused, isEmpty);
      expect(written, isEmpty);
    });

    test('apply(null) focuses the default and resyncs, without navigating', () {
      final layout = layoutWith([tab('overview'), tab('diff')], selected: 1);
      final t = tracker(initialKey: 'diff');

      t.apply(layout, null);
      expect(defaultFocused, 1);
      expect(written, isEmpty);
      // Resynced to the layout's focus (still 'diff' — the fake focusDefault
      // doesn't mutate), so no spurious write follows.
      expect(t.lastKey, 'diff');
      t.writeFromLayout(layout);
      expect(written, isEmpty);
    });

    test('force apply re-focuses even when the key matches', () {
      final layout = layoutWith([tab('chat'), tab('terminal')]);
      final t = tracker(initialKey: 'terminal');
      t.apply(layout, 'terminal', force: true);
      expect(focused, ['terminal']);
      expect(written, isEmpty);
    });

    test('force apply(null) resyncs to a replaced tab set', () {
      // Conversation switch: the tracker still holds space A's key while
      // the layout now focuses space B's chat tab.
      final layout = layoutWith([tab('chat', dedupKey: 'chat:b')]);
      final t = tracker(initialKey: 'chat:a');

      t.apply(layout, null, force: true);
      expect(t.lastKey, 'chat:b');
      expect(defaultFocused, 0);
      // A later non-focus layout change must NOT push a spurious entry.
      t.writeFromLayout(layout);
      expect(written, isEmpty);
    });

    test('a null focused key writes a tab-less location', () {
      final layout = layoutWith(const []);
      final t = tracker(initialKey: 'chat:c1');
      t.writeFromLayout(layout);
      expect(written, [null]);
      expect(t.lastKey, isNull);
    });
  });
}
