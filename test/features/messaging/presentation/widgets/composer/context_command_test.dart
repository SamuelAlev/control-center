import 'package:control_center/features/messaging/presentation/widgets/composer/context_command_target.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one decision `/context` makes: which agent's window to open.
///
/// Pure, so it is tested without a widget tree — the alternative pumped a
/// toast overlay whose dismiss timer outlived the test.
void main() {
  const architect = 'agent-architect';
  const qa = 'agent-qa';
  const names = {architect: 'architect', qa: 'qa'};

  ContextCommandTarget resolve(
    List<String> ids, [
    String args = '',
    String? currentAgentId,
  ]) => resolveContextTarget(
    agentIdsInSpace: ids,
    namesById: names,
    args: args,
    currentAgentId: currentAgentId,
  );

  test('a lone agent is the answer without consulting what was typed', () {
    // The common case must not be the fussy one: with one agent there is no
    // ambiguity to resolve, so a stray word is not an error.
    expect(
      resolve([architect]),
      isA<ContextTargetResolved>().having(
        (t) => t.agentId,
        'agentId',
        architect,
      ),
    );
    expect(
      resolve([architect], 'whatever'),
      isA<ContextTargetResolved>().having(
        (t) => t.agentId,
        'agentId',
        architect,
      ),
    );
  });

  test('a space with no agent has no context window', () {
    expect(resolve(const []), isA<ContextTargetNoAgent>());
  });

  test('two agents and no name opens the one the header is metering', () {
    // The command and the header counter must never disagree about what "the
    // context" means here, so `/context` follows the same current agent
    // instead of refusing.
    expect(
      resolve([architect, qa], '', qa),
      isA<ContextTargetResolved>().having((t) => t.agentId, 'agentId', qa),
    );
  });

  test('with no current agent known, the first participant answers', () {
    // Same fallback the meter makes. Dead-ending on "which one?" would leave
    // the command unusable in exactly the space it exists for.
    expect(
      resolve([architect, qa]),
      isA<ContextTargetResolved>().having(
        (t) => t.agentId,
        'agentId',
        architect,
      ),
    );
  });

  test('a current agent that has left the space does not win', () {
    // The hint is a hint: it is only honoured while it names a participant.
    expect(
      resolve([architect, qa], '', 'agent-departed'),
      isA<ContextTargetResolved>().having(
        (t) => t.agentId,
        'agentId',
        architect,
      ),
    );
  });

  test('a typed name still beats the current agent', () {
    expect(
      resolve([architect, qa], 'architect', qa),
      isA<ContextTargetResolved>().having(
        (t) => t.agentId,
        'agentId',
        architect,
      ),
    );
  });

  test('an exact name resolves, case-insensitively', () {
    expect(
      resolve([architect, qa], 'qa'),
      isA<ContextTargetResolved>().having((t) => t.agentId, 'agentId', qa),
    );
    expect(
      resolve([architect, qa], 'ARCHITECT'),
      isA<ContextTargetResolved>().having(
        (t) => t.agentId,
        'agentId',
        architect,
      ),
    );
  });

  test('the mention sigil and surrounding space are tolerated', () {
    expect(
      resolve([architect, qa], '  @qa  '),
      isA<ContextTargetResolved>().having((t) => t.agentId, 'agentId', qa),
    );
  });

  test('a near-miss is refused, never fuzzily matched', () {
    // `arch` is an unambiguous prefix and is still refused: opening the wrong
    // agent's window is worse than saying what is here. Guessing is only for
    // the operator who named NOBODY.
    expect(
      resolve([architect, qa], 'arch'),
      isA<ContextTargetUnknownAgent>()
          .having((t) => t.typed, 'typed', 'arch')
          .having((t) => t.choices, 'choices', ['architect', 'qa']),
    );
  });

  test('an agent the roster cannot name is not offered as a choice', () {
    // A participant row carries an id, not a name. An id with no roster entry
    // would otherwise be listed as a blank option nobody can type.
    expect(
      resolveContextTarget(
        agentIdsInSpace: [architect, qa, 'agent-ghost'],
        namesById: names,
        args: 'ghost',
      ),
      isA<ContextTargetUnknownAgent>().having((t) => t.choices, 'choices', [
        'architect',
        'qa',
      ]),
    );
  });

  test('choices are sorted, so the message does not reshuffle', () {
    final target = resolveContextTarget(
      agentIdsInSpace: [qa, architect],
      namesById: names,
      args: 'nobody',
    );
    expect((target as ContextTargetUnknownAgent).choices, ['architect', 'qa']);
  });
}
