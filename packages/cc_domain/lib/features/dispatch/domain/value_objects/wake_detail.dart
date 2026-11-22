import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/value_objects/json_safe.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';

/// The typed facts behind a wake (`agent_wakes.detail`): which goal, rule,
/// ask, ticket or event produced it. Every field is optional; a reason uses
/// the ones that describe it.
///
/// The server renders the first line of a wake from these fields, never from
/// the payload text, and producers cancel wakes by them (`goalId`, `ruleId`,
/// `askId` are queried with `json_extract`). [fields] carries structured
/// completion data (status, summary, artifacts) for a reason that has it.
///
/// Stored as a JSON object with these camelCase keys. [tryParse] never
/// throws: a malformed column reads as an empty detail, and a field of the
/// wrong type is dropped.
class WakeDetail {
  /// Creates a detail. Throws [ArgumentError] when [fields] holds a value
  /// that is not JSON.
  WakeDetail({
    this.goalId,
    this.ruleId,
    DateTime? slot,
    this.askId,
    this.ticketId,
    this.pipelineRunId,
    this.sourceAgentId,
    this.sourceRunId,
    this.sourceConversationId,
    this.messageId,
    this.eventKind,
    this.status,
    Map<String, Object?> fields = const {},
  }) : slot = slot == null ? null : wakeSlotOf(slot),
       fields = Map.unmodifiable(fields) {
    JsonSafe.require(fields, 'fields');
  }

  /// A detail with no field set.
  static final WakeDetail empty = WakeDetail();

  /// The goal the wake belongs to (`goalContinuation`, `goalVerification`,
  /// `goalReview`, `limitReset` of a goal segment).
  final String? goalId;

  /// The wake rule that produced it (`schedule`, `watch`).
  final String? ruleId;

  /// The rule's slot this wake fires for (the key's `<slot>`), in UTC and
  /// whole seconds ([wakeSlotOf]).
  final DateTime? slot;

  /// The peer ask it answers or delivers (`peerReply`, `peerMessage`).
  final String? askId;

  /// The ticket that settled (`childCompleted`).
  final String? ticketId;

  /// The pipeline run that settled (`watch` on `pipeline_run`).
  final String? pipelineRunId;

  /// The agent whose work or message caused the wake.
  final String? sourceAgentId;

  /// The run that caused the wake.
  final String? sourceRunId;

  /// The conversation the cause happened in.
  final String? sourceConversationId;

  /// The message the wake points at (a question, a reply, a final message).
  final String? messageId;

  /// The watched event that fired a `watch` wake.
  final WakeEventKind? eventKind;

  /// The status the wake reports, when it reports one: a free string, not
  /// checked here. A settled status (`completed`, `failed`, `expired`, a
  /// check conclusion), or an interim peer notice (`promised`,
  /// `blocked_on_person`) on a `peerReply` wake.
  final String? status;

  /// Structured completion data, JSON values only.
  final Map<String, Object?> fields;

  /// Whether no field is set.
  bool get isEmpty =>
      goalId == null &&
      ruleId == null &&
      slot == null &&
      askId == null &&
      ticketId == null &&
      pipelineRunId == null &&
      sourceAgentId == null &&
      sourceRunId == null &&
      sourceConversationId == null &&
      messageId == null &&
      eventKind == null &&
      status == null &&
      fields.isEmpty;

  /// The stored JSON object. Unset fields are omitted.
  Map<String, Object?> toJson() => {
    'goalId': ?goalId,
    'ruleId': ?ruleId,
    'slot': ?slot?.toIso8601String(),
    'askId': ?askId,
    'ticketId': ?ticketId,
    'pipelineRunId': ?pipelineRunId,
    'sourceAgentId': ?sourceAgentId,
    'sourceRunId': ?sourceRunId,
    'sourceConversationId': ?sourceConversationId,
    'messageId': ?messageId,
    'eventKind': ?eventKind?.wire,
    'status': ?status,
    if (fields.isNotEmpty) 'fields': fields,
  };

  /// [toJson] encoded, as the column stores it.
  String encode() => jsonEncode(toJson());

  /// Rebuilds from [toJson]'s output. Fields of the wrong type are dropped;
  /// anything that is not an object reads as [empty].
  static WakeDetail fromJson(Object? json) {
    if (json is! Map) {
      return empty;
    }
    return WakeDetail(
      goalId: JsonSafe.stringOrNull(json['goalId']),
      ruleId: JsonSafe.stringOrNull(json['ruleId']),
      slot: JsonSafe.dateOrNull(json['slot']),
      askId: JsonSafe.stringOrNull(json['askId']),
      ticketId: JsonSafe.stringOrNull(json['ticketId']),
      pipelineRunId: JsonSafe.stringOrNull(json['pipelineRunId']),
      sourceAgentId: JsonSafe.stringOrNull(json['sourceAgentId']),
      sourceRunId: JsonSafe.stringOrNull(json['sourceRunId']),
      sourceConversationId: JsonSafe.stringOrNull(json['sourceConversationId']),
      messageId: JsonSafe.stringOrNull(json['messageId']),
      eventKind: WakeEventKindWire.tryParse(
        JsonSafe.stringOrNull(json['eventKind']),
      ),
      status: JsonSafe.stringOrNull(json['status']),
      fields: JsonSafe.mapOrNull(json['fields']) ?? const {},
    );
  }

  /// Decodes the stored column. A null, empty or malformed value reads as
  /// [empty]; it never throws.
  static WakeDetail tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return empty;
    }
    try {
      return fromJson(jsonDecode(raw));
    } on FormatException {
      return empty;
    }
  }

  /// A copy with the given fields replaced.
  WakeDetail copyWith({
    String? goalId,
    String? ruleId,
    DateTime? slot,
    String? askId,
    String? ticketId,
    String? pipelineRunId,
    String? sourceAgentId,
    String? sourceRunId,
    String? sourceConversationId,
    String? messageId,
    WakeEventKind? eventKind,
    String? status,
    Map<String, Object?>? fields,
  }) => WakeDetail(
    goalId: goalId ?? this.goalId,
    ruleId: ruleId ?? this.ruleId,
    slot: slot ?? this.slot,
    askId: askId ?? this.askId,
    ticketId: ticketId ?? this.ticketId,
    pipelineRunId: pipelineRunId ?? this.pipelineRunId,
    sourceAgentId: sourceAgentId ?? this.sourceAgentId,
    sourceRunId: sourceRunId ?? this.sourceRunId,
    sourceConversationId: sourceConversationId ?? this.sourceConversationId,
    messageId: messageId ?? this.messageId,
    eventKind: eventKind ?? this.eventKind,
    status: status ?? this.status,
    fields: fields ?? this.fields,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WakeDetail &&
          goalId == other.goalId &&
          ruleId == other.ruleId &&
          sameWakeInstant(slot, other.slot) &&
          askId == other.askId &&
          ticketId == other.ticketId &&
          pipelineRunId == other.pipelineRunId &&
          sourceAgentId == other.sourceAgentId &&
          sourceRunId == other.sourceRunId &&
          sourceConversationId == other.sourceConversationId &&
          messageId == other.messageId &&
          eventKind == other.eventKind &&
          status == other.status &&
          JsonSafe.equals(fields, other.fields);

  @override
  int get hashCode => Object.hash(
    goalId,
    ruleId,
    slot,
    askId,
    ticketId,
    pipelineRunId,
    sourceAgentId,
    sourceRunId,
    sourceConversationId,
    messageId,
    eventKind,
    status,
    JsonSafe.hash(fields),
  );

  @override
  String toString() => 'WakeDetail(${toJson()})';
}
