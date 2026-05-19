import 'package:cc_domain/features/rigs/domain/value_objects/browser_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/computer_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/mobile_action.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:test/test.dart';

/// Action payloads arrive as model-authored JSON. Parsing is hand-written and
/// total on purpose: a `TypeError` three frames deep teaches the next attempt
/// nothing, while "Missing or invalid argument: coordinate (expected [x, y])"
/// teaches it exactly what to fix.
void main() {
  T parsed<T extends RigAction>(RigActionParse result) {
    expect(result, isA<RigActionParsed>());
    final action = (result as RigActionParsed).action;
    expect(action, isA<T>());
    return action as T;
  }

  String invalid(RigActionParse result) {
    expect(result, isA<RigActionInvalid>());
    return (result as RigActionInvalid).message;
  }

  group('computer actions', () {
    test('the Anthropic click verbs map onto one class', () {
      for (final (verb, button, clicks) in [
        ('left_click', RigMouseButton.left, 1),
        ('right_click', RigMouseButton.right, 1),
        ('middle_click', RigMouseButton.middle, 1),
        ('double_click', RigMouseButton.left, 2),
        ('triple_click', RigMouseButton.left, 3),
      ]) {
        final click = parsed<ComputerClick>(
          ComputerAction.parse({
            'action': verb,
            'coordinate': [10, 20],
          }),
        );
        expect(click.button, button);
        expect(click.clicks, clicks);
        // The verb round-trips, so a wire-compatible vocabulary survives the
        // collapse into fewer classes.
        expect(click.verb, verb);
      }
    });

    test('a float coordinate is accepted', () {
      // Models emit `100.0` routinely; refusing it would be pedantry that
      // costs a whole turn.
      final move = parsed<ComputerMouseMove>(
        ComputerAction.parse({
          'action': 'mouse_move',
          'coordinate': [100.0, 200.0],
        }),
      );
      expect(move.x, 100);
      expect(move.y, 200);
    });

    test('a missing coordinate names the field and its shape', () {
      final message = invalid(ComputerAction.parse({'action': 'mouse_move'}));
      expect(message, contains('coordinate'));
      expect(message, contains('[x, y]'));
    });

    test('an unknown verb lists nothing it cannot do', () {
      expect(
        invalid(ComputerAction.parse({'action': 'teleport'})),
        contains('teleport'),
      );
    });

    test('a missing action enumerates the vocabulary', () {
      final message = invalid(ComputerAction.parse(const {}));
      expect(message, contains('screenshot'));
      expect(message, contains('left_click'));
    });

    test('wait is bounded', () {
      // A long wait means taking a screenshot again later, not blocking a turn
      // for a minute.
      expect(
        invalid(ComputerAction.parse({'action': 'wait', 'duration': 600})),
        contains('0-60'),
      );
    });

    test('set_display refuses an unusable mode and clamps a huge one', () {
      expect(
        invalid(
          ComputerAction.parse({
            'action': 'set_display',
            'width': 100,
            'height': 50,
          }),
        ),
        contains('320x240'),
      );
      final big = parsed<ComputerSetDisplay>(
        ComputerAction.parse({
          'action': 'set_display',
          'width': 8000,
          'height': 5000,
        }),
      );
      expect(big.size.width, lessThanOrEqualTo(2560));
      expect(big.size.height, lessThanOrEqualTo(1600));
    });

    test('screenshots and waits do not mutate the guest', () {
      // The take-over lock lets observation through while a human drives, so
      // this classification is load-bearing rather than cosmetic.
      expect(const ComputerScreenshot().mutatesGuest, isFalse);
      expect(
        const ComputerWait(Duration(seconds: 1)).mutatesGuest,
        isFalse,
      );
      expect(
        const ComputerClick(button: RigMouseButton.left).mutatesGuest,
        isTrue,
      );
    });
  });

  group('browser actions', () {
    test('a relative URL is refused', () {
      expect(
        invalid(BrowserAction.parse({'action': 'navigate', 'url': '/login'})),
        contains('absolute'),
      );
    });

    test('file:// and chrome:// are refused', () {
      for (final url in ['file:///etc/passwd', 'chrome://settings']) {
        final message = invalid(
          BrowserAction.parse({'action': 'navigate', 'url': url}),
        );
        expect(message, contains('not allowed'));
      }
    });

    test('click needs a selector or a coordinate', () {
      expect(
        invalid(BrowserAction.parse({'action': 'click'})),
        contains('selector or coordinate'),
      );
      expect(
        parsed<BrowserClick>(
          BrowserAction.parse({'action': 'click', 'selector': '#go'}),
        ).selector,
        '#go',
      );
    });

    test('fill accepts an empty string as "clear the field"', () {
      final fill = parsed<BrowserFill>(
        BrowserAction.parse({
          'action': 'fill',
          'selector': '#q',
          'text': '',
        }),
      );
      expect(fill.text, isEmpty);
    });

    test('fill rejects a missing text rather than assuming empty', () {
      expect(
        invalid(BrowserAction.parse({'action': 'fill', 'selector': '#q'})),
        contains('text'),
      );
    });

    test('extract defaults to the accessibility tree', () {
      final extract = parsed<BrowserExtract>(
        BrowserAction.parse({'action': 'extract'}),
      );
      expect(extract.kind, BrowserExtractKind.a11y);
      expect(extract.mutatesGuest, isFalse);
    });

    test('history refuses a no-op delta', () {
      expect(
        invalid(BrowserAction.parse({'action': 'history', 'delta': 0})),
        contains('non-zero'),
      );
    });

    test('click takes a button and a click count', () {
      final click = parsed<BrowserClick>(
        BrowserAction.parse({
          'action': 'click',
          'coordinate': [10, 20],
          'button': 'right',
          'click_count': 2,
        }),
      );
      expect(click.button, RigMouseButton.right);
      expect(click.clicks, 2);
      expect(click.summary, contains('Right-clicked'));
    });

    test('an out-of-range click count is refused', () {
      expect(
        invalid(
          BrowserAction.parse({
            'action': 'click',
            'coordinate': [1, 1],
            'click_count': 9,
          }),
        ),
        contains('click_count'),
      );
    });

    test('type carries the text the audit redacts', () {
      final type = parsed<BrowserType>(
        BrowserAction.parse({'action': 'type', 'text': 'hunter2'}),
      );
      expect(type.toJson()['text'], 'hunter2');
      // The redaction keys on a quoted preview; an unquoted summary would
      // leak nothing to strip and the test below would not catch it.
      expect(type.summary, contains('"'));
      expect(
        invalid(BrowserAction.parse({'action': 'type'})),
        contains('text'),
      );
    });

    test('key accepts only known modifiers', () {
      final key = parsed<BrowserKey>(
        BrowserAction.parse({
          'action': 'key',
          'key': 'ArrowLeft',
          'modifiers': ['shift'],
        }),
      );
      expect(key.modifiers, ['shift']);
      expect(key.summary, 'Pressed shift+ArrowLeft');
      expect(
        invalid(
          BrowserAction.parse({
            'action': 'key',
            'key': 'a',
            'modifiers': ['hyper'],
          }),
        ),
        contains('hyper'),
      );
    });

    test('mouse_move needs a coordinate', () {
      final move = parsed<BrowserMouseMove>(
        BrowserAction.parse({
          'action': 'mouse_move',
          'coordinate': [5, 6],
        }),
      );
      expect((move.x, move.y), (5, 6));
      expect(
        invalid(BrowserAction.parse({'action': 'mouse_move'})),
        contains('coordinate'),
      );
    });

    test('the mouse-button halves round-trip their verb', () {
      final down = parsed<BrowserMouseButtonHold>(
        BrowserAction.parse({'action': 'left_mouse_down'}),
      );
      expect(down.pressed, isTrue);
      expect(down.verb, 'left_mouse_down');
      final up = parsed<BrowserMouseButtonHold>(
        BrowserAction.parse({
          'action': 'left_mouse_up',
          'coordinate': [3, 4],
        }),
      );
      expect(up.pressed, isFalse);
      expect((up.x, up.y), (3, 4));
    });

    test('drag needs its destination and takes an optional origin', () {
      expect(
        invalid(BrowserAction.parse({'action': 'drag'})),
        contains('coordinate'),
      );
      final drag = parsed<BrowserDrag>(
        BrowserAction.parse({
          'action': 'drag',
          'start_coordinate': [1, 2],
          'coordinate': [30, 40],
        }),
      );
      expect((drag.fromX, drag.fromY), (1, 2));
      expect((drag.toX, drag.toY), (30, 40));
    });

    test('reload takes an optional hard flag', () {
      expect(parsed<BrowserReload>(
        BrowserAction.parse({'action': 'reload'}),
      ).hard, isFalse);
      expect(parsed<BrowserReload>(
        BrowserAction.parse({'action': 'reload', 'hard': true}),
      ).hard, isTrue);
    });

    test('stop_loading takes no arguments', () {
      expect(
        BrowserAction.parse({'action': 'stop_loading'}),
        isA<RigActionParsed>().having(
          (p) => p.action,
          'action',
          isA<BrowserStopLoading>(),
        ),
      );
    });

    test('wait_for clamps its timeout', () {
      final wait = parsed<BrowserWaitFor>(
        BrowserAction.parse({
          'action': 'wait_for',
          'selector': '#done',
          'timeout_ms': 999999,
        }),
      );
      expect(wait.timeout.inMilliseconds, lessThanOrEqualTo(30000));
    });
  });

  group('mobile actions', () {
    test('friendly key names resolve to Android keycodes', () {
      expect(
        parsed<MobileKey>(
          MobileAction.parse({'action': 'key', 'key': 'back'}),
        ).keycode,
        'KEYCODE_BACK',
      );
      expect(
        parsed<MobileKey>(
          MobileAction.parse({'action': 'key', 'key': 'KEYCODE_TAB'}),
        ).keycode,
        'KEYCODE_TAB',
      );
    });

    test('an unknown key lists the aliases instead of guessing', () {
      final message = invalid(
        MobileAction.parse({'action': 'key', 'key': 'wiggle'}),
      );
      expect(message, contains('wiggle'));
      expect(message, contains('back'));
    });

    test('a malformed package name is refused', () {
      expect(
        invalid(
          MobileAction.parse({'action': 'start_app', 'package': 'not a pkg'}),
        ),
        contains('valid Android package name'),
      );
      expect(
        parsed<MobileStartApp>(
          MobileAction.parse({
            'action': 'start_app',
            'package': 'com.example.app',
          }),
        ).package,
        'com.example.app',
      );
    });

    test('install_apk insists on an apk', () {
      expect(
        invalid(
          MobileAction.parse({'action': 'install_apk', 'path': '/tmp/thing.zip'}),
        ),
        contains('.apk'),
      );
    });

    test('a swipe duration is clamped to something physical', () {
      final swipe = parsed<MobileSwipe>(
        MobileAction.parse({
          'action': 'swipe',
          'from': [0, 0],
          'to': [100, 100],
          'duration_ms': 999999,
        }),
      );
      expect(swipe.duration.inMilliseconds, lessThanOrEqualTo(5000));
    });
  });

  group('surface separation', () {
    test('each parser only knows its own verbs', () {
      // A tap is not a click. Crossing surfaces must fail at the boundary
      // rather than producing an action the wrong driver will refuse later.
      expect(ComputerAction.parse({'action': 'tap'}), isA<RigActionInvalid>());
      expect(
        MobileAction.parse({'action': 'left_click'}),
        isA<RigActionInvalid>(),
      );
      expect(
        BrowserAction.parse({'action': 'ui_dump'}),
        isA<RigActionInvalid>(),
      );
    });
  });
}
