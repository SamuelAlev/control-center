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
