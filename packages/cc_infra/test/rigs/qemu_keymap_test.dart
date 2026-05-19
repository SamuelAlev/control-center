import 'package:cc_infra/src/rigs/qemu_keymap.dart';
import 'package:test/test.dart';

void main() {
  group('qemuKeysFor', () {
    test('plain characters map to their qcode', () {
      expect(qemuKeysFor('a'), ['a']);
      expect(qemuKeysFor('5'), ['5']);
      expect(qemuKeysFor('-'), ['minus']);
    });

    test('uppercase letters carry shift', () {
      expect(qemuKeysFor('A'), ['shift', 'a']);
    });

    test('shifted symbols carry shift and the base key', () {
      // The regression this pins: '!' had no mapping at all, so half of
      // shell syntax ("echo $PATH | grep …") could not be typed into a rig —
      // by an agent or by a human in take-over.
      expect(qemuKeysFor('!'), ['shift', '1']);
      expect(qemuKeysFor(r'$'), ['shift', '4']);
      expect(qemuKeysFor('_'), ['shift', 'minus']);
      expect(qemuKeysFor('+'), ['shift', 'equal']);
      expect(qemuKeysFor('|'), ['shift', 'backslash']);
      expect(qemuKeysFor('"'), ['shift', 'apostrophe']);
      expect(qemuKeysFor('?'), ['shift', 'slash']);
      expect(qemuKeysFor('~'), ['shift', 'grave_accent']);
    });

    test('a literal space maps to the space bar', () {
      // The regression this pins: `qemuKeysFor` trimmed its argument first, so
      // ' ' became '' and returned null — no string containing a space could
      // be typed into a rig by an agent or by a human in take-over.
      expect(qemuKeysFor(' '), ['spc']);
    });

    test('named keys are case-insensitive', () {
      expect(qemuKeysFor('Return'), ['ret']);
      expect(qemuKeysFor('BackSpace'), ['backspace']);
      expect(qemuKeysFor('Page_Up'), ['pgup']);
    });
  });

  group('qemuComboFor', () {
    test('modifier chords translate whole', () {
      expect(qemuComboFor('ctrl+s'), ['ctrl', 's']);
      expect(qemuComboFor('ctrl+shift+t'), ['ctrl', 'shift', 't']);
      expect(qemuComboFor('super+Left'), ['meta_l', 'left']);
    });

    test('an unknown component refuses the whole chord', () {
      expect(qemuComboFor('hyper+s'), isNull);
    });
  });

  group('planQemuTyping', () {
    test('a representable string becomes one chord per character', () {
      final plan = planQemuTyping('Hi!');
      expect(plan.isTypeable, isTrue);
      expect(plan.unsupported, isEmpty);
      expect(plan.chords, [
        ['shift', 'h'],
        ['i'],
        ['shift', '1'],
      ]);
    });

    test('newlines and tabs become their own keys', () {
      expect(planQemuTyping('a\nb\tc').chords, [
        ['a'],
        ['ret'],
        ['b'],
        ['tab'],
        ['c'],
      ]);
    });

    test('CRLF is one Return, not two', () {
      expect(planQemuTyping('a\r\nb').chords, [
        ['a'],
        ['ret'],
        ['b'],
      ]);
    });

    test('an unrepresentable character plans NOTHING', () {
      // The regression this pins: typing used to send every representable
      // character and then throw for the rest, so the model read "it failed"
      // with half the string already in the field, retried, and doubled it.
      final plan = planQemuTyping('hello 🌍 world');
      expect(plan.isTypeable, isFalse);
      expect(plan.unsupported, ['🌍']);
      expect(
        plan.chords,
        isEmpty,
        reason: 'All-or-nothing: a partial send is what causes double-typing.',
      );
    });

    test('unsupported characters are listed once, in order', () {
      final plan = planQemuTyping('日本 🌍 日本');
      expect(plan.unsupported, ['日', '本', '🌍']);
    });

    test('an empty string is typeable and sends nothing', () {
      final plan = planQemuTyping('');
      expect(plan.isTypeable, isTrue);
      expect(plan.chords, isEmpty);
    });
  });

  group('named punctuation that needs shift', () {
    // A named key resolves to ONE qcode, which is the UNSHIFTED key. So
    // `plus` sent `equal` and typed `=` — quietly, visible only as the wrong
    // character appearing in the guest.
    test('plus sends shift+equal, not a bare equal', () {
      expect(qemuKeysFor('plus'), ['shift', 'equal']);
      expect(qemuKeysFor('equal'), ['equal']);
    });

    test('the rest of the shifted punctuation family carries shift too', () {
      expect(qemuKeysFor('colon'), ['shift', 'semicolon']);
      expect(qemuKeysFor('question'), ['shift', 'slash']);
      expect(qemuKeysFor('underscore'), ['shift', 'minus']);
      expect(qemuKeysFor('bar'), ['shift', 'backslash']);
      expect(qemuKeysFor('asciitilde'), ['shift', 'grave_accent']);
    });

    test('their unshifted partners stay unshifted', () {
      expect(qemuKeysFor('semicolon'), ['semicolon']);
      expect(qemuKeysFor('slash'), ['slash']);
      expect(qemuKeysFor('minus'), ['minus']);
      expect(qemuKeysFor('backslash'), ['backslash']);
      expect(qemuKeysFor('grave'), ['grave_accent']);
    });
  });
}
