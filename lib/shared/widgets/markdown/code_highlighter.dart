import 'package:control_center/shared/utils/syntax_palette.dart';
import 'package:flutter/painting.dart';
import 'package:highlight/highlight.dart' as hl;

/// Maps a markdown fenced-code-block info string (the text after the opening
/// ```` ``` ````, e.g. `dart`, `ts`, `bash`) to a `highlight.dart` language id.
///
/// Accepts both canonical language names and the common aliases / file
/// extensions people write in fences. Only the first whitespace-separated token
/// is considered, so attribute-style fences (` ```js title="x" `,
/// ` ```dart {1,3} `) still resolve. Returns `null` for an empty/unknown hint —
/// the caller should then render the block as plain (unhighlighted) text.
String? resolveHighlightLanguage(String? info) {
  if (info == null) {
    return null;
  }
  final first = info.trim().split(RegExp(r'\s+')).first.toLowerCase();
  if (first.isEmpty) {
    return null;
  }
  return _languageAliases[first];
}

/// Tokenizes [code] with `highlight.dart` for [languageId] and returns coloured
/// [TextSpan]s using [palette]. Each span carries only a `color` override; the
/// caller supplies the shared base style (mono font, size, weight) on the
/// wrapping [TextSpan] / `Text.rich`.
///
/// Falls back to a single uncoloured span when there's no language, the code is
/// empty, or the language isn't registered (parsing throws) — so an unknown
/// fence degrades to plain monospace text rather than failing.
List<InlineSpan> highlightCodeSpans({
  required String code,
  required String? languageId,
  required Map<String, int> palette,
}) {
  if (languageId == null || code.isEmpty) {
    return [TextSpan(text: code)];
  }

  hl.Result result;
  try {
    result = hl.highlight.parse(code, language: languageId);
  } catch (_) {
    return [TextSpan(text: code)];
  }

  final spans = <InlineSpan>[];
  void walk(hl.Node node, Color? inherited) {
    final scope = node.className;
    final color =
        scope != null ? (syntaxColorFor(palette, scope) ?? inherited) : inherited;
    if (node.value != null) {
      spans.add(
        TextSpan(
          text: node.value,
          style: color != null ? TextStyle(color: color) : null,
        ),
      );
    } else if (node.children != null) {
      for (final child in node.children!) {
        walk(child, color);
      }
    }
  }

  for (final node in result.nodes ?? const <hl.Node>[]) {
    walk(node, null);
  }
  if (spans.isEmpty) {
    return [TextSpan(text: code)];
  }
  return spans;
}

/// Fence-info / extension → `highlight.dart` language id. Canonical ids are
/// the ones the bundled `highlight` package registers; unmapped or
/// unregistered hints fall back to plain text in [highlightCodeSpans].
const Map<String, String> _languageAliases = {
  'dart': 'dart',
  // TypeScript / JavaScript — all routed to the `javascript` grammar on
  // purpose. highlight 0.7.0's `typescript` grammar THROWS on JSX/TSX content
  // (e.g. `<Foo.Bar>`), and because a fenced block is parsed as one unit a
  // single JSX line drops the *entire* block back to plain text. The
  // `javascript` grammar highlights JS, JSX and TSX (and TS as a superset)
  // robustly without throwing, so it's the reliable choice for whole-block
  // markdown rendering.
  'ts': 'javascript',
  'tsx': 'javascript',
  'typescript': 'javascript',
  'mts': 'javascript',
  'cts': 'javascript',
  'js': 'javascript',
  'jsx': 'javascript',
  'mjs': 'javascript',
  'cjs': 'javascript',
  'javascript': 'javascript',
  'node': 'javascript',
  // Python
  'py': 'python',
  'py3': 'python',
  'python': 'python',
  // Ruby
  'rb': 'ruby',
  'ruby': 'ruby',
  // Go
  'go': 'go',
  'golang': 'go',
  // Rust
  'rs': 'rust',
  'rust': 'rust',
  // JVM
  'java': 'java',
  'kt': 'kotlin',
  'kts': 'kotlin',
  'kotlin': 'kotlin',
  'scala': 'scala',
  'groovy': 'groovy',
  'gradle': 'groovy',
  // Apple
  'swift': 'swift',
  'objc': 'objectivec',
  'objectivec': 'objectivec',
  'objective-c': 'objectivec',
  // C family
  'cs': 'cs',
  'csharp': 'cs',
  'c#': 'cs',
  'cpp': 'cpp',
  'c++': 'cpp',
  'cc': 'cpp',
  'cxx': 'cpp',
  'hpp': 'cpp',
  'hh': 'cpp',
  'c': 'c',
  'h': 'c',
  // Data / config
  'json': 'json',
  'jsonc': 'json',
  'json5': 'json',
  'yaml': 'yaml',
  'yml': 'yaml',
  'toml': 'ini',
  'ini': 'ini',
  'cfg': 'ini',
  'conf': 'ini',
  'properties': 'properties',
  // Markup
  'xml': 'xml',
  'html': 'xml',
  'htm': 'xml',
  'xhtml': 'xml',
  'svg': 'xml',
  'vue': 'xml',
  'plist': 'xml',
  // Styles
  'css': 'css',
  'scss': 'scss',
  'sass': 'scss',
  'less': 'less',
  // Shell
  'sh': 'bash',
  'bash': 'bash',
  'zsh': 'bash',
  'shell': 'bash',
  'shellsession': 'bash',
  'console': 'bash',
  'powershell': 'powershell',
  'ps1': 'powershell',
  'pwsh': 'powershell',
  // Query / schema
  'sql': 'sql',
  'mysql': 'sql',
  'postgres': 'sql',
  'postgresql': 'sql',
  'plpgsql': 'sql',
  'graphql': 'graphql',
  'gql': 'graphql',
  'protobuf': 'protobuf',
  'proto': 'protobuf',
  // Docs
  'md': 'markdown',
  'mdx': 'markdown',
  'markdown': 'markdown',
  'tex': 'tex',
  'latex': 'tex',
  // Web / scripting
  'php': 'php',
  'lua': 'lua',
  'r': 'r',
  'perl': 'perl',
  'pl': 'perl',
  // Functional
  'haskell': 'haskell',
  'hs': 'haskell',
  'elixir': 'elixir',
  'ex': 'elixir',
  'exs': 'elixir',
  'erlang': 'erlang',
  'erl': 'erlang',
  'clojure': 'clojure',
  'clj': 'clojure',
  // DevOps
  'dockerfile': 'dockerfile',
  'docker': 'dockerfile',
  'makefile': 'makefile',
  'make': 'makefile',
  'mk': 'makefile',
  'nginx': 'nginx',
  'apache': 'apache',
  // Diffs
  'diff': 'diff',
  'patch': 'diff',
};
