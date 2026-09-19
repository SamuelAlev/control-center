; Tree-sitter query for Assembly code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-asm and may need tuning.
; Labels are captured as @function.* — assembly has no class/function AST.

(label (ident) @function.name) @function.def
;;;
(label (word) @function.name) @function.def
