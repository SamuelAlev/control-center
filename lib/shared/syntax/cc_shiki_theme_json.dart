// CC TextMate theme JSON from `syntax_palette.dart` (drift-tested).
// Bump `kCcThemeRevision` when either changes (cache key).
//
// `editor.foreground` = sentinel `#010203` → adapter maps to null (inherit).
// `_ccNeutralScopes` forced to sentinel (no ident/punct coloring). No
// `fontStyle`. Neutral overrides last (later rules win).

/// Neutral scopes forced back to the sentinel foreground, shared by both
/// themes. Kept in one place so light/dark cannot diverge.
const String _neutralRules = '''
    {
      "name": "cc-neutral (identifiers, punctuation, operators stay base)",
      "scope": [
        "variable",
        "variable.other",
        "meta.brace",
        "punctuation",
        "keyword.operator"
      ],
      "settings": { "foreground": "#010203" }
    }''';

/// cc-light: the light syntax palette expressed as TextMate rules.
const String ccLightThemeJson =
    '''
{
  "name": "cc-light",
  "type": "light",
  "colors": {
    "editor.foreground": "#010203",
    "editor.background": "#FFFFFF"
  },
  "tokenColors": [
    {
      "name": "keyword",
      "scope": [
        "keyword",
        "keyword.control",
        "keyword.other",
        "storage",
        "storage.type",
        "storage.modifier",
        "variable.language"
      ],
      "settings": { "foreground": "#CF222E" }
    },
    {
      "name": "literal",
      "scope": ["constant.language"],
      "settings": { "foreground": "#0550AE" }
    },
    {
      "name": "symbol",
      "scope": [
        "constant.other.symbol",
        "constant.character",
        "constant.other.placeholder"
      ],
      "settings": { "foreground": "#E36209" }
    },
    {
      "name": "name",
      "scope": ["entity.name.other", "entity.name.label"],
      "settings": { "foreground": "#8250DF" }
    },
    {
      "name": "string (quotes stay string-colored via punctuation.definition.string)",
      "scope": [
        "string",
        "string.quoted",
        "string.template",
        "string.unquoted",
        "punctuation.definition.string"
      ],
      "settings": { "foreground": "#0A3069" }
    },
    {
      "name": "subst / interpolation",
      "scope": [
        "meta.embedded.line",
        "punctuation.section.embedded",
        "constant.character.escape"
      ],
      "settings": { "foreground": "#0A3069" }
    },
    {
      "name": "regexp",
      "scope": ["string.regexp"],
      "settings": { "foreground": "#0A3069" }
    },
    {
      "name": "number",
      "scope": ["constant.numeric"],
      "settings": { "foreground": "#0550AE" }
    },
    {
      "name": "comment",
      "scope": ["comment", "punctuation.definition.comment"],
      "settings": { "foreground": "#6E7781" }
    },
    {
      "name": "doctag",
      "scope": [
        "comment.block.documentation",
        "storage.type.class.jsdoc"
      ],
      "settings": { "foreground": "#6E7781" }
    },
    {
      "name": "meta / preprocessor / annotations",
      "scope": [
        "meta.preprocessor",
        "keyword.control.directive",
        "entity.name.tag.doctype",
        "meta.tag.sgml",
        "storage.type.annotation",
        "punctuation.definition.annotation"
      ],
      "settings": { "foreground": "#E36209" }
    },
    {
      "name": "type",
      "scope": ["support.type", "entity.other.inherited-class"],
      "settings": { "foreground": "#E36209" }
    },
    {
      "name": "class",
      "scope": ["support.class", "entity.name.namespace"],
      "settings": { "foreground": "#E36209" }
    },
    {
      "name": "title (declared names; hljs colors the identifier purple)",
      "scope": [
        "entity.name.function",
        "entity.name.class",
        "entity.name.struct",
        "entity.name.enum",
        "entity.name.type"
      ],
      "settings": { "foreground": "#8250DF" }
    },
    {
      "name": "built_in",
      "scope": ["support.function", "support.constant", "support.variable"],
      "settings": { "foreground": "#E36209" }
    },
    {
      "name": "function (references)",
      "scope": ["variable.function"],
      "settings": { "foreground": "#8250DF" }
    },
    {
      "name": "tag (also covers css selector tags — same green as selector-tag)",
      "scope": ["entity.name.tag"],
      "settings": { "foreground": "#116329" }
    },
    {
      "name": "attr / attribute",
      "scope": ["entity.other.attribute-name"],
      "settings": { "foreground": "#E36209" }
    },
    {
      "name": "params",
      "scope": ["variable.parameter"],
      "settings": { "foreground": "#24292F" }
    },
    {
      "name": "selector-id",
      "scope": ["entity.other.attribute-name.id"],
      "settings": { "foreground": "#8250DF" }
    },
    {
      "name": "selector-class",
      "scope": ["entity.other.attribute-name.class"],
      "settings": { "foreground": "#8250DF" }
    },
    {
      "name": "addition",
      "scope": ["markup.inserted"],
      "settings": { "foreground": "#116329" }
    },
    {
      "name": "deletion",
      "scope": ["markup.deleted"],
      "settings": { "foreground": "#CF222E" }
    },
$_neutralRules
  ]
}
''';

/// cc-dark: the dark syntax palette expressed as TextMate rules.
const String ccDarkThemeJson =
    '''
{
  "name": "cc-dark",
  "type": "dark",
  "colors": {
    "editor.foreground": "#010203",
    "editor.background": "#0D1117"
  },
  "tokenColors": [
    {
      "name": "keyword",
      "scope": [
        "keyword",
        "keyword.control",
        "keyword.other",
        "storage",
        "storage.type",
        "storage.modifier",
        "variable.language"
      ],
      "settings": { "foreground": "#FF7B72" }
    },
    {
      "name": "literal",
      "scope": ["constant.language"],
      "settings": { "foreground": "#79C0FF" }
    },
    {
      "name": "symbol",
      "scope": [
        "constant.other.symbol",
        "constant.character",
        "constant.other.placeholder"
      ],
      "settings": { "foreground": "#FFA657" }
    },
    {
      "name": "name",
      "scope": ["entity.name.other", "entity.name.label"],
      "settings": { "foreground": "#D2A8FF" }
    },
    {
      "name": "string (quotes stay string-colored via punctuation.definition.string)",
      "scope": [
        "string",
        "string.quoted",
        "string.template",
        "string.unquoted",
        "punctuation.definition.string"
      ],
      "settings": { "foreground": "#A5D6FF" }
    },
    {
      "name": "subst / interpolation",
      "scope": [
        "meta.embedded.line",
        "punctuation.section.embedded",
        "constant.character.escape"
      ],
      "settings": { "foreground": "#A5D6FF" }
    },
    {
      "name": "regexp",
      "scope": ["string.regexp"],
      "settings": { "foreground": "#A5D6FF" }
    },
    {
      "name": "number",
      "scope": ["constant.numeric"],
      "settings": { "foreground": "#79C0FF" }
    },
    {
      "name": "comment",
      "scope": ["comment", "punctuation.definition.comment"],
      "settings": { "foreground": "#8B949E" }
    },
    {
      "name": "doctag",
      "scope": [
        "comment.block.documentation",
        "storage.type.class.jsdoc"
      ],
      "settings": { "foreground": "#8B949E" }
    },
    {
      "name": "meta / preprocessor / annotations",
      "scope": [
        "meta.preprocessor",
        "keyword.control.directive",
        "entity.name.tag.doctype",
        "meta.tag.sgml",
        "storage.type.annotation",
        "punctuation.definition.annotation"
      ],
      "settings": { "foreground": "#FFA657" }
    },
    {
      "name": "type",
      "scope": ["support.type", "entity.other.inherited-class"],
      "settings": { "foreground": "#FFA657" }
    },
    {
      "name": "class",
      "scope": ["support.class", "entity.name.namespace"],
      "settings": { "foreground": "#FFA657" }
    },
    {
      "name": "title (declared names; hljs colors the identifier purple)",
      "scope": [
        "entity.name.function",
        "entity.name.class",
        "entity.name.struct",
        "entity.name.enum",
        "entity.name.type"
      ],
      "settings": { "foreground": "#D2A8FF" }
    },
    {
      "name": "built_in",
      "scope": ["support.function", "support.constant", "support.variable"],
      "settings": { "foreground": "#FFA657" }
    },
    {
      "name": "function (references)",
      "scope": ["variable.function"],
      "settings": { "foreground": "#D2A8FF" }
    },
    {
      "name": "tag (also covers css selector tags — same green as selector-tag)",
      "scope": ["entity.name.tag"],
      "settings": { "foreground": "#7EE787" }
    },
    {
      "name": "attr / attribute",
      "scope": ["entity.other.attribute-name"],
      "settings": { "foreground": "#FFA657" }
    },
    {
      "name": "params",
      "scope": ["variable.parameter"],
      "settings": { "foreground": "#E6EDF3" }
    },
    {
      "name": "selector-id",
      "scope": ["entity.other.attribute-name.id"],
      "settings": { "foreground": "#D2A8FF" }
    },
    {
      "name": "selector-class",
      "scope": ["entity.other.attribute-name.class"],
      "settings": { "foreground": "#D2A8FF" }
    },
    {
      "name": "addition",
      "scope": ["markup.inserted"],
      "settings": { "foreground": "#7EE787" }
    },
    {
      "name": "deletion",
      "scope": ["markup.deleted"],
      "settings": { "foreground": "#FF7B72" }
    },
$_neutralRules
  ]
}
''';
