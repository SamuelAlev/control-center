import 'package:control_center/core/providers/cache_for.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ttl = Duration(minutes: 5);

  late int builds;
  late int disposals;
  late Provider<int> provider;

  setUp(() {
    builds = 0;
    disposals = 0;
    provider = Provider.autoDispose<int>((ref) {
      ref
        ..cacheFor(ttl)
        ..onDispose(() => disposals++);
      return ++builds;
    });
  });

  test('a listener returning inside the window gets the held value', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.listen(provider, (_, _) {}).close();
      async.elapse(ttl - const Duration(seconds: 1));

      expect(container.read(provider), 1);
      expect(builds, 1);
      expect(disposals, 0);
    });
  });

  test('the value is released once the window passes unwatched', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.listen(provider, (_, _) {}).close();
      async
        ..elapse(ttl + const Duration(seconds: 1))
        ..flushMicrotasks();

      expect(disposals, 1);
      expect(container.read(provider), 2);
    });
  });

  test('the window counts from the last listener leaving, not the build', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sub = container.listen(provider, (_, _) {});
      async.elapse(ttl * 2);
      sub.close();
      async
        ..elapse(ttl - const Duration(seconds: 1))
        ..flushMicrotasks();

      expect(disposals, 0);
      expect(container.read(provider), 1);
    });
  });

  test('a return cancels the countdown', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.listen(provider, (_, _) {}).close();
      async.elapse(ttl - const Duration(seconds: 1));
      final sub = container.listen(provider, (_, _) {});
      async
        ..elapse(ttl * 2)
        ..flushMicrotasks();

      expect(disposals, 0);
      sub.close();
    });
  });
}
