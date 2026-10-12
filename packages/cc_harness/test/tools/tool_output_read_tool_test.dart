import 'package:cc_harness/context.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

const ToolOutputScope _scope = ToolOutputScope(
  workspaceId: 'ws',
  conversationId: 'conv',
  agentId: 'agent',
);

HarnessToolContext _ctx({
  String? workspaceId = 'ws',
  String? conversationId = 'conv',
  String? agentId = 'agent',
}) => HarnessToolContext(
  workingDirectory: '/workspace',
  workspaceId: workspaceId,
  conversationId: conversationId,
  agentId: agentId,
);

/// Counts reads so a rejected handle can be proven to never reach the store.
class _CountingStore implements ToolOutputStore {
  _CountingStore(this.delegate);

  final ToolOutputStore delegate;
  int reads = 0;

  @override
  Future<ToolOutputReference?> put(ToolOutputWrite write) =>
      delegate.put(write);

  @override
  Future<ToolOutputReadResult> read(
    ToolOutputScope scope,
    String handle, {
    int offsetChars = 0,
    int limitChars = kToolOutputReadDefaultChars,
  }) {
    reads++;
    return delegate.read(
      scope,
      handle,
      offsetChars: offsetChars,
      limitChars: limitChars,
    );
  }

  @override
  Future<void> clearScope(ToolOutputScope scope) => delegate.clearScope(scope);

  @override
  Future<void> clearConversation(ToolOutputScope scope) =>
      delegate.clearConversation(scope);
}

void main() {
  late InMemoryToolOutputStore store;
  late String original;
  late ToolOutputReference reference;

  setUp(() async {
    store = InMemoryToolOutputStore();
    original = List.generate(400, (i) => 'line ${i + 1}: content').join('\n');
    reference = (await store.put(
      ToolOutputWrite(scope: _scope, toolName: 'bash', content: original),
    ))!;
  });

  group('argument validation', () {
    test('rejects a missing or empty handle', () async {
      final tool = ToolOutputReadTool(store);
      for (final args in const <Map<String, dynamic>>[
        {},
        {'handle': ''},
      ]) {
        final result = await tool.execute(args, _ctx());
        expect(result.isError, isTrue);
        expect(result.content, contains('handle'));
      }
    });

    test('rejects a path-shaped handle without asking the store', () async {
      final counting = _CountingStore(store);
      final tool = ToolOutputReadTool(counting);
      for (final handle in const [
        '../../etc/passwd',
        'out_../secrets',
        'not-a-handle',
        'out_x',
      ]) {
        final result = await tool.execute({'handle': handle}, _ctx());
        expect(result.isError, isTrue);
        expect(result.content, contains('Invalid output handle'));
      }
      expect(counting.reads, 0);
    });

    test('rejects a limit below one', () async {
      final tool = ToolOutputReadTool(store);
      final result = await tool.execute({
        'handle': reference.handle,
        'limit': 0,
      }, _ctx());
      expect(result.isError, isTrue);
      expect(result.content, contains('limit'));
    });
  });

  group('availability', () {
    test('reports retrieval unavailable when no store is wired', () async {
      final tool = ToolOutputReadTool(null);
      final result = await tool.execute({'handle': reference.handle}, _ctx());
      expect(result.isError, isTrue);
      expect(result.content, contains('unavailable'));
    });

    test(
      'reports an unscoped run rather than reading without a boundary',
      () async {
        final counting = _CountingStore(store);
        final tool = ToolOutputReadTool(counting);
        final result = await tool.execute({
          'handle': reference.handle,
        }, _ctx(workspaceId: null));
        expect(result.isError, isTrue);
        expect(result.content, contains('workspace scope'));
        expect(counting.reads, 0);
      },
    );
  });

  group('ranged reads', () {
    test(
      'returns the exact range with a header and a continuation hint',
      () async {
        final tool = ToolOutputReadTool(store);
        final result = await tool.execute({
          'handle': reference.handle,
          'offset': 10,
          'limit': 25,
        }, _ctx());
        expect(result.isError, isFalse);
        expect(result.content, contains(original.substring(10, 35)));
        expect(result.content, contains(reference.handle));
        expect(result.content, contains('(bash)'));
        expect(result.content, contains('chars 10-35 of ${original.length}'));
        expect(result.content, contains('continue with offset=35'));
      },
    );

    test(
      'paging with the hinted offset reaches the end with nothing lost',
      () async {
        final tool = ToolOutputReadTool(store);
        final buffer = StringBuffer();
        var offset = 0;
        while (true) {
          final result = await tool.execute({
            'handle': reference.handle,
            'offset': offset,
            'limit': 4000,
          }, _ctx());
          expect(result.isError, isFalse);
          final body = _stripHeaderAndTrailer(result.content);
          buffer.write(body);
          final next = RegExp(
            r'continue with offset=(\d+)',
          ).firstMatch(result.content);
          if (next == null) {
            break;
          }
          offset = int.parse(next.group(1)!);
        }
        expect(buffer.toString(), original);
      },
    );

    test('caps the limit at the retrieval ceiling', () async {
      final big = (await store.put(
        ToolOutputWrite(
          scope: _scope,
          toolName: 'bash',
          content: 'z' * (kToolOutputReadMaxChars + 1000),
        ),
      ))!;
      final tool = ToolOutputReadTool(store);
      final result = await tool.execute({
        'handle': big.handle,
        'limit': 999999,
      }, _ctx());
      expect(result.isError, isFalse);
      final body = _stripHeaderAndTrailer(result.content);
      expect(body.length, kToolOutputReadMaxChars);
      expect(result.content, contains('continue with offset='));
    });

    test('an offset past the end returns an empty, complete read', () async {
      final tool = ToolOutputReadTool(store);
      final result = await tool.execute({
        'handle': reference.handle,
        'offset': 999999,
      }, _ctx());
      expect(result.isError, isFalse);
      expect(_stripHeaderAndTrailer(result.content), isEmpty);
      expect(result.content, isNot(contains('continue with offset=')));
    });
  });

  group('isolation', () {
    test(
      'a handle from another conversation is unknown, not readable',
      () async {
        final tool = ToolOutputReadTool(store);
        final result = await tool.execute({
          'handle': reference.handle,
        }, _ctx(conversationId: 'other-conversation'));
        expect(result.isError, isTrue);
        expect(result.content, contains('Unknown output handle'));
        expect(result.content, isNot(contains('line 1: content')));
      },
    );

    test('a handle from another agent is unknown', () async {
      final tool = ToolOutputReadTool(store);
      final result = await tool.execute({
        'handle': reference.handle,
      }, _ctx(agentId: 'other-agent'));
      expect(result.isError, isTrue);
      expect(result.content, contains('Unknown output handle'));
      expect(result.content, isNot(contains('line 1: content')));
    });

    test('a local anomaly is reported as a denial, without details', () async {
      // The store's own "this entry is not recorded to your scope" verdict is
      // surfaced as a refusal rather than a not-found, and names no other run.
      final tool = ToolOutputReadTool(const _DenyingStore());
      final result = await tool.execute({'handle': reference.handle}, _ctx());
      expect(result.isError, isTrue);
      expect(result.content, contains('Denied'));
      expect(result.content, isNot(contains('out_abcdefghijklmnop')));
    });

    test('reports an unknown handle as unknown, not as denied', () async {
      final tool = ToolOutputReadTool(store);
      final result = await tool.execute({'handle': 'out_${'q' * 22}'}, _ctx());
      expect(result.isError, isTrue);
      expect(result.content, contains('Unknown output handle'));
    });
  });
}

/// A store whose every read is a scope denial (exercises that port status).
class _DenyingStore implements ToolOutputStore {
  const _DenyingStore();

  @override
  Future<ToolOutputReference?> put(ToolOutputWrite write) async => null;

  @override
  Future<ToolOutputReadResult> read(
    ToolOutputScope scope,
    String handle, {
    int offsetChars = 0,
    int limitChars = kToolOutputReadDefaultChars,
  }) async => ToolOutputReadResult.denied('recorded to a different scope');

  @override
  Future<void> clearScope(ToolOutputScope scope) async {}

  @override
  Future<void> clearConversation(ToolOutputScope scope) async {}
}

/// The result body between the provenance header and the continuation trailer.
String _stripHeaderAndTrailer(String content) {
  final lines = content.split('\n');
  if (lines.isNotEmpty && lines.first.startsWith('[output ')) {
    lines.removeAt(0);
  }
  if (lines.isNotEmpty && lines.last.startsWith('[+')) {
    lines.removeLast();
  }
  return lines.join('\n');
}
