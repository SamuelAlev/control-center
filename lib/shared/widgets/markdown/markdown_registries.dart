/// The single wiring point for cc_markdown plugin sets, parse options and
/// builder registries across the app's two functional registers.
///
/// The registers differ FUNCTIONALLY, not visually (the stylesheet is the one
/// `appMarkdownStyle` for all surfaces):
///  * chat — AI block plugins (thinking/artifact/tool_call) ON, footnotes OFF
///    (LLM output doesn't use them; matches the old chat path);
///  * GitHub — footnotes ON (PR bodies use them), no AI plugins; `@user`
///    mention chips live on the default `'link'` builder. PR/commit
///    reference chips are layered per call site because they need repo
///    context.
///
/// Both registers draw ```` ```mermaid ```` fences through [AppMermaidBuilder]
/// (diagrams show up in LLM answers and in PR bodies alike).
///
/// All values here are process-global finals ON PURPOSE: plugin-set identity
/// participates in the parse-cache key and registry identity gates the
/// streaming widget's block memo.
library;

import 'package:cc_markdown/cc_markdown.dart';
import 'package:control_center/shared/widgets/github_user_mention_link_builder.dart';
import 'package:control_center/shared/widgets/markdown/markdown_builders.dart';
import 'package:control_center/shared/widgets/markdown/mermaid_block.dart';

/// Chat-register plugins: the AI block constructs LLM output can contain.
final CcPluginSet chatMarkdownPlugins = CcPluginSet(const [
  CcThinkingPlugin(),
  CcArtifactPlugin(),
  CcToolCallPlugin(),
]);

/// Chat-register parse options (footnotes off, everything else GFM).
const CcParseOptions chatMarkdownOptions = CcParseOptions(footnotes: false);

/// Chat-register builder overrides.
final CcBuilderRegistry chatMarkdownBuilders = CcBuilderRegistry(const {
  'inline_code': AppInlineCodeBuilder(),
  'details': AppDetailsBuilder(),
  'mermaid': AppMermaidBuilder(),
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
