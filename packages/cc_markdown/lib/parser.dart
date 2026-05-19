/// Flutter-free entrypoint for the cc_markdown PARSER only.
///
/// The main `package:cc_markdown/cc_markdown.dart` barrel also exports the
/// render/widget/stream/selection layers, which depend on Flutter and so cannot
/// be compiled by `dart compile js`. This barrel re-exports ONLY the pure-Dart
/// parse island (parser + AST + options + plugin types) plus the
/// AST↔primitive codec, so a background isolate / Web Worker can parse markdown
/// off the main thread and ship the result back as primitives.
///
/// A purity test (`architecture_constraints_test.dart`) enforces that nothing
/// reachable from here imports Flutter/`dart:ui`.
library;

export 'package:cc_markdown/src/ast/document.dart';
export 'package:cc_markdown/src/ast/nodes.dart';
export 'package:cc_markdown/src/codec/markdown_ast_codec.dart';
export 'package:cc_markdown/src/parser/emoji_shortcodes.dart';
export 'package:cc_markdown/src/parser/parse_options.dart';
export 'package:cc_markdown/src/parser/parser.dart';
export 'package:cc_markdown/src/plugins/plugin.dart';
