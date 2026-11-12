import 'dart:async';

import 'package:cc_server_core/src/catalog/reemit_on.dart';
import 'package:test/test.dart';

/// A watch whose frames carry a value computed while rendering sends its
/// latest rows again when that value changes.
void main() {
  late StreamController<List<String>> rows;
  late StreamController<Object?> trigger;

  setUp(() {
    rows = StreamController<List<String>>();
    trigger = StreamController<Object?>.broadcast();
  });

  tearDown(() async {
    await trigger.close();
  });

  test('sends the latest rows again each time the trigger fires', () async {
    final seen = <List<String>>[];
    final sub = reemitOn(rows.stream, trigger.stream).listen(seen.add);
    addTearDown(sub.cancel);

    rows.add(['a']);
    await pumpEventQueue();
    trigger.add(null);
    await pumpEventQueue();
    rows.add(['a', 'b']);
    await pumpEventQueue();
    trigger.add(null);
    await pumpEventQueue();

    expect(seen, [
      ['a'],
      ['a'],
      ['a', 'b'],
      ['a', 'b'],
    ]);
  });

  test(
    'sends nothing for a trigger that fires before the first rows',
    () async {
      final seen = <List<String>>[];
      final sub = reemitOn(rows.stream, trigger.stream).listen(seen.add);
      addTearDown(sub.cancel);

      trigger.add(null);
      await pumpEventQueue();

      expect(seen, isEmpty);
    },
  );

  test('ends with the source and stops listening to the trigger', () async {
    final done = Completer<void>();
    reemitOn(rows.stream, trigger.stream).listen((_) {}, onDone: done.complete);

    await rows.close();
    await done.future;

    expect(trigger.hasListener, isFalse);
  });

  test('cancelling stops both subscriptions', () async {
    final sub = reemitOn(rows.stream, trigger.stream).listen((_) {});
    await pumpEventQueue();
    expect(trigger.hasListener, isTrue);

    await sub.cancel();

    expect(trigger.hasListener, isFalse);
    expect(rows.hasListener, isFalse);
  });

  test('without a trigger it is the source', () {
    final source = rows.stream;
    expect(reemitOn(source, null), same(source));
  });
}
