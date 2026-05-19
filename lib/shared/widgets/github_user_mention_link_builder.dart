import 'package:cc_markdown/cc_markdown.dart';
import 'package:control_center/shared/utils/github_user_mention_parser.dart';
import 'package:control_center/shared/widgets/github_user_mention.dart';
import 'package:flutter/widgets.dart';

/// cc_markdown `'link'` builder that swaps `@user` / `@org/team` mentions
/// for a [GitHubUserMention] chip (reserved-size avatar + name).
///
/// Claims preprocessor-emitted `control-center://user|team/…` hrefs and
/// author-labelled `@login` links. Every other link falls through to the
/// engine's default rendering.
class GitHubUserMentionLinkBuilder extends CcNodeBuilder {
  /// Creates a [GitHubUserMentionLinkBuilder].
  const GitHubUserMentionLinkBuilder();

  /// Parses [node] as a mention chip target, or null.
  static GitHubMentionLink? tryParse(CcNode node) {
    if (node is! CcLink) {
      return null;
    }
    return parseGitHubMentionLink(
      url: node.url,
      label: _inlinePlainText(node.children),
    );
  }

  @override
  bool canBuild(CcNode node) => tryParse(node) != null;

  @override
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context) {
    final mention = tryParse(node);
    if (mention == null) {
      return const SizedBox.shrink();
    }
    final base = style.paragraph ?? const TextStyle();
    return GitHubUserMention(
      login: mention.login,
      avatarUrl: '',
      isTeam: mention.isTeam,
      style: base.copyWith(
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none,
        height: 1,
      ),
    );
  }
}

String _inlinePlainText(List<CcInlineNode> nodes) {
  final buf = StringBuffer();
  void walk(List<CcInlineNode> list) {
    for (final node in list) {
      switch (node) {
        case CcText(:final text):
          buf.write(text);
        case CcInlineCode(:final code):
          buf.write(code);
        case CcEmphasis(:final children) ||
            CcStrong(:final children) ||
            CcStrikethrough(:final children) ||
            CcLink(:final children):
          walk(children);
        case CcImage(:final alt):
          buf.write(alt);
        case CcSoftBreak() || CcHardBreak():
          buf.write(' ');
        case CcFootnoteRef() || CcInlineHtml() || CcCustomInline():
          break;
      }
    }
  }

  walk(nodes);
  return buf.toString();
}
