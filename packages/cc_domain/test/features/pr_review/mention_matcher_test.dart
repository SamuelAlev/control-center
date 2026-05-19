import 'package:cc_domain/features/pr_review/domain/services/mention_matcher.dart';
import 'package:test/test.dart';

void main() {
  group('acceptedMentionLogins', () {
    test('a bot login also answers to its bare slug', () {
      expect(acceptedMentionLogins('cc-review[bot]'), [
        'cc-review[bot]',
        'cc-review',
      ]);
    });

    test('a human login yields exactly itself', () {
      // The bracket handling has to be inert for a person, or the viewer lane
      // would start matching a second, invented name.
      expect(acceptedMentionLogins('octocat'), ['octocat']);
    });

    test('an empty login accepts nothing', () {
      expect(acceptedMentionLogins(''), isEmpty);
    });
  });

  group('bodyMentions — human logins', () {
    test('a plain mention matches', () {
      expect(bodyMentions('cc @octocat please look', 'octocat'), isTrue);
    });

    test('a longer login is not a match', () {
      // The failure this guards: notifying @sam every time someone writes
      // @samuel.
      expect(bodyMentions('ping @samuel', 'sam'), isFalse);
      expect(bodyMentions('ping @octocatx', 'octocat'), isFalse);
    });

    test('a hyphenated continuation is not a match', () {
      expect(bodyMentions('ping @octocat-bot', 'octocat'), isFalse);
    });

    test('a bracket continuation is not a match', () {
      expect(bodyMentions('ping @octocat[bot]', 'octocat'), isFalse);
    });

    test('other punctuation still matches', () {
      expect(bodyMentions('thanks @octocat!', 'octocat'), isTrue);
      expect(bodyMentions('@octocat: see below', 'octocat'), isTrue);
      expect(bodyMentions('(@octocat)', 'octocat'), isTrue);
    });

    test('matching is case-insensitive', () {
      expect(bodyMentions('hey @OctoCat', 'octocat'), isTrue);
      expect(bodyMentions('hey @octocat', 'OctoCat'), isTrue);
    });

    test('a mention at the very end matches', () {
      expect(bodyMentions('over to @octocat', 'octocat'), isTrue);
    });

    test('no mention, empty body or empty login is false', () {
      expect(bodyMentions('nothing here', 'octocat'), isFalse);
      expect(bodyMentions('', 'octocat'), isFalse);
      expect(bodyMentions('@octocat', ''), isFalse);
    });

    test('a bare name without the @ is not a mention', () {
      expect(bodyMentions('octocat should look', 'octocat'), isFalse);
    });
  });

  group('bodyMentions — bot logins keep the short form', () {
    test('the full login matches', () {
      expect(bodyMentions('@cc-review[bot] review', 'cc-review[bot]'), isTrue);
    });

    test('the bare slug matches', () {
      expect(bodyMentions('@cc-review review', 'cc-review[bot]'), isTrue);
    });

    test('the slug does not match inside another bracketed account', () {
      expect(bodyMentions('@cc-review[bots]', 'cc-review[bot]'), isFalse);
    });
  });

  group('bodyMentionsAny', () {
    test('true when any login matches', () {
      expect(bodyMentionsAny('@hubot hi', ['octocat', 'hubot']), isTrue);
    });

    test('false when none do', () {
      expect(bodyMentionsAny('nobody', ['octocat', 'hubot']), isFalse);
    });
  });

  group('stripMention', () {
    test('the full login is stripped before the slug', () {
      expect(
        stripMention('@cc-review[bot] question', 'cc-review[bot]'),
        'question',
      );
    });

    test('the slug form strips too', () {
      expect(stripMention('@cc-review question', 'cc-review[bot]'), 'question');
    });

    test('a body with no mention is returned trimmed', () {
      expect(stripMention('  question  ', 'octocat'), 'question');
    });
  });

  group('threadCommentIdsAuthoredBy', () {
    bool isOctocat(String? login) => login?.toLowerCase() == 'octocat';

    test('a comment the viewer wrote is in their thread', () {
      final ids = threadCommentIdsAuthoredBy(
        [(id: 1, inReplyToId: null, authorLogin: 'octocat')],
        isOctocat,
      );
      expect(ids, {1});
    });

    test('a reply under the viewer roots into their thread', () {
      final ids = threadCommentIdsAuthoredBy(
        [
          (id: 1, inReplyToId: null, authorLogin: 'octocat'),
          (id: 2, inReplyToId: 1, authorLogin: 'hubot'),
          (id: 3, inReplyToId: 2, authorLogin: 'someone'),
        ],
        isOctocat,
      );
      expect(ids, {1, 2, 3});
    });

    test('a thread the viewer never wrote in is excluded', () {
      final ids = threadCommentIdsAuthoredBy(
        [
          (id: 1, inReplyToId: null, authorLogin: 'hubot'),
          (id: 2, inReplyToId: 1, authorLogin: 'someone'),
        ],
        isOctocat,
      );
      expect(ids, isEmpty);
    });

    test('the viewer replying INTO a stranger thread pulls in their own '
        'comment and its descendants only', () {
      final ids = threadCommentIdsAuthoredBy(
        [
          (id: 1, inReplyToId: null, authorLogin: 'hubot'),
          (id: 2, inReplyToId: 1, authorLogin: 'octocat'),
          (id: 3, inReplyToId: 2, authorLogin: 'hubot'),
        ],
        isOctocat,
      );
      expect(ids, {2, 3});
    });

    test('a missing parent ends the walk rather than assuming', () {
      // Deleted or page-truncated: the thread cannot be PROVEN theirs.
      final ids = threadCommentIdsAuthoredBy(
        [(id: 5, inReplyToId: 99, authorLogin: 'hubot')],
        isOctocat,
      );
      expect(ids, isEmpty);
    });

    test('an empty list yields nothing', () {
      expect(threadCommentIdsAuthoredBy(const [], isOctocat), isEmpty);
    });
  });
}
