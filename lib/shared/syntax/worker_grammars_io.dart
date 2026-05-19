// Native worker grammar surface: everything. See worker_grammars.dart.

import 'package:control_center/shared/syntax/grammar_registry_io.dart' as io;
import 'package:shiki_flutter/langs.dart';

/// The grammar for [id] available to the diff worker, or `null`.
CodeLanguage? workerGrammarForId(String id) => io.codeLanguageForId(id);
