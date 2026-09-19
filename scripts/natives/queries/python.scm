; Tree-sitter query for Python code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-python and may need tuning.

(class_definition name: (identifier) @class.name) @class.def
;;;
(function_definition name: (identifier) @function.name) @function.def
;;;
(decorated_definition definition: (class_definition name: (identifier) @class.name) @class.def)
;;;
(decorated_definition definition: (function_definition name: (identifier) @function.name) @function.def)
;;;
(import_statement name: (dotted_name) @import.uri)
;;;
(import_from_statement module_name: (dotted_name) @import.uri)
;;;
(import_from_statement module_name: (relative_import) @import.uri)
;;;
(call function: (identifier) @call.name)
;;;
(call function: (attribute attribute: (identifier) @call.name))
