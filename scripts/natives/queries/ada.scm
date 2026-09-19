; Tree-sitter query for Ada code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-ada and may need tuning.
; Packages are captured as @class.*.

(procedure_specification name: (_) @function.name) @function.def
;;;
(function_specification name: (_) @function.name) @function.def
;;;
(package_declaration name: (_) @class.name) @class.def
;;;
(package_body name: (_) @class.name) @class.def
;;;
(generic_instantiation name: (_) @class.name) @class.def
;;;
(with_clause (_) @import.uri)
;;;
(use_clause (_) @import.uri)
