import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/username.dart';
import 'package:cc_domain/core/domain/value_objects/username_check.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/user/username_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> asked;
  late Map<String, Completer<UsernameCheck>> pending;

  UsernameAvailability make({String current = 'sam'}) {
    asked = [];
    pending = {};
    final availability = UsernameAvailability(
      current: current,
      debounce: const Duration(milliseconds: 5),
      check: (handle) {
        asked.add(handle);
        return (pending[handle] = Completer<UsernameCheck>()).future;
      },
    );
    addTearDown(availability.dispose);
    return availability;
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test('the own current name is fine without asking', () async {
    final a = make()..update('  SAM ');
    await settle();
    expect(a.status, UsernameStatus.current);
    expect(a.status.blocksSave, isFalse);
    expect(asked, isEmpty);
  });

  test('the rule answers locally, the server only for a valid name', () async {
    final a = make()..update('x');
    expect(a.status, UsernameStatus.invalid);
    a.update('here');
    expect(a.status, UsernameStatus.reserved);
    await settle();
    expect(asked, isEmpty);

    a.update('Ada');
    expect(a.status, UsernameStatus.checking);
    expect(a.status.blocksSave, isTrue);
    await settle();
    expect(asked, ['ada']);
    pending['ada']!.complete(
      const UsernameCheck(
        available: false,
        normalized: 'ada',
        reason: UsernameRefusal.taken,
      ),
    );
    await settle();
    expect(a.status, UsernameStatus.taken);
    expect(a.normalized, 'ada');
  });

  test('an answer for anything but the latest text is dropped', () async {
    final a = make()..update('first');
    await settle();
    a.update('second');
    pending['first']!.complete(
      const UsernameCheck(available: true, normalized: 'first'),
    );
    await settle();
    expect(a.status, UsernameStatus.checking);
    pending['second']!.complete(
      const UsernameCheck(
        available: false,
        normalized: 'second',
        reason: UsernameRefusal.taken,
      ),
    );
    await settle();
    expect(a.status, UsernameStatus.taken);
  });

  test('a failed check leaves the decision to the save', () async {
    final a = make()..update('newname');
    await settle();
    pending['newname']!.completeError(StateError('offline'));
    await settle();
    expect(a.status, UsernameStatus.unknown);
    expect(a.status.blocksSave, isFalse);
  });

  test('a refused save and a saved name both settle the state', () async {
    final a = make()..update('newname');
    a.refused(UsernameRefusal.taken);
    expect(a.status, UsernameStatus.taken);
    await settle();
    // The debounced check was cancelled by the refusal.
    expect(asked, isEmpty);

    a.saved('newname');
    expect(a.status, UsernameStatus.current);
    a.update('newname');
    expect(a.status, UsernameStatus.current);
  });
}
