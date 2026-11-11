import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pipelines/domain/services/template_renderer.dart';
import 'package:cc_domain/features/pr_review/domain/services/mention_matcher.dart'
    show mentionBreak, neutralizeMentions;

/// The placeholders a `prReview.comment` message takes from the run's
/// verified pull request: the repository and number the step posts on, read
/// from the run's trigger payload (written by the engine from the event, the
/// webhook or the person who started the run) and checked, never from state
/// a step can rewrite mid-run. Rendered as is: they are forge coordinates.
const Set<String> kPrCommentCoordinateKeys = {
  'repo_full_name',
  'repo_owner',
  'repo_name',
  'pr_number',
};

/// The placeholder naming the pull request's author. Read from the trigger
/// payload only and rendered as is (so `@{{author}}` greets them) once it
/// is a valid username on the forge ([isForgeUsername]); any other value
/// fails the step.
const String kPrCommentAuthorKey = 'author';

/// The placeholders a message renders as raw markdown: server-produced
/// reports whose formatting is the point. Mentions in them are still made
/// inert ([neutralizeMentions]). Every other value is escaped
/// ([escapeMarkdownText]).
const Set<String> kPrCommentRawKeys = {'consolidated_findings'};

/// Whether [value] is a username [forge] allows, so `@value` names exactly
/// one account and carries no markup: GitHub `[A-Za-z0-9-]{1,39}` (an App's
/// `[bot]` suffix allowed), GitLab letters, digits, `_`, `.` and `-` (not
/// leading `-`, at most 255), Bitbucket letters, digits, `_`, `.` and `-`
/// (at most 100).
bool isForgeUsername(ForgeHost forge, String value) => switch (forge) {
  ForgeHost.github => RegExp(r'^[A-Za-z0-9-]{1,39}(\[bot\])?$').hasMatch(value),
  ForgeHost.gitlab => RegExp(
    r'^[A-Za-z0-9_.][A-Za-z0-9_.-]{0,254}$',
  ).hasMatch(value),
  ForgeHost.bitbucket => RegExp(r'^[A-Za-z0-9_.-]{1,100}$').hasMatch(value),
  ForgeHost.local => false,
};

final RegExp _markdownPunctuation = RegExp(r'[\\`*_{}\[\]()#+\-.!|<>~&]');
final RegExp _lineBreaks = RegExp(r'[\r\n]+');
final RegExp _atName = RegExp(r'@(?=[A-Za-z0-9_{])');

/// [value] as literal text inside markdown: one line, every markdown
/// punctuation character backslash-escaped (an escaped `&` cannot start an
/// entity), and every `@` before a name made inert ([mentionBreak]).
String escapeMarkdownText(String value) => value
    .replaceAll(_lineBreaks, ' ')
    .replaceAllMapped(_markdownPunctuation, (m) => '\\${m[0]}')
    .replaceAll(_atName, '@$mentionBreak');

/// A rendered `prReview.comment` message: its text, or why it cannot be
/// posted.
typedef PrCommentMessage = ({String? text, String? error});

/// Renders [template] for a comment on [owner]/[name]#[number] on [forge].
///
/// The coordinates ([kPrCommentCoordinateKeys]) render from those verified
/// values, `author` from [trigger] only and only as a valid username, the
/// [kPrCommentRawKeys] as raw markdown with inert mentions, and everything
/// else from [state] then [trigger], escaped. A placeholder that resolves to
/// nothing fails, as before.
PrCommentMessage renderPrCommentMessage(
  String template, {
  required Map<String, dynamic> state,
  required Map<String, dynamic>? trigger,
  required ForgeHost forge,
  required String owner,
  required String name,
  required int number,
}) {
  const renderer = TemplateRenderer();
  String keyOf(String ref) => ref.startsWith(r'$trigger.')
      ? ref.substring(r'$trigger.'.length)
      : ref.startsWith(r'$state.')
      ? ref.substring(r'$state.'.length)
      : ref;
  final refs = [
    for (final part in renderer.parts(template))
      if (part is TemplatePlaceholder) part.ref,
  ];
  final refAt = Map.fromIterables(renderer.placeholderOffsets(template), refs);
  final author = trigger?[kPrCommentAuthorKey];
  if (refs.any((r) => keyOf(r) == kPrCommentAuthorKey) &&
      (author is! String || !isForgeUsername(forge, author))) {
    return (
      text: null,
      error:
          'the pull request author "${author ?? ''}" is not a '
          '${forge.displayName} username',
    );
  }
  final verified = <String, dynamic>{
    'repo_full_name': '$owner/$name',
    'repo_owner': owner,
    'repo_name': name,
    'pr_number': number,
    kPrCommentAuthorKey: ?author,
  };
  final rendered = renderer.render(
    template,
    state: {...state}..removeWhere((k, _) => verified.containsKey(k)),
    trigger: {...?trigger, ...verified},
    escape: (value, offset) {
      final key = keyOf(refAt[offset] ?? '');
      if (verified.containsKey(key)) {
        return value;
      }
      if (kPrCommentRawKeys.contains(key)) {
        return neutralizeMentions(value);
      }
      return escapeMarkdownText(value);
    },
  );
  if (!rendered.isComplete) {
    return (
      text: null,
      error: 'unresolved placeholders: ${rendered.unresolved.join(', ')}',
    );
  }
  return (text: rendered.text.trim(), error: null);
}
