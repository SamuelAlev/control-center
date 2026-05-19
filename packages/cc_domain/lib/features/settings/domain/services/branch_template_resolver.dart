import 'package:cc_domain/core/domain/services/slugify.dart';

/// Renders a user-configurable branch-name template into a valid git ref.
///
/// Supported placeholders: `{type}`, `{ticket-key}`, `{slug}`, `{pr}`.
/// `{slug}` is produced from a title via [slugify]. The result is sanitized to
/// a legal git branch name (per-segment, illegal characters collapsed to `-`).
class BranchTemplateResolver {
  /// Creates a resolver bound to [template].
  const BranchTemplateResolver(this.template);

  /// The raw template, e.g. `{type}/{ticket-key}-{slug}`.
  final String template;

  /// The default template used when none is configured.
  static const String defaultTemplate = '{type}/{ticket-key}-{slug}';

  /// Renders the template. Empty placeholders collapse cleanly (e.g. a missing
  /// `{ticket-key}` won't leave a dangling `-`).
  String resolve({
    String type = 'feature',
    String? ticketKey,
    String? title,
    int? prNumber,
  }) {
    final effective = template.trim().isEmpty ? defaultTemplate : template;
    final typeValue = type.trim().isEmpty ? 'task' : type.trim();
    final keyValue =
        (ticketKey != null && ticketKey.trim().isNotEmpty) ? ticketKey.trim() : '';
    final slugValue =
        (title != null && title.trim().isNotEmpty) ? slugify(title) : '';
    final prValue = prNumber?.toString() ?? '';

    final rendered = effective
        .replaceAll('{type}', typeValue)
        .replaceAll('{ticket-key}', keyValue)
        .replaceAll('{slug}', slugValue)
        .replaceAll('{pr}', prValue);

    return sanitizeBranchName(rendered);
  }
}

/// Sanitizes [raw] into a valid git branch name, preserving slash segments and
/// case. Illegal characters become `-`; empty segments are dropped.
String sanitizeBranchName(String raw) {
  final segments = raw
      .split('/')
      .map(
        (segment) => segment
            .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
            .replaceAll(RegExp('-+'), '-')
            .replaceAll(RegExp(r'^[-.]+|[-.]+$'), ''),
      )
      .where((segment) => segment.isNotEmpty)
      .toList();
  final name = segments.join('/');
  return name.isEmpty ? 'agent-work' : name;
}
