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
