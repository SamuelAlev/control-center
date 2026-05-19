import 'package:cc_mcp_client/src/advisor/advisor_models.dart';
import 'package:cc_mcp_client/src/advisor/secret_obfuscator.dart';

/// The secondary (cheap) model that reviews the primary agent's transcript and
/// optionally returns one piece of advice. Returns null when it has nothing to
/// say. The host implements this over its provider stack (Claude/Pi/ACP).
abstract interface class AdvisorModel {
  /// Reviews [transcriptDelta] under [systemPrompt] and returns advice or null.
  Future<AdvisorVerdict?> review({
    required String systemPrompt,
    required String transcriptDelta,
  });
}

/// Delivers a piece of advice to the primary agent — passively ([AdvisorDelivery.aside])
/// or by interrupting via the steering channel ([AdvisorDelivery.steer]).
typedef AdviceSink =
    void Function(AdvisorVerdict verdict, AdvisorDelivery delivery);

/// A live secondary-model reviewer that watches the primary agent's transcript
/// and surfaces `nit | concern | blocker` advice (PRD 01 feature 9).
///
/// On every primary turn the runtime renders only the *delta* (messages since
/// the last review, excluding the advisor's own), obfuscates secrets, and asks
/// the [AdvisorModel] for advice. A `concern`/`blocker` interrupts the agent via
/// the steering channel; a `nit` is queued passively. Repeat advice is de-duped
/// unless it escalates in severity, so the same note doesn't nag every turn.
class AdvisorRuntime {
  /// Creates an [AdvisorRuntime].
  AdvisorRuntime({
    required AdvisorModel model,
    required AdviceSink onAdvice,
    SecretObfuscator? obfuscator,
    String? watchdogGuidance,
  }) : _model = model,
       _onAdvice = onAdvice,
       _obfuscator = obfuscator,
       _watchdogGuidance = watchdogGuidance;

  final AdvisorModel _model;
  final AdviceSink _onAdvice;
  final SecretObfuscator? _obfuscator;
  final String? _watchdogGuidance;

  int _cursor = 0;
  int _lastRank = 0;
  String _lastNote = '';
  bool _reviewing = false;

  /// The advisor's system prompt: base instructions + any WATCHDOG.md guidance.
  String buildSystemPrompt() {
    final buffer = StringBuffer()
      ..writeln(
        'You are a watchful senior reviewer observing another agent work. '
        'Watch for correctness bugs, security mistakes, destructive or '
        'irreversible actions, scope creep, and wasted effort. Only speak when '
        'it matters; stay silent otherwise.',
      )
      ..writeln(
        'When you do speak, return ONE terse, specific, actionable note and a '
        'severity: "nit" (minor), "concern" (worth pausing for), or "blocker" '
        '(stop and reconsider). Omit advice you have already given unless the '
        'situation has escalated.',
      );
    final guidance = _watchdogGuidance;
    if (guidance != null && guidance.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(guidance.trim());
    }
    return buffer.toString().trimRight();
  }

  /// Renders the transcript delta since the last review: new, non-advisor
  /// messages, secret-obfuscated, as markdown. Returns an empty string when
  /// there is nothing new. Advances the cursor.
  String renderDelta(List<AdvisorMessage> messages) {
    if (messages.length <= _cursor) {
      _cursor = messages.length;
      return '';
    }
    final fresh = messages.sublist(_cursor);
    _cursor = messages.length;
    final buffer = StringBuffer();
    for (final message in fresh) {
      if (message.isAdvisor) {
        continue;
      }
      final text = _obfuscator?.obfuscate(message.text) ?? message.text;
      if (text.trim().isEmpty) {
        continue;
      }
      buffer
        ..writeln('### ${message.role}')
        ..writeln(text.trim())
        ..writeln();
    }
    return buffer.toString().trim();
  }

  /// Reviews the transcript at the end of a primary turn. Renders the delta,
  /// asks the model, and (if it returns non-duplicate advice) routes it to the
  /// [AdviceSink]. Concurrent calls are coalesced — a review already in flight
  /// drops the new tick.
  Future<void> onTurnEnd(List<AdvisorMessage> messages) async {
    if (_reviewing) {
      return;
    }
    final delta = renderDelta(messages);
    if (delta.isEmpty) {
      return;
    }
    _reviewing = true;
    try {
      final verdict = await _model.review(
        systemPrompt: buildSystemPrompt(),
        transcriptDelta: delta,
      );
      if (verdict == null || verdict.note.trim().isEmpty) {
        return;
      }
      if (!_shouldDeliver(verdict)) {
        return;
      }
      _onAdvice(
        verdict,
        verdict.severity.interrupts ? AdvisorDelivery.steer : AdvisorDelivery.aside,
      );
    } finally {
      _reviewing = false;
    }
  }

  /// De-dup gate: deliver only when the note is new OR it escalates above the
  /// last-delivered severity. Prevents the advisor nagging the same point.
  bool _shouldDeliver(AdvisorVerdict verdict) {
    final normalized = verdict.note.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final escalated = verdict.severity.rank > _lastRank;
    final isNew = normalized != _lastNote;
    if (isNew || escalated) {
      _lastNote = normalized;
      _lastRank = verdict.severity.rank;
      return true;
    }
    return false;
  }
}
