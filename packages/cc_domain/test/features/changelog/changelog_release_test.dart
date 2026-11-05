import 'package:cc_domain/features/changelog/domain/entities/changelog_release.dart';
import 'package:test/test.dart';

const _source = '''
# Changelog

> Release notes, newest first.

## v0.0.11 — Oct 27, 2026 — The phone app — grown up

The phone app can now manage spaces.

Notes: The phone app&rsquo;s push uses FCM.

- [new] Phone conversations.
- [new] Phone runs.
- [improved] Launching opens straight into the main window.
- [fixed] Copying a link no longer fails &amp; retries.
- [breaking] Something this build has never heard of.

## v0.0.10 — someday — Older

Lead.
''';

void main() {
  test('reads each release, newest first', () {
    final releases = ChangelogRelease.parseMarkdown(_source);

    expect(releases.map((r) => r.version), ['0.0.11', '0.0.10']);
    final latest = releases.first;
    expect(latest.title, 'The phone app — grown up');
    expect(latest.lead, 'The phone app can now manage spaces.');
    expect(latest.releasedOn, DateTime(2026, 10, 27));
  });

  test('groups entries by type and keeps an unknown tag', () {
    final groups = ChangelogRelease.parseMarkdown(_source).first.groups;

    expect(groups.map((g) => g.type), [
      ChangelogChangeType.added,
      ChangelogChangeType.improved,
      ChangelogChangeType.fixed,
      ChangelogChangeType.other,
    ]);
    expect(groups.first.items, ['Phone conversations.', 'Phone runs.']);
  });

  test('decodes the entities the website leaves in its Markdown', () {
    final latest = ChangelogRelease.parseMarkdown(_source).first;

    expect(latest.note, 'The phone app’s push uses FCM.');
    expect(latest.groups[2].items.single, contains('fails & retries'));
  });

  test('keeps a date it cannot read as its label', () {
    final older = ChangelogRelease.parseMarkdown(_source).last;

    expect(older.releasedOn, isNull);
    expect(older.dateLabel, 'someday');
  });

  test('a document with no releases yields none', () {
    expect(ChangelogRelease.parseMarkdown('<html>not found</html>'), isEmpty);
  });

  test('compares by value', () {
    expect(
      ChangelogRelease.parseMarkdown(_source),
      ChangelogRelease.parseMarkdown(_source),
    );
  });
}
