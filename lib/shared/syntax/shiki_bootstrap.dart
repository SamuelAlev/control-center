// One-time shiki configuration for app startup. Registration itself is lazy
// and idempotent (CcShikiTokenizer registers themes/grammars before every
// tokenize), so widget tests work without this — bootstrap only warms the
// common path so the first visible code block doesn't pay the grammar
// compile.

import 'package:control_center/shared/syntax/shiki_tokenizers.dart';
import 'package:shiki_flutter/engine.dart';

/// Configures shiki for the app process and pre-warms the hottest grammars.
/// Call once from the platform bootstrap. Safe to call more than once.
void initializeShikiHighlighting() {
  ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
    // Web: use the prebuilt tokenize Web Worker (web/shiki_tokenize_worker.js,
    // installed by tool/gen_workers.sh). Falls back to inline transparently
    // when the asset is missing or CSP-blocked.
    asyncWeb: true,
  );
  CcShikiTokenizer.instance.warmUp(const [
    'dart',
    'javascript',
    'typescript',
    'json',
    'yaml',
    'shellscript',
  ]);
}
