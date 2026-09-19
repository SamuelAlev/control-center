; Tree-sitter query for R code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-r and may need tuning.
; Named function bindings (`f <- function(...)`) are captured as @function.*.

(binary_operator lhs: (identifier) @function.name operator: "<-" rhs: (function_definition)) @function.def
;;;
(binary_operator lhs: (identifier) @function.name operator: "=" rhs: (function_definition)) @function.def
;;;
(binary_operator lhs: (identifier) @function.name operator: "<<-" rhs: (function_definition)) @function.def
;;;
(call function: (identifier) @call.name)
;;;
(call function: (namespace_operator rhs: (identifier) @call.name))
;;;
(call function: (extract_operator rhs: (identifier) @call.name))
