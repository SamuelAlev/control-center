; Tree-sitter query for C# code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-c-sharp and may need tuning.
; Interfaces, structs and records are captured as @class.*.

(class_declaration name: (identifier) @class.name) @class.def
;;;
(interface_declaration name: (identifier) @class.name) @class.def
;;;
(struct_declaration name: (identifier) @class.name) @class.def
;;;
(record_declaration name: (identifier) @class.name) @class.def
;;;
(enum_declaration name: (identifier) @enum.name) @enum.def
;;;
(method_declaration name: (identifier) @method.name) @method.def
;;;
(constructor_declaration name: (identifier) @constructor.name) @constructor.def
;;;
(base_list (identifier) @extends.name)
;;;
(using_directive (identifier) @import.uri)
;;;
(using_directive (qualified_name) @import.uri)
;;;
(invocation_expression function: (identifier) @call.name)
;;;
(invocation_expression function: (member_access_expression name: (identifier) @call.name))
