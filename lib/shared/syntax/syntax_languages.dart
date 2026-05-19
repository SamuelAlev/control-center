// The ONE language table: markdown fence hints, file paths, extensions and
// well-known filenames → canonical shiki grammar ids.
//
// Replaces three divergent maps that used to disagree with each other:
// `_languageAliases` in code_highlighter.dart (fences), `languageForExtension`
// in pr_review/syntax_highlighter.dart (diffs — whose `ts → typescript`
// mapping silently rendered every TS/TSX/TOML diff as plain text under
// highlight 0.7.0) and suggestion_renderer's private extension parse.
//
// Every id returned here MUST resolve in the desktop grammar registry
// (`CodeLanguages.all`); test/shared/syntax/syntax_languages_test.dart pins
// that, so a typo'd id fails CI instead of silently degrading to plain text.
//
// FLUTTER-FREE ON PURPOSE: pure data + string helpers, importable by the
// PR-diff worker core (compiled by `dart compile js`).

/// Resolves a markdown fenced-code-block info string (the text after the
/// opening ``` , e.g. `dart`, `ts`, `bash`) to a shiki language id.
///
/// Only the first whitespace-separated token is considered, so
/// attribute-style fences (` ```js title="x" `, ` ```dart {1,3} `) still
/// resolve. Returns `null` for an empty/unknown hint — callers render plain.
String? shikiLangForFence(String? info) {
  if (info == null) {
    return null;
  }
  final first = info.trim().split(RegExp(r'\s+')).first.toLowerCase();
  if (first.isEmpty) {
    return null;
  }
  return _fenceAliases[first];
}

/// Resolves a file path to a shiki language id: exact basename first
/// (Dockerfile, Makefile, CMakeLists.txt, …), then extension, then dotfile
/// name (`.zshrc`). Returns `null` when unknown — callers render plain.
String? shikiLangForPath(String path) {
  final basename = path.split('/').last.split(r'\').last;
  if (basename.isEmpty) {
    return null;
  }
  final byName = _filenames[basename] ?? _filenames[basename.toLowerCase()];
  if (byName != null) {
    return byName;
  }
  // `.env.local` / `.env.production` — prefix, not exact.
  if (basename.startsWith('.env')) {
    return 'dotenv';
  }
  final dot = basename.lastIndexOf('.');
  if (dot > 0 && dot < basename.length - 1) {
    return shikiLangForExtension(basename.substring(dot + 1));
  }
  if (dot == 0 && basename.length > 1) {
    // Dotfile with no extension: try the name after the dot (`.zshrc`).
    return _dotfileNames[basename.substring(1).toLowerCase()];
  }
  return null;
}

/// Resolves a bare file extension (no dot, e.g. `tsx`) to a shiki language
/// id, or `null` when unknown.
String? shikiLangForExtension(String ext) {
  if (ext.isEmpty) {
    return null;
  }
  return _extensions[ext.toLowerCase()];
}

/// Every shiki id any table in this module can return. The registry guard
/// test pins that each resolves in the desktop grammar bundle, so a typo'd
/// id fails CI instead of silently rendering plain.
Set<String> get allMappedLanguageIds => {
  ..._fenceAliases.values,
  ..._extensions.values,
  ..._filenames.values,
  ..._dotfileNames.values,
  'dotenv', // the `.env*` prefix branch in shikiLangForPath
};

/// Relative tokenization cost of a grammar, measured in the Phase-0 spike
/// (debug VM, µs/line): light ≲60, medium ≲200, heavy ≲1200, extreme beyond.
/// Unmeasured grammars default to [heavy] — misclassifying an exotic grammar
/// as async costs a one-frame color swap; misclassifying it as sync costs a
/// dropped frame.
enum SyntaxWeight {
  /// dart 35, json 37, yaml 54 µs/line.
  light,

  /// markdown 134, html 141, rust 148, python 150, go 184 µs/line.
  medium,

  /// bash 436, javascript/typescript/tsx ~1100 µs/line — and the default.
  heavy,

  /// cpp 3818, sql 4616 µs/line.
  extreme,
}

/// The measured/estimated weight class for [langId] (`null` = plain = free).
SyntaxWeight syntaxWeightFor(String? langId) {
  if (langId == null) {
    return SyntaxWeight.light;
  }
  if (_lightLangs.contains(langId)) {
    return SyntaxWeight.light;
  }
  if (_mediumLangs.contains(langId)) {
    return SyntaxWeight.medium;
  }
  if (_extremeLangs.contains(langId)) {
    return SyntaxWeight.extreme;
  }
  return SyntaxWeight.heavy;
}

/// How many lines a surface may tokenize synchronously inside `build()` for
/// [weight] before it must go async (or plain). Derived from the spike
/// numbers with a ~1-frame budget in debug mode.
int syncLineBudget(SyntaxWeight weight) => switch (weight) {
  SyntaxWeight.light => 400,
  SyntaxWeight.medium => 100,
  SyntaxWeight.heavy => 16,
  SyntaxWeight.extreme => 8,
};

const Set<String> _lightLangs = {
  'dart',
  'json',
  'jsonc',
  'json5',
  'jsonl',
  'yaml',
  'ini',
  'dotenv',
  'diff',
  'csv',
  'tsv',
  'log',
};

const Set<String> _mediumLangs = {
  'markdown',
  'mdx',
  'html',
  'xml',
  'xsl',
  'css',
  'scss',
  'sass',
  'less',
  'python',
  'go',
  'rust',
  'toml',
  'java',
  'kotlin',
  'ruby',
  'php',
  'swift',
  'graphql',
  'proto',
  'make',
  'docker',
  'cmake',
  'gherkin',
  'http',
  'codeowners',
  'mermaid',
  'r',
  'julia',
  'elm',
  'gleam',
};

const Set<String> _extremeLangs = {'cpp', 'objective-cpp', 'sql', 'plsql'};

/// Fence hint → canonical shiki id. Includes every alias the old
/// `_languageAliases` handled, retargeted to real grammars (the deliberate
/// `ts → javascript` workaround for highlight 0.7.0's throwing TS grammar is
/// gone — shiki's typescript/tsx grammars handle JSX).
const Map<String, String> _fenceAliases = {
  'dart': 'dart',
  // TypeScript / JavaScript — real grammars again.
  'ts': 'typescript',
  'typescript': 'typescript',
  'mts': 'typescript',
  'cts': 'typescript',
  'tsx': 'tsx',
  'jsx': 'jsx',
  'js': 'javascript',
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
  'objc': 'objective-c',
  'objectivec': 'objective-c',
  'objective-c': 'objective-c',
  // C family
  'cs': 'csharp',
  'csharp': 'csharp',
  'c#': 'csharp',
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
  'jsonc': 'jsonc',
  'json5': 'json5',
  'jsonl': 'jsonl',
  'ndjson': 'jsonl',
  'yaml': 'yaml',
  'yml': 'yaml',
  'toml': 'toml',
  'ini': 'ini',
  'cfg': 'ini',
  'conf': 'ini',
  'properties': 'ini',
  'dotenv': 'dotenv',
  'env': 'dotenv',
  // Markup
  'xml': 'xml',
  'html': 'html',
  'htm': 'html',
  'xhtml': 'html',
  'svg': 'xml',
  'plist': 'xml',
  'vue': 'vue',
  'svelte': 'svelte',
  'astro': 'astro',
  // Styles
  'css': 'css',
  'scss': 'scss',
  'sass': 'sass',
  'less': 'less',
  // Shell
  'sh': 'shellscript',
  'bash': 'shellscript',
  'zsh': 'shellscript',
  'shell': 'shellscript',
  'shellscript': 'shellscript',
  'shellsession': 'shellsession',
  'console': 'shellsession',
  'fish': 'fish',
  'powershell': 'powershell',
  'ps1': 'powershell',
  'pwsh': 'powershell',
  'bat': 'bat',
  'cmd': 'bat',
  // Query / schema
  'sql': 'sql',
  'mysql': 'sql',
  'postgres': 'sql',
  'postgresql': 'sql',
  'plpgsql': 'plsql',
  'graphql': 'graphql',
  'gql': 'graphql',
  'protobuf': 'proto',
  'proto': 'proto',
  'prisma': 'prisma',
  // Docs
  'md': 'markdown',
  'markdown': 'markdown',
  'mdx': 'mdx',
  'tex': 'latex',
  'latex': 'latex',
  'rst': 'rst',
  'adoc': 'asciidoc',
  'asciidoc': 'asciidoc',
  // Web / scripting
  'php': 'php',
  'lua': 'lua',
  'r': 'r',
  'perl': 'perl',
  'pl': 'perl',
  'coffee': 'coffee',
  'coffeescript': 'coffee',
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
  'elm': 'elm',
  'ocaml': 'ocaml',
  'ml': 'ocaml',
  'fsharp': 'fsharp',
  'gleam': 'gleam',
  // DevOps
  'dockerfile': 'docker',
  'docker': 'docker',
  'makefile': 'make',
  'make': 'make',
  'mk': 'make',
  'cmake': 'cmake',
  'nginx': 'nginx',
  'apache': 'apache',
  'terraform': 'terraform',
  'tf': 'terraform',
  'hcl': 'hcl',
  'nix': 'nix',
  'just': 'just',
  'justfile': 'just',
  // Diffs
  'diff': 'diff',
  'patch': 'diff',
  // Misc
  'mermaid': 'mermaid',
  'mmd': 'mermaid',
  'zig': 'zig',
  'nim': 'nim',
  'julia': 'julia',
  'jl': 'julia',
  'matlab': 'matlab',
  'solidity': 'solidity',
  'sol': 'solidity',
  'vim': 'viml',
  'viml': 'viml',
  'asm': 'asm',
  'wasm': 'wasm',
  'regex': 'regexp',
  'regexp': 'regexp',
  'gherkin': 'gherkin',
  'feature': 'gherkin',
  'http': 'http',
  'csv': 'csv',
  'tsv': 'tsv',
  'log': 'log',
  'jinja': 'jinja',
  'twig': 'twig',
  'liquid': 'liquid',
  'kdl': 'kdl',
  'typst': 'typst',
  'nushell': 'nushell',
  'nu': 'nushell',
};

/// File extension (lowercased, no dot) → canonical shiki id.
const Map<String, String> _extensions = {
  'dart': 'dart',
  'ts': 'typescript',
  'mts': 'typescript',
  'cts': 'typescript',
  'tsx': 'tsx',
  'jsx': 'jsx',
  'js': 'javascript',
  'mjs': 'javascript',
  'cjs': 'javascript',
  'py': 'python',
  'rb': 'ruby',
  'go': 'go',
  'rs': 'rust',
  'java': 'java',
  'kt': 'kotlin',
  'kts': 'kotlin',
  'scala': 'scala',
  'groovy': 'groovy',
  'gradle': 'groovy',
  'swift': 'swift',
  'm': 'objective-c',
  'mm': 'objective-cpp',
  'cs': 'csharp',
  'cpp': 'cpp',
  'cc': 'cpp',
  'cxx': 'cpp',
  'hpp': 'cpp',
  'hh': 'cpp',
  'hxx': 'cpp',
  'c': 'c',
  'h': 'c',
  'json': 'json',
  'jsonc': 'jsonc',
  'json5': 'json5',
  'jsonl': 'jsonl',
  'ndjson': 'jsonl',
  'yaml': 'yaml',
  'yml': 'yaml',
  'toml': 'toml',
  'ini': 'ini',
  'cfg': 'ini',
  'conf': 'ini',
  'properties': 'ini',
  'env': 'dotenv',
  'xml': 'xml',
  'svg': 'xml',
  'plist': 'xml',
  'xsd': 'xml',
  'xsl': 'xsl',
  'html': 'html',
  'htm': 'html',
  'xhtml': 'html',
  'vue': 'vue',
  'svelte': 'svelte',
  'astro': 'astro',
  'css': 'css',
  'scss': 'scss',
  'sass': 'sass',
  'less': 'less',
  'sh': 'shellscript',
  'bash': 'shellscript',
  'zsh': 'shellscript',
  'fish': 'fish',
  'ps1': 'powershell',
  'psm1': 'powershell',
  'bat': 'bat',
  'cmd': 'bat',
  'sql': 'sql',
  'graphql': 'graphql',
  'gql': 'graphql',
  'proto': 'proto',
  'prisma': 'prisma',
  'md': 'markdown',
  'markdown': 'markdown',
  'mdx': 'mdx',
  'tex': 'latex',
  'rst': 'rst',
  'adoc': 'asciidoc',
  'asciidoc': 'asciidoc',
  'php': 'php',
  'lua': 'lua',
  'r': 'r',
  'pl': 'perl',
  'pm': 'perl',
  'coffee': 'coffee',
  'hs': 'haskell',
  'ex': 'elixir',
  'exs': 'elixir',
  'erl': 'erlang',
  'hrl': 'erlang',
  'clj': 'clojure',
  'cljs': 'clojure',
  'cljc': 'clojure',
  'elm': 'elm',
  'ml': 'ocaml',
  'mli': 'ocaml',
  'fs': 'fsharp',
  'gleam': 'gleam',
  'diff': 'diff',
  'patch': 'diff',
  'zig': 'zig',
  'nim': 'nim',
  'jl': 'julia',
  'tf': 'terraform',
  'tfvars': 'terraform',
  'hcl': 'hcl',
  'nix': 'nix',
  'vim': 'viml',
  's': 'asm',
  'asm': 'asm',
  'wat': 'wasm',
  'sol': 'solidity',
  'feature': 'gherkin',
  'csv': 'csv',
  'tsv': 'tsv',
  'log': 'log',
  'http': 'http',
  'mmd': 'mermaid',
  'mermaid': 'mermaid',
  'cmake': 'cmake',
  'mk': 'make',
  'gd': 'gdscript',
  'dockerfile': 'docker',
  'kdl': 'kdl',
  'typ': 'typst',
  'nu': 'nushell',
  'just': 'just',
};

/// Exact basename → id. Checked before the extension so `CMakeLists.txt`
/// beats `.txt` and `Dockerfile.prod` still resolves via [_extensions].
const Map<String, String> _filenames = {
  'Dockerfile': 'docker',
  'dockerfile': 'docker',
  'Containerfile': 'docker',
  'Makefile': 'make',
  'makefile': 'make',
  'GNUmakefile': 'make',
  'CMakeLists.txt': 'cmake',
  'cmakelists.txt': 'cmake',
  'Gemfile': 'ruby',
  'Rakefile': 'ruby',
  'Podfile': 'ruby',
  'Brewfile': 'ruby',
  'Fastfile': 'ruby',
  'Justfile': 'just',
  'justfile': 'just',
  'CODEOWNERS': 'codeowners',
  'codeowners': 'codeowners',
  '.gitignore': 'ini',
  '.gitattributes': 'ini',
  '.editorconfig': 'ini',
  'go.mod': 'go',
  'go.sum': 'ini',
};

/// Dotfile name (after the leading dot, lowercased) → id, for dotfiles that
/// are not in [_filenames] and have no extension (`.zshrc` → `zshrc`).
const Map<String, String> _dotfileNames = {
  'zshrc': 'shellscript',
  'zshenv': 'shellscript',
  'zprofile': 'shellscript',
  'bashrc': 'shellscript',
  'bash_profile': 'shellscript',
  'bash_aliases': 'shellscript',
  'profile': 'shellscript',
  'vimrc': 'viml',
  'npmrc': 'ini',
  'yarnrc': 'ini',
  'gemrc': 'yaml',
};
