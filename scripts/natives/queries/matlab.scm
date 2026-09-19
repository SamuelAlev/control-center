; Tree-sitter query for MATLAB code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-matlab and may need tuning.

(class_definition name: (identifier) @class.name) @class.def
;;;
(function_definition name: (identifier) @function.name) @function.def
;;;
(function_signature name: (identifier) @function.name) @function.def
;;;
(function_call name: (identifier) @call.name)
;;;
(command (command_name) @call.name)
