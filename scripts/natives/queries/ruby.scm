; Tree-sitter query for Ruby code indexing.
;
; Same capture-name contract as dart.scm. Patterns are `;;;`-separated so the
; parser compiles each independently and skips ones the installed grammar
; rejects. NODE TYPE names target tree-sitter-ruby and may need tuning.
; Modules are captured as @class.*.

(class name: (constant) @class.name) @class.def
;;;
(module name: (constant) @class.name) @class.def
;;;
(method name: (identifier) @method.name) @method.def
;;;
(singleton_method name: (identifier) @method.name) @method.def
;;;
(superclass (constant) @extends.name)
;;;
(call method: (identifier) @call.name)
;;;
(command method: (identifier) @call.name)
