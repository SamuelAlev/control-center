import 'package:control_center/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testCreatedAt = DateTime(2024, 1, 1);
  final testUpdatedAt = DateTime(2024, 6, 1);

  RssFeed createFeed({
    String id = 'feed-1',
    String name = 'Test Feed',
    String url = 'https://example.com/rss',
    String description = 'A test feed',
    String iconUrl = 'https://example.com/icon.png',
    String userAgent = '',
    bool enabled = true,
    DateTime? lastFetchedAt,
    String? lastError,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RssFeed(
      id: id,
      name: name,
      url: url,
      description: description,
      iconUrl: iconUrl,
      userAgent: userAgent,
      enabled: enabled,
      lastFetchedAt: lastFetchedAt,
      lastError: lastError,
      createdAt: createdAt ?? testCreatedAt,
      updatedAt: updatedAt ?? testUpdatedAt,
    );
  }

  group('RssFeed', () {
    group('constructor', () {
      test('creates feed with all fields', timeout: const Timeout.factor(2), () {
        final f = createFeed();
        expect(f.id, 'feed-1');
        expect(f.name, 'Test Feed');
        expect(f.url, 'https://example.com/rss');
        expect(f.description, 'A test feed');
        expect(f.iconUrl, 'https://example.com/icon.png');
        expect(f.userAgent, '');
        expect(f.enabled, isTrue);
        expect(f.lastFetchedAt, isNull);
        expect(f.lastError, isNull);
        expect(f.createdAt, testCreatedAt);
        expect(f.updatedAt, testUpdatedAt);
      });

      test('asserts id is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => RssFeed(
            id: '',
            name: 'n',
            url: 'u',
            createdAt: testCreatedAt,
            updatedAt: testUpdatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts name is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => RssFeed(
            id: 'f',
            name: '',
            url: 'u',
            createdAt: testCreatedAt,
            updatedAt: testUpdatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts url is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => RssFeed(
            id: 'f',
            name: 'n',
            url: '',
            createdAt: testCreatedAt,
            updatedAt: testUpdatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('hasError', () {
      test('returns false when lastError is null', timeout: const Timeout.factor(2), () {
        final f = createFeed();
        expect(f.hasError, isFalse);
      });

      test('returns false when lastError is empty', timeout: const Timeout.factor(2), () {
        final f = createFeed(lastError: '');
        expect(f.hasError, isFalse);
      });

      test('returns true when lastError is non-empty', timeout: const Timeout.factor(2), () {
        final f = createFeed(lastError: 'Connection refused');
        expect(f.hasError, isTrue);
      });
    });

    group('copyWith', () {
      test('returns identical feed with no arguments', timeout: const Timeout.factor(2), () {
        final f = createFeed(description: 'original');
        final copy = f.copyWith();
        expect(copy.name, f.name);
        expect(copy.description, f.description);
        expect(copy.id, f.id);
      });

      test('updates name', timeout: const Timeout.factor(2), () {
        final f = createFeed();
        final copy = f.copyWith(name: 'New Name');
        expect(copy.name, 'New Name');
        expect(copy.id, f.id);
      });

      test('updates enabled', timeout: const Timeout.factor(2), () {
        final f = createFeed(enabled: true);
        final copy = f.copyWith(enabled: false);
        expect(copy.enabled, isFalse);
      });

      test('clears lastError by passing null', timeout: const Timeout.factor(2), () {
        final f = createFeed(lastError: 'some error');
        final copy = f.copyWith();
        // copyWith doesn't set lastError => it becomes null
        expect(copy.lastError, isNull);
      });
    });

    group('== and hashCode', () {
      test('== returns true for same id', timeout: const Timeout.factor(2), () {
        final f1 = createFeed();
        final f2 = createFeed(name: 'Different Name');
        expect(f1, equals(f2));
      });

      test('== returns false for different id', timeout: const Timeout.factor(2), () {
        final f1 = createFeed(id: 'feed-1');
        final f2 = createFeed(id: 'feed-2');
        expect(f1, isNot(equals(f2)));
      });

      test('== returns true for same reference', timeout: const Timeout.factor(2), () {
        final f = createFeed();
        expect(f, equals(f));
      });

      test('== returns false for different runtime type', timeout: const Timeout.factor(2), () {
        final f = createFeed();
        expect(f, isNot(equals('not a feed')));
      });

      test('hashCode matches for equal feeds', timeout: const Timeout.factor(2), () {
        final f1 = createFeed();
        final f2 = createFeed();
        expect(f1.hashCode, equals(f2.hashCode));
      });

      test('hashCode differs for different feeds', timeout: const Timeout.factor(2), () {
        final f1 = createFeed(id: 'feed-1');
        final f2 = createFeed(id: 'feed-2');
        expect(f1.hashCode, isNot(equals(f2.hashCode)));
      });
    });
  });
}
