// The curated eager grammar tier: the ~50 languages that cover day-to-day fences, tool
// bodies and PR diffs.
// This is the FULL grammar surface on web until a deferred pack loads
// (grammar_registry_web.dart) and the full surface of the web-compiled diff worker
// (worker_grammars_web.dart).
// Uses only the public `CodeLanguages` members, so each reference pulls in exactly that
// grammar (plus its embedded dependencies) and the other ~200 tree-shake away.

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
