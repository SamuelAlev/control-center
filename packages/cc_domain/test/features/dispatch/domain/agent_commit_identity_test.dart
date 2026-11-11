import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:test/test.dart';

const _ada = (name: 'Ada Lovelace', email: '7+ada@users.noreply.github.com');
const _key =
    'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEexampleexampleexampleexampleexampleexample';

void main() {
  group('a person started the work', () {
    test('they are author and committer', () {
      final identity = AgentCommitIdentity.person(_ada);

      expect(identity.isPerson, isTrue);
      expect(identity.author, _ada);
      expect(identity.environment, {
        'GIT_AUTHOR_NAME': 'Ada Lovelace',
        'GIT_AUTHOR_EMAIL': '7+ada@users.noreply.github.com',
        'GIT_COMMITTER_NAME': 'Ada Lovelace',
        'GIT_COMMITTER_EMAIL': '7+ada@users.noreply.github.com',
      });
    });

    test('credits nobody and signs nothing unless told to', () {
      final identity = AgentCommitIdentity.person(_ada);

      expect(identity.coAuthors, isEmpty);
      expect(identity.coAuthorTrailers, isEmpty);
      expect(identity.signingKey, isNull);
    });

    test('credits Control Center when attribution is on', () {
      final identity = AgentCommitIdentity.person(_ada, creditAgent: true);

      expect(identity.coAuthors, [AgentCommitIdentity.controlCenter]);
      expect(identity.coAuthorTrailers, [
        'Co-Authored-By: Control Center <hi@usectrl.dev>',
      ]);
    });

    test('carries their signing key, and drops it when unsigned', () {
      final identity = AgentCommitIdentity.person(
        _ada,
        creditAgent: true,
        signingKey: _key,
      );

      expect(identity.signingKey, _key);
      final unsigned = identity.unsigned;
      expect(unsigned.signingKey, isNull);
      expect(unsigned.author, _ada);
      expect(unsigned.coAuthors, identity.coAuthors);
      expect(unsigned.isPerson, isTrue);
      expect(unsigned.unsigned, same(unsigned));
    });
  });

  group('nobody started the work', () {
    test('the agent is author and committer, unsigned', () {
      final identity = AgentCommitIdentity.automation();

      expect(identity.isPerson, isFalse);
      expect(identity.author, AgentCommitIdentity.controlCenter);
      expect(identity.environment['GIT_AUTHOR_EMAIL'], 'hi@usectrl.dev');
      expect(identity.environment['GIT_COMMITTER_NAME'], 'Control Center');
      expect(identity.signingKey, isNull);
      expect(identity.coAuthorTrailers, isEmpty);
    });

    test('on GitHub the agent is the App bot', () {
      final bot = AgentCommitIdentity.githubAppBot(
        botUserId: 4242,
        slug: 'control-center',
      );
      final identity = AgentCommitIdentity.automation(agent: bot);

      expect(identity.author.name, 'control-center[bot]');
      expect(
        identity.author.email,
        '4242+control-center[bot]@users.noreply.github.com',
      );
    });

    test('credits everyone accountable for it, in order', () {
      const grace = (name: 'Grace', email: '9+grace@users.noreply.github.com');
      final identity = AgentCommitIdentity.automation(
        accountable: [_ada, grace],
      );

      expect(identity.coAuthorTrailers, [
        'Co-Authored-By: Ada Lovelace <7+ada@users.noreply.github.com>',
        'Co-Authored-By: Grace <9+grace@users.noreply.github.com>',
      ]);
    });
  });

  test('a GitHub noreply address keeps the account id when it is known', () {
    expect(
      AgentCommitIdentity.githubNoreply(accountId: 7, login: 'ada'),
      '7+ada@users.noreply.github.com',
    );
    expect(
      AgentCommitIdentity.githubNoreply(accountId: 0, login: 'ada'),
      'ada@users.noreply.github.com',
    );
  });

  test('names and emails are kept as git writes them', () {
    // Git strips these from both ends of a name or an email before it
    // writes a commit; an identity that kept them would never match its
    // own commits.
    final identity = AgentCommitIdentity.person(
      (name: ' "Doe, John," ', email: '<john@example.com>;'),
      creditAgent: true,
    );
    expect(identity.author, (name: 'Doe, John', email: 'john@example.com'));
    expect(identity.environment['GIT_AUTHOR_NAME'], 'Doe, John');
    expect(identity.environment['GIT_COMMITTER_EMAIL'], 'john@example.com');
    expect(
      AgentCommitIdentity.automation(
        accountable: [(name: "'Ada'", email: 'ada@example.com')],
      ).coAuthorTrailers,
      ['Co-Authored-By: Ada <ada@example.com>'],
    );
    expect(AgentCommitIdentity.asGitWrites(r'\:;Ada\'), 'Ada');
    // Inner punctuation and non-ASCII space are part of the name.
    expect(AgentCommitIdentity.asGitWrites('O\'Neil, A. B'), 'O\'Neil, A. B');
    // A dot at either end goes too: git before 2.46 strips it, and one
    // identity must hold under every git.
    expect(AgentCommitIdentity.asGitWrites('.Doe Jr.'), 'Doe Jr');
    expect(AgentCommitIdentity.asGitWrites('\u00a0Ada'), '\u00a0Ada');
  });

  test('names and emails that could forge a header are refused', () {
    for (final bad in [
      '',
      '  ',
      // Nothing is left once git has stripped it.
      '"\',;:."',
      'a<b',
      'a>b',
      'a\nb',
      'a\rb',
      'a\x00b',
    ]) {
      expect(
        () => AgentCommitIdentity.person((name: bad, email: 'a@b.c')),
        throwsArgumentError,
        reason: 'name "$bad"',
      );
      expect(
        () => AgentCommitIdentity.person((name: 'Ada', email: bad)),
        throwsArgumentError,
        reason: 'email "$bad"',
      );
      expect(
        () => AgentCommitIdentity.automation(
          accountable: [(name: bad, email: 'a@b.c')],
        ),
        throwsArgumentError,
        reason: 'co-author "$bad"',
      );
    }
  });

  test('a signing key must be a bare ssh-ed25519 public key', () {
    for (final bad in [
      'ssh-rsa AAAAB3NzaC1yc2E',
      'ssh-ed25519 AAAA comment',
      'ssh-ed25519',
      'AAAAC3NzaC1lZDI1NTE5',
      'ssh-ed25519 AAAA\nssh-ed25519 BBBB',
    ]) {
      expect(
        () => AgentCommitIdentity.person(_ada, signingKey: bad),
        throwsArgumentError,
        reason: bad,
      );
    }
  });

  test('identities compare by everything they decide', () {
    final a = AgentCommitIdentity.person(_ada, creditAgent: true);
    expect(a, AgentCommitIdentity.person(_ada, creditAgent: true));
    expect(
      a.hashCode,
      AgentCommitIdentity.person(_ada, creditAgent: true).hashCode,
    );
    expect(a, isNot(AgentCommitIdentity.person(_ada)));
    expect(
      a,
      isNot(
        AgentCommitIdentity.person(_ada, creditAgent: true, signingKey: _key),
      ),
    );
    expect(
      AgentCommitIdentity.automation(agent: _ada),
      isNot(AgentCommitIdentity.person(_ada)),
    );
  });
}
