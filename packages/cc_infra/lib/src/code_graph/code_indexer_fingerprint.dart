import 'dart:convert';

import 'package:cc_natives/cc_natives.dart' show GrammarManager;
import 'package:crypto/crypto.dart';

/// Bump when `CodeExtractor`'s capture→symbol/edge mapping changes in a way
/// that should re-extract every file (new symbol kinds, changed qualified
/// naming, different edge semantics). Query/grammar changes are picked up
/// automatically via [codeIndexerFingerprint]'s artifact stamps.
const int kCodeIndexerVersion = 1;

/// SHA-256 fingerprint of the extraction toolchain: [kCodeIndexerVersion] +
/// every `.scm` query and tree-sitter grammar the [GrammarManager] can see
/// (embedded content hashes; on-disk `name|mtime|size` stamps).
///
/// Stored in each index checkpoint so a toolchain change — editing a query,
/// installing a grammar for a previously-unindexable language, bumping the
/// extractor — invalidates every checkpoint and forces a real run, without
/// any manual cache-busting.
///
/// Deliberately conservative: the stamps include on-disk MTIMES, so
/// re-staging byte-identical artifacts (any `dart build cli`, which re-copies
/// the grammar dylibs into the bundle) also invalidates. The cost is one
/// re-walk per rebuild, and that walk keeps the per-file mtime fast-path — it
/// stats rather than re-reads, and re-extracts nothing. Under-invalidating
/// would be the worse failure: a stale graph that never self-heals.
Future<String> codeIndexerFingerprint(GrammarManager manager) async {
  final stamps = await manager.artifactStamps();
  return sha256
      .convert(utf8.encode('v$kCodeIndexerVersion|${stamps.join('|')}'))
      .toString();
}
