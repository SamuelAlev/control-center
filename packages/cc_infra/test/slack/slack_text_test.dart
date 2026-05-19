import 'package:cc_infra/cc_infra.dart';
import 'package:test/test.dart';

/// [SlackText]: the two asymmetric translations at the boundary.
///
/// Inbound matters because whatever survives here lands in an agent's prompt —
/// a leftover `<@U123>` is an id the model has to guess at. Outbound matters
/// only for the non-streaming fallback, where Slack still speaks its older
/// mrkdwn dialect and `**bold**` renders as literal asterisks.
void main() {
  group('toMarkdown', () {
    test('drops the mention that addressed the bot', () {
      expect(
        SlackText.toMarkdown(
          '<@UBOT> summarize the open PRs',
          botUserId: 'UBOT',
        ),
        'summarize the open PRs',
      );
    });

    test('keeps a mention of somebody else, by name where Slack gave one', () {
      expect(
        SlackText.toMarkdown('<@UBOT> ask <@U2|dana> too', botUserId: 'UBOT'),
        'ask @dana too',
      );
      expect(SlackText.toMarkdown('ping <@U2>'), 'ping @U2');
    });

    test('unwraps channels, links and broadcasts', () {
      expect(
        SlackText.toMarkdown('see <#C1|general> and <#C2>'),
        'see #general and #C2',
      );
      expect(
        SlackText.toMarkdown('read <https://example.com|the docs>'),
        'read [the docs](https://example.com)',
      );
      // A bare link needs no label and a label equal to the url is noise.
      expect(
        SlackText.toMarkdown('<https://example.com>'),
        'https://example.com',
      );
      expect(SlackText.toMarkdown('<!here> deploy?'), '@here deploy?');
    });

    test('decodes entities without re-reading them as markup', () {
      // Slack escapes these and decoding before unwrapping would turn a quoted
      // `&lt;@U1&gt;` into a mention that was never there.
      expect(
        SlackText.toMarkdown('compare a &lt; b &amp;&amp; c &gt; d'),
        'compare a < b && c > d',
      );
      expect(SlackText.toMarkdown('literally &lt;@U1&gt;'), 'literally <@U1>');
    });

    test('mentionsBot only matches this app’s bot', () {
      expect(SlackText.mentionsBot('<@UBOT> hi', 'UBOT'), isTrue);
      expect(SlackText.mentionsBot('<@UBOT|cc> hi', 'UBOT'), isTrue);
      expect(SlackText.mentionsBot('<@UOTHER> hi', 'UBOT'), isFalse);
      // An app with no known bot user must not claim every message.
      expect(SlackText.mentionsBot('<@UBOT> hi', ''), isFalse);
    });
  });

  group('toMrkdwn', () {
    test('rewrites the four things Slack spells differently', () {
      expect(SlackText.toMrkdwn('**bold**'), '*bold*');
      expect(SlackText.toMrkdwn('__bold__'), '*bold*');
      expect(SlackText.toMrkdwn('*italic*'), '_italic_');
      expect(SlackText.toMrkdwn('***both***'), '*_both_*');
      expect(SlackText.toMrkdwn('## Heading'), '*Heading*');
      expect(
        SlackText.toMrkdwn('[the docs](https://example.com)'),
        '<https://example.com|the docs>',
      );
    });

    test('leaves code untouched', () {
      // An agent's answer is full of code; converting inside it would corrupt
      // the one part of the reply that has to be copied verbatim.
      expect(
        SlackText.toMrkdwn('run `git commit -m "**wip**"`'),
        'run `git commit -m "**wip**"`',
      );
      expect(
        SlackText.toMrkdwn('```\n**not bold**\n```'),
        '```\n**not bold**\n```',
      );
    });

    test('leaves structure Slack already renders alone', () {
      const markdown = '- one\n- two\n\n> quoted\n\n1. first';
      expect(SlackText.toMrkdwn(markdown), markdown);
    });

    test('does not italicize a bare asterisk in prose or a bullet', () {
      expect(SlackText.toMrkdwn('2 * 3 * 4'), '2 * 3 * 4');
      expect(SlackText.toMrkdwn('a*b*c'), 'a*b*c');
    });
  });
}
