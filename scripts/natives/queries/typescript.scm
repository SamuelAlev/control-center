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
