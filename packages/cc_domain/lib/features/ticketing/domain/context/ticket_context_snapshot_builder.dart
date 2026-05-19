import 'package:cc_domain/features/ticketing/domain/context/ticket_context_input.dart';
import 'package:cc_domain/features/ticketing/domain/context/ticket_context_snapshot.dart';

/// Renders a [TicketContextInput] into a token-budgeted [TicketContextSnapshot]
/// for prompt injection.
///
/// The identity header always fits; each following section (description,
/// relations, children, comments, attachments) is appended only while the
/// character budget allows, truncating the section and marking the snapshot
/// `partial` when it would overflow. Depth caps and per-section load errors also
/// mark the snapshot partial, so the agent always knows when context is
/// incomplete rather than silently trusting a clipped block.
class TicketContextSnapshotBuilder {
  /// Creates a [TicketContextSnapshotBuilder].
  const TicketContextSnapshotBuilder();

  /// Builds the snapshot.
  TicketContextSnapshot build(
    TicketContextInput input, {
    TicketContextOptions options = const TicketContextOptions(),
  }) {
    final budget = options.budgetChars;
    final buffer = StringBuffer();
    final truncated = <String>{};
    final sectionErrors = <String, String>{...input.sectionErrors};
    final t = input.ticket;

    // ── Header (mandatory) ──
    final key = input.externalKey ?? t.externalKey ?? t.displayKey;
    final header = StringBuffer()
      ..writeln('# Ticket $key — ${t.title}')
      ..writeln('Status: ${t.status.name}   Priority: ${t.priority.name}');
    if (input.assigneeName != null) {
      header.writeln('Assignee: ${input.assigneeName}');
    }
    if (t.labels.isNotEmpty) {
      header.writeln('Labels: ${t.labels.join(', ')}');
    }
    if (t.url != null) {
      header.writeln('URL: ${t.url}');
    }
    final headerText = header.toString();
    if (headerText.length > budget) {
      // Even the header overflows: hard-truncate and stop.
      return TicketContextSnapshot(
        text: _clip(headerText, budget),
        meta: const TicketContextMeta(
          partial: true,
          truncatedSections: {'header'},
        ),
      );
    }
    buffer.write(headerText);

    int remaining() => budget - buffer.length;

    // ── Description ──
    if (t.description != null && t.description!.trim().isNotEmpty) {
      final block = '\n## Description\n${t.description!.trim()}\n';
      if (!_append(buffer, block, remaining())) {
        truncated.add('description');
      }
    }

    // ── Relations ──
    if (options.includeRelations && input.relations.isNotEmpty) {
      final capped = input.relations.take(options.maxRelations).toList();
      if (capped.length < input.relations.length) {
        truncated.add('relations');
      }
      final block = StringBuffer('\n## Relations\n');
      for (final r in capped) {
        block.writeln(
          '- ${r.kind} ${r.otherKey}${r.otherTitle != null ? ' (${r.otherTitle})' : ''}',
        );
      }
      if (!_append(buffer, block.toString(), remaining())) {
        truncated.add('relations');
      }
    }

    // ── Children ──
    if (options.includeChildren && input.children.isNotEmpty) {
      final capped = input.children.take(options.maxChildren).toList();
      if (capped.length < input.children.length) {
        truncated.add('children');
      }
      final block = StringBuffer('\n## Sub-issues\n');
      for (final c in capped) {
        block.writeln('- [${c.status}] ${c.key} — ${c.title}');
      }
      if (!_append(buffer, block.toString(), remaining())) {
        truncated.add('children');
      }
    }

    // ── Comments (most recent first within the cap) ──
    if (options.includeComments && input.comments.isNotEmpty) {
      final all = input.comments;
      final capped = all.length > options.maxComments
          ? all.sublist(all.length - options.maxComments)
          : all;
      if (capped.length < all.length) {
        truncated.add('comments');
      }
      final block = StringBuffer('\n## Comments (${capped.length})\n');
      for (final c in capped) {
        final when = c.createdAt != null
            ? ' (${c.createdAt!.toIso8601String()})'
            : '';
        block.writeln('- ${c.author}$when: ${_oneLine(c.body)}');
      }
      if (!_append(buffer, block.toString(), remaining())) {
        truncated.add('comments');
      }
    }

    // ── Attachments ──
    if (options.includeAttachments && input.attachments.isNotEmpty) {
      final capped = input.attachments.take(options.maxAttachments).toList();
      if (capped.length < input.attachments.length) {
        truncated.add('attachments');
      }
      final block = StringBuffer('\n## Attachments\n');
      for (final a in capped) {
        block.writeln('- ${a.name}${a.url != null ? ' (${a.url})' : ''}');
      }
      if (!_append(buffer, block.toString(), remaining())) {
        truncated.add('attachments');
      }
    }

    // ── Section load errors (inline note) ──
    if (sectionErrors.isNotEmpty) {
      final block = StringBuffer('\n## Notes\n');
      for (final entry in sectionErrors.entries) {
        block.writeln('- ${entry.key}: failed to load (${entry.value})');
      }
      _append(buffer, block.toString(), remaining());
    }

    final partial = truncated.isNotEmpty || sectionErrors.isNotEmpty;
    return TicketContextSnapshot(
      text: buffer.toString(),
      meta: TicketContextMeta(
        partial: partial,
        truncatedSections: truncated,
        sectionErrors: sectionErrors,
      ),
    );
  }

  /// Appends [block] to [buffer] when it fits in [remaining]; otherwise appends
  /// as much as fits with a truncation marker. Returns true when the whole
  /// block was appended.
  static bool _append(StringBuffer buffer, String block, int remaining) {
    if (remaining <= 0) {
      return false;
    }
    if (block.length <= remaining) {
      buffer.write(block);
      return true;
    }
    const marker = '\n… (truncated)\n';
    final room = remaining - marker.length;
    if (room > 0) {
      buffer
        ..write(_clip(block, room))
        ..write(marker);
    }
    return false;
  }

  static String _clip(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);

  static String _oneLine(String s) {
    final collapsed = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return collapsed.length <= 280
        ? collapsed
        : '${collapsed.substring(0, 277)}…';
  }
}
