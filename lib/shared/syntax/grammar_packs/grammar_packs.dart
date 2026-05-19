// Deferred grammar packs (web only): the long tail of grammars beyond the
// curated tier, grouped into a handful of `deferred as` libraries so dart2js
// emits a few well-gzipped chunks instead of ~200 tiny ones.
//
// Loaded packs register their grammars into [_loaded]; the pack index below
// says which pack owns which id so `loadPackForId` fetches at most one pack
// per miss.
//
// FLUTTER-FREE ON PURPOSE (see grammar_registry.dart).

import 'package:control_center/shared/syntax/grammar_packs/pack_index.dart';
import 'package:shiki_flutter/langs.dart';

final Map<String, CodeLanguage> _loaded = <String, CodeLanguage>{};
final Map<String, Future<bool>> _inflight = <String, Future<bool>>{};

/// The grammar for [id] from an already-loaded pack, or `null`.
CodeLanguage? loadedPackGrammarForId(String id) => _loaded[id];

/// Loads the deferred pack owning [id] (at most once per pack; concurrent
/// callers share the same future). Returns whether [id] is available after.
Future<bool> loadPackForId(String id) {
  final packName = packOfId[id];
  if (packName == null) {
    return Future<bool>.value(false);
  }
  return _inflight
      .putIfAbsent(packName, () => loadPack(packName, _register))
      .then((ok) => ok && _loaded.containsKey(id));
}

void _register(Iterable<CodeLanguage> langs) {
  for (final lang in langs) {
    _loaded[lang.id] = lang;
    for (final alias in lang.aliases) {
      _loaded.putIfAbsent(alias, () => lang);
    }
  }
}
