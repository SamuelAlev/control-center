; Tree-sitter query for Rust code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-rust and may need tuning.
; Traits and structs are captured as @class.* (no dedicated trait kind).

(struct_item name: (type_identifier) @class.name) @class.def
;;;
(enum_item name: (type_identifier) @enum.name) @enum.def
;;;
(union_item name: (type_identifier) @class.name) @class.def
;;;
(trait_item name: (type_identifier) @class.name) @class.def
;;;
(function_item name: (identifier) @function.name) @function.def
;;;
(function_signature_item name: (identifier) @function.name) @function.def
;;;
(impl_item type: (type_identifier) @implements.name)
;;;
(impl_item trait: (type_identifier) @implements.name)
;;;
(use_declaration argument: (identifier) @import.uri)
;;;
(use_declaration argument: (scoped_identifier) @import.uri)
;;;
(call_expression function: (identifier) @call.name)
;;;
(call_expression function: (field_expression field: (field_identifier) @call.name))
