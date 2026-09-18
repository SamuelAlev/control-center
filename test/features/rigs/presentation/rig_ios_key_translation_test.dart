import 'package:control_center/features/rigs/presentation/rig_ios_key_translation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('contained coordinate mapping', () {
    test('maps a portrait simulator through horizontal letterboxing', () {
      expect(
        rigContainedGuestPoint(
          local: const Offset(200, 400),
          canvas: const Size(400, 800),
          guestWidth: 390,
          guestHeight: 844,
        ),
        (195, 422),
      );
      expect(
        rigContainedGuestPoint(
          local: const Offset(5, 400),
          canvas: const Size(400, 800),
          guestWidth: 390,
          guestHeight: 844,
        ),
        isNull,
      );
    });

    test('maps a landscape simulator through vertical letterboxing', () {
      expect(
        rigContainedGuestPoint(
          local: const Offset(400, 200),
          canvas: const Size(800, 400),
          guestWidth: 844,
          guestHeight: 390,
        ),
        (422, 195),
      );
      expect(
        rigContainedGuestPoint(
          local: const Offset(400, 5),
          canvas: const Size(800, 400),
          guestWidth: 844,
          guestHeight: 390,
        ),
        isNull,
      );
    });
  });

  group('pointer gesture translation', () {
    test('movement within eight points is a tap', () {
      expect(
        rigIosGestureAction(
          from: (100, 100),
          to: (106, 105),
          elapsed: const Duration(milliseconds: 700),
        ),
        {
          'action': 'tap',
          'coordinate': [106, 105],
        },
      );
    });

    test('a drag becomes a duration-clamped swipe', () {
      expect(
        rigIosGestureAction(
          from: (10, 20),
          to: (210, 320),
          elapsed: const Duration(milliseconds: 5),
        ),
        {
          'action': 'swipe',
          'from': [10, 20],
          'to': [210, 320],
          'duration_ms': 50,
        },
      );
    });
  });

  test('maps stable WebDriverAgent named keys', () {
    expect(rigIosKeyNameFor(LogicalKeyboardKey.enter), 'enter');
    expect(rigIosKeyNameFor(LogicalKeyboardKey.backspace), 'backspace');
    expect(rigIosKeyNameFor(LogicalKeyboardKey.arrowLeft), 'arrow_left');
  });

  test('maps Flutter modifiers to iOS modifier names', () {
    expect(
      rigIosKeyAction(
        key: LogicalKeyboardKey.keyA,
        character: 'a',
        control: false,
        alt: true,
        meta: true,
        shift: true,
      ),
      {
        'action': 'key',
        'key': 'a',
        'modifiers': ['command', 'option', 'shift'],
      },
    );
  });

  test('leaves unmodified printable text to the coalescer', () {
    expect(
      rigIosKeyAction(
        key: LogicalKeyboardKey.keyA,
        character: 'a',
        control: false,
        alt: false,
        meta: false,
        shift: false,
      ),
      isNull,
    );
  });
}
