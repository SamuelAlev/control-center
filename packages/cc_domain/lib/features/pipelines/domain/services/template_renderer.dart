import 'dart:convert';

/// Renders `{{key}}` placeholders in prompt/script templates against pipeline
/// state and trigger payload and reports which placeholders could not be
/// resolved.
///
/// This is the single source of truth for `{{...}}` substitution — the engine
/// snapshot, the prompt-agent body and the bash-script body all delegate here
/// instead of re-implementing the regex (which previously silently turned a
/// missing key into an empty string in three places).
///
/// Supported placeholder forms:
/// - `{{key}}`            — bare key, resolved from state then trigger payload
/// - `{{$state.key}}`     — explicit state lookup
/// - `{{$trigger.key}}`   — explicit trigger-payload lookup
///
/// Unresolved placeholders render as empty string but are also returned in
/// [RenderResult.unresolved] so callers can fail loudly or warn.
class TemplateRenderer {
  /// Creates a [TemplateRenderer].
  const TemplateRenderer();

  static final RegExp _pattern = RegExp(r'\{\{\s*(\$?[a-zA-Z0-9_.]+)\s*\}\}');

  static const _jsonEncoder = JsonEncoder.withIndent('  ');

  /// Renders [template] against [state] and [trigger].
  ///
  /// [escape], when set, is applied to every resolved value AFTER
  /// stringification. Pass a shell-escape function when rendering a value that
  /// is spliced into a shell script (the `bashScript` body) so an untrusted
  /// trigger value — e.g. a ticket title arriving from an external ticketing
  /// system — cannot break out of its context into arbitrary commands
  /// (VULN-007). Leave it null for LLM prompt bodies, where the raw value is
  /// correct.
  RenderResult render(
    String template, {
    required Map<String, dynamic> state,
    Map<String, dynamic>? trigger,
    String Function(String value)? escape,
  }) {
    final unresolved = <String>{};
    final text = template.replaceAllMapped(_pattern, (m) {
      final ref = m.group(1)!;
      final value = resolve(ref, state: state, trigger: trigger);
      if (value == null) {
        unresolved.add(ref);
        return '';
      }
      // Structured values (orchestration sub-ticket outputs, discussion
      // positions) render as pretty JSON so downstream prompts get the real
      // shape, not Dart's `{a: b}` toString.
      final raw = (value is Map || value is List)
          ? _jsonEncoder.convert(value)
          : '$value';
      return escape == null ? raw : escape(raw);
    });
    return RenderResult(text: text, unresolved: unresolved);
  }

  /// Returns every placeholder reference found in [template] (in order of
  /// first appearance, de-duplicated).
  Set<String> placeholders(String template) {
    return _pattern.allMatches(template).map((m) => m.group(1)!).toSet();
  }

  /// Whether [template] contains at least one `{{placeholder}}`.
  bool containsPlaceholders(String template) => _pattern.hasMatch(template);

  /// Splits [template] into literal text and placeholder refs, in source
  /// order, so a canvas can draw the braces as chips instead of as syntax.
  ///
  /// Empty literals (two placeholders back-to-back, or a template that
  /// starts/ends on a placeholder) are omitted. Unknown `{{…}}` shapes that
  /// the renderer does not substitute stay literal text.
  List<TemplatePart> parts(String template) {
    final out = <TemplatePart>[];
    var cursor = 0;
    for (final match in _pattern.allMatches(template)) {
      if (match.start > cursor) {
        out.add(TemplateText(template.substring(cursor, match.start)));
      }
      out.add(TemplatePlaceholder(match.group(1)!));
      cursor = match.end;
    }
    if (cursor < template.length) {
      out.add(TemplateText(template.substring(cursor)));
    }
    return out;
  }

  /// Resolves a single placeholder reference, or null if absent.
  Object? resolve(
    String ref, {
    required Map<String, dynamic> state,
    Map<String, dynamic>? trigger,
  }) {
    if (ref.startsWith(r'$state.')) {
      return state[ref.substring(7)];
    }
    if (ref.startsWith(r'$trigger.')) {
      return trigger?[ref.substring(9)];
    }
    return state[ref] ?? trigger?[ref];
  }

  /// Whether [ref] targets the trigger payload only (so the validator should
  /// not treat it as an undeclared upstream-output reference).
  bool isTriggerScoped(String ref) => ref.startsWith(r'$trigger.');

  /// The bare key a reference resolves against in state (drops a `$state.`
  /// prefix; trigger-scoped refs return null).
  String? stateKeyOf(String ref) {
    if (ref.startsWith(r'$trigger.')) {
      return null;
    }
    if (ref.startsWith(r'$state.')) {
      return ref.substring(7);
    }
    return ref;
  }
}

/// One piece of a template string: literal text or a placeholder ref.
sealed class TemplatePart {
  /// Creates a [TemplatePart].
  const TemplatePart();
}

/// Literal characters between (or around) placeholders.
class TemplateText extends TemplatePart {
  /// Creates a [TemplateText].
  const TemplateText(this.value);

  /// The literal substring.
  final String value;

  @override
  bool operator ==(Object other) =>
      other is TemplateText && other.value == value;

  @override
  int get hashCode => Object.hash('text', value);
}

/// A `{{ref}}` placeholder, carrying the inner reference (`pr_number`,
/// `$trigger.author`).
class TemplatePlaceholder extends TemplatePart {
  /// Creates a [TemplatePlaceholder].
  const TemplatePlaceholder(this.ref);

  /// The placeholder reference, without braces.
  final String ref;

  @override
  bool operator ==(Object other) =>
      other is TemplatePlaceholder && other.ref == ref;

  @override
  int get hashCode => Object.hash('ph', ref);
}

/// Result of [TemplateRenderer.render].
class RenderResult {
  /// Creates a [RenderResult].
  const RenderResult({required this.text, required this.unresolved});

  /// The rendered text with all resolvable placeholders substituted.
  final String text;

  /// Placeholder references that had no value (rendered as empty string).
  final Set<String> unresolved;

  /// Whether every placeholder resolved.
  bool get isComplete => unresolved.isEmpty;
}
