import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart'
    show DeletedWorkspaceException;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_storage_state.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_host_approval.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:cc_infra/cc_infra.dart'
    show ForgeCredentialUnavailable, mapHttpException;
import 'package:cc_infra/src/environments/environment_host_approval.dart';
import 'package:cc_persistence/cc_persistence.dart'
    show
        DatabaseDamagedException,
        DatabaseNewerThanBinaryException,
        ForeignDatabaseFileException;
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:drift/drift.dart' show DriftWrappedException;
import 'package:rhttp/rhttp.dart';
import 'package:sqlite3/common.dart' show SqliteException;
import 'package:test/test.dart';

RhttpStatusCodeException _status(
  int code, {
  List<(String, String)> headers = const [],
  Object? body = '{}',
}) => RhttpStatusCodeException(
  request: HttpRequest(url: 'https://api.example.test/x'),
  statusCode: code,
  headers: headers,
  body: body,
);

SqliteException _sqlite(int code) => SqliteException(
  extendedResultCode: code,
  message: 'database failure',
  causingStatement: 'INSERT INTO messages (body, token) VALUES (?, ?)',
  parametersToStatement: const ['secret body', 'ghp_secret_token'],
  operation: 'executing',
);

void main() {
  test('a second active goal answers conflict with goal_already_active', () {
    final mapped = mapAppExceptionToRpc(
      const GoalAlreadyActiveException(workspaceId: 'ws-1', agentId: 'a-1'),
    );
    expect(mapped?.code, RpcErrorCodes.conflict);
    expect(mapped?.data, {'kind': 'goal_already_active'});
  });

  test('a goal not waiting for a review answers conflict with '
      'goal_not_in_review', () {
    final mapped = mapAppExceptionToRpc(
      const GoalRefusedException(
        'Only a goal paused for a review can be closed as done.',
        kind: GoalRefusedException.notInReviewKind,
      ),
    );
    expect(mapped?.code, RpcErrorCodes.conflict);
    expect(mapped?.data, {'kind': 'goal_not_in_review'});
  });

  group('storage failures', () {
    test('busy and locked answer storage.busy, even wrapped by drift', () {
      for (final error in <Object>[
        _sqlite(5),
        _sqlite(6),
        // SQLITE_BUSY_SNAPSHOT: an extended code of busy.
        _sqlite(517),
        DriftWrappedException(message: 'failed', cause: _sqlite(5)),
      ]) {
        final mapped = mapAppExceptionToRpc(error);
        expect(mapped?.data, {'kind': storageBusyKind}, reason: '$error');
        expect(mapped?.message, isNot(contains('secret')));
      }
    });

    test('a full disk answers storage.full', () {
      expect(mapAppExceptionToRpc(_sqlite(13))?.data, {
        'kind': storageFullKind,
      });
    });

    test('damage answers storage.damaged', () {
      for (final code in [11, 26]) {
        expect(mapAppExceptionToRpc(_sqlite(code))?.data, {
          'kind': storageDamagedKind,
        });
      }
      expect(
        mapAppExceptionToRpc(
          const DatabaseDamagedException(database: 'global', finding: 'bad'),
        )?.data,
        {'kind': storageDamagedKind},
      );
    });

    test('a write to a workspace served read-only answers '
        'storage.read_only', () {
      expect(mapAppExceptionToRpc(_sqlite(8))?.data, {
        'kind': workspaceReadOnlyKind,
      });
    });

    test('a file from a newer server names both versions, and never the '
        'file', () {
      final mapped = mapAppExceptionToRpc(
        const DatabaseNewerThanBinaryException(
          database: 'workspace ws-secret-id',
          fileVersion: 31,
          binaryVersion: 30,
        ),
      );
      expect(mapped?.data, {
        'kind': storageNewerSchemaKind,
        'file_version': 31,
        'server_version': 30,
      });
      expect(mapped?.message, isNot(contains('ws-secret-id')));
    });

    test('a file this server did not write answers storage.foreign_file', () {
      expect(
        mapAppExceptionToRpc(
          const ForeignDatabaseFileException(
            database: 'global',
            applicationId: 7,
            expectedApplicationId: 9,
          ),
        )?.data,
        {'kind': storageForeignFileKind},
      );
    });

    test('a deleted workspace answers workspace.deleted as not found', () {
      final mapped = mapAppExceptionToRpc(
        const DeletedWorkspaceException('ws-1'),
      );
      expect(mapped?.code, RpcErrorCodes.notFound);
      expect(mapped?.data, {'kind': workspaceDeletedKind});
    });

    test('any other storage failure stays an unmapped internal error', () {
      expect(mapAppExceptionToRpc(_sqlite(19)), isNull);
    });

    test('the log rendering keeps the statement and drops bound values', () {
      final line = describeErrorForLog(
        DriftWrappedException(message: 'failed', cause: _sqlite(19)),
      );
      expect(line, contains('19'));
      expect(line, contains('INSERT INTO messages'));
      expect(line, isNot(contains('secret body')));
      expect(line, isNot(contains('ghp_secret_token')));
      // The raw exception text is exactly what would have leaked.
      expect(_sqlite(19).toString(), contains('ghp_secret_token'));
    });
  });

  test('a refused workspace import answers its import kind, and a newer '
      'file names both versions', () {
    final newer = mapAppExceptionToRpc(
      const WorkspaceImportRefusedException(
        WorkspaceImportRefusal.newerSchema,
        'A newer server version wrote this file',
        fileVersion: 31,
        serverVersion: 30,
      ),
    );
    expect(newer?.code, RpcErrorCodes.validation);
    expect(newer?.data, {
      'kind': 'import.newer_schema',
      'file_version': 31,
      'server_version': 30,
    });
    for (final refusal in WorkspaceImportRefusal.values) {
      final mapped = mapAppExceptionToRpc(
        WorkspaceImportRefusedException(refusal, 'refused'),
      );
      expect(mapped?.code, RpcErrorCodes.validation);
      expect((mapped?.data as Map?)?['kind'], refusal.kind);
      expect(refusal.kind, startsWith('import.'));
    }
  });

  test('a forge refusal names its kind and its forge', () {
    for (final (code, forge) in [
      ('forge_cannot_read', ForgeHost.github),
      ('forge_unconfirmed', ForgeHost.gitlab),
      ('repo_replaced', ForgeHost.bitbucket),
    ]) {
      final mapped = mapAppExceptionToRpc(
        ForgeAccessRefusedException('refused', code: code, forge: forge),
      );
      expect(mapped?.code, RpcErrorCodes.unauthorized);
      expect(mapped?.message, 'refused');
      expect(mapped?.data, {'kind': code, 'forge': forge.wire});
    }
    // Any other coded refusal still carries its kind alone.
    expect(
      mapAppExceptionToRpc(
        const AuthException('no', code: 'repo_path.host_path'),
      )?.data,
      {'kind': 'repo_path.host_path'},
    );
  });

  test('an unapproved host definition is its own refusal, not the owner '
      'gate', () {
    final mapped = mapAppExceptionToRpc(
      const EnvironmentHostUnapprovedException(),
    );
    expect(mapped?.code, RpcErrorCodes.unauthorized);
    expect(mapped?.data, {'kind': environmentHostUnapprovedKind});
    expect(mapped?.message, contains('the server owner has not approved it'));
  });

  test('a surface the forge lacks is a named validation error', () {
    final mapped = mapAppExceptionToRpc(
      const ForgeUnsupportedError(ForgeHost.gitlab, 'issueSearch'),
    );
    expect(mapped?.code, RpcErrorCodes.validation);
    expect(mapped?.data, {
      'unsupported_capability': 'issueSearch',
      'forge': 'gitlab',
    });
  });

  // cc_infra forge clients deliberately let an unhandled status through as a raw
  // [RhttpException] (GitLab/Bitbucket's optional-status branches), so the RPC
  // boundary must classify it instead of reporting a generic internal error.
  group('mapAppExceptionToRpc - raw transport failures', () {
    test('404 becomes notFound', () {
      expect(mapAppExceptionToRpc(_status(404))?.code, RpcErrorCodes.notFound);
    });

    test('401 and a non-rate-limit 403 become unauthorized', () {
      expect(
        mapAppExceptionToRpc(_status(401))?.code,
        RpcErrorCodes.unauthorized,
      );
      expect(
        mapAppExceptionToRpc(_status(403))?.code,
        RpcErrorCodes.unauthorized,
      );
    });

    test('400 and 422 become validation', () {
      expect(
        mapAppExceptionToRpc(_status(400))?.code,
        RpcErrorCodes.validation,
      );
      expect(
        mapAppExceptionToRpc(_status(422))?.code,
        RpcErrorCodes.validation,
      );
    });

    test('409 becomes conflict and 429 becomes rateLimited', () {
      expect(mapAppExceptionToRpc(_status(409))?.code, RpcErrorCodes.conflict);
      expect(
        mapAppExceptionToRpc(_status(429))?.code,
        RpcErrorCodes.rateLimited,
      );
    });

    test(
      'a server failure stays unmapped (internal error, logged locally)',
      () {
        expect(mapAppExceptionToRpc(_status(500)), isNull);
      },
    );

    test('a transport failure without a status stays unmapped', () {
      expect(
        mapAppExceptionToRpc(
          RhttpConnectionException(
            HttpRequest(url: 'https://api.example.test/x'),
            'refused',
          ),
        ),
        isNull,
      );
    });

    test('a cancellation maps to requestCancelled, not an internal error', () {
      expect(
        mapAppExceptionToRpc(
          RhttpCancelException(HttpRequest(url: 'https://api.example.test/x')),
        )?.code,
        RpcErrorCodes.requestCancelled,
      );
    });

    test('a suspended App installation reads as unauthorized', () {
      final mapped = mapAppExceptionToRpc(
        _status(
          403,
          body: '{"message":"This installation has been suspended"}',
        ),
      );
      expect(mapped?.code, RpcErrorCodes.unauthorized);
      expect(mapped?.message, contains('suspended'));
    });
  });

  test('domain exceptions keep their existing codes', () {
    expect(
      mapAppExceptionToRpc(const WorkspaceMismatchException('nope'))?.code,
      RpcErrorCodes.workspaceMismatch,
    );
    expect(
      mapAppExceptionToRpc(const NotFoundException('gone'))?.code,
      RpcErrorCodes.notFound,
    );
  });

  // A person acting on GitLab/Bitbucket/Linear with no sign-in of their own
  // is refused locally; every shape that refusal reaches the RPC boundary in
  // carries the lane, so the client offers that sign-in.
  group('needs_sign_in', () {
    final request = HttpRequest(url: 'https://gitlab.example.test/api/v4/x');
    final local = const ForgeCredentialUnavailable.needsSignIn(
      'gitlab',
      'Connect your GitLab account to do this as yourself.',
    ).asStatusFailure(request);
    const expected = {'kind': 'needs_sign_in', 'lane': 'gitlab'};

    test('the raw local failure maps with its lane', () {
      final mapped = mapAppExceptionToRpc(local);
      expect(mapped?.code, RpcErrorCodes.unauthorized);
      expect(mapped?.data, expected);
      expect(mapped?.message, contains('GitLab'));
    });

    test('a forge client that classified it keeps the lane', () {
      final classified = mapHttpException(local);
      expect(classified.code, 'needs_sign_in');
      final mapped = mapAppExceptionToRpc(classified);
      expect(mapped?.code, RpcErrorCodes.unauthorized);
      expect(mapped?.data, expected);
    });

    test('a NeedsSignInException wrapped by an interceptor is unwrapped', () {
      final mapped = mapAppExceptionToRpc(
        RhttpInterceptorException(
          request,
          const NeedsSignInException('linear', 'Sign in to Linear.'),
        ),
      );
      expect(mapped?.code, RpcErrorCodes.unauthorized);
      expect(mapped?.data, {'kind': 'needs_sign_in', 'lane': 'linear'});
    });

    test('an ordinary 401 stays a plain unauthorized', () {
      final mapped = mapAppExceptionToRpc(_status(401));
      expect(mapped?.code, RpcErrorCodes.unauthorized);
      expect(mapped?.data, isNull);
    });
  });
}
