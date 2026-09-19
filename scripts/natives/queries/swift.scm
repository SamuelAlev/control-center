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
