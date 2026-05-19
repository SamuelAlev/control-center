import 'package:control_center/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 5, 18, 9, 0);

  PrInlineEntry createEntry({
    String id = 'entry-1',
    String author = 'dev',
    String body = 'Please fix this',
    DateTime? createdAt,
  }) {
    return PrInlineEntry(
      id: id,
      author: author,
      body: body,
      createdAt: createdAt,
    );
  }

  PrInlineThread createThread({
    String id = 'thread-1',
    String filePath = 'src/main.dart',
    int line = 10,
    String side = 'RIGHT',
    PrInlineThreadKind kind = PrInlineThreadKind.comment,
    String originalCode = 'var x = 1;',
    String suggestedCode = '',
    List<PrInlineEntry>? entries,
    int? lineEnd,
    bool resolved = false,
    PrInlineSyncState syncState = PrInlineSyncState.local,
    int? serverId,
    String? syncError,
  }) {
    return PrInlineThread(
      id: id,
      filePath: filePath,
      line: line,
      side: side,
      kind: kind,
      originalCode: originalCode,
      suggestedCode: suggestedCode,
      entries: entries ?? [createEntry()],
      lineEnd: lineEnd,
      resolved: resolved,
      syncState: syncState,
      serverId: serverId,
      syncError: syncError,
    );
  }

  group('PrInlineEntry', () {
    group('constructor', () {
      test('creates instance with all fields', () {
        final entry = PrInlineEntry(
          id: 'e1',
          author: 'alice',
          body: 'Looks good',
          createdAt: now,
        );
        expect(entry.id, 'e1');
        expect(entry.author, 'alice');
        expect(entry.body, 'Looks good');
        expect(entry.createdAt, now);
      });

      test('createdAt defaults to now when not provided', () {
        final before = DateTime.now();
        final entry = PrInlineEntry(
          id: 'e1',
          author: 'alice',
          body: 'Looks good',
        );
        final after = DateTime.now();
        expect(entry.createdAt.isAfter(before) || entry.createdAt == before, isTrue);
        expect(entry.createdAt.isBefore(after) || entry.createdAt == after, isTrue);
      });
    });

    group('== and hashCode', () {
      test('identical entries are equal', () {
        final a = PrInlineEntry(id: '1', author: 'a', body: 'b', createdAt: now);
        final b = PrInlineEntry(id: '1', author: 'a', body: 'b', createdAt: now);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different id makes unequal', () {
        final a = PrInlineEntry(id: '1', author: 'a', body: 'b', createdAt: now);
        final b = PrInlineEntry(id: '2', author: 'a', body: 'b', createdAt: now);
        expect(a, isNot(equals(b)));
      });

      test('different author makes unequal', () {
        final a = PrInlineEntry(id: '1', author: 'a', body: 'b', createdAt: now);
        final b = PrInlineEntry(id: '1', author: 'z', body: 'b', createdAt: now);
        expect(a, isNot(equals(b)));
      });

      test('different body makes unequal', () {
        final a = PrInlineEntry(id: '1', author: 'a', body: 'b', createdAt: now);
        final b = PrInlineEntry(id: '1', author: 'a', body: 'z', createdAt: now);
        expect(a, isNot(equals(b)));
      });

      test('createdAt not used in equality', () {
        final a = PrInlineEntry(id: '1', author: 'a', body: 'b', createdAt: now);
        final b = PrInlineEntry(id: '1', author: 'a', body: 'b',
            createdAt: now.add(const Duration(hours: 1)));
        expect(a, equals(b));
      });

      test('self equality', () {
        final a = createEntry();
        expect(a, equals(a));
      });
    });

    group('copyWith', () {
      test('returns new instance with updated id', () {
        final entry = createEntry();
        final updated = entry.copyWith(id: 'new-id');
        expect(updated.id, 'new-id');
        expect(updated.author, 'dev');
        expect(updated.body, 'Please fix this');
      });

      test('returns new instance with updated author', () {
        final entry = createEntry();
        final updated = entry.copyWith(author: 'bob');
        expect(updated.author, 'bob');
      });

      test('returns new instance with updated body', () {
        final entry = createEntry();
        final updated = entry.copyWith(body: 'Updated body');
        expect(updated.body, 'Updated body');
      });

      test('returns new instance with updated createdAt', () {
        final entry = createEntry();
        final updated = entry.copyWith(createdAt: now);
        expect(updated.createdAt, now);
      });

      test('copyWith without changes returns equal entry', () {
        final entry = createEntry(createdAt: now);
        final updated = entry.copyWith();
        expect(updated, equals(entry));
      });
    });

    group('toString', () {
      test('returns formatted string', () {
        final entry = createEntry(id: 'e42', author: 'alice');
        expect(entry.toString(), contains('PrInlineEntry'));
        expect(entry.toString(), contains('e42'));
        expect(entry.toString(), contains('alice'));
      });
    });
  });

  group('PrInlineThread constructor', () {
    test('creates instance with all fields', () {
      final entries = [createEntry()];
      final thread = PrInlineThread(
        id: 't1',
        filePath: 'src/main.dart',
        line: 5,
        side: 'LEFT',
        kind: PrInlineThreadKind.suggestion,
        originalCode: 'old code',
        suggestedCode: 'new code',
        entries: entries,
        lineEnd: 8,
        resolved: true,
        syncState: PrInlineSyncState.synced,
        serverId: 100,
        syncError: 'timeout',
      );

      expect(thread.id, 't1');
      expect(thread.filePath, 'src/main.dart');
      expect(thread.line, 5);
      expect(thread.lineEnd, 8);
      expect(thread.side, 'LEFT');
      expect(thread.kind, PrInlineThreadKind.suggestion);
      expect(thread.originalCode, 'old code');
      expect(thread.suggestedCode, 'new code');
      expect(thread.entries, entries);
      expect(thread.resolved, isTrue);
      expect(thread.syncState, PrInlineSyncState.synced);
      expect(thread.serverId, 100);
      expect(thread.syncError, 'timeout');
    });

    test('lineEnd defaults to line when not provided', () {
      final thread = createThread(line: 10);
      expect(thread.lineEnd, 10);
    });

    test('default values for optional fields', () {
      final thread = createThread();
      expect(thread.resolved, isFalse);
      expect(thread.syncState, PrInlineSyncState.local);
      expect(thread.serverId, isNull);
      expect(thread.syncError, isNull);
    });
  });

  group('PrInlineThread computed properties', () {
    test('isMultiLine returns true when lineEnd > line', () {
      expect(createThread(line: 1, lineEnd: 3).isMultiLine, isTrue);
    });

    test('isMultiLine returns false when lineEnd == line', () {
      expect(createThread(line: 5).isMultiLine, isFalse);
    });

    test('isSuggestion returns true for suggestion kind', () {
      expect(
        createThread(kind: PrInlineThreadKind.suggestion).isSuggestion,
        isTrue,
      );
    });

    test('isSuggestion returns false for comment kind', () {
      expect(
        createThread(kind: PrInlineThreadKind.comment).isSuggestion,
        isFalse,
      );
    });
  });

  group('PrInlineThread == and hashCode', () {
    test('identical threads are equal', () {
      final a = createThread();
      final b = createThread();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different id makes unequal', () {
      final a = createThread(id: 'a');
      final b = createThread(id: 'b');
      expect(a, isNot(equals(b)));
    });

    test('different filePath makes unequal', () {
      final a = createThread(filePath: 'a.dart');
      final b = createThread(filePath: 'b.dart');
      expect(a, isNot(equals(b)));
    });

    test('different line makes unequal', () {
      final a = createThread(line: 1);
      final b = createThread(line: 2);
      expect(a, isNot(equals(b)));
    });

    test('different kind makes unequal', () {
      final a = createThread(kind: PrInlineThreadKind.comment);
      final b = createThread(kind: PrInlineThreadKind.suggestion);
      expect(a, isNot(equals(b)));
    });

    test('different syncState makes unequal', () {
      final a = createThread(syncState: PrInlineSyncState.local);
      final b = createThread(syncState: PrInlineSyncState.synced);
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      final a = createThread();
      expect(a, equals(a));
    });
  });

  group('PrInlineThread copyWith', () {
    test('returns new instance with updated id', () {
      final thread = createThread();
      final updated = thread.copyWith(id: 't2');
      expect(updated.id, 't2');
      expect(updated.filePath, 'src/main.dart');
    });

    test('returns new instance with updated resolved', () {
      final thread = createThread(resolved: false);
      final updated = thread.copyWith(resolved: true);
      expect(updated.resolved, isTrue);
    });

    test('returns new instance with updated entries', () {
      final thread = createThread();
      final newEntries = [createEntry(id: 'new')];
      final updated = thread.copyWith(entries: newEntries);
      expect(updated.entries, newEntries);
    });

    test('removeServerId sets serverId to null', () {
      final thread = createThread(serverId: 42);
      final updated = thread.copyWith(removeServerId: true);
      expect(updated.serverId, isNull);
    });

    test('removeServerId false keeps serverId', () {
      final thread = createThread(serverId: 42);
      final updated = thread.copyWith(removeServerId: false);
      expect(updated.serverId, 42);
    });

    test('removeSyncError sets syncError to null', () {
      final thread = createThread(syncError: 'error');
      final updated = thread.copyWith(removeSyncError: true);
      expect(updated.syncError, isNull);
    });

    test('copyWith without changes returns equal thread', () {
      final thread = createThread();
      final updated = thread.copyWith();
      expect(updated, equals(thread));
    });
  });

  group('PrInlineThread toString', () {
    test('returns file:line format', () {
      final thread = createThread(filePath: 'src/main.dart', line: 42);
      expect(thread.toString(), 'PrInlineThread(src/main.dart:42, comment)');
    });
  });

  group('PrInlineSyncState', () {
    test('all enum values are distinct', () {
      expect(PrInlineSyncState.values.length, 4);
      expect(PrInlineSyncState.values.toSet().length, 4);
    });
  });

  group('PrInlineThreadKind', () {
    test('all enum values are distinct', () {
      expect(PrInlineThreadKind.values.length, 2);
    });
  });
}
