// GENERATED-STYLE FILE (hand-managed): the deferred-pack index and loader.
// Which pack owns which non-curated grammar id, plus the `deferred as`
// loaders. dart2js emits one loading unit per pack; shared embedded grammars
// land in shared units automatically. Regenerate with
// tool/gen_grammar_packs.py after a shiki_flutter upgrade.

import 'package:control_center/shared/syntax/grammar_packs/pack_a.dart'
    deferred as pack_a;
import 'package:control_center/shared/syntax/grammar_packs/pack_b.dart'
    deferred as pack_b;
import 'package:control_center/shared/syntax/grammar_packs/pack_c.dart'
    deferred as pack_c;
import 'package:control_center/shared/syntax/grammar_packs/pack_d.dart'
    deferred as pack_d;
import 'package:control_center/shared/syntax/grammar_packs/pack_e.dart'
    deferred as pack_e;
import 'package:shiki_flutter/langs.dart';

/// Which pack owns which non-curated grammar id.
const Map<String, String> packOfId = <String, String>{
  'abap': 'pack_a',
  'actionscript-3': 'pack_a',
  'ada': 'pack_a',
  'angular-expression': 'pack_a',
  'angular-html': 'pack_a',
  'angular-inline-style': 'pack_a',
  'angular-inline-template': 'pack_a',
  'angular-let-declaration': 'pack_a',
  'angular-template': 'pack_a',
  'angular-template-blocks': 'pack_a',
  'angular-ts': 'pack_a',
  'apache': 'pack_a',
  'apex': 'pack_a',
  'apl': 'pack_a',
  'applescript': 'pack_a',
  'ara': 'pack_a',
  'asciidoc': 'pack_a',
  'asm': 'pack_a',
  'astro': 'pack_a',
  'awk': 'pack_a',
  'ballerina': 'pack_a',
  'beancount': 'pack_a',
  'berry': 'pack_a',
  'bibtex': 'pack_a',
  'bicep': 'pack_a',
  'bird2': 'pack_a',
  'blade': 'pack_a',
  'bsl': 'pack_a',
  'c3': 'pack_a',
  'cadence': 'pack_a',
  'cairo': 'pack_a',
  'clarity': 'pack_a',
  'clojure': 'pack_a',
  'cobol': 'pack_a',
  'codeowners': 'pack_a',
  'codeql': 'pack_a',
  'coffee': 'pack_a',
  'common-lisp': 'pack_a',
  'coq': 'pack_a',
  'cpp-macro': 'pack_a',
  'crystal': 'pack_a',
  'cue': 'pack_b',
  'cypher': 'pack_b',
  'd': 'pack_b',
  'dax': 'pack_b',
  'desktop': 'pack_b',
  'dream-maker': 'pack_b',
  'edge': 'pack_b',
  'elixir': 'pack_b',
  'elm': 'pack_b',
  'emacs-lisp': 'pack_b',
  'erb': 'pack_b',
  'erlang': 'pack_b',
  'es-tag-css': 'pack_b',
  'es-tag-glsl': 'pack_b',
  'es-tag-html': 'pack_b',
  'es-tag-sql': 'pack_b',
  'es-tag-xml': 'pack_b',
  'fennel': 'pack_b',
  'fish': 'pack_b',
  'fluent': 'pack_b',
  'fortran-fixed-form': 'pack_b',
  'fortran-free-form': 'pack_b',
  'fsharp': 'pack_b',
  'gdresource': 'pack_b',
  'gdscript': 'pack_b',
  'gdshader': 'pack_b',
  'genie': 'pack_b',
  'gherkin': 'pack_b',
  'git-commit': 'pack_b',
  'git-rebase': 'pack_b',
  'gleam': 'pack_b',
  'glimmer-js': 'pack_b',
  'glimmer-ts': 'pack_b',
  'glsl': 'pack_b',
  'gn': 'pack_b',
  'gnuplot': 'pack_b',
  'hack': 'pack_b',
  'haml': 'pack_b',
  'handlebars': 'pack_b',
  'haskell': 'pack_b',
  'haxe': 'pack_b',
  'hcl': 'pack_c',
  'hjson': 'pack_c',
  'hlsl': 'pack_c',
  'html-derivative': 'pack_c',
  'http': 'pack_c',
  'hurl': 'pack_c',
  'hxml': 'pack_c',
  'hy': 'pack_c',
  'imba': 'pack_c',
  'jinja': 'pack_c',
  'jinja-html': 'pack_c',
  'jison': 'pack_c',
  'jsonnet': 'pack_c',
  'jssm': 'pack_c',
  'julia': 'pack_c',
  'just': 'pack_c',
  'kdl': 'pack_c',
  'kusto': 'pack_c',
  'latex': 'pack_c',
  'lean': 'pack_c',
  'liquid': 'pack_c',
  'llvm': 'pack_c',
  'logo': 'pack_c',
  'luau': 'pack_c',
  'markdown': 'pack_c',
  'markdown-nix': 'pack_c',
  'markdown-vue': 'pack_c',
  'marko': 'pack_c',
  'matlab': 'pack_c',
  'mdc': 'pack_c',
  'mdx': 'pack_c',
  'mermaid': 'pack_c',
  'mipsasm': 'pack_c',
  'mojo': 'pack_c',
  'moonbit': 'pack_c',
  'move': 'pack_c',
  'narrat': 'pack_c',
  'nextflow': 'pack_c',
  'nextflow-groovy': 'pack_c',
  'nginx': 'pack_c',
  'nim': 'pack_c',
  'nix': 'pack_d',
  'nushell': 'pack_d',
  'objective-cpp': 'pack_d',
  'ocaml': 'pack_d',
  'odin': 'pack_d',
  'openscad': 'pack_d',
  'pascal': 'pack_d',
  'pkl': 'pack_d',
  'plsql': 'pack_d',
  'po': 'pack_d',
  'polar': 'pack_d',
  'postcss': 'pack_d',
  'powerquery': 'pack_d',
  'prisma': 'pack_d',
  'prolog': 'pack_d',
  'pug': 'pack_d',
  'puppet': 'pack_d',
  'purescript': 'pack_d',
  'qml': 'pack_d',
  'qmldir': 'pack_d',
  'qss': 'pack_d',
  'racket': 'pack_d',
  'raku': 'pack_d',
  'razor': 'pack_d',
  'reg': 'pack_d',
  'rel': 'pack_d',
  'riscv': 'pack_d',
  'ron': 'pack_d',
  'rosmsg': 'pack_d',
  'rst': 'pack_d',
  'sas': 'pack_d',
  'scheme': 'pack_d',
  'sdbl': 'pack_d',
  'shaderlab': 'pack_d',
  'smalltalk': 'pack_d',
  'solidity': 'pack_d',
  'soy': 'pack_d',
  'sparql': 'pack_d',
  'splunk': 'pack_d',
  'ssh-config': 'pack_d',
  'stata': 'pack_d',
  'stylus': 'pack_e',
  'surrealql': 'pack_e',
  'svelte': 'pack_e',
  'system-verilog': 'pack_e',
  'systemd': 'pack_e',
  'talonscript': 'pack_e',
  'tasl': 'pack_e',
  'tcl': 'pack_e',
  'templ': 'pack_e',
  'terraform': 'pack_e',
  'tex': 'pack_e',
  'ts-tags': 'pack_e',
  'tsv': 'pack_e',
  'turtle': 'pack_e',
  'twig': 'pack_e',
  'typespec': 'pack_e',
  'typst': 'pack_e',
  'v': 'pack_e',
  'vala': 'pack_e',
  'vb': 'pack_e',
  'verilog': 'pack_e',
  'vhdl': 'pack_e',
  'viml': 'pack_e',
  'vue': 'pack_e',
  'vue-directives': 'pack_e',
  'vue-html': 'pack_e',
  'vue-interpolations': 'pack_e',
  'vue-sfc-style-variable-injection': 'pack_e',
  'vue-vine': 'pack_e',
  'vyper': 'pack_e',
  'wasm': 'pack_e',
  'wenyan': 'pack_e',
  'wgsl': 'pack_e',
  'wikitext': 'pack_e',
  'wit': 'pack_e',
  'wolfram': 'pack_e',
  'xsl': 'pack_e',
  'zenscript': 'pack_e',
  'zig': 'pack_e',
};

/// Loads pack [name] and hands its grammars to [register]. Returns whether
/// the pack loaded. Unknown names resolve false (defensive; the index above
/// is the only caller's source of names).
Future<bool> loadPack(
  String name,
  void Function(Iterable<CodeLanguage>) register,
) async {
  switch (name) {
    case 'pack_a':
      await pack_a.loadLibrary();
      register(pack_a.grammars);
      return true;
    case 'pack_b':
      await pack_b.loadLibrary();
      register(pack_b.grammars);
      return true;
    case 'pack_c':
      await pack_c.loadLibrary();
      register(pack_c.grammars);
      return true;
    case 'pack_d':
      await pack_d.loadLibrary();
      register(pack_d.grammars);
      return true;
    case 'pack_e':
      await pack_e.loadLibrary();
      register(pack_e.grammars);
      return true;
  }
  return false;
}
