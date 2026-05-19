// Web grammar registry: curated tier resident, long tail via deferred packs.
// See grammar_registry.dart.

import 'package:control_center/shared/syntax/curated_grammars.dart';
import 'package:control_center/shared/syntax/grammar_packs/grammar_packs.dart';
import 'package:shiki_flutter/langs.dart';

/// The grammar for [id], or `null` when it is neither curated nor in an
/// already-loaded deferred pack.
CodeLanguage? codeLanguageForId(String id) =>
    curatedGrammars[id] ?? loadedPackGrammarForId(id);

/// Whether [id] can be tokenized right now without a pack fetch.
bool isLanguageResident(String id) => codeLanguageForId(id) != null;

/// Makes [id] available, fetching its deferred grammar pack when needed.
/// Returns false for ids no pack owns.
Future<bool> ensureLanguageAvailable(String id) async {
  if (isLanguageResident(id)) {
    return true;
  }
  return loadPackForId(id);
}
