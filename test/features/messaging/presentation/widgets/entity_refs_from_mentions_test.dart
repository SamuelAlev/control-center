import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_input_bar.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ResolvedMention m(String kind, Map<String, dynamic>? payload) =>
      ResolvedMention(kind: kind, label: 'x', start: 0, end: 1, payload: payload);

  group('entityRefsFromMentions', () {
    test('maps ticket/pr/meeting mentions and ignores other kinds', () {
      final refs = entityRefsFromMentions([
        m('agent', {'agentId': 'a1'}),
        m('ticket', {'ticketId': 't1', 'label': 'LIN-1'}),
        m('pr', {'number': 42, 'repoFullName': 'a/b', 'label': '#42'}),
        m('meeting', {'meetingId': 'mm1', 'label': 'Standup'}),
        m('channel', {'channelId': 'c1'}),
      ]);
      expect(refs, const [
        EntityRef(type: EntityRefType.ticket, id: 't1', label: 'LIN-1'),
        EntityRef(
          type: EntityRefType.pullRequest,
          id: '42',
          label: '#42',
          repoFullName: 'a/b',
        ),
        EntityRef(type: EntityRefType.meeting, id: 'mm1', label: 'Standup'),
      ]);
    });

    test('dedupes by (type, id)', () {
      final refs = entityRefsFromMentions([
        m('ticket', {'ticketId': 't1'}),
        m('ticket', {'ticketId': 't1'}),
      ]);
      expect(refs.length, 1);
    });

    test('skips entity mentions with missing payload ids', () {
      final refs = entityRefsFromMentions([
        m('ticket', null),
        m('pr', {'repoFullName': 'a/b'}), // no number
      ]);
      expect(refs, isEmpty);
    });
  });

  group('entityMentionToken', () {
    test('prefers the natural key, dashing whitespace', () {
      expect(entityMentionToken('LIN-123', 'Title', 'uuid'), 'LIN-123');
      expect(entityMentionToken('a b', 'x', 'id'), 'a-b');
    });

    test('slugifies the fallback text when there is no key', () {
      expect(
        entityMentionToken(null, 'Fix the login bug!', 'uuid'),
        'fix-the-login-bug',
      );
    });

    test('falls back to a short id when no key and no slug', () {
      expect(entityMentionToken(null, '', '0123456789abcdef'), '01234567');
    });
  });
}
