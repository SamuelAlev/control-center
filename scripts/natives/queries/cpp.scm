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
