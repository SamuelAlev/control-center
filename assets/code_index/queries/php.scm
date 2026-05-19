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
