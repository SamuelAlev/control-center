import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/github_graphql_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Exercises the GitHub GraphQL client: variable passing, pagination cursor
/// walking, partial-failure tolerance (errored repo aliases), the
/// `_postTolerant` cancel-as-null path and the `_runQuery` GraphQL-error →
/// NetworkException mapping. Uses a stubbed [HttpClientAdapter].

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? body, {int status = 200}) => ResponseBody.fromString(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

ResponseBody _dioError(int status, {String message = 'boom'}) =>
    _json({'message': message}, status: status);

typedef Handler = ResponseBody Function(RequestOptions o);

({GitHubGraphQLClient client, _FakeAdapter fake}) build(Handler handler) {
  final fake = _FakeAdapter(handler);
  final dio = Dio()..httpClientAdapter = fake;
  return (client: GitHubGraphQLClient(dio), fake: fake);
}

void main() {
  group('GitHubGraphQLClient markFileAsViewed / unmarkFileAsViewed', () {
    test('POSTs the mutation with variables', () async {
      final b = build(
        (_) => _json({
          'data': {'markFileAsViewed': null},
        }),
      );
      await b.client.markFileAsViewed(pullRequestId: 'PR_1', path: 'a.dart');
      final req = b.fake.requests.single;
      expect(req.method, 'POST');
      expect(req.path, '/graphql');
      final body = req.data as Map<String, dynamic>;
      expect(body['query'], contains('MarkFileAsViewed'));
      expect((body['variables'] as Map)['pullRequestId'], 'PR_1');
      expect((body['variables'] as Map)['path'], 'a.dart');
    });

    test('unmark POSTs the unmark mutation', () async {
      final b = build((_) => _json({'data': {}}));
      await b.client.unmarkFileAsViewed(pullRequestId: 'PR_1', path: 'a.dart');
      final body = b.fake.requests.single.data as Map<String, dynamic>;
      expect(body['query'], contains('UnmarkFileAsViewed'));
    });

    test('maps a non-cancel DioException via mapDioException', () async {
      final b = build((_) => _dioError(401));
      await expectLater(
        b.client.markFileAsViewed(pullRequestId: 'PR_1', path: 'a.dart'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('GitHubGraphQLClient.getFileViewedStates', () {
    test('walks pages and collects path→state', () async {
      var page = 0;
      final b = build((_) {
        page++;
        final hasNext = page == 1;
        return _json({
          'data': {
            'repository': {
              'pullRequest': {
                'files': {
                  'pageInfo': {
                    'hasNextPage': hasNext,
                    if (hasNext) 'endCursor': 'cur$page',
                  },
                  'nodes': [
                    {'path': 'a.dart', 'viewerViewedState': 'VIEWED'},
                    {'path': 'b.dart', 'viewerViewedState': 'UNVIEWED'},
                    // null path/state are skipped by the implementation.
                    {'viewerViewedState': 'DISMISSED'},
                    {'path': 'c.dart'},
                  ],
                },
              },
            },
          },
        });
      });
      final states = await b.client.getFileViewedStates(
        owner: 'o',
        repo: 'r',
        number: 1,
      );
      expect(states, {'a.dart': 'VIEWED', 'b.dart': 'UNVIEWED'});
      expect(b.fake.requests, hasLength(2));
    });

    test('breaks when the files connection is null', () async {
      final b = build(
        (_) => _json({
          'data': {
            'repository': {'pullRequest': null},
          },
        }),
      );
      final states = await b.client.getFileViewedStates(
        owner: 'o',
        repo: 'r',
        number: 1,
      );
      expect(states, isEmpty);
    });
  });

  group('GitHubGraphQLClient.listBranchesWithActivity', () {
    test('maps branch name + committed date + author login', () async {
      final b = build(
        (_) => _json({
          'data': {
            'repository': {
              'refs': {
                'pageInfo': {'hasNextPage': false},
                'nodes': [
                  {
                    'name': 'main',
                    'target': {
                      'committedDate': '2026-01-02T03:04:05Z',
                      'author': {
                        'user': {'login': 'sam'},
                      },
                    },
                  },
                  {
                    'name': '', // skipped
                    'target': {},
                  },
                  {'name': 'orphan', 'target': null},
                ],
              },
            },
          },
        }),
      );
      final branches = await b.client.listBranchesWithActivity('o', 'r');
      expect(branches.map((b) => b.name), ['main', 'orphan']);
      expect(branches.first.authorLogin, 'sam');
      expect(branches.first.committedDate, isNotNull);
      expect(branches.last.committedDate, isNull);
    });
  });

  group('GitHubGraphQLClient.listAssignableUsers', () {
    test('maps login, name and avatar and paginates', () async {
      var page = 0;
      final b = build((_) {
        page++;
        final hasNext = page == 1;
        return _json({
          'data': {
            'repository': {
              'assignableUsers': {
                'pageInfo': {
                  'hasNextPage': hasNext,
                  if (hasNext) 'endCursor': 'cur$page',
                },
                'nodes': [
                  if (page == 1)
                    {
                      'login': 'alice',
                      'name': 'Alice Smith',
                      'avatarUrl': 'https://a/alice',
                    }
                  else
                    {'login': 'bob', 'name': '', 'avatarUrl': 'https://a/bob'},
                  {'login': ''},
                ],
              },
            },
          },
        });
      });
      final users = await b.client.listAssignableUsers('o', 'r');
      expect(users.map((u) => u.login), ['alice', 'bob']);
      expect(users.first.name, 'Alice Smith');
      expect(users.first.displayLabel, 'alice (Alice Smith)');
      expect(users.last.name, isNull);
      expect(users.last.displayLabel, 'bob');
      expect(b.fake.requests, hasLength(2));
    });

    test('breaks when the connection is null', () async {
      final b = build(
        (_) => _json({
          'data': {
            'repository': {'assignableUsers': null},
          },
        }),
      );
      expect(await b.client.listAssignableUsers('o', 'r'), isEmpty);
    });
  });

  group('GitHubGraphQLClient.fetchPullRequestTemplates', () {
    test('returns [] on any non-cancel DioException', () async {
      final b = build((_) => _dioError(500));
      final templates = await b.client.fetchPullRequestTemplates('o', 'r');
      expect(templates, isEmpty);
    });

    test(
      'returns [] on a NetworkException-shaped response (no data)',
      () async {
        final b = build(
          (_) => _json({
            'errors': [
              {'message': 'bad repo'},
            ],
          }),
        );
        expect(await b.client.fetchPullRequestTemplates('o', 'r'), isEmpty);
      },
    );

    test('collects named templates from dirs then the default file', () async {
      final b = build(
        (_) => _json({
          'data': {
            'repository': {
              'githubDir': {
                'entries': [
                  {
                    'name': 'bug_fix.md',
                    'type': 'blob',
                    'object': {'text': 'bug template'},
                  },
                  {
                    'name': 'not_md.txt',
                    'type': 'blob',
                    'object': {'text': 'skip'},
                  },
                  {
                    'name': 'empty.md',
                    'type': 'blob',
                    'object': {'text': '   '},
                  },
                  {
                    'name': 'tree_dir',
                    'type': 'tree',
                    'object': {'text': 'skip'},
                  },
                ],
              },
              'githubFile': {'text': 'default body'},
            },
          },
        }),
      );
      final templates = await b.client.fetchPullRequestTemplates('o', 'r');
      // Named first, then the default.
      expect(templates, hasLength(2));
      expect(templates.first.name, 'bug fix'); // _ replaced with space
      expect(templates.first.body, 'bug template');
      expect(templates.first.isDefault, isFalse);
      expect(templates.last.isDefault, isTrue);
      expect(templates.last.name, '');
    });

    test('first-found default wins (.github > root > docs)', () async {
      final b = build(
        (_) => _json({
          'data': {
            'repository': {
              'githubFile': {'text': 'gh'},
              'rootFile': {'text': 'root'},
              'docsFile': {'text': 'docs'},
            },
          },
        }),
      );
      final templates = await b.client.fetchPullRequestTemplates('o', 'r');
      expect(templates.single.body, 'gh');
      expect(templates.single.isDefault, isTrue);
    });

    test('dedupes named templates by lowercased display name', () async {
      final b = build(
        (_) => _json({
          'data': {
            'repository': {
              'githubDir': {
                'entries': [
                  {
                    'name': 'Bug_Fix.md',
                    'type': 'blob',
                    'object': {'text': 'one'},
                  },
                  {
                    'name': 'bug-fix.markdown',
                    'type': 'blob',
                    'object': {'text': 'two'},
                  },
                ],
              },
            },
          },
        }),
      );
      final templates = await b.client.fetchPullRequestTemplates('o', 'r');
      expect(templates, hasLength(1)); // 'bug fix' dedup
      expect(templates.single.body, 'one');
    });
  });

  group('GitHubGraphQLClient.fetchOpenPullRequestsBatch', () {
    test('empty repo list returns an empty result without a request', () async {
      final b = build((_) => _json({}));
      final res = await b.client.fetchOpenPullRequestsBatch(const []);
      expect(res.viewerLogin, isNull);
      expect(res.byIndex, isEmpty);
      expect(b.fake.requests, isEmpty);
    });

    test(
      'chunks repos and tolerates errored aliases (null repository)',
      () async {
        final b = build(
          (_) => _json({
            'data': {
              'r0': {
                'pullRequests': {
                  'pageInfo': {'hasNextPage': true},
                  'nodes': [
                    {'number': 1},
                    {'number': 2},
                  ],
                },
              },
              'r1': null, // inaccessible repo — skipped
            },
          }),
        );
        final res = await b.client.fetchOpenPullRequestsBatch(const [
          (owner: 'o', name: 'a'),
          (owner: 'o', name: 'b'),
        ]);
        expect(res.byIndex, contains(0));
        expect(res.byIndex[0]!.nodes.map((n) => n['number']), [1, 2]);
        expect(res.byIndex[0]!.hasMore, isTrue);
        expect(res.byIndex.containsKey(1), isFalse); // skipped
      },
    );

    test('continues when a chunk returns no data', () async {
      final b = build((_) => _json({'data': null}));
      final res = await b.client.fetchOpenPullRequestsBatch(const [
        (owner: 'o', name: 'a'),
      ]);
      expect(res.byIndex, isEmpty);
    });
  });

  group('GitHubGraphQLClient.fetchOpenPullRequestsChecks', () {
    test('empty repos → empty map', () async {
      final b = build((_) => _json({}));
      expect(await b.client.fetchOpenPullRequestsChecks(const []), isEmpty);
      expect(b.fake.requests, isEmpty);
    });

    test('decodes rollup state + review decision per PR number', () async {
      final b = build(
        (_) => _json({
          'data': {
            'r0': {
              'pullRequests': {
                'nodes': [
                  {
                    'number': 11,
                    'reviewDecision': 'APPROVED',
                    'lastCommit': {
                      'nodes': [
                        {
                          'commit': {
                            'statusCheckRollup': {'state': 'SUCCESS'},
                          },
                        },
                      ],
                    },
                  },
                  {
                    'number': 22,
                    'reviewDecision': null,
                    'lastCommit': {
                      'nodes': [
                        {
                          'commit': {
                            'statusCheckRollup': {'state': null},
                          },
                        },
                      ],
                    },
                  },
                  {'number': 0}, // filtered (number <= 0)
                  {'number': 33}, // no lastCommit → state null
                ],
              },
            },
          },
        }),
      );
      final res = await b.client.fetchOpenPullRequestsChecks(const [
        (owner: 'o', name: 'a'),
      ]);
      expect(res[0]![11]!.checksRollup, 'SUCCESS');
      expect(res[0]![11]!.reviewDecision, 'APPROVED');
      expect(res[0]![22]!.checksRollup, isNull);
      expect(res[0]![22]!.reviewDecision, isNull);
      expect(res[0]![33]!.checksRollup, isNull);
      expect(res[0]!.containsKey(0), isFalse);
    });
  });

  group('GitHubGraphQLClient review-requested / reviewed-by / search', () {
    test(
      'searchReviewRequestedPullRequests short-circuits on empty inputs',
      () async {
        final b = build((_) => _json({}));
        expect(
          await b.client.searchReviewRequestedPullRequests(
            reviewerLogin: '',
            repos: const [(owner: 'o', name: 'r')],
          ),
          isEmpty,
        );
        expect(
          await b.client.searchReviewRequestedPullRequests(
            reviewerLogin: 'me',
            repos: const [],
          ),
          isEmpty,
        );
        expect(b.fake.requests, isEmpty);
      },
    );

    test('searchReviewRequestedPullRequests returns raw PR nodes', () async {
      final b = build(
        (_) => _json({
          'data': {
            'search': {
              'nodes': [
                {'number': 1, 'title': 'A'},
                {}, // empty (non-PR) hit filtered out
              ],
            },
          },
        }),
      );
      final nodes = await b.client.searchReviewRequestedPullRequests(
        reviewerLogin: 'me',
        repos: const [(owner: 'o', name: 'r')],
      );
      expect(nodes, hasLength(1));
      expect(nodes.single['number'], 1);
    });

    test(
      'searchReviewedByPullRequests returns (repoFullName,number) pairs',
      () async {
        final b = build(
          (_) => _json({
            'data': {
              'search': {
                'nodes': [
                  {
                    'number': 5,
                    'repository': {'nameWithOwner': 'o/r'},
                  },
                  {
                    'number': 0,
                    'repository': {'nameWithOwner': 'o/r'},
                  }, // filtered
                  {
                    'number': 6,
                    'repository': {'nameWithOwner': ''},
                  }, // filtered
                ],
              },
            },
          }),
        );
        final pairs = await b.client.searchReviewedByPullRequests(
          reviewerLogin: 'me',
          repos: const [(owner: 'o', name: 'r')],
        );
        expect(pairs, hasLength(1));
        expect(pairs.single.repoFullName, 'o/r');
        expect(pairs.single.number, 5);
      },
    );

    test('searchPullRequestNodes returns [] for empty repos', () async {
      final b = build((_) => _json({}));
      expect(
        await b.client.searchPullRequestNodes(
          searchQualifiers: 'x',
          repos: const [],
        ),
        isEmpty,
      );
    });

    test('searchPullRequestNodes decodes matched nodes', () async {
      final b = build(
        (_) => _json({
          'data': {
            'search': {
              'nodes': [
                {'number': 7, 'title': 'x'},
              ],
            },
          },
        }),
      );
      final nodes = await b.client.searchPullRequestNodes(
        searchQualifiers: 'author:me',
        repos: const [(owner: 'o', name: 'r')],
      );
      expect(nodes.single['number'], 7);
    });
  });

  group('GitHubGraphQLClient.prCountsByAuthor', () {
    test('returns zeros for empty login/repos', () async {
      final b = build((_) => _json({}));
      final r1 = await b.client.prCountsByAuthor(
        login: '',
        repos: const [(owner: 'o', name: 'r')],
      );
      expect((r1.open, r1.draft, r1.merged, r1.closed), (0, 0, 0, 0));
      final r2 = await b.client.prCountsByAuthor(login: 'me', repos: const []);
      expect((r2.open, r2.draft, r2.merged, r2.closed), (0, 0, 0, 0));
      expect(b.fake.requests, isEmpty);
    });

    test('sums issueCount across aliases', () async {
      final b = build(
        (_) => _json({
          'data': {
            'open': {'issueCount': 3},
            'draft': {'issueCount': 1},
            'merged': {'issueCount': 5},
            'closed': {'issueCount': 2},
          },
        }),
      );
      final r = await b.client.prCountsByAuthor(
        login: 'me',
        repos: const [(owner: 'o', name: 'r')],
      );
      expect((r.open, r.draft, r.merged, r.closed), (3, 1, 5, 2));
    });

    test('tolerates missing issueCount (defaults to 0)', () async {
      final b = build((_) => _json({'data': {}}));
      final r = await b.client.prCountsByAuthor(
        login: 'me',
        repos: const [(owner: 'o', name: 'r')],
      );
      expect((r.open, r.draft, r.merged, r.closed), (0, 0, 0, 0));
    });
  });

  group('GitHubGraphQLClient getUserProfile / getUserContributions', () {
    test('getUserProfile parses a full profile', () async {
      final b = build(
        (_) => _json({
          'data': {
            'user': {
              'login': 'sam',
              'name': 'Sam',
              'avatarUrl': 'a',
              'contributionsCollection': {
                'restrictedContributionsCount': 2,
                'contributionCalendar': {
                  'totalContributions': 100,
                  'weeks': [
                    {
                      'contributionDays': [
                        {'contributionCount': 4, 'date': '2026-01-01'},
                      ],
                    },
                  ],
                },
              },
            },
          },
        }),
      );
      final profile = await b.client.getUserProfile(login: 'sam');
      expect(profile?.login, 'sam');
      expect(profile?.contributionCalendar?.totalContributions, 100);
      expect(profile?.contributionCalendar?.restrictedContributions, 2);
      expect(profile?.contributionCalendar?.grandTotal, 102);
    });

    test('getUserProfile returns null when user is null', () async {
      final b = build(
        (_) => _json({
          'data': {'user': null},
        }),
      );
      expect(await b.client.getUserProfile(login: 'x'), isNull);
    });

    test('getUserProfile does not query GitHub App bot logins', () async {
      final b = build((_) => _json({'data': {}}));
      expect(await b.client.getUserProfile(login: 'renovate[bot]'), isNull);
      expect(await b.client.getUserProfile(login: 'dependabot[bot]'), isNull);
      expect(
        await b.client.getUserProfile(login: 'github-actions[bot]'),
        isNull,
      );
      expect(b.fake.requests, isEmpty);
    });

    test('getUserContributions returns the parsed calendar', () async {
      final b = build(
        (_) => _json({
          'data': {
            'user': {
              'contributionCalendar': {'totalContributions': 7, 'weeks': []},
            },
          },
        }),
      );
      final cal = await b.client.getUserContributions(login: 'x');
      expect(cal?.totalContributions, 7);
    });

    test('getUserContributions returns null when calendar missing', () async {
      final b = build(
        (_) => _json({
          'data': {'user': null},
        }),
      );
      expect(await b.client.getUserContributions(login: 'x'), isNull);
    });

    test('getUserContributions does not query GitHub App bot logins', () async {
      final b = build((_) => _json({'data': {}}));
      expect(
        await b.client.getUserContributions(login: 'renovate[bot]'),
        isNull,
      );
      expect(b.fake.requests, isEmpty);
    });
  });

  group('GitHubGraphQLClient.getPullRequestReviewState', () {
    test('returns empty state when pullRequest is null', () async {
      final b = build(
        (_) => _json({
          'data': {
            'repository': {'pullRequest': null},
          },
        }),
      );
      final state = await b.client.getPullRequestReviewState(
        owner: 'o',
        repo: 'r',
        number: 1,
      );
      expect(state.pendingUsers, isEmpty);
      expect(state.pendingTeams, isEmpty);
      expect(state.completedReviews, isEmpty);
      expect(state.isDraft, isFalse);
    });

    test(
      'maps pending users + teams + completed reviews with onBehalfOf',
      () async {
        final b = build(
          (_) => _json({
            'data': {
              'repository': {
                'pullRequest': {
                  'reviewRequests': {
                    'nodes': [
                      {
                        'asCodeOwner': true,
                        'requestedReviewer': {
                          '__typename': 'User',
                          'login': 'sam',
                          'avatarUrl': 'a',
                        },
                      },
                      {
                        'asCodeOwner': false,
                        'requestedReviewer': {
                          '__typename': 'Team',
                          'name': 'Eng',
                          'slug': 'eng',
                          'avatarUrl':
                              'https://avatars.githubusercontent.com/t/9',
                        },
                      },
                      {
                        'asCodeOwner': false,
                        'requestedReviewer': {
                          '__typename': 'Team',
                          'name': '',
                          'slug': '',
                        },
                      },
                      {
                        'asCodeOwner': false,
                        'requestedReviewer': {
                          '__typename': 'User',
                          'login': '',
                          'avatarUrl': '',
                        },
                      },
                    ],
                  },
                  'latestReviews': {
                    'nodes': [
                      {
                        'state': 'APPROVED',
                        'author': {'login': 'joe', 'avatarUrl': 'j'},
                        'onBehalfOf': {
                          'nodes': [
                            {
                              'name': 'Eng',
                              'slug': 'eng',
                              'avatarUrl': 'https://t/eng',
                            },
                            {'name': '', 'slug': ''}, // filtered
                          ],
                        },
                      },
                    ],
                  },
                },
              },
            },
          }),
        );
        final state = await b.client.getPullRequestReviewState(
          owner: 'o',
          repo: 'r',
          number: 1,
        );
        expect(state.pendingUsers.single.login, 'sam');
        expect(state.pendingUsers.single.asCodeOwner, isTrue);
        expect(state.pendingTeams.single.slug, 'eng');
        // team name empty → falls back to slug
        expect(state.pendingTeams.single.name, 'Eng');
        expect(
          state.pendingTeams.single.avatarUrl,
          'https://avatars.githubusercontent.com/t/9',
        );
        expect(state.completedReviews.single.authorLogin, 'joe');
        expect(state.completedReviews.single.state, 'APPROVED');
        expect(state.completedReviews.single.onBehalfOf.single.slug, 'eng');
        expect(
          state.completedReviews.single.onBehalfOf.single.avatarUrl,
          'https://t/eng',
        );
        expect(state.isDraft, isFalse);
        expect(state.prState, isEmpty);
      },
    );

    test('completed review with empty author login is skipped', () async {
      final b = build(
        (_) => _json({
          'data': {
            'repository': {
              'pullRequest': {
                'latestReviews': {
                  'nodes': [
                    {
                      'state': 'COMMENTED',
                      'author': {'login': '', 'avatarUrl': ''},
                    },
                  ],
                },
              },
            },
          },
        }),
      );
      final state = await b.client.getPullRequestReviewState(
        owner: 'o',
        repo: 'r',
        number: 1,
      );
      expect(state.completedReviews, isEmpty);
    });

    test('pending team without avatarUrl uses databaseId CDN path', () async {
      final b = build(
        (_) => _json({
          'data': {
            'repository': {
              'pullRequest': {
                'reviewRequests': {
                  'nodes': [
                    {
                      'asCodeOwner': false,
                      'requestedReviewer': {
                        '__typename': 'Team',
                        'name': 'Ops',
                        'slug': 'ops',
                        'databaseId': 11,
                      },
                    },
                  ],
                },
              },
            },
          },
        }),
      );
      final state = await b.client.getPullRequestReviewState(
        owner: 'o',
        repo: 'r',
        number: 1,
      );
      expect(state.pendingTeams.single.slug, 'ops');
      expect(
        state.pendingTeams.single.avatarUrl,
        'https://avatars.githubusercontent.com/t/11',
      );
    });

    test('maps isDraft from the pull request', () async {
      final b = build(
        (_) => _json({
          'data': {
            'repository': {
              'pullRequest': {'state': 'OPEN', 'isDraft': true},
            },
          },
        }),
      );
      final state = await b.client.getPullRequestReviewState(
        owner: 'o',
        repo: 'r',
        number: 1,
      );
      expect(state.isDraft, isTrue);
      expect(state.prState, 'OPEN');
      final body = b.fake.requests.single.data as Map<String, dynamic>;
      expect(body['query'], contains('isDraft'));
    });
  });

  group('GitHubGraphQLClient _runQuery error mapping', () {
    test('a GraphQL errors array maps to NetworkException', () async {
      final b = build(
        (_) => _json({
          'errors': [
            {'message': 'field x missing'},
          ],
        }),
      );
      await expectLater(
        b.client.getPullRequestReviewState(owner: 'o', repo: 'r', number: 1),
        throwsA(isA<NetworkException>()),
      );
    });

    test('a non-200 transport error maps via mapDioException', () async {
      final b = build((_) => _dioError(403));
      await expectLater(
        b.client.getUserProfile(login: 'x'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
