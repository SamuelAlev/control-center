import 'package:control_center/core/constants/keybindings.dart';
import 'package:control_center/core/keybindings/key_stroke.dart';
import 'package:control_center/core/keybindings/keybinding_dispatcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a dispatcher that never touches the global `hotkey_manager` and does
/// not observe focus, so its resolution logic can be exercised in isolation
/// via [KeybindingDispatcher.debugDispatchStroke].
KeybindingDispatcher dispatcher(List<Keybinding> bindings) =>
    KeybindingDispatcher(
      bindings: bindings,
      platform: TargetPlatform.macOS,
      registerWithOs: false,
      observeFocus: false,
    );

Keybinding binding(
  String id,
  KeyStroke stroke, {
  String scope = '/x',
  String? when,
}) =>
    Keybinding(
      id: id,
      category: KeybindingCategory.view,
      scope: scope,
      chord: KeyChord([stroke]),
      when: when,
    );

String canon(KeyStroke stroke) => stroke.canonical(TargetPlatform.macOS);

void main() {
  group('single-stroke resolution', () {
    test('fires the handler for a registered, active binding', () {
      const j = KeyStroke(LogicalKeyboardKey.keyJ);
      final d = dispatcher([binding('t.next', j)]);
      var fired = 0;
      d.registerScope({'t.next': () => fired++});

      d.debugDispatchStroke(j);
      expect(fired, 1);
      expect(d.debugRegisteredCanonicals, contains(canon(j)));
    });

    test('a binding with no registered handler is inactive', () {
      const j = KeyStroke(LogicalKeyboardKey.keyJ);
      final d = dispatcher([binding('t.next', j)]);
      // No registerScope call.
      expect(d.debugRegisteredCanonicals, isNot(contains(canon(j))));
      d.debugDispatchStroke(j); // must not throw
    });
  });

  group('when-clause gating', () {
    test('route guard activates/deactivates as context changes', () {
      const j = KeyStroke(LogicalKeyboardKey.keyJ);
      final d = dispatcher([binding('t.next', j, when: "route == '/x'")]);
      var fired = 0;
      d.registerScope({'t.next': () => fired++});

      // No route set yet → inactive.
      expect(d.debugRegisteredCanonicals, isNot(contains(canon(j))));
      d.debugDispatchStroke(j);
      expect(fired, 0);

      d.setRoute('/x');
      expect(d.debugRegisteredCanonicals, contains(canon(j)));
      d.debugDispatchStroke(j);
      expect(fired, 1);

      d.setRoute('/y');
      expect(d.debugRegisteredCanonicals, isNot(contains(canon(j))));
      d.debugDispatchStroke(j);
      expect(fired, 1);
    });

    test('!textInputFocus suppresses a bare key while a field is focused', () {
      const j = KeyStroke(LogicalKeyboardKey.keyJ);
      final d = dispatcher([binding('t.next', j, when: '!textInputFocus')]);
      var fired = 0;
      d.registerScope({'t.next': () => fired++});

      d.debugDispatchStroke(j);
      expect(fired, 1, reason: 'active when nothing is focused');

      d.setContext('textInputFocus', true);
      expect(d.debugRegisteredCanonicals, isNot(contains(canon(j))));
      d.debugDispatchStroke(j);
      expect(fired, 1, reason: 'suppressed while typing');

      d.setContext('textInputFocus', false);
      d.debugDispatchStroke(j);
      expect(fired, 2, reason: 're-activated when focus leaves the field');
    });
  });

  group('priority: most specific scope wins', () {
    test('scoped binding beats a global one on the same stroke', () {
      const cmd1 = KeyStroke(LogicalKeyboardKey.digit1, cmd: true);
      final global = binding('nav', cmd1, scope: 'global');
      final scoped = binding('settings', cmd1, scope: '/settings');
      final d = dispatcher([global, scoped]);

      final hits = <String>[];
      d.registerScope({
        'nav': () => hits.add('nav'),
        'settings': () => hits.add('settings'),
      });

      d.debugDispatchStroke(cmd1);
      expect(hits, ['settings']);

      // Once the scoped handler is gone, the global one wins.
      final partial = dispatcher([global, scoped]);
      final hits2 = <String>[];
      partial.registerScope({'nav': () => hits2.add('nav')});
      partial.debugDispatchStroke(cmd1);
      expect(hits2, ['nav']);
    });
  });

  group('chord sequences', () {
    test('two-stroke chord completes on the second stroke', () {
      const cmdK = KeyStroke(LogicalKeyboardKey.keyK, cmd: true);
      const cmdC = KeyStroke(LogicalKeyboardKey.keyC, cmd: true);
      const chord = Keybinding(
        id: 't.chord',
        category: KeybindingCategory.view,
        scope: '/x',
        chord: KeyChord([cmdK, cmdC]),
      );
      final d = dispatcher([chord]);
      var fired = 0;
      d.registerScope({'t.chord': () => fired++});

      d.debugDispatchStroke(cmdK);
      expect(fired, 0, reason: 'prefix alone does not fire');
      expect(d.debugChordPending, isTrue);

      d.debugDispatchStroke(cmdC);
      expect(fired, 1, reason: 'completing stroke fires the command');
      expect(d.debugChordPending, isFalse);
    });

    test('a single binding on a key fires immediately, no chord wait', () {
      const cmdK = KeyStroke(LogicalKeyboardKey.keyK, cmd: true);
      final single = binding('t.k', cmdK);
      final d = dispatcher([single]);
      var fired = 0;
      d.registerScope({'t.k': () => fired++});

      d.debugDispatchStroke(cmdK);
      expect(fired, 1);
      expect(d.debugChordPending, isFalse);
    });
  });

  group('registry integrity', () {
    test('every binding has a unique id', () {
      final ids = KeybindingRegistry.all.map((b) => b.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every screen-scoped bare-key binding guards text input', () {
      for (final b in KeybindingRegistry.all) {
        final s = b.chord.first;
        final isBareKey = !s.cmd && !s.ctrl && !s.alt;
        // Enter/Backspace with cmd would clobber text editing too.
        final clobbersText = isBareKey ||
            (s.cmd &&
                (s.trigger == LogicalKeyboardKey.backspace ||
                    s.trigger == LogicalKeyboardKey.enter));
        if (b.scope == KeybindingRegistry.globalScope || !clobbersText) {
          continue;
        }
        // msg.send is owned by the composer (fires *while* typing) and is not
        // dispatched, so it is exempt.
        if (b.id == 'msg.send') {
          continue;
        }
        expect(
          b.when ?? '',
          contains('!textInputFocus'),
          reason: '${b.id} can clobber text input but lacks a '
              '!textInputFocus guard',
        );
      }
    });
  });
}
