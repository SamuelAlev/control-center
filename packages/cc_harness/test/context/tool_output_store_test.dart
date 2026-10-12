import 'package:cc_harness/context.dart';
import 'package:test/test.dart';

void main() {
  const scope = ToolOutputScope(
    workspaceId: 'ws',
    conversationId: 'conv',
    agentId: 'agent',
  );

  const otherConversation = ToolOutputScope(
    workspaceId: 'ws',
    conversationId: 'other',
    agentId: 'agent',
  );

  group('InMemoryToolOutputStore', () {
    test('round-trips exact slices and reports continuation', () async {
      final store = InMemoryToolOutputStore();
      final reference = await store.put(
        const ToolOutputWrite(
          scope: scope,
          toolName: 'bash',
          content: '0123456789',
        ),
      );
      expect(reference, isNotNull);
      expect(reference!.charLength, 10);
      expect(reference.byteLength, 10);

      final first = await store.read(scope, reference.handle, limitChars: 4);
      expect(first.status, ToolOutputReadStatus.ok);
      expect(first.chunk!.text, '0123');
      expect(first.chunk!.hasMore, isTrue);
      expect(first.chunk!.nextOffsetChars, 4);

      final second = await store.read(
        scope,
        reference.handle,
        offsetChars: first.chunk!.nextOffsetChars,
        limitChars: 100,
      );
      expect(second.chunk!.text, '456789');
      expect(second.chunk!.hasMore, isFalse);
    });

    test('clamps offsets and limits to the port bounds', () async {
      final store = InMemoryToolOutputStore();
      final reference = (await store.put(
        const ToolOutputWrite(
          scope: scope,
          toolName: 'bash',
          content: 'abcdef',
        ),
      ))!;

      final negative = await store.read(
        scope,
        reference.handle,
        offsetChars: -5,
      );
      expect(negative.chunk!.text, 'abcdef');

      final zeroLimit = await store.read(
        scope,
        reference.handle,
        limitChars: 0,
      );
      expect(zeroLimit.chunk!.text, 'a', reason: 'a limit below 1 becomes 1');

      final huge = await store.read(
        scope,
        reference.handle,
        limitChars: kToolOutputReadMaxChars + 1000,
      );
      expect(huge.chunk!.text, 'abcdef');

      final beyond = await store.read(scope, reference.handle, offsetChars: 99);
      expect(beyond.chunk!.text, isEmpty);
      expect(beyond.chunk!.hasMore, isFalse);
    });

    test('refuses an output past its entry ceiling without a handle', () async {
      final store = InMemoryToolOutputStore(maxEntryChars: 4);
      final reference = await store.put(
        const ToolOutputWrite(scope: scope, toolName: 'bash', content: '12345'),
      );
      expect(reference, isNull);
    });

    test('refuses an unscoped write', () async {
      final store = InMemoryToolOutputStore();
      final reference = await store.put(
        const ToolOutputWrite(
          scope: ToolOutputScope(workspaceId: ''),
          toolName: 'bash',
          content: 'x',
        ),
      );
      expect(reference, isNull);
      expect(store.length, 0);
    });

    test('refuses a scope whose ids are path-like', () async {
      final store = InMemoryToolOutputStore();
      for (final bad in const [
        ToolOutputScope(workspaceId: 'ws', conversationId: '../c'),
        ToolOutputScope(workspaceId: 'ws', conversationId: 'a/b'),
        ToolOutputScope(workspaceId: 'ws', agentId: 'a\\b'),
        ToolOutputScope(workspaceId: 'ws', agentId: 'x\u0000y'),
      ]) {
        final reference = await store.put(
          ToolOutputWrite(scope: bad, toolName: 'bash', content: 'x'),
        );
        expect(reference, isNull, reason: '$bad must be refused');
      }
      expect(store.length, 0);
    });

    test(
      'at its scope cap the new write is refused, old handles survive',
      () async {
        final store = InMemoryToolOutputStore(maxEntriesPerScope: 2);
        final first = await store.put(
          const ToolOutputWrite(scope: scope, toolName: 'bash', content: 'one'),
        );
        final second = await store.put(
          const ToolOutputWrite(scope: scope, toolName: 'bash', content: 'two'),
        );
        final third = await store.put(
          const ToolOutputWrite(
            scope: scope,
            toolName: 'bash',
            content: 'three',
          ),
        );
        expect(third, isNull, reason: 'capacity refuses the new write');
        expect(store.length, 2);
        expect((await store.read(scope, first!.handle)).chunk!.text, 'one');
        expect((await store.read(scope, second!.handle)).chunk!.text, 'two');
      },
    );

    test('an unknown but well-formed handle is not found', () async {
      final store = InMemoryToolOutputStore();
      final result = await store.read(scope, 'out_${'a' * 22}');
      expect(result.status, ToolOutputReadStatus.notFound);
    });

    test('a malformed handle is rejected before any lookup', () async {
      final store = InMemoryToolOutputStore();
      for (final handle in const ['', '../x', 'out_x', 'nope', 'out_../etc']) {
        final result = await store.read(scope, handle);
        expect(result.status, ToolOutputReadStatus.invalid);
        expect(result.chunk, isNull);
      }
    });
  });

  group('scope isolation', () {
    test('a handle is unknown in another conversation', () async {
      final store = InMemoryToolOutputStore();
      final reference = await store.put(
        const ToolOutputWrite(
          scope: scope,
          toolName: 'bash',
          content: 'secret',
        ),
      );
      final result = await store.read(otherConversation, reference!.handle);
      // Not "denied with details": another scope's existence is not this run's
      // business, so the answer is the same as for a handle nobody stored.
      expect(result.status, ToolOutputReadStatus.notFound);
      expect(result.chunk, isNull, reason: 'a foreign read returns no content');
      expect(result.message, isNot(contains('secret')));
      expect(result.message, isNot(contains('conv')));
    });

    test('a handle is unknown in another agent', () async {
      final store = InMemoryToolOutputStore();
      final reference = await store.put(
        const ToolOutputWrite(
          scope: scope,
          toolName: 'bash',
          content: 'secret',
        ),
      );
      final result = await store.read(
        const ToolOutputScope(
          workspaceId: 'ws',
          conversationId: 'conv',
          agentId: 'other',
        ),
        reference!.handle,
      );
      expect(result.status, ToolOutputReadStatus.notFound);
    });

    test('a handle is unknown in another workspace', () async {
      final store = InMemoryToolOutputStore();
      final reference = await store.put(
        const ToolOutputWrite(
          scope: scope,
          toolName: 'bash',
          content: 'secret',
        ),
      );
      final result = await store.read(
        const ToolOutputScope(
          workspaceId: 'other-ws',
          conversationId: 'conv',
          agentId: 'agent',
        ),
        reference!.handle,
      );
      expect(result.status, ToolOutputReadStatus.notFound);
    });

    test('a null conversation is a distinct scope, not a wildcard', () async {
      final store = InMemoryToolOutputStore();
      final reference = await store.put(
        const ToolOutputWrite(
          scope: ToolOutputScope(workspaceId: 'ws'),
          toolName: 'bash',
          content: 'secret',
        ),
      );
      for (final probe in const [
        scope,
        ToolOutputScope(workspaceId: 'ws', conversationId: ''),
        ToolOutputScope(workspaceId: 'ws', conversationId: 'conv'),
      ]) {
        expect(
          (await store.read(probe, reference!.handle)).status,
          ToolOutputReadStatus.notFound,
          reason: '$probe must not alias the null-conversation scope',
        );
      }
      expect(
        (await store.read(
          const ToolOutputScope(workspaceId: 'ws'),
          reference!.handle,
        )).status,
        ToolOutputReadStatus.ok,
      );
    });

    test('an empty conversation id is distinct from a missing one', () {
      const missing = ToolOutputScope(workspaceId: 'ws');
      const empty = ToolOutputScope(workspaceId: 'ws', conversationId: '');
      expect(missing.key, isNot(empty.key));
      expect(missing.storageKey, isNot(empty.storageKey));
    });

    test('storage keys are injective for tricky id shapes', () {
      const cases = <ToolOutputScope>[
        ToolOutputScope(workspaceId: 'ws', conversationId: 'a', agentId: 'b#c'),
        ToolOutputScope(workspaceId: 'ws', conversationId: 'a#b', agentId: 'c'),
        ToolOutputScope(workspaceId: 'ws', conversationId: 'a.b', agentId: 'c'),
        ToolOutputScope(workspaceId: 'ws', conversationId: 'a_b', agentId: 'c'),
        ToolOutputScope(workspaceId: 'ws', conversationId: 'a%b', agentId: 'c'),
      ];
      final keys = {for (final c in cases) c.storageKey};
      expect(keys.length, cases.length);
      for (final key in keys) {
        expect(key, isNot(contains('/')));
        expect(key, isNot(contains('..')));
        expect(key, isNot(contains('#')));
      }
    });

    test(
      'clearConversation retires every agent scope of one conversation',
      () async {
        final store = InMemoryToolOutputStore();
        const otherAgent = ToolOutputScope(
          workspaceId: 'ws',
          conversationId: 'conv',
          agentId: 'agent-2',
        );
        // A conversation whose id EXTENDS this one's: the length-prefixed key
        // must keep the two apart.
        const longer = ToolOutputScope(
          workspaceId: 'ws',
          conversationId: 'conversation',
          agentId: 'agent',
        );
        final mine = await store.put(
          const ToolOutputWrite(
            scope: scope,
            toolName: 'bash',
            content: 'mine',
          ),
        );
        final sibling = await store.put(
          const ToolOutputWrite(
            scope: otherAgent,
            toolName: 'bash',
            content: 'sibling',
          ),
        );
        final extended = await store.put(
          const ToolOutputWrite(
            scope: longer,
            toolName: 'bash',
            content: 'long',
          ),
        );

        await store.clearConversation(scope);

        expect(
          (await store.read(scope, mine!.handle)).status,
          ToolOutputReadStatus.notFound,
        );
        expect(
          (await store.read(otherAgent, sibling!.handle)).status,
          ToolOutputReadStatus.notFound,
        );
        expect(
          (await store.read(longer, extended!.handle)).chunk!.text,
          'long',
        );
      },
    );

    test('clearScope retires one scope only', () async {
      final store = InMemoryToolOutputStore();
      final mine = await store.put(
        const ToolOutputWrite(scope: scope, toolName: 'bash', content: 'mine'),
      );
      final theirs = await store.put(
        const ToolOutputWrite(
          scope: otherConversation,
          toolName: 'bash',
          content: 'theirs',
        ),
      );
      await store.clearScope(scope);
      expect(
        (await store.read(scope, mine!.handle)).status,
        ToolOutputReadStatus.notFound,
      );
      expect(
        (await store.read(otherConversation, theirs!.handle)).chunk!.text,
        'theirs',
      );
    });
  });

  group('handles', () {
    test('generated handles are opaque, unique, and path-safe', () {
      final handles = {for (var i = 0; i < 200; i++) newToolOutputHandle()};
      expect(handles.length, 200);
      for (final handle in handles) {
        expect(isToolOutputHandle(handle), isTrue);
        expect(handle, isNot(contains('/')));
        expect(handle, isNot(contains('.')));
      }
    });

    test('path-like and short names are not handles', () {
      for (final bad in [
        'out_../../etc/passwd',
        'out_short',
        'OUT_aaaaaaaaaaaaaaaaaaaa',
        'aaaaaaaaaaaaaaaaaaaaaaaa',
        'out_${'a' * 80}',
      ]) {
        expect(isToolOutputHandle(bad), isFalse, reason: bad);
      }
    });
  });

  group('utf8LengthOf', () {
    test('counts ascii, two-, three- and four-byte code points', () {
      expect(utf8LengthOf('abc'), 3);
      expect(utf8LengthOf('é'), 2);
      expect(utf8LengthOf('✓'), 3);
      expect(utf8LengthOf('🙂'), 4);
      expect(utf8LengthOf('a🙂é'), 1 + 4 + 2);
      expect(utf8LengthOf(''), 0);
    });
  });

  group('ToolOutputReference', () {
    test('round-trips through JSON', () {
      const reference = ToolOutputReference(
        handle: 'out_abcdefghijklmnopqrst',
        toolName: 'bash',
        byteLength: 900,
        charLength: 850,
        previewChars: 240,
      );
      final restored = ToolOutputReference.fromJson(reference.toJson());
      expect(restored, reference);
      expect(restored.previewChars, 240);
    });

    test('tolerates a sparse or foreign JSON payload', () {
      final restored = ToolOutputReference.fromJson(const {'handle': 'out_x'});
      expect(restored.handle, 'out_x');
      expect(restored.charLength, 0);
      expect(restored.toolName, isEmpty);
    });

    test('omits the preview key when nothing is inline', () {
      const reference = ToolOutputReference(
        handle: 'out_abcdefghijklmnopqrst',
        toolName: 'read',
        byteLength: 10,
        charLength: 10,
      );
      expect(reference.toJson(), isNot(contains('preview')));
    });
  });

  group('markers', () {
    const reference = ToolOutputReference(
      handle: 'out_abcdefghijklmnopqrst',
      toolName: 'bash',
      byteLength: 900,
      charLength: 850,
    );

    test(
      'the omission marker names the handle and the exact resume offset',
      () {
        final marker = omittedOutputMarker(
          reference,
          omittedChars: 500,
          resumeOffsetChars: 12000,
        );
        expect(marker, startsWith(omittedOutputPrefix));
        expect(marker, contains('"out_abcdefghijklmnopqrst"'));
        expect(marker, contains('offset: 12000'));
        expect(marker, contains('500 chars'));
      },
    );

    test('without a reference the marker says the original was not stored', () {
      final marker = omittedOutputMarker(
        null,
        omittedChars: 10,
        resumeOffsetChars: 0,
      );
      expect(marker, contains('not stored'));
      expect(marker, isNot(contains('read_output')));
    });

    test('the masked marker is recognizable and recoverable', () {
      final marker = maskedObservationMarker(reference);
      expect(isMaskedObservation(marker), isTrue);
      expect(marker, contains('read_output'));
      expect(marker, contains('850 chars'));
    });

    test('ordinary content is not mistaken for a mask', () {
      expect(isMaskedObservation('exit code 0'), isFalse);
      expect(isMaskedObservation(''), isFalse);
    });
  });
}
