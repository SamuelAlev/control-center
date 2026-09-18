import 'package:control_center/features/messaging/presentation/widgets/visible_conversation_registrar.dart';
import 'package:control_center/features/messaging/providers/visible_conversation_spaces.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VisibleConversationSpaces', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container;
    }

    // acquire/release notify on a microtask so widget-lifecycle callers
    // do not mutate the provider mid-build. Flush it.
    Future<void> flush() => Future<void>.microtask(() {});

    test('starts empty', () {
      final container = makeContainer();
      expect(container.read(visibleConversationSpacesProvider), isEmpty);
    });

    test('acquire publishes the space after a flush', () async {
      final container = makeContainer();
      container.read(visibleConversationSpacesProvider.notifier).acquire('s1');
      expect(container.read(visibleConversationSpacesProvider), isEmpty);

      await flush();
      expect(container.read(visibleConversationSpacesProvider), {'s1'});
    });

    test('release drops a space once its last holder leaves', () async {
      final container = makeContainer();
      final spaces = container.read(visibleConversationSpacesProvider.notifier)
        ..acquire('s1')
        ..acquire('s1');
      await flush();
      expect(container.read(visibleConversationSpacesProvider), {'s1'});

      spaces.release('s1');
      await flush();
      expect(container.read(visibleConversationSpacesProvider), {'s1'});

      spaces.release('s1');
      await flush();
      expect(container.read(visibleConversationSpacesProvider), isEmpty);
    });

    test('empty spaceId is a no-op', () async {
      final container = makeContainer();
      container.read(visibleConversationSpacesProvider.notifier).acquire('');
      await flush();
      expect(container.read(visibleConversationSpacesProvider), isEmpty);
    });
  });

  group('VisibleConversationRegistrar', () {
    Widget host(ProviderContainer container, Widget child) {
      return UncontrolledProviderScope(
        container: container,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Consumer(
            builder: (context, ref, _) {
              // The approval overlay watches this. Mounting a pane used to
              // acquire synchronously here and trip Riverpod's build-phase
              // mutation assert.
              ref.watch(visibleConversationSpacesProvider);
              return child;
            },
          ),
        ),
      );
    }

    testWidgets('can mount while a listener is building without throwing', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        host(
          container,
          const VisibleConversationRegistrar(
            spaceId: 'space-1',
            child: SizedBox.shrink(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pump();
      expect(container.read(visibleConversationSpacesProvider), {'space-1'});

      await tester.pumpWidget(host(container, const SizedBox.shrink()));
      expect(tester.takeException(), isNull);
      await tester.pump();
      expect(container.read(visibleConversationSpacesProvider), isEmpty);
    });

    testWidgets('swaps the registered space when spaceId changes', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        host(
          container,
          const VisibleConversationRegistrar(
            spaceId: 'space-a',
            child: SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();
      expect(container.read(visibleConversationSpacesProvider), {'space-a'});

      await tester.pumpWidget(
        host(
          container,
          const VisibleConversationRegistrar(
            spaceId: 'space-b',
            child: SizedBox.shrink(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pump();
      expect(container.read(visibleConversationSpacesProvider), {'space-b'});
    });
  });
}
