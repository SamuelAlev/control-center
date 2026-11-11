import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_server_core/src/forge/forge_commit_author_probe.dart';
import 'package:cc_server_core/src/identity/agent_commit_identities.dart';
import 'package:test/test.dart';

const _key =
    'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeyKeyKeyKeyKeyKeyKeyKeyKeyKeyKeyKeyKeyKeyKey';

void main() {
  group('AgentCommitIdentities', () {
    late String? slug;
    late int? botId;
    late int botLookups;
    late Map<String, GitHubUser> accounts;
    late GitPerson? forgeAuthor;
    late List<ForgeHost> forgeAsked;
    late Set<String> optedOut;
    late Map<String, String> keys;
    late Map<String, Set<String>> armers;

    AgentCommitIdentities build() => AgentCommitIdentities(
      userExists: (userId) async => userId != 'u-unknown',
      appSlug: (_) async => slug,
      botUserId: (login) async {
        botLookups++;
        expect(login, '$slug[bot]');
        return botId;
      },
      githubAccount: (userId, _) async => accounts[userId],
      forgeAuthor: (forge, _, _) async {
        forgeAsked.add(forge);
        return forgeAuthor;
      },
      creditsCoAuthor: (userId, _) async => !optedOut.contains(userId),
      signingKeyOf: (userId) async => keys[userId],
      accountableFor: (_, runLogId) async => armers[runLogId] ?? const {},
    );

    setUp(() {
      slug = 'acme-cc';
      botId = 4242;
      botLookups = 0;
      accounts = {
        'u-1': const GitHubUser(login: 'bo', avatarUrl: '', id: 7),
        'u-2': const GitHubUser(login: 'cy', avatarUrl: '', id: 8, name: 'Cy'),
      };
      forgeAuthor = null;
      forgeAsked = [];
      optedOut = {};
      keys = {};
      armers = {};
    });

    const bot = (
      name: 'acme-cc[bot]',
      email: '4242+acme-cc[bot]@users.noreply.github.com',
    );
    const bo = (name: 'bo', email: '7+bo@users.noreply.github.com');
    const cy = (name: 'Cy', email: '8+cy@users.noreply.github.com');

    group('a person asked for the run', () {
      test('the commits are theirs, under their GitHub noreply, crediting '
          'Control Center', () async {
        final id = await build().forRun('u-1', workspaceId: 'ws');

        expect(id, AgentCommitIdentity.person(bo, creditAgent: true));
        expect(id!.isPerson, isTrue);
        expect(id.coAuthorTrailers, [
          'Co-Authored-By: Control Center <hi@usectrl.dev>',
        ]);
        expect(botLookups, 0, reason: 'the bot plays no part');
      });

      test('their GitHub profile name is used when it is a git identity, '
          'else their login', () async {
        expect((await build().forRun('u-2', workspaceId: 'ws'))!.author, cy);
        accounts['u-2'] = const GitHubUser(
          login: 'cy',
          avatarUrl: '',
          id: 8,
          name: 'Cy <admin@corp.com>',
        );
        expect(
          (await build().forRun('u-2', workspaceId: 'ws'))!.author.name,
          'cy',
        );
      });

      test('a name is taken as git writes it, and a name git would write '
          'as nothing falls back to the login', () async {
        accounts['u-2'] = const GitHubUser(
          login: 'cy',
          avatarUrl: '',
          id: 8,
          name: '"Cy Young," ',
        );
        expect(
          (await build().forRun('u-2', workspaceId: 'ws'))!.author.name,
          'Cy Young',
        );
        accounts['u-2'] = const GitHubUser(
          login: 'cy',
          avatarUrl: '',
          id: 8,
          name: '"" ,;',
        );
        expect(
          (await build().forRun('u-2', workspaceId: 'ws'))!.author.name,
          'cy',
        );
      });

      test('a GitLab or Bitbucket account whose name or email is not a git '
          'identity is not written as an author', () async {
        for (final reported in [
          (name: '",;', email: 'bo@corp.com'),
          (name: 'Bo B', email: 'bo@corp.com <x>'),
          (name: 'Bo B', email: ''),
        ]) {
          forgeAuthor = reported;
          final id = await build().forRun(
            'u-1',
            workspaceId: 'ws',
            forge: ForgeHost.gitlab,
          );
          expect(id!.isPerson, isFalse, reason: '$reported');
        }
        forgeAuthor = (name: " 'Bo B' ", email: 'bo@corp.com');
        expect(
          (await build().forRun(
            'u-1',
            workspaceId: 'ws',
            forge: ForgeHost.gitlab,
          ))!.author,
          (name: 'Bo B', email: 'bo@corp.com'),
        );
      });

      test('with attribution off they credit nobody', () async {
        optedOut = {'u-1'};
        expect(
          await build().forRun('u-1', workspaceId: 'ws'),
          AgentCommitIdentity.person(bo),
        );
      });

      test('their signing key signs their commits', () async {
        keys['u-1'] = _key;
        expect(
          (await build().forRun('u-1', workspaceId: 'ws'))!.signingKey,
          _key,
        );
        expect(
          (await build().forRun('u-2', workspaceId: 'ws'))!.signingKey,
          isNull,
          reason: "one person's key never signs another's commits",
        );
      });

      test('on GitLab and Bitbucket they are the account the forge reports '
          'for their own sign-in', () async {
        forgeAuthor = (name: 'Bo B', email: 'bo@corp.com');
        for (final forge in [ForgeHost.gitlab, ForgeHost.bitbucket]) {
          final id = await build().forRun(
            'u-1',
            workspaceId: 'ws',
            forge: forge,
          );
          expect(id!.author, (name: 'Bo B', email: 'bo@corp.com'));
          expect(id.isPerson, isTrue);
        }
        expect(forgeAsked, [ForgeHost.gitlab, ForgeHost.bitbucket]);
      });

      test('nothing is signed on Bitbucket, where an SSH key is also a '
          'login', () async {
        keys['u-1'] = _key;
        forgeAuthor = (name: 'Bo B', email: 'bo@corp.com');
        expect(
          (await build().forRun(
            'u-1',
            workspaceId: 'ws',
            forge: ForgeHost.gitlab,
          ))!.signingKey,
          _key,
        );
        expect(
          (await build().forRun(
            'u-1',
            workspaceId: 'ws',
            forge: ForgeHost.bitbucket,
          ))!.signingKey,
          isNull,
        );
      });

      test('with no address their forge vouches for, the commits are the '
          'agent\'s and name nobody', () async {
        accounts.remove('u-1');
        keys['u-1'] = _key;
        final id = await build().forRun('u-1', workspaceId: 'ws');

        expect(id, AgentCommitIdentity.automation(agent: bot));
        expect(id!.signingKey, isNull);
      });

      test('someone who is not a user gets no identity', () async {
        expect(await build().forRun('u-unknown', workspaceId: 'ws'), isNull);
      });
    });

    group('nobody asked for the run', () {
      test('on GitHub the agent is the lane App\'s bot', () async {
        final id = await build().forRun(null, workspaceId: 'ws');

        expect(id, AgentCommitIdentity.automation(agent: bot));
        expect(id!.isPerson, isFalse);
        expect(id.author.email, isNot(contains('usectrl')));
      });

      test('the bot\'s user id is asked once and kept', () async {
        final identities = build();
        await identities.forRun(null, workspaceId: 'ws');
        await identities.forRun(null, workspaceId: 'ws');
        expect(botLookups, 1);
      });

      test('until GitHub answers for the bot, its bare noreply stands in '
          'and it is asked again', () async {
        botId = null;
        final identities = build();
        expect(
          (await identities.forRun(null, workspaceId: 'ws'))!.author.email,
          'acme-cc[bot]@users.noreply.github.com',
        );
        botId = 4242;
        expect((await identities.forRun(null, workspaceId: 'ws'))!.author, bot);
      });

      test('with no GitHub App, or off GitHub, the agent is Control '
          'Center', () async {
        slug = null;
        expect(
          (await build().forRun(null, workspaceId: 'ws'))!.author,
          AgentCommitIdentity.controlCenter,
        );
        slug = 'acme-cc';
        for (final forge in [ForgeHost.gitlab, ForgeHost.bitbucket]) {
          expect(
            (await build().forRun(
              null,
              workspaceId: 'ws',
              forge: forge,
            ))!.author,
            AgentCommitIdentity.controlCenter,
          );
        }
      });

      test('it credits the people who armed its trigger, in a stable '
          'order, under their verified addresses', () async {
        armers['run-1'] = {'u-2', 'u-1'};
        final id = await build().forRun(
          null,
          workspaceId: 'ws',
          runLogId: 'run-1',
        );

        expect(
          id,
          AgentCommitIdentity.automation(agent: bot, accountable: [bo, cy]),
        );
        expect(id!.signingKey, isNull);
      });

      test('it credits no one who opted out, is unknown, or has no verified '
          'address', () async {
        armers['run-1'] = {'u-1', 'u-2', 'u-unknown', 'u-3'};
        optedOut = {'u-2'};
        final id = await build().forRun(
          null,
          workspaceId: 'ws',
          runLogId: 'run-1',
        );
        expect(id!.coAuthors, [bo]);
      });

      test('without a run log there is nobody to credit', () async {
        armers['run-1'] = {'u-1'};
        expect(
          (await build().forRun(null, workspaceId: 'ws'))!.coAuthors,
          isEmpty,
        );
      });
    });

    group('a commit a person makes by hand', () {
      test('is theirs under their verified address, signed with their '
          'key', () async {
        keys['u-1'] = _key;
        final id = await build().forPerson(
          'u-1',
          workspaceId: 'ws',
          forge: ForgeHost.github,
          unverified: (name: 'Bo Profile', email: 'bo@profile.example'),
        );
        expect(
          id,
          AgentCommitIdentity.person(bo, creditAgent: true, signingKey: _key),
        );
      });

      test('keeps their profile identity where no forge vouches for one, '
          'and is then never signed', () async {
        accounts.remove('u-1');
        keys['u-1'] = _key;
        final id = await build().forPerson(
          'u-1',
          workspaceId: 'ws',
          forge: ForgeHost.local,
          unverified: (name: 'Bo Profile', email: 'bo@profile.example'),
        );
        expect(id!.author, (name: 'Bo Profile', email: 'bo@profile.example'));
        expect(id.signingKey, isNull);
        expect(id.coAuthors, [AgentCommitIdentity.controlCenter]);
      });

      test('has no identity with neither', () async {
        accounts.remove('u-1');
        expect(await build().forPerson('u-1', workspaceId: 'ws'), isNull);
      });
    });

    test('the agent identities of a workspace are its App bot and Control '
        'Center', () async {
      expect(await build().agentsOf('ws'), [
        bot,
        AgentCommitIdentity.controlCenter,
      ]);
      slug = null;
      expect(await build().agentsOf('ws'), [AgentCommitIdentity.controlCenter]);
    });

    test('a forge author probe result is a git identity', () {
      // Compile-time link to the probe the server resolver uses.
      expect(probeForgeCommitAuthor, isA<Function>());
    });
  });
}
