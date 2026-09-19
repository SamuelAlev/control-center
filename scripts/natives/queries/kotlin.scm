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
