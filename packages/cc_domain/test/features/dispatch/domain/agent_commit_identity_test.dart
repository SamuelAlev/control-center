import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:test/test.dart';

void main() {
  group('AgentCommitIdentity', () {
    test('the owner authors, commits and may sign', () {
      final id = AgentCommitIdentity.owner(name: 'Ada', email: 'ada@x.dev');
      expect(id.authorEmail, 'ada@x.dev');
      expect(id.committerEmail, 'ada@x.dev');
      expect(id.mayHostSign, isTrue);
    });

    test('another member authors; Control Center commits; nothing signs', () {
      final id = AgentCommitIdentity.member(
        name: 'Bo',
        email: AgentCommitIdentity.githubNoreply(accountId: 7, login: 'bo'),
      );
      expect(id.authorEmail, '7+bo@users.noreply.github.com');
      expect(id.committerName, AgentCommitIdentity.controlCenterName);
      expect(id.committerEmail, AgentCommitIdentity.controlCenterEmail);
      expect(id.mayHostSign, isFalse);
    });

    test('an unrequested run is Control Center throughout', () {
      final id = AgentCommitIdentity.unrequested();
      expect(id.authorEmail, AgentCommitIdentity.controlCenterEmail);
      expect(id.committerEmail, AgentCommitIdentity.controlCenterEmail);
      expect(id.mayHostSign, isFalse);
    });

    test('the noreply address falls back to the bare login without an id', () {
      expect(
        AgentCommitIdentity.githubNoreply(accountId: 0, login: 'bo'),
        'bo@users.noreply.github.com',
      );
    });

    test('environment carries the four git identity variables', () {
      final id = AgentCommitIdentity.member(name: 'Bo', email: 'bo@x.dev');
      expect(id.environment, {
        'GIT_AUTHOR_NAME': 'Bo',
        'GIT_AUTHOR_EMAIL': 'bo@x.dev',
        'GIT_COMMITTER_NAME': 'Control Center',
        'GIT_COMMITTER_EMAIL': 'hi@usectrl.dev',
      });
    });

    test('values that would break a git ident are refused', () {
      for (final bad in ['', '  ', 'a<b', 'a>b', 'a\nb']) {
        expect(
          () => AgentCommitIdentity.owner(name: bad, email: 'a@x'),
          throwsArgumentError,
          reason: bad,
        );
        expect(
          () => AgentCommitIdentity.owner(name: 'A', email: bad),
          throwsArgumentError,
          reason: bad,
        );
      }
    });

    test('equality is by value', () {
      expect(
        AgentCommitIdentity.owner(name: 'A', email: 'a@x'),
        AgentCommitIdentity.owner(name: 'A', email: 'a@x'),
      );
      expect(
        AgentCommitIdentity.owner(name: 'A', email: 'a@x').hashCode,
        AgentCommitIdentity.owner(name: 'A', email: 'a@x').hashCode,
      );
      expect(
        AgentCommitIdentity.owner(name: 'A', email: 'a@x'),
        isNot(AgentCommitIdentity.member(name: 'A', email: 'a@x')),
      );
    });
  });
}
