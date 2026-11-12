import 'dart:ui';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one presenter every generic failure goes through: a refusal is worded
/// by its `data.kind`, never by the server's English.
void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  RemoteRpcException refused(String kind, {Map<String, Object?>? extra}) =>
      RemoteRpcException(
        RpcErrorCodes.internalError,
        'SQLITE_BUSY: database is locked at /data/ws-1/workspace.db',
        {'kind': kind, ...?extra},
      );

  final expected = <String, String Function()>{
    'storage.busy': () => l10n.refusalStorageBusy,
    'storage.full': () => l10n.refusalStorageFull,
    'storage.damaged': () => l10n.refusalStorageDamaged,
    'storage.read_only': () => l10n.refusalStorageReadOnly,
    'storage.newer_schema': () => l10n.refusalStorageNewerSchema,
    'storage.foreign_file': () => l10n.refusalStorageForeignFile,
    'workspace.deleted': () => l10n.refusalWorkspaceDeleted,
    'idempotency.in_progress': () => l10n.refusalIdempotencyInProgress,
    'import.missing_source': () => l10n.refusalImportMissingSource,
    'import.damaged': () => l10n.refusalImportDamaged,
    'import.checksum_mismatch': () => l10n.refusalImportChecksumMismatch,
    'import.newer_schema': () => l10n.refusalImportNewerSchema,
    'import.foreign_file': () => l10n.refusalImportForeignFile,
    'import.schema_mismatch': () => l10n.refusalImportSchemaMismatch,
    'import.route_conflict': () => l10n.refusalImportRouteConflict,
  };

  group('storageRefusalMessage', () {
    for (final entry in expected.entries) {
      test('words ${entry.key} by kind, not by message', () {
        final message = storageRefusalMessage(l10n, refused(entry.key));
        expect(message, entry.value());
        expect(message, isNot(contains('SQLITE')));
        expect(message, isNot(contains('/data')));
      });
    }

    test('every kind has its own sentence', () {
      final sentences = expected.values.map((s) => s()).toSet();
      expect(sentences, hasLength(expected.length));
    });

    test('a newer file names no version the server did not send', () {
      final message = storageRefusalMessage(
        l10n,
        refused('import.newer_schema', extra: {'file_version': 31}),
      );
      expect(message, l10n.refusalImportNewerSchema);
      expect(message, isNot(contains('31')));
    });

    test('an unknown kind is not a storage refusal', () {
      expect(
        storageRefusalMessage(l10n, refused('repo_grant_required')),
        isNull,
      );
      expect(storageRefusalMessage(l10n, refused('storage.someday')), isNull);
    });

    test('an RPC error without a kind is not one', () {
      expect(
        storageRefusalMessage(
          l10n,
          RemoteRpcException(RpcErrorCodes.internalError, 'boom'),
        ),
        isNull,
      );
      expect(
        storageRefusalMessage(
          l10n,
          RemoteRpcException(RpcErrorCodes.internalError, 'boom', 'kind'),
        ),
        isNull,
      );
    });

    test('a non-RPC error is not one', () {
      expect(storageRefusalMessage(l10n, StateError('storage.busy')), isNull);
    });

    test('the kind alone reads the same, for lanes outside RPC', () {
      expect(
        storageRefusalMessageForKind(l10n, 'import.damaged'),
        l10n.refusalImportDamaged,
      );
      expect(storageRefusalMessageForKind(l10n, null), isNull);
    });
  });

  group('failureMessage', () {
    test('a storage refusal wins over the server message', () {
      expect(
        failureMessage(l10n, refused('storage.read_only')),
        l10n.refusalStorageReadOnly,
      );
    });

    test('any other RPC refusal shows the server message', () {
      expect(
        failureMessage(
          l10n,
          RemoteRpcException(RpcErrorCodes.validation, 'Name is taken', {
            'kind': 'name_taken',
          }),
        ),
        'Name is taken',
      );
    });

    test('a non-RPC error falls back to the generic sentence', () {
      final error = StateError('offline');
      expect(failureMessage(l10n, error), l10n.failedWithError('$error'));
    });
  });
}
