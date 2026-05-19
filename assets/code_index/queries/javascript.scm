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
