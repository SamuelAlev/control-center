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
  'ada': _$ada,
  'asm': _$asm,
  'c': _$c,
  'c_sharp': _$cSharp,
  'cpp': _$cpp,
  'dart': _$dart,
  'go': _$go,
  'java': _$java,
  'javascript': _$javascript,
  'kotlin': _$kotlin,
  'matlab': _$matlab,
  'php': _$php,
  'python': _$python,
  'r': _$r,
  'ruby': _$ruby,
  'rust': _$rust,
  'swift': _$swift,
  'typescript': _$typescript,
  'zig': _$zig,
};

const String _$ada = r'''
; Tree-sitter query for Ada code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-ada and may need tuning.
; Packages are captured as @class.*.

(procedure_specification name: (_) @function.name) @function.def
;;;
(function_specification name: (_) @function.name) @function.def
;;;
(package_declaration name: (_) @class.name) @class.def
;;;
(package_body name: (_) @class.name) @class.def
;;;
(generic_instantiation name: (_) @class.name) @class.def
;;;
(with_clause (_) @import.uri)
;;;
(use_clause (_) @import.uri)
''';

const String _$asm = r'''
; Tree-sitter query for Assembly code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-asm and may need tuning.
; Labels are captured as @function.* — assembly has no class/function AST.

(label (ident) @function.name) @function.def
;;;
(label (word) @function.name) @function.def
''';

const String _$c = r'''
; Tree-sitter query for C code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-c and may need tuning.
; Structs and unions are captured as @class.* (no dedicated struct kind).

(struct_specifier name: (type_identifier) @class.name) @class.def
;;;
(union_specifier name: (type_identifier) @class.name) @class.def
;;;
(enum_specifier name: (type_identifier) @enum.name) @enum.def
;;;
(function_definition declarator: (function_declarator declarator: (identifier) @function.name)) @function.def
;;;
(function_definition declarator: (pointer_declarator declarator: (function_declarator declarator: (identifier) @function.name))) @function.def
;;;
(preproc_include path: (string_literal) @import.uri)
;;;
(preproc_include path: (system_lib_string) @import.uri)
;;;
(call_expression function: (identifier) @call.name)
;;;
(call_expression function: (field_expression field: (field_identifier) @call.name))
''';

const String _$cSharp = r'''
; Tree-sitter query for C# code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-c-sharp and may need tuning.
; Interfaces, structs and records are captured as @class.*.

(class_declaration name: (identifier) @class.name) @class.def
;;;
(interface_declaration name: (identifier) @class.name) @class.def
;;;
(struct_declaration name: (identifier) @class.name) @class.def
;;;
(record_declaration name: (identifier) @class.name) @class.def
;;;
(enum_declaration name: (identifier) @enum.name) @enum.def
;;;
(method_declaration name: (identifier) @method.name) @method.def
;;;
(constructor_declaration name: (identifier) @constructor.name) @constructor.def
;;;
(base_list (identifier) @extends.name)
;;;
(using_directive (identifier) @import.uri)
;;;
(using_directive (qualified_name) @import.uri)
;;;
(invocation_expression function: (identifier) @call.name)
;;;
(invocation_expression function: (member_access_expression name: (identifier) @call.name))
''';

const String _$cpp = r'''
; Tree-sitter query for C++ code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-cpp and may need tuning.

(class_specifier name: (type_identifier) @class.name) @class.def
;;;
(struct_specifier name: (type_identifier) @class.name) @class.def
;;;
(union_specifier name: (type_identifier) @class.name) @class.def
;;;
(enum_specifier name: (type_identifier) @enum.name) @enum.def
;;;
(namespace_definition name: (namespace_identifier) @class.name) @class.def
;;;
(function_definition declarator: (function_declarator declarator: (identifier) @function.name)) @function.def
;;;
(function_definition declarator: (function_declarator declarator: (qualified_identifier name: (identifier) @function.name))) @function.def
;;;
(function_definition declarator: (pointer_declarator declarator: (function_declarator declarator: (identifier) @function.name))) @function.def
;;;
(field_declaration declarator: (function_declarator declarator: (field_identifier) @method.name)) @method.def
;;;
(preproc_include path: (string_literal) @import.uri)
;;;
(preproc_include path: (system_lib_string) @import.uri)
;;;
(using_declaration (identifier) @import.uri)
;;;
(call_expression function: (identifier) @call.name)
;;;
(call_expression function: (field_expression field: (field_identifier) @call.name))
;;;
(call_expression function: (qualified_identifier name: (identifier) @call.name))
''';

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

const String _$go = r'''
; Tree-sitter query for Go code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-go and may need tuning.
; Struct and interface types are captured as @class.*.

(function_declaration name: (identifier) @function.name) @function.def
;;;
(method_declaration name: (field_identifier) @method.name) @method.def
;;;
(type_declaration (type_spec name: (type_identifier) @class.name type: (struct_type)) @class.def)
;;;
(type_declaration (type_spec name: (type_identifier) @class.name type: (interface_type)) @class.def)
;;;
(import_spec path: (interpreted_string_literal) @import.uri)
;;;
(import_spec path: (raw_string_literal) @import.uri)
;;;
(call_expression function: (identifier) @call.name)
;;;
(call_expression function: (selector_expression field: (field_identifier) @call.name))
''';

const String _$java = r'''
; Tree-sitter query for Java code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-java and may need tuning.
; Interfaces and records are captured as @class.*.

(class_declaration name: (identifier) @class.name) @class.def
;;;
(interface_declaration name: (identifier) @class.name) @class.def
;;;
(enum_declaration name: (identifier) @enum.name) @enum.def
;;;
(record_declaration name: (identifier) @class.name) @class.def
;;;
(method_declaration name: (identifier) @method.name) @method.def
;;;
(constructor_declaration name: (identifier) @constructor.name) @constructor.def
;;;
(superclass (type_identifier) @extends.name)
;;;
(super_interfaces (type_list (type_identifier) @implements.name))
;;;
(import_declaration (scoped_identifier) @import.uri)
;;;
(import_declaration (identifier) @import.uri)
;;;
(method_invocation name: (identifier) @call.name)
;;;
(object_creation_expression type: (type_identifier) @call.name)
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

const String _$kotlin = r'''
; Tree-sitter query for Kotlin code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-kotlin (Amaan / tree-sitter-grammars)
; and may need tuning. class_declaration has no named fields — match positionally.
; Objects and interfaces are captured as @class.*.

(class_declaration (type_identifier) @class.name) @class.def
;;;
(object_declaration (type_identifier) @class.name) @class.def
;;;
(companion_object (type_identifier) @class.name) @class.def
;;;
(function_declaration (simple_identifier) @function.name) @function.def
;;;
(import_header (identifier) @import.uri)
;;;
(call_expression (simple_identifier) @call.name)
;;;
(call_expression (navigation_expression (navigation_suffix (simple_identifier) @call.name)))
''';

const String _$matlab = r'''
; Tree-sitter query for MATLAB code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-matlab and may need tuning.

(class_definition name: (identifier) @class.name) @class.def
;;;
(function_definition name: (identifier) @function.name) @function.def
;;;
(function_signature name: (identifier) @function.name) @function.def
;;;
(function_call name: (identifier) @call.name)
;;;
(command (command_name) @call.name)
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

const String _$python = r'''
; Tree-sitter query for Python code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-python and may need tuning.

(class_definition name: (identifier) @class.name) @class.def
;;;
(function_definition name: (identifier) @function.name) @function.def
;;;
(decorated_definition definition: (class_definition name: (identifier) @class.name) @class.def)
;;;
(decorated_definition definition: (function_definition name: (identifier) @function.name) @function.def)
;;;
(import_statement name: (dotted_name) @import.uri)
;;;
(import_from_statement module_name: (dotted_name) @import.uri)
;;;
(import_from_statement module_name: (relative_import) @import.uri)
;;;
(call function: (identifier) @call.name)
;;;
(call function: (attribute attribute: (identifier) @call.name))
''';

const String _$r = r'''
; Tree-sitter query for R code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-r and may need tuning.
; Named function bindings (`f <- function(...)`) are captured as @function.*.

(binary_operator lhs: (identifier) @function.name operator: "<-" rhs: (function_definition)) @function.def
;;;
(binary_operator lhs: (identifier) @function.name operator: "=" rhs: (function_definition)) @function.def
;;;
(binary_operator lhs: (identifier) @function.name operator: "<<-" rhs: (function_definition)) @function.def
;;;
(call function: (identifier) @call.name)
;;;
(call function: (namespace_operator rhs: (identifier) @call.name))
;;;
(call function: (extract_operator rhs: (identifier) @call.name))
''';

const String _$ruby = r'''
; Tree-sitter query for Ruby code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-ruby and may need tuning.
; Modules are captured as @class.*.

(class name: (constant) @class.name) @class.def
;;;
(module name: (constant) @class.name) @class.def
;;;
(method name: (identifier) @method.name) @method.def
;;;
(singleton_method name: (identifier) @method.name) @method.def
;;;
(superclass (constant) @extends.name)
;;;
(call method: (identifier) @call.name)
;;;
(command method: (identifier) @call.name)
''';

const String _$rust = r'''
; Tree-sitter query for Rust code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-rust and may need tuning.
; Traits and structs are captured as @class.* (no dedicated trait kind).

(struct_item name: (type_identifier) @class.name) @class.def
;;;
(enum_item name: (type_identifier) @enum.name) @enum.def
;;;
(union_item name: (type_identifier) @class.name) @class.def
;;;
(trait_item name: (type_identifier) @class.name) @class.def
;;;
(function_item name: (identifier) @function.name) @function.def
;;;
(function_signature_item name: (identifier) @function.name) @function.def
;;;
(impl_item type: (type_identifier) @implements.name)
;;;
(impl_item trait: (type_identifier) @implements.name)
;;;
(use_declaration argument: (identifier) @import.uri)
;;;
(use_declaration argument: (scoped_identifier) @import.uri)
;;;
(call_expression function: (identifier) @call.name)
;;;
(call_expression function: (field_expression field: (field_identifier) @call.name))
''';

const String _$swift = r'''
; Tree-sitter query for Swift code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-swift and may need tuning.
; Protocols and structs are captured as @class.*.

(class_declaration name: (type_identifier) @class.name) @class.def
;;;
(class_declaration (type_identifier) @class.name) @class.def
;;;
(protocol_declaration name: (type_identifier) @class.name) @class.def
;;;
(protocol_declaration (type_identifier) @class.name) @class.def
;;;
(enum_declaration name: (type_identifier) @enum.name) @enum.def
;;;
(enum_declaration (type_identifier) @enum.name) @enum.def
;;;
(function_declaration name: (simple_identifier) @function.name) @function.def
;;;
(function_declaration (simple_identifier) @function.name) @function.def
;;;
(protocol_function_declaration name: (simple_identifier) @function.name) @function.def
;;;
(import_declaration (identifier) @import.uri)
;;;
(call_expression (simple_identifier) @call.name)
;;;
(call_expression (navigation_expression (navigation_suffix (simple_identifier) @call.name)))
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

const String _$zig = r'''
; Tree-sitter query for Zig code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-zig and may need tuning.
; `const Foo = struct { ... }` is a variable_declaration wrapping a struct.

(function_declaration name: (identifier) @function.name) @function.def
;;;
(variable_declaration (identifier) @class.name (struct_declaration)) @class.def
;;;
(variable_declaration (identifier) @enum.name (enum_declaration)) @enum.def
;;;
(variable_declaration (identifier) @class.name (union_declaration)) @class.def
;;;
(variable_declaration (identifier) @class.name (opaque_declaration)) @class.def
;;;
(using_namespace_declaration (identifier) @import.uri)
;;;
(builtin_function (arguments (string) @import.uri))
;;;
(call_expression function: (identifier) @call.name)
;;;
(call_expression function: (field_expression member: (identifier) @call.name))
''';
