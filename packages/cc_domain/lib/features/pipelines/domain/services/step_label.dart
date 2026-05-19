import 'package:cc_domain/features/pipelines/domain/services/template_renderer.dart';

const TemplateRenderer _renderer = TemplateRenderer();

final RegExp _whitespace = RegExp(r'\s+');
final RegExp _trailingSeparators = RegExp(r'[\s·\-–—:,/]+$');
final RegExp _anyPlaceholder = RegExp(r'\{\{[^}]*\}\}');

/// Collapses whitespace and drops trailing separators left behind when a
/// placeholder renders empty, so `PR digest · ` reads as `PR digest`.
String tidyStepLabel(String value) => value
    .replaceAll(_whitespace, ' ')
    .trim()
    .replaceAll(_trailingSeparators, '')
    .trim();

/// A step's label with its `{{placeholders}}` resolved against a run.
///
/// Node labels are authored as templates — `Code analysis · {{repo_name}}` — so
/// anything showing one IN THE CONTEXT OF A RUN resolves it first. Rendering
/// the raw string puts `{{repo_name}}` on the canvas, in the waterfall and in
/// the step panel, which reads as a broken template rather than as the step it
/// names. The pipeline EDITOR is the deliberate exception: there the braces are
/// the thing being edited.
///
/// A placeholder with no value renders empty rather than failing — a scheduled
/// run carries no PR number, a `RepoAdded` run no repo full name — so the
/// result is tidied and, if that empties it, falls back to the label with its
/// placeholders stripped and then to [fallback]. A name is never worth failing
/// over.
String renderStepLabel(
  String? label, {
  required Map<String, dynamic> state,
  Map<String, dynamic>? trigger,
  required String fallback,
}) {
  final raw = label?.trim() ?? '';
  if (raw.isEmpty) {
    return fallback;
  }
  if (!raw.contains('{{')) {
    return raw;
  }
  final rendered = tidyStepLabel(
    _renderer.render(raw, state: state, trigger: trigger).text,
  );
  if (rendered.isNotEmpty) {
    return rendered;
  }
  final stripped = tidyStepLabel(raw.replaceAll(_anyPlaceholder, ''));
  return stripped.isEmpty ? fallback : stripped;
}
