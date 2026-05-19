// The curated eager grammar tier: the ~50 languages that cover day-to-day
// fences, tool bodies, and PR diffs. This is the FULL grammar surface on web
// until a deferred pack loads (grammar_registry_web.dart) and the full
// surface of the web-compiled diff worker (worker_grammars_web.dart). Native
// builds don't use it — they index `CodeLanguages.all`.
//
// Uses only the public `CodeLanguages` members, so each reference pulls in
// exactly that grammar (plus its embedded dependencies) and the other ~200
// tree-shake away.
//
// DELIBERATE EXCLUSIONS — the mega-embedders: `markdown`/`mdx` statically
// reference ~57 embedded grammars, `vue`/`svelte`/`astro` ~25 each. One
// reference would drag the whole dependency tree into every web bundle and
// the worker JS. On web they arrive via the deferred packs instead; markdown
// fences *inside* CC markdown are extracted and highlighted per-fence by
// cc_markdown anyway, so the missing `markdown` grammar only affects diffs
// of .md files on web (plain text, same as today's hljs rendering of them).
//
// FLUTTER-FREE ON PURPOSE: imported by the diff worker core (dart compile js).

import 'package:shiki_flutter/langs.dart';

/// Grammars resident in the curated tier, indexed by id and aliases.
final Map<String, CodeLanguage> curatedGrammars = _index(const [
  // Core app + config
  CodeLanguages.dart,
  CodeLanguages.json,
  CodeLanguages.jsonc,
  CodeLanguages.json5,
  CodeLanguages.jsonl,
  CodeLanguages.yaml,
  CodeLanguages.toml,
  CodeLanguages.ini,
  CodeLanguages.dotenv,
  // Web
  CodeLanguages.typescript,
  CodeLanguages.tsx,
  CodeLanguages.jsx,
  CodeLanguages.javascript,
  CodeLanguages.html,
  CodeLanguages.xml,
  CodeLanguages.css,
  CodeLanguages.scss,
  CodeLanguages.sass,
  CodeLanguages.less,
  // Shell
  CodeLanguages.shellscript,
  CodeLanguages.shellsession,
  CodeLanguages.powershell,
  CodeLanguages.bat,
  // General-purpose
  CodeLanguages.python,
  CodeLanguages.go,
  CodeLanguages.rust,
  CodeLanguages.java,
  CodeLanguages.kotlin,
  CodeLanguages.swift,
  CodeLanguages.objectiveC,
  CodeLanguages.c,
  CodeLanguages.cpp,
  CodeLanguages.csharp,
  CodeLanguages.php,
  CodeLanguages.ruby,
  CodeLanguages.scala,
  CodeLanguages.groovy,
  CodeLanguages.lua,
  CodeLanguages.r,
  CodeLanguages.perl,
  // Query / schema
  CodeLanguages.sql,
  CodeLanguages.graphql,
  CodeLanguages.proto,
  // DevOps
  CodeLanguages.docker,
  CodeLanguages.make,
  CodeLanguages.cmake,
  // Misc
  CodeLanguages.diff,
  CodeLanguages.regexp,
  CodeLanguages.csv,
  CodeLanguages.log,
]);

Map<String, CodeLanguage> _index(List<CodeLanguage> langs) {
  final map = <String, CodeLanguage>{};
  for (final lang in langs) {
    map[lang.id] = lang;
    for (final alias in lang.aliases) {
      map.putIfAbsent(alias, () => lang);
    }
  }
  return Map.unmodifiable(map);
}
