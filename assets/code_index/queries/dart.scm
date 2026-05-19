; Tree-sitter query for Dart code indexing.
;
; CAPTURE NAMES are the stable contract with CodeExtractor:
;   @<kind>.def / @<kind>.name  declaration span + identifier
;   @extends.name / @implements.name / @mixesin.name  relationship targets
;   @import.uri   import/export URI     @call.name  call-site callee
;
; Patterns are separated by `;;;` lines: the parser compiles each independently
; and skips any that fail (e.g. a node type missing from the installed grammar),
; so one bad pattern never blanks the whole language. NODE TYPE names target the
; community Dart grammar and may need tuning to the grammar build that ships.

(class_definition (identifier) @class.name) @class.def
;;;
(mixin_declaration (identifier) @mixin.name) @mixin.def
;;;
(extension_declaration (identifier) @extension.name) @extension.def
;;;
(enum_declaration (identifier) @enum.name) @enum.def
;;;
(function_signature (identifier) @function.name) @function.def
;;;
(method_signature (function_signature (identifier) @method.name)) @method.def
;;;
(getter_signature (identifier) @getter.name) @getter.def
;;;
(setter_signature (identifier) @setter.name) @setter.def
;;;
(constructor_signature (identifier) @constructor.name) @constructor.def
;;;
(superclass (type_identifier) @extends.name)
;;;
(interfaces (type_identifier) @implements.name)
;;;
(mixins (type_identifier) @mixesin.name)
;;;
(import_or_export (library_import (import_specification (uri) @import.uri)))
;;;
(method_invocation (identifier) @call.name)
