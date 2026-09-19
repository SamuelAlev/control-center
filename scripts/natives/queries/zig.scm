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
