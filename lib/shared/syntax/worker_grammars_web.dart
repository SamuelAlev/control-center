// Web worker grammar surface: the curated eager tier only (no deferred
// loading inside a single-file worker bundle). See worker_grammars.dart.

import 'package:control_center/shared/syntax/curated_grammars.dart';
import 'package:shiki_flutter/langs.dart';

/// The grammar for [id] available to the diff worker, or `null`.
CodeLanguage? workerGrammarForId(String id) => curatedGrammars[id];
