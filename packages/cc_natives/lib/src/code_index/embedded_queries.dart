// GENERATED FILE — DO NOT EDIT BY HAND.
//
// Generated from the canonical `scripts/natives/queries/*.scm` by
// `tool/gen_embedded_queries.dart`. To change a query, edit the .scm and run:
//
//   fvm dart run tool/gen_embedded_queries.dart
//
// test/tooling/embedded_queries_test.dart pins this file byte-identical to
// the .scm sources, so a stale regeneration fails CI.

/// The tree-sitter `.scm` extraction queries, embedded as Dart constants so
/// every host (the Flutter desktop AND the `dart build cli` server binary)
/// carries them without shipping loose data files — the grammar dylibs bundle
/// as code assets and these queries compile in beside them.
///
/// An on-disk `<queryId>.scm` beside the grammar libs still wins at runtime
/// (`GrammarManager.loadQuery`), staged by `build_tree_sitter.sh` as a
/// dev-time override.
///
/// Keyed by query id (see `queryIdFor` — `tsx` reuses the `typescript` query).
library;

/// Query id → `.scm` source.
const Map<String, String> embeddedTreeSitterQueries = {
  'dart': _$dart,
  'javascript': _$javascript,
  'php': _$php,
  'typescript': _$typescript,
};

const String _$dart = r'''
; Tree-sitter query for Dart code indexing.
;
; CAPTURE NAMES are the stable contract with CodeExtractor:
;   @<kind>.def / @<kind>.name  declaration span + identifier
;   @extends.name / @implements.name / @mixesin.name  relationship targets
;   @import.uri   import/export URI     @call.name  call-site callee
;
; Patterns are separated by `;;;` lines: the parser compiles each independently
; and skips any that fail (e.g. a node type missing from the installed grammar),
; so one bad pattern never blanks the whole language. NODE TYPE names target the
; community Dart grammar and may need tuning to the grammar build that ships.

(class_definition (identifier) @class.name) @class.def
;;;
(mixin_declaration (identifier) @mixin.name) @mixin.def
;;;
(extension_declaration (identifier) @extension.name) @extension.def
;;;
(enum_declaration (identifier) @enum.name) @enum.def
;;;
(function_signature (identifier) @function.name) @function.def
;;;
(method_signature (function_signature (identifier) @method.name)) @method.def
;;;
(getter_signature (identifier) @getter.name) @getter.def
;;;
(setter_signature (identifier) @setter.name) @setter.def
;;;
(constructor_signature (identifier) @constructor.name) @constructor.def
;;;
(superclass (type_identifier) @extends.name)
;;;
(interfaces (type_identifier) @implements.name)
;;;
(mixins (type_identifier) @mixesin.name)
;;;
(import_or_export (library_import (import_specification (uri) @import.uri)))
;;;
(method_invocation (identifier) @call.name)
''';

const String _$javascript = r'''
; Tree-sitter query for JavaScript (and JSX) code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-javascript and may need tuning.

(class_declaration name: (identifier) @class.name) @class.def
;;;
(function_declaration name: (identifier) @function.name) @function.def
;;;
(generator_function_declaration name: (identifier) @function.name) @function.def
;;;
(method_definition name: (property_identifier) @method.name) @method.def
;;;
(class_heritage (identifier) @extends.name)
;;;
(import_statement source: (string) @import.uri)
;;;
(call_expression function: (identifier) @call.name)
;;;
(call_expression function: (member_expression property: (property_identifier) @call.name))
;;;
(new_expression constructor: (identifier) @call.name)
''';

const String _$php = r'''
; Tree-sitter query for PHP code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-php and may need tuning.
; Interfaces and traits are captured as @class.* / @enum.* approximations.

(class_declaration name: (name) @class.name) @class.def
;;;
(interface_declaration name: (name) @class.name) @class.def
;;;
(trait_declaration name: (name) @class.name) @class.def
;;;
(enum_declaration name: (name) @enum.name) @enum.def
;;;
(function_definition name: (name) @function.name) @function.def
;;;
(method_declaration name: (name) @method.name) @method.def
;;;
(base_clause (name) @extends.name)
;;;
(class_interface_clause (name) @implements.name)
;;;
(namespace_use_clause (qualified_name) @import.uri)
;;;
(namespace_use_clause (name) @import.uri)
;;;
(function_call_expression function: (name) @call.name)
;;;
(member_call_expression name: (name) @call.name)
;;;
(scoped_call_expression name: (name) @call.name)
;;;
(object_creation_expression (name) @call.name)
''';

const String _$typescript = r'''
; Tree-sitter query for TypeScript (also used for .tsx via the tsx grammar).
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-typescript and may need tuning.
; Interfaces are captured as @class.* (no dedicated interface kind).

(class_declaration name: (type_identifier) @class.name) @class.def
;;;
(interface_declaration name: (type_identifier) @class.name) @class.def
;;;
(function_declaration name: (identifier) @function.name) @function.def
;;;
(method_definition name: (property_identifier) @method.name) @method.def
;;;
(abstract_method_signature name: (property_identifier) @method.name) @method.def
;;;
(extends_clause (identifier) @extends.name)
;;;
(extends_clause (type_identifier) @extends.name)
;;;
(implements_clause (type_identifier) @implements.name)
;;;
(import_statement source: (string) @import.uri)
;;;
(call_expression function: (identifier) @call.name)
;;;
(call_expression function: (member_expression property: (property_identifier) @call.name))
;;;
(new_expression constructor: (identifier) @call.name)
''';
