/// The single wiring point for cc_markdown plugin sets, parse options and builder
/// registries across the app's two functional registers.
/// All values here are process-global finals ON PURPOSE: plugin-set identity participates
/// in the parse-cache key and registry identity gates the streaming widget's block memo.
library;

import 'package:cc_markdown/cc_markdown.dart';
import 'package:control_center/shared/widgets/github_user_mention_link_builder.dart';
import 'package:control_center/shared/widgets/markdown/file_reference_chip.dart';
import 'package:control_center/shared/widgets/markdown/markdown_builders.dart';
import 'package:control_center/shared/widgets/markdown/mermaid_block.dart';

/// Chat-register plugins: the AI block constructs LLM output can contain, plus
/// the `@[file:…]` reference a human's own message carries (the composer writes
/// the token, the transcript draws it as the same pill).
final CcPluginSet chatMarkdownPlugins = CcPluginSet(const [
  CcThinkingPlugin(),
  CcArtifactPlugin(),
  CcToolCallPlugin(),
  FileRefInlinePlugin(),
]);

/// Chat-register parse options (footnotes off, everything else GFM).
const CcParseOptions chatMarkdownOptions = CcParseOptions(footnotes: false);

/// Chat-register builder overrides.
final CcBuilderRegistry chatMarkdownBuilders = CcBuilderRegistry(const {
  'inline_code': AppInlineCodeBuilder(),
  'details': AppDetailsBuilder(),
  'mermaid': AppMermaidBuilder(),
  kFileRefNodeType: FileRefChipBuilder(),
});

/// GitHub-register plugins (none — PR bodies are plain GFM).
const CcPluginSet githubMarkdownPlugins = CcPluginSet.empty;

/// GitHub-register parse options (full GFM incl. footnotes).
const CcParseOptions githubMarkdownOptions = CcParseOptions();

/// GitHub-register builder overrides WITHOUT repo context. `@user` mentions
/// are claimed here; call sites that also resolve PR/commit chips layer their
/// `'link'` builder on top via `withOverrides` and must delegate mentions
/// back to [GitHubUserMentionLinkBuilder].
final CcBuilderRegistry githubMarkdownBuilders = CcBuilderRegistry(const {
  'inline_code': AppInlineCodeBuilder(),
  'details': AppDetailsBuilder(),
  'mermaid': AppMermaidBuilder(),
  'link': GitHubUserMentionLinkBuilder(),
});
