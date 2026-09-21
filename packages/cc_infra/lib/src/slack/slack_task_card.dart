/// Slack's Thinking Steps payload shapes.
// Pure payload construction with no state to inject: a namespace, not a service.
// ignore_for_file: avoid_classes_with_only_static_members
library;

import 'package:cc_infra/src/chat/chat_provider_adapter.dart';

/// Maps a [ChatTaskCard] onto Slack Thinking Steps payloads.
///
/// Two shapes: streaming chunks (`plan_update`/`task_update`) vs one-shot
/// blocks (`plan` + `task_card`, or a lone `task_card`). Block uses `task_id`
/// + rich-text; chunk uses `id` + plain strings (≤256 chars per chunk).
/// Same-id `details`/`output` concatenate with no separator; title/status replace.
/// Stream opens with `task_display_mode: plan` (not `dense`/`timeline`).
/// Send `details` once per row id; later updates omit it.
/// Answer is its own `markdown_text` chunk — never mixed with plan/task updates
/// and never with top-level `markdown_text`.
/// Deep-link row is appended when the turn finishes (first-seen id order).
abstract final class SlackTaskCard {
  /// How Slack should display task updates on a stream that carries cards.
  ///
  /// `plan` is one grouped card with a row per task. Asked for explicitly
  /// rather than left to Slack's default (`timeline`), because a mode mismatch
  /// is a layout that cannot be fixed after the stream has opened.
  static const String displayMode = 'plan';

  /// The block form, for `chat.postMessage`.
  ///
  /// A turn with [ChatTaskCard.steps] is a `plan` wrapping `task_card`s — the
  /// shape `blocks.validate` accepts for this surface. A one-shot card (a
  /// filed ticket, no steps) stays a lone `task_card`. The answer is the
  /// message body, not a task's `output`.
  static Map<String, dynamic> block(ChatTaskCard card) {
    if (card.steps.isNotEmpty) {
      final rows = SlackTaskCard.rows(card);
      return {
        'type': 'plan',
        'title': card.title,
        'tasks': [
          for (var i = 0; i < rows.length; i++)
            _taskBlock(rows[i], link: i == rows.length - 1 ? card.link : null),
        ],
      };
    }
    final narration = card.narration?.trim() ?? '';
    return {
      'type': 'task_card',
      'task_id': card.id,
      'title': card.title,
      'status': status(card.status),
      if (narration.isNotEmpty) 'details': _richText([_section(narration)]),
      'sources': ?_sources(card),
    };
  }

  /// Work rows, then a trailing CTA when the turn is finished.
  ///
  /// Slack appends new task ids in first-seen order. A chip sent on the first
  /// (setup) row stays under that row as later steps appear below it, so the
  /// CTA is a new last id added only once [ChatTaskCard.status] is complete
  /// or error — when no more work rows will be inserted.
  static List<ChatTaskStep> rows(ChatTaskCard card) {
    final live = card.narration?.trim() ?? '';
    final steps = <ChatTaskStep>[
      if (card.steps.isNotEmpty)
        ...card.steps
      else
        ChatTaskStep(
          id: card.id,
          title: live.isNotEmpty ? live : card.title,
          status: card.status,
        ),
    ];
    final link = card.link;
    final finished =
        card.status == ChatTaskStatus.complete ||
        card.status == ChatTaskStatus.error;
    if (link != null && finished) {
      steps.add(
        ChatTaskStep(
          id: '${card.id}-open',
          title: link.label,
          status: ChatTaskStatus.complete,
        ),
      );
    }
    return steps;
  }

  /// The plan's title. Slack replaces it on each send.
  static Map<String, dynamic> plan({required String title}) => {
    'type': 'plan_update',
    'title': _fitTitle(title),
  };

  /// Prose under the plan. Slack's plan view ignores markdown mixed into a
  /// task-update append, so this chunk travels on its own call.
  static Map<String, dynamic> markdown(String text) => {
    'type': 'markdown_text',
    'text': text,
  };

  /// One streaming `task_update` chunk for a single row.
  ///
  /// Title is the current line (`Working on it…`, `Thinking…`, a tool) and
  /// replaces on each send of the same [id]. [details] is the row body (the
  /// thought on `Thinking…`) and must be sent once: Slack concatenates it.
  static Map<String, dynamic> task({
    required String id,
    required String title,
    required ChatTaskStatus status,
    String? details,
    ChatTaskLink? link,
  }) {
    return {
      'type': 'task_update',
      'id': id,
      'title': _fitTitle(title),
      'status': SlackTaskCard.status(status),
      if (details != null && details.trim().isNotEmpty)
        'details': _fitTitle(details.trim()),
      if (link != null) 'sources': ?_sourcesFrom(link),
    };
  }

  /// Slack's spelling of a task's state.
  ///
  /// Taken from the task-card block reference (`pending` / `in_progress` /
  /// `complete` / `error`). Slack's streaming guide spells the finished state
  /// `completed` instead; the two disagree, so this is the one place to change if
  /// Slack rejects a status.
  static String status(ChatTaskStatus status) => switch (status) {
    ChatTaskStatus.pending => 'pending',
    ChatTaskStatus.inProgress => 'in_progress',
    ChatTaskStatus.complete => 'complete',
    ChatTaskStatus.error => 'error',
  };

  static Map<String, dynamic> _taskBlock(
    ChatTaskStep step, {
    ChatTaskLink? link,
  }) {
    final details = step.details?.trim() ?? '';
    return {
      'type': 'task_card',
      'task_id': step.id,
      'title': step.title,
      'status': status(step.status),
      if (details.isNotEmpty) 'details': _richText([_section(details)]),
      'sources': ?_sourcesFrom(link),
    };
  }

  static List<Map<String, dynamic>>? _sources(ChatTaskCard card) =>
      _sourcesFrom(card.link);

  static List<Map<String, dynamic>>? _sourcesFrom(ChatTaskLink? link) =>
      switch (link) {
        null => null,
        final value => [
          {'type': 'url', 'url': value.url, 'text': value.label},
        ],
      };

  /// Title is required and must survive the 256-character ceiling, so it is
  /// cropped rather than dropped.
  static String _fitTitle(String title) {
    if (title.length <= _maxChunkText) {
      return title;
    }
    return '${title.substring(0, _maxChunkText - 1).trimRight()}…';
  }

  /// Slack's ceiling on one `task_update` / `plan_update` chunk.
  static const int _maxChunkText = 256;

  static Map<String, dynamic> _richText(List<Map<String, dynamic>> elements) =>
      {'type': 'rich_text', 'elements': elements};

  static Map<String, dynamic> _section(String text) => {
    'type': 'rich_text_section',
    'elements': [
      {'type': 'text', 'text': text},
    ],
  };
}
