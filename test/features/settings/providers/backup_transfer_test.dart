import 'dart:convert';
import 'dart:typed_data';

import 'package:control_center/core/providers/media_proxy_provider.dart';
import 'package:control_center/features/settings/providers/backup_transfer.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The byte lane: downloading a backup onto this device and uploading one back.
///
/// The RPC ops speak in paths on the SERVER, which only answers the question
/// when the server is this machine. What has to hold here is that the bytes go
/// to a signed URL for the right target, that a saved download actually reaches
/// the chosen path, and that a refusal arrives as a STATUS rather than as prose
/// — the words are the UI's job, in the l10n table with every other string.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final proxy = MediaProxyConfig(
    httpBase: Uri.parse('http://127.0.0.1:9030'),
    deviceId: 'device-1',
    psk: 'psk-1',
  );

  late List<Uri> requested;
  late List<int> written;
  late String? writtenTo;

  setUp(() {
    requested = [];
    written = [];
    writtenTo = null;
    BackupTransfer.chooseSaveLocation = (_) async => '/tmp/chosen.db';
    writeFile = (stream, path) async {
      writtenTo = path;
      await for (final chunk in stream) {
        written.addAll(chunk);
      }
    };
  });

  tearDown(() {
    // `chooseSaveLocation` is re-set by setUp on every test, so only the
    // client needs putting back.
    BackupTransfer.clientFactory = http.Client.new;
  });

  ProviderContainer containerWith({required MediaProxyConfig? config}) {
    final container = ProviderContainer(
      overrides: [mediaProxyConfigProvider.overrideWithValue(config)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// A client answering every request with [status] and [body].
  void respondWith({
    int status = 200,
    List<int> body = const [1, 2, 3],
    String? textBody,
  }) {
    BackupTransfer.clientFactory = () => MockClient.streaming((
      request,
      bodyStream,
    ) async {
      requested.add(request.url);
      final bytes = textBody != null
          ? utf8.encode(textBody)
          : Uint8List.fromList(body);
      return http.StreamedResponse(Stream.value(bytes), status);
    });
  }

  test('is unavailable on a connection with no HTTP lane', () {
    // A relayed connection carries RPC and nothing else. The UI disables the
    // controls off this rather than offering a button that cannot work.
    expect(containerWith(config: null).read(backupTransferAvailableProvider),
        isFalse);
    expect(
      containerWith(config: proxy).read(backupTransferAvailableProvider),
      isTrue,
    );
  });

  test('a workspace download is signed and lands where it was asked to', () async {
    respondWith(body: const [7, 7, 7]);

    final result = await containerWith(config: proxy)
        .read(backupTransferProvider)
        .downloadWorkspace(workspaceId: 'ws-1', suggestedName: 'ws-1.db');

    expect(result.outcome, BackupDownloadOutcome.saved);
    expect(result.path, '/tmp/chosen.db');
    expect(writtenTo, '/tmp/chosen.db');
    expect(written, const [7, 7, 7]);
    // Signed for THIS workspace, and carrying the device id the host resolves
    // the verifying key from.
    final url = requested.single;
    expect(url.path, '/backup/workspace');
    expect(url.queryParameters['w'], 'ws-1');
    expect(url.queryParameters['d'], 'device-1');
    expect(url.queryParameters['s'], isNotEmpty);
  });

  test('a cancelled save dialog downloads nothing', () async {
    BackupTransfer.chooseSaveLocation = (_) async => null;
    respondWith();

    final result = await containerWith(config: proxy)
        .read(backupTransferProvider)
        .downloadWorkspace(workspaceId: 'ws-1', suggestedName: 'ws-1.db');

    expect(result.outcome, BackupDownloadOutcome.cancelled);
    // Not even requested: the bytes are a whole database, and fetching them to
    // discard them is the one thing a cancel must not do.
    expect(requested, isEmpty);
    expect(written, isEmpty);
  });

  test('a snapshot download asks for the archive by name', () async {
    respondWith();

    await containerWith(config: proxy)
        .read(backupTransferProvider)
        .downloadSnapshot(name: '2026-08-31T09-00-00-000Z');

    final url = requested.single;
    expect(url.path, '/backup/snapshot');
    expect(url.queryParameters['n'], '2026-08-31T09-00-00-000Z');
  });

  test('a refusal arrives as a status, not as prose', () async {
    // 403 on these routes always means one specific missing role, and only the
    // UI has the l10n table to say which.
    respondWith(status: 403, body: const []);

    await expectLater(
      containerWith(config: proxy)
          .read(backupTransferProvider)
          .downloadWorkspace(workspaceId: 'ws-1', suggestedName: 'ws-1.db'),
      throwsA(
        isA<BackupTransferException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having((e) => e.serverMessage, 'serverMessage', isNull),
      ),
    );
  });

  test('the adopter’s own sentence survives the trip back', () async {
    respondWith(
      status: 400,
      textBody: '{"error":"not a Control Center workspace database"}',
    );

    await expectLater(
      containerWith(config: proxy)
          .read(backupTransferProvider)
          .downloadWorkspace(workspaceId: 'ws-1', suggestedName: 'ws-1.db'),
      throwsA(
        isA<BackupTransferException>().having(
          (e) => e.serverMessage,
          'serverMessage',
          contains('not a Control Center workspace database'),
        ),
      ),
    );
  });

  test('a restore posts the file to the signed restore URL', () async {
    final uploaded = <int>[];
    BackupTransfer.clientFactory = () => MockClient.streaming((
      request,
      bodyStream,
    ) async {
      requested.add(request.url);
      uploaded.addAll(await bodyStream.toBytes());
      return http.StreamedResponse(
        Stream.value(utf8.encode('{"ok":true}')),
        200,
      );
    });

    await containerWith(config: proxy)
        .read(backupTransferProvider)
        .restoreFromFile(
          workspaceId: 'ws-9',
          file: XFile.fromData(
            Uint8List.fromList(const [10, 20, 30]),
            name: 'workspace.db',
          ),
        );

    expect(uploaded, const [10, 20, 30]);
    final url = requested.single;
    expect(url.path, '/backup/restore');
    expect(url.queryParameters['w'], 'ws-9');
    expect(url.queryParameters['s'], isNotEmpty);
  });

  test('a download reports progress, and always lands on the total', () async {
    // Three chunks with a declared length: the bar has a denominator and the
    // last report is the whole file, so it finishes full rather than at 97%.
    BackupTransfer.clientFactory = () => MockClient.streaming((
      request,
      body,
    ) async {
      requested.add(request.url);
      return http.StreamedResponse(
        Stream.fromIterable([
          [1, 2, 3, 4],
          [5, 6, 7, 8],
          [9, 10],
        ]),
        200,
        contentLength: 10,
      );
    });
    final reports = <({int transferred, int? total})>[];

    await containerWith(config: proxy)
        .read(backupTransferProvider)
        .downloadWorkspace(
          workspaceId: 'ws-1',
          suggestedName: 'ws-1.db',
          onProgress: (transferred, total) =>
              reports.add((transferred: transferred, total: total)),
        );

    // Opens at zero so the bar appears immediately rather than after the first
    // chunk of a slow transfer.
    expect(reports.first, (transferred: 0, total: 10));
    expect(reports.last, (transferred: 10, total: 10));
    expect(written, const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  });

  test('a length-less response reports bytes with no denominator', () async {
    BackupTransfer.clientFactory = () => MockClient.streaming((
      request,
      body,
    ) async => http.StreamedResponse(
      Stream.value(const [1, 2, 3]),
      200,
    ));
    final reports = <({int transferred, int? total})>[];

    await containerWith(config: proxy)
        .read(backupTransferProvider)
        .downloadWorkspace(
          workspaceId: 'ws-1',
          suggestedName: 'ws-1.db',
          onProgress: (transferred, total) =>
              reports.add((transferred: transferred, total: total)),
        );

    // Null total, so the UI draws an indeterminate bar instead of inventing a
    // denominator.
    expect(reports.last, (transferred: 3, total: null));
  });

  test('an upload reports progress against the file length', () async {
    BackupTransfer.clientFactory = () => MockClient.streaming((
      request,
      bodyStream,
    ) async {
      await bodyStream.toBytes();
      return http.StreamedResponse(
        Stream.value(utf8.encode('{"ok":true}')),
        200,
      );
    });
    final reports = <({int transferred, int? total})>[];

    await containerWith(config: proxy)
        .read(backupTransferProvider)
        .restoreFromFile(
          workspaceId: 'ws-9',
          file: XFile.fromData(
            Uint8List.fromList(const [10, 20, 30, 40]),
            name: 'workspace.db',
          ),
          onProgress: (transferred, total) =>
              reports.add((transferred: transferred, total: total)),
        );

    expect(reports.first, (transferred: 0, total: 4));
    expect(reports.last, (transferred: 4, total: 4));
  });
}
