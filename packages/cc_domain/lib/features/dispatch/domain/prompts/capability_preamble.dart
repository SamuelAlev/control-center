import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';

/// Builds the machine-authored capability block for a run.
///
/// **This is the consistency guarantee, not a convenience.** The sentence "you
/// may call these tools" is derived from [materializedToolNames] — the very list
/// handed to `AgentLoop.run` — so a prompt cannot advertise a tool the run does
/// not have, and cannot omit the verb that delivers the run's output. The bug
/// this replaces was a hand-written prompt that named a file-writing workflow
/// the tool surface had already removed.
///
/// Never hand-edit the wording of the generated part. Craft belongs in the
/// hand-authored mode guidance, which is forbidden from naming tools at all
/// (a parity test enforces that).
String buildCapabilityPreamble(
  ModeCapabilityProfile profile, {
  required List<String> materializedToolNames,
}) {
  final buf = StringBuffer()
    ..writeln('## Mode: ${profile.label}')
    ..writeln()
    ..writeln(profile.intent)
    ..writeln('Deliverable: a ${profile.deliverableNoun}.')
    ..writeln();

  final names = [...materializedToolNames]..sort();
  if (names.isNotEmpty) {
    buf
      ..writeln(
        'You have exactly ${names.length} tools. These, and nothing else:',
      )
      ..writeln(names.map((n) => '`$n`').join(', '))
      ..writeln();
  }

  final forbidden =
      profile.forbiddenVerbs
          .where((v) => !materializedToolNames.contains(v))
          .toList()
        ..sort();
  if (forbidden.isNotEmpty) {
    buf
      ..writeln(
        'You do NOT have ${forbidden.map((v) => '`$v`').join(', ')}. They are '
        'absent from the list above, so do not attempt them and do not narrate '
        'doing them.',
      )
      ..writeln();
  }

  final required = profile.requiredVerbs.toList()..sort();
  if (required.isNotEmpty) {
    final verbs = required.map((v) => '`$v`').join(' or ');
    buf
      ..writeln(
        'You MUST finish by calling $verbs. A run that ends without it has '
        'produced nothing — the user sees no ${profile.deliverableNoun}, and '
        'the run is recorded as failed. Describing the '
        '${profile.deliverableNoun} in prose is not delivering it.',
      )
      ..writeln();
    // A required verb missing from the surface is a composition bug. Say so in
    // the prompt rather than letting the agent discover it by failing: a loud
    // inconsistency is debuggable, a silent one is what caused this whole class
    // of bug.
    final missing = required
        .where((v) => !materializedToolNames.contains(v))
        .toList();
    if (missing.isNotEmpty) {
      buf
        ..writeln(
          'WARNING: ${missing.map((v) => '`$v`').join(', ')} is required in '
          'this mode but is NOT in your tool list. This is a configuration '
          'fault, not something you can work around. Report it plainly and '
          'stop.',
        )
        ..writeln();
    }
  }

  // Checklist hygiene, emitted only when the run actually has the tool — same
  // derived-from-the-surface guarantee as the inventory above. The rule lives
  // here rather than in a mode's hand-authored guidance because that guidance is
  // forbidden from naming tools, and because the failure it corrects (append
  // items, never transition them) is mode-independent.
  if (materializedToolNames.contains('todo_write')) {
    buf
      ..writeln(
        'Multi-step work goes in `todo_write`, and the list must stay CURRENT: '
        'mark an item in_progress before you start it (exactly one at a time) '
        'and completed the moment it is done, re-sending the full list each '
        'time. A checklist that only ever grows tells the user nothing about '
        'where you are.',
      )
      ..writeln();
  }

  final exit = profile.sanctionedExitVerb;
  if (exit != null) {
    buf
      ..writeln(
        'To leave ${profile.mode.name} mode and start executing in this same '
        'conversation, call `$exit` — a human approves before anything '
        'unlocks. That is not a way to deliver the '
        '${profile.deliverableNoun}.',
      )
      ..writeln();
  }
  return buf.toString().trimRight();
}
