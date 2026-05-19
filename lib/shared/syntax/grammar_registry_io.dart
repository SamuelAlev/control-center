// Native grammar registry: everything is resident. See grammar_registry.dart.

import 'package:shiki_flutter/langs.dart';

final Map<String, CodeLanguage> _byId = _buildIndex();

Map<String, CodeLanguage> _buildIndex() {
  final map = <String, CodeLanguage>{};
  for (final lang in CodeLanguages.all) {
    map[lang.id] = lang;
    for (final alias in lang.aliases) {
      map.putIfAbsent(alias, () => lang);
    }
  }
  return map;
}

/// The grammar for [id] (canonical id or shiki alias), or `null` when the id
/// is unknown to the bundle.
CodeLanguage? codeLanguageForId(String id) => _byId[id];

/// Whether [id] can be tokenized right now without further loading.
bool isLanguageResident(String id) => _byId.containsKey(id);

/// Makes [id] available, returning whether it is. Synchronous-in-effect on
/// native: every grammar ships in the binary.
Future<bool> ensureLanguageAvailable(String id) =>
    Future<bool>.value(_byId.containsKey(id));
