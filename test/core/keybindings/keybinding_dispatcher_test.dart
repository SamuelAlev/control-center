import 'package:control_center/core/constants/keybindings.dart';
import 'package:control_center/core/keybindings/key_stroke.dart';
import 'package:control_center/core/keybindings/keybinding_dispatcher.dart';
import 'package:control_center/core/keybindings/text_input_surface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a dispatcher that neither listens to the hardware keyboard nor
/// observes focus, so its resolution logic can be exercised in isolation
/// via [KeybindingDispatcher.debugDispatchStroke].
KeybindingDispatcher dispatcher(List<Keybinding> bindings) =>
    KeybindingDispatcher(
      bindings: bindings,
      platform: TargetPlatform.macOS,
      observeFocus: false,
      listenToHardwareKeyboard: false,
    );

Keybinding binding(
  String id,
  KeyStroke stroke, {
  String scope = '/x',
  String? when,
}) => Keybinding(
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

  group('textInputFocus probe', () {
    testWidgets('focus inside a TextInputSurface counts as text input', (
      tester,
    ) async {
      final d = KeybindingDispatcher(
        bindings: const [],
        platform: TargetPlatform.macOS,
        listenToHardwareKeyboard: false,
      );
      addTearDown(d.dispose);
      final outside = FocusNode();
      final inSurface = FocusNode();
      addTearDown(outside.dispose);
      addTearDown(inSurface.dispose);

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, _) => Column(
            children: [
              Focus(
                focusNode: outside,
                child: const SizedBox(width: 10, height: 10),
              ),
              // A custom TextInputClient surface (like the xterm terminal):
              // no EditableText anywhere, only the marker.
              TextInputSurface(
                child: Focus(
                  focusNode: inSurface,
                  child: const SizedBox(width: 10, height: 10),
                ),
              ),
            ],
          ),
        ),
      );

      outside.requestFocus();
      await tester.pumpAndSettle();
      expect(d.debugContext['textInputFocus'], isFalse);

      inSurface.requestFocus();
      await tester.pumpAndSettle();
      expect(d.debugContext['textInputFocus'], isTrue);

      outside.requestFocus();
      await tester.pumpAndSettle();
      expect(d.debugContext['textInputFocus'], isFalse);
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
        final clobbersText =
            isBareKey ||
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
          reason:
              '${b.id} can clobber text input but lacks a '
              '!textInputFocus guard',
        );
      }
    });
  });

  group('HardwareKeyboard source', () {
    // The dispatcher observes HardwareKeyboard directly on every platform.
    // These drive real (simulated) key events through that handler rather
    // than `debugDispatchStroke`.
    KeybindingDispatcher webDispatcher(List<Keybinding> bindings) =>
        KeybindingDispatcher(
          bindings: bindings,
          platform: TargetPlatform.macOS,
          observeFocus: false,
        );

    testWidgets('a matching active binding fires and is consumed', (
      tester,
    ) async {
      const cmdK = KeyStroke(LogicalKeyboardKey.keyK, cmd: true);
      final d = webDispatcher([binding('t.k', cmdK)]);
      addTearDown(d.dispose);
      var fired = 0;
      d.registerScope({'t.k': () => fired++});
      await tester.pumpWidget(const SizedBox.shrink());

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.metaLeft,
        platform: 'macos',
      );
      final handled = await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyK,
        platform: 'macos',
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK, platform: 'macos');
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.metaLeft,
        platform: 'macos',
      );

      expect(fired, 1, reason: '⌘K reaches the dispatcher on web');
      expect(handled, isTrue, reason: 'an owned stroke is consumed');
    });

    // macOS derives a printable key's logical key from the character it
    // produces *with Shift applied*: pressing Shift+/ reports
    // `LogicalKeyboardKey.question` (the '?' code point), never `slash`. The
    // cheat-sheet is bound to slash+shift, so without folding the shifted symbol
    // back to its base key the stroke never matches — the key falls through
    // unhandled and macOS rings the system alert ("boop") instead of opening the
    // sheet. The test simulator can't synthesize `question` (it has no macOS
    // keyCode), so the real event is crafted by hand.
    testWidgets('macOS: Shift+/ (reported as question) fires a slash+shift '
        'binding and is consumed', (tester) async {
      const cheat = KeyStroke(LogicalKeyboardKey.slash, shift: true);
      final d = webDispatcher([
        binding('t.cheat', cheat, when: '!textInputFocus'),
      ]);
      addTearDown(d.dispose);
      var fired = 0;
      d.registerScope({'t.cheat': () => fired++});
      await tester.pumpWidget(const SizedBox.shrink());

      // Hold Shift (it has a macOS keyCode, so the simulator can send it) so
      // `HardwareKeyboard.isShiftPressed` reads true when the stroke is built.
      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.shiftLeft,
        platform: 'macos',
      );

      const down = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.slash,
        logicalKey: LogicalKeyboardKey.question,
        timeStamp: Duration.zero,
      );
      final handled = HardwareKeyboard.instance.handleKeyEvent(down);
      HardwareKeyboard.instance.handleKeyEvent(
        const KeyUpEvent(
          physicalKey: PhysicalKeyboardKey.slash,
          logicalKey: LogicalKeyboardKey.question,
          timeStamp: Duration.zero,
        ),
      );
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.shiftLeft,
        platform: 'macos',
      );

      expect(fired, 1, reason: 'the shifted symbol folds back to slash+shift');
      expect(
        handled,
        isTrue,
        reason: 'an owned stroke is consumed → no macOS system alert',
      );
    });

    testWidgets('a matched binding whose handler throws is still consumed', (
      tester,
    ) async {
      // A throwing command must not let the exception escape the
      // HardwareKeyboard callback: an escaped throw is caught by Flutter's key
      // dispatch, which then reports the event unhandled → the macOS boop fires
      // for a key the user did bind. The stroke must still be consumed.
      const cmdK = KeyStroke(LogicalKeyboardKey.keyK, cmd: true);
      final d = webDispatcher([binding('t.k', cmdK)]);
      addTearDown(d.dispose);
      d.registerScope({'t.k': () => throw StateError('boom')});
      await tester.pumpWidget(const SizedBox.shrink());

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.metaLeft,
        platform: 'macos',
      );
      final handled = await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyK,
        platform: 'macos',
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK, platform: 'macos');
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.metaLeft,
        platform: 'macos',
      );

      expect(
        handled,
        isTrue,
        reason: 'a matched-but-throwing binding is still consumed (no boop)',
      );
      // The handler's failure is reported to FlutterError rather than rethrown.
      expect(tester.takeException(), isA<StateError>());
    });

    // macOS rings the system alert ("boop") for every key-down the app
    // reports unhandled — in a Flutter window that is every keypress outside a
    // text field. Unmatched keys are therefore consumed-but-inert on macOS
    // desktop: nothing fires, but the event is marked handled so AppKit stays
    // quiet. Focus-tree Shortcuts and other HardwareKeyboard handlers still
    // receive consumed events (all handlers always run; results are OR'd).
    testWidgets('macOS: an unmatched bare key is consumed but fires nothing '
        '(system-alert silencer)', (tester) async {
      const cmdK = KeyStroke(LogicalKeyboardKey.keyK, cmd: true);
      final d = webDispatcher([binding('t.k', cmdK)]);
      addTearDown(d.dispose);
      var fired = 0;
      d.registerScope({'t.k': () => fired++});
      await tester.pumpWidget(const SizedBox.shrink());

      // Bare 'k' (no command modifier) is not a registered stroke.
      final handled = await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyK,
        platform: 'macos',
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK, platform: 'macos');

      expect(fired, 0, reason: 'unmatched keys never fire a command');
      expect(
        handled,
        isTrue,
        reason: 'consumed so macOS does not ring the system alert',
      );
    });

    testWidgets('macOS: an unmatched ⌘-combo is consumed too (menu Edit/Find '
        'items are text-field-only and would just beep)', (tester) async {
      final d = webDispatcher([]);
      addTearDown(d.dispose);
      await tester.pumpWidget(const SizedBox.shrink());

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.metaLeft,
        platform: 'macos',
      );
      final handled = await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyP,
        platform: 'macos',
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyP, platform: 'macos');
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.metaLeft,
        platform: 'macos',
      );

      expect(
        handled,
        isTrue,
        reason:
            '⌘P matches nothing in-app or in the '
            'menu — silence it instead of beeping',
      );
    });

    testWidgets('macOS: system menu equivalents (⌘Q/⌘H/⌘M) fall through to '
        'the menu bar', (tester) async {
      final d = webDispatcher([]);
      addTearDown(d.dispose);
      await tester.pumpWidget(const SizedBox.shrink());

      for (final key in [
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyH,
        LogicalKeyboardKey.keyM,
      ]) {
        await tester.sendKeyDownEvent(
          LogicalKeyboardKey.metaLeft,
          platform: 'macos',
        );
        final handled = await tester.sendKeyDownEvent(key, platform: 'macos');
        await tester.sendKeyUpEvent(key, platform: 'macos');
        await tester.sendKeyUpEvent(
          LogicalKeyboardKey.metaLeft,
          platform: 'macos',
        );
        expect(
          handled,
          isFalse,
          reason:
              'consuming ⌘${key.keyLabel} would disable '
              'quit/hide/minimize',
        );
      }
    });

    testWidgets('the silencer stays inert while a text field is focused '
        '(native text input needs unhandled events)', (tester) async {
      final d = webDispatcher([]);
      addTearDown(d.dispose);
      await tester.pumpWidget(const SizedBox.shrink());
      d.setContext('textInputFocus', true);

      final handled = await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyX,
        platform: 'macos',
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyX, platform: 'macos');

      expect(
        handled,
        isFalse,
        reason:
            'typing/IME only receive events the framework leaves '
            'unhandled',
      );
    });

    testWidgets('the silencer is macOS-only (other desktops do not beep)', (
      tester,
    ) async {
      final d = KeybindingDispatcher(
        bindings: const [],
        platform: TargetPlatform.linux,
        observeFocus: false,
      );
      addTearDown(d.dispose);
      await tester.pumpWidget(const SizedBox.shrink());

      final handled = await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyX,
        platform: 'linux',
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyX, platform: 'linux');

      expect(handled, isFalse);
    });

    testWidgets('a deactivated binding is neither fired nor consumed', (
      tester,
    ) async {
      const j = KeyStroke(LogicalKeyboardKey.keyJ);
      final d = webDispatcher([binding('t.next', j, when: '!textInputFocus')]);
      addTearDown(d.dispose);
      var fired = 0;
      d.registerScope({'t.next': () => fired++});
      await tester.pumpWidget(const SizedBox.shrink());

      // Simulate a focused text field: the binding deactivates, so its key
      // must reach the field instead of being swallowed.
      d.setContext('textInputFocus', true);
      final handled = await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyJ,
        platform: 'macos',
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyJ, platform: 'macos');

      expect(fired, 0, reason: 'suppressed while typing');
      expect(handled, isFalse, reason: 'the key reaches the text field');
    });

    // Flutter's macOS engine frequently drops the KeyUp of a non-modifier key
    // pressed while ⌘ is held (flutter/flutter#136419), so the next genuine
    // ⌘K press arrives misclassified as a KeyRepeatEvent. macOS suppresses
    // true auto-repeat while ⌘ is held, so such a "repeat" is really a fresh
    // press and MUST fire — this was the "⌘K only works every other time" bug
    // (the old hotkey_manager dispatch swallowed repeats).
    testWidgets('macOS: a ⌘-modified KeyRepeatEvent fires as a fresh press', (
      tester,
    ) async {
      const cmdK = KeyStroke(LogicalKeyboardKey.keyK, cmd: true);
      final d = webDispatcher([binding('t.k', cmdK)]);
      addTearDown(d.dispose);
      var fired = 0;
      d.registerScope({'t.k': () => fired++});
      await tester.pumpWidget(const SizedBox.shrink());

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.metaLeft,
        platform: 'macos',
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK, platform: 'macos');
      expect(fired, 1, reason: 'initial press fires');

      // The engine lost K's KeyUp, so the next real press is a "repeat".
      final handled = await tester.sendKeyRepeatEvent(
        LogicalKeyboardKey.keyK,
        platform: 'macos',
      );
      expect(fired, 2, reason: 'misclassified repeat press fires too');
      expect(handled, isTrue, reason: 'the stroke is still consumed');

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK, platform: 'macos');
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.metaLeft,
        platform: 'macos',
      );
    });

    testWidgets('a bare-key repeat does not machine-gun its action', (
      tester,
    ) async {
      const j = KeyStroke(LogicalKeyboardKey.keyJ);
      final d = webDispatcher([binding('t.next', j)]);
      addTearDown(d.dispose);
      var fired = 0;
      d.registerScope({'t.next': () => fired++});
      await tester.pumpWidget(const SizedBox.shrink());

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyJ, platform: 'macos');
      await tester.sendKeyRepeatEvent(
        LogicalKeyboardKey.keyJ,
        platform: 'macos',
      );
      await tester.sendKeyRepeatEvent(
        LogicalKeyboardKey.keyJ,
        platform: 'macos',
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyJ, platform: 'macos');

      expect(fired, 1, reason: 'held bare key fires once, repeats swallowed');
    });

    // ⌘W closes the active IDE tab. On web this collides with the browser's
    // "close tab" shortcut — which would tear down the whole app — so the
    // stroke MUST be consumed (handled == true → preventDefault on web). The
    // binding is route-gated (not textInputFocus-gated), so it stays active.
    testWidgets('⌘W (ide-close-tab) is consumed on web → browser close-tab '
        'suppressed', (tester) async {
      const cmdW = KeyStroke(LogicalKeyboardKey.keyW, cmd: true);
      final d = webDispatcher([
        binding('msg.ide-close-tab', cmdW, when: "route == '/channels'"),
      ]);
      addTearDown(d.dispose);
      var fired = 0;
      d.registerScope({'msg.ide-close-tab': () => fired++});
      d.setRoute('/channels');
      await tester.pumpWidget(const SizedBox.shrink());

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.metaLeft,
        platform: 'macos',
      );
      final handled = await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyW,
        platform: 'macos',
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyW, platform: 'macos');
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.metaLeft,
        platform: 'macos',
      );

      expect(fired, 1, reason: '⌘W closes the active tab');
      // handled == true → the HardwareKeyboard handler returned true → Flutter
      // maps that to event.preventDefault() on web, so the browser's native
      // close-tab does NOT fire.
      expect(
        handled,
        isTrue,
        reason: '⌘W is consumed → preventDefault on web (no browser close)',
      );
    });
  });

  group('handler survival (clearState regression)', () {
    // `HardwareKeyboard.clearState()` is a test-hermeticity API that detaches
    // EVERY registered key handler. The dispatcher used to call it on window
    // deactivation and on text-field focus, so the first ⌘Tab away (or first
    // focused search field) permanently killed every shortcut in the app —
    // each later press fell through unhandled and rang the macOS system alert
    // ("boop"). The dispatcher now synthesises key-ups via releaseStuckKeys,
    // which clears the same stuck state but keeps handlers attached.
    KeybindingDispatcher liveDispatcher(
      List<Keybinding> bindings, {
      bool observeFocus = false,
    }) => KeybindingDispatcher(
      bindings: bindings,
      platform: TargetPlatform.macOS,
      observeFocus: observeFocus,
    );

    testWidgets('window deactivation keeps the dispatcher attached', (
      tester,
    ) async {
      const cmdK = KeyStroke(LogicalKeyboardKey.keyK, cmd: true);
      final d = liveDispatcher([binding('t.k', cmdK)]);
      addTearDown(d.dispose);
      var fired = 0;
      d.registerScope({'t.k': () => fired++});
      await tester.pumpWidget(const SizedBox.shrink());

      // ⌘Tab away and back — the transition that used to clearState().
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.metaLeft,
        platform: 'macos',
      );
      final handled = await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyK,
        platform: 'macos',
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK, platform: 'macos');
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.metaLeft,
        platform: 'macos',
      );

      expect(fired, 1, reason: '⌘K still fires after a deactivation cycle');
      expect(handled, isTrue, reason: 'still consumed — no macOS system alert');
    });

    testWidgets('focusing a text field keeps the dispatcher attached', (
      tester,
    ) async {
      const cmdK = KeyStroke(LogicalKeyboardKey.keyK, cmd: true);
      // observeFocus: true — the production configuration whose editable-focus
      // branch used to clearState().
      final d = liveDispatcher([binding('t.k', cmdK)], observeFocus: true);
      addTearDown(d.dispose);
      var fired = 0;
      d.registerScope({'t.k': () => fired++});

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            autofocus: true,
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
            cursorColor: const Color(0xFF000000),
            backgroundCursorColor: const Color(0xFF000000),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, focusNode);
      expect(
        d.debugContext['textInputFocus'],
        isTrue,
        reason:
            'precondition: the editable-focus branch (the one that used '
            'to call clearState) has run',
      );

      // ⌘K has no !textInputFocus guard — it must fire even while typing.
      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.metaLeft,
        platform: 'macos',
      );
      final handled = await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyK,
        platform: 'macos',
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK, platform: 'macos');
      await tester.sendKeyUpEvent(
        LogicalKeyboardKey.metaLeft,
        platform: 'macos',
      );

      expect(fired, 1, reason: '⌘K still fires with a text field focused');
      expect(handled, isTrue, reason: 'still consumed — no macOS system alert');
    });

    testWidgets('deactivation releases stuck keys without corrupting later '
        'strokes', (tester) async {
      const j = KeyStroke(LogicalKeyboardKey.keyJ);
      final d = liveDispatcher([binding('t.next', j)]);
      addTearDown(d.dispose);
      var fired = 0;
      d.registerScope({'t.next': () => fired++});
      await tester.pumpWidget(const SizedBox.shrink());

      // Simulate the engine losing ⌘'s KeyUp (flutter/flutter#136419): inject
      // the down directly so HardwareKeyboard believes meta is held forever.
      HardwareKeyboard.instance.handleKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.metaLeft,
          logicalKey: LogicalKeyboardKey.metaLeft,
          timeStamp: Duration.zero,
        ),
      );
      expect(HardwareKeyboard.instance.isMetaPressed, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      expect(
        HardwareKeyboard.instance.physicalKeysPressed,
        isEmpty,
        reason: 'the stuck ⌘ was released on deactivation',
      );

      // Without the release, this bare J would canonicalise as ⌘J and miss.
      final handled = await tester.sendKeyDownEvent(
        LogicalKeyboardKey.keyJ,
        platform: 'macos',
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyJ, platform: 'macos');

      expect(fired, 1, reason: 'bare J matches once the stale ⌘ is gone');
      expect(handled, isTrue);
    });
  });

  group('lifecycle safety', () {
    testWidgets(
      'building the dispatcher during a frame that tears down a focused field '
      'does not throw on a deactivated-ancestor lookup',
      (tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        // Tree A: a focused EditableText, so `primaryFocus` points into it.
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: EditableText(
              autofocus: true,
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
              cursorColor: const Color(0xFF000000),
              backgroundCursorColor: const Color(0xFF000000),
            ),
          ),
        );
        await tester.pump();
        expect(FocusManager.instance.primaryFocus, focusNode);

        KeybindingDispatcher? built;
        // Tree B: a widget that builds the dispatcher in `initState` — mirrors
        // how `keybindingDispatcherProvider` is first read from
        // `_AppShortcutsState.initState`. Swapping the root deactivates tree A's
        // EditableText while B.initState runs and the constructor eagerly probes
        // focus; before the guard this tripped "Looking up a deactivated
        // widget's ancestor is unsafe" and poisoned the provider.
        await tester.pumpWidget(
          _InitStateProbe(onInit: () => built = KeybindingDispatcher()),
        );
        addTearDown(() => built?.dispose());

        expect(tester.takeException(), isNull);
        expect(built, isNotNull);
      },
    );
  });
}

/// Runs [onInit] from `initState`, reproducing the build-phase construction of
/// the dispatcher that `_AppShortcutsState` performs.
class _InitStateProbe extends StatefulWidget {
  const _InitStateProbe({required this.onInit});

  final VoidCallback onInit;

  @override
  State<_InitStateProbe> createState() => _InitStateProbeState();
}

class _InitStateProbeState extends State<_InitStateProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
