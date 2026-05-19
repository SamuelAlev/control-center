import 'package:cc_domain/cc_domain.dart' show FileSearchHit;
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/file_mention_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// The composer's `@<path>` source must never search the client's filesystem —
/// it queries `cc_server` (`repos.searchFiles`), which owns the checkouts and
/// the native searcher. These tests pin the behaviour that makes one round trip
/// per settled query instead of one per keystroke, and that a superseded query
/// never reaches the wire at all.
void main() {
  const query = MentionQuery(
    trigger: MentionTrigger.at,
    partial: 'widget',
    start: 0,
    end: 7,
  );

  FileSearchHit hit(String relativePath, {bool isDirectory = false}) =>
      FileSearchHit(
        absolutePath: '/srv/repo/$relativePath',
        relativePath: relativePath,
        rootPath: '/srv/repo',
        isDirectory: isDirectory,
        score: 1,
      );

  group('FileMentionSource', () {
    test('maps server hits to suggestions, capped at the limit', () async {
      final source = FileMentionSource(
        debounce: Duration.zero,
        limit: 2,
        search: (_) async => [
          hit('lib/widget.dart'),
          hit('lib/ui/widget_test.dart'),
          hit('lib/dropped.dart'),
        ],
      );

      final items = await source.suggest(query).first;

      expect(items.map((s) => s.label), ['widget.dart', 'widget_test.dart']);
      expect(items.first.kind, 'file');
      expect(items.first.replacement, '@lib/widget.dart ');
      expect(items.first.payload?['path'], '/srv/repo/lib/widget.dart');
      // A file's description is its directory; a root-level hit falls back to
      // the repo folder name.
      expect(items.first.description, 'lib');
    });

    test(
      'quotes a basename with spaces so the token stays one mention',
      () async {
        final source = FileMentionSource(
          debounce: Duration.zero,
          search: (_) async => [hit('docs/release notes.md')],
        );

        final items = await source.suggest(query).first;

        expect(items.single.replacement, "@'release notes.md' ");
      },
    );

    test(
      'never searches on an empty partial (it would dump the tree)',
      () async {
        var calls = 0;
        final source = FileMentionSource(
          debounce: Duration.zero,
          search: (_) async {
            calls++;
            return const [];
          },
        );

        final items = await source
            .suggest(
              const MentionQuery(
                trigger: MentionTrigger.at,
                partial: '',
                start: 0,
                end: 1,
              ),
            )
            .first;

        expect(items, isEmpty);
        expect(calls, 0);
      },
    );

    test('ignores non-`@` triggers', () async {
      var calls = 0;
      final source = FileMentionSource(
        debounce: Duration.zero,
        search: (_) async {
          calls++;
          return const [];
        },
      );

      await source
          .suggest(
            const MentionQuery(
              trigger: MentionTrigger.slash,
              partial: 'plan',
              start: 0,
              end: 5,
            ),
          )
          .drain<void>();

      expect(calls, 0);
    });

    test(
      'a query cancelled inside the debounce never reaches the server',
      () async {
        var calls = 0;
        final source = FileMentionSource(
          debounce: const Duration(milliseconds: 60),
          search: (_) async {
            calls++;
            return const [];
          },
        );

        // The popup re-queries on every keystroke and cancels the previous
        // subscription — the pending timer must die with it.
        final sub = source.suggest(query).listen((_) {});
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await sub.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(calls, 0);

        // A query the user settles on does reach the server, once.
        await source.suggest(query).first;
        expect(calls, 1);
      },
    );

    test('surfaces a search failure as a stream error', () {
      final source = FileMentionSource(
        debounce: Duration.zero,
        search: (_) async => throw StateError('server unreachable'),
      );

      expect(source.suggest(query), emitsError(isStateError));
    });
  });
}
