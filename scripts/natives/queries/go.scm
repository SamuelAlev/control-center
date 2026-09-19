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
