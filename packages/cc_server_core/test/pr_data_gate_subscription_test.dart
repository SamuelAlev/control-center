import 'dart:async';

import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_server_core/src/catalog/pr_data_gate.dart';
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart';
import 'package:test/test.dart';

/// Every stream the space gate opens for a subscriber (the review spaces,
/// the person's PR visibility, the rows) is cancelled with that subscriber,
/// so no listener outlives a dropped subscription or reaches a database
/// after shutdown.
void main() {
  late StreamController<List<ReviewSpaceAssociation>> associations;
  late StreamController<RepoVisibility> visibility;
  late StreamController<List<String>> rows;
  late PrDataGate gate;

  setUp(() {
    associations = StreamController.broadcast();
    visibility = StreamController.broadcast();
    rows = StreamController.broadcast();
    gate = PrDataGate(
      reviewSpaces: _ReviewSpaces(associations),
      resolve: (_, _) async => RepoVisibility.empty,
      watch: (_, _) => visibility.stream,
      spaceRead: const _Unreadable({'s-secret'}),
    );
  });

  tearDown(() async {
    await associations.close();
    await visibility.close();
    await rows.close();
  });

  ReviewSpaceAssociation review(String spaceId) => ReviewSpaceAssociation(
    id: 'a-$spaceId',
    spaceId: spaceId,
    workspaceId: 'ws1',
    prExternalId: 'pr-1',
    prNumber: 1,
    repoFullName: 'acme/widgets',
    status: ReviewSpaceStatus.requested,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test(
    'a cancelled space-list subscription leaves no listener behind',
    () async {
      final frames = <Map<String, dynamic>>[];
      final sub = gate
          .spaceRows(
            'ws1',
            'gina',
            rows.stream,
            (String id) => id,
            (list) => {'spaces': list},
          )
          .listen(frames.add);
      await settle();
      associations.add([review('s-review')]);
      await settle();
      // Followed once a review space needs it.
      expect(visibility.hasListener, isTrue);
      visibility.add(RepoVisibility.empty);
      rows.add(['s-open', 's-secret', 's-review']);
      for (var i = 0; i < 5; i++) {
        await settle();
      }
      expect(frames.last['spaces'], ['s-open']);
      expect(associations.hasListener, isTrue);
      expect(visibility.hasListener, isTrue);
      expect(rows.hasListener, isTrue);

      await sub.cancel();
      await settle();
      expect(associations.hasListener, isFalse);
      expect(visibility.hasListener, isFalse);
      expect(rows.hasListener, isFalse);
    },
  );

  test('a guarded space stream cancels what it follows', () async {
    final source = StreamController<int>.broadcast();
    addTearDown(source.close);
    final sub = gate
        .guardSpace('ws1', 'gina', 's-review', source.stream)
        .listen((_) {});
    await settle();
    associations.add([review('s-review')]);
    await settle();
    expect(visibility.hasListener, isTrue);

    await sub.cancel();
    await settle();
    expect(source.hasListener, isFalse);
    expect(associations.hasListener, isFalse);
    expect(visibility.hasListener, isFalse);
  });
}

class _ReviewSpaces implements ReviewSpaceRepository {
  _ReviewSpaces(this._associations);

  final StreamController<List<ReviewSpaceAssociation>> _associations;

  @override
  Stream<List<ReviewSpaceAssociation>> watchByWorkspace(String workspaceId) =>
      _associations.stream;

  @override
  Stream<List<ReviewSpaceAssociation>> watchAllBySpace(
    String workspaceId,
    String spaceId,
  ) => _associations.stream.map(
    (list) => [
      for (final a in list)
        if (a.spaceId == spaceId) a,
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A space read gate that withholds [_spaces] from everyone.
class _Unreadable implements SpaceReadGate {
  const _Unreadable(this._spaces);

  final Set<String> _spaces;

  @override
  Future<void> require(
    String workspaceId,
    String userId,
    String spaceId,
  ) async {}

  @override
  Future<Set<String>> unreadable(String workspaceId, String userId) async =>
      _spaces;

  @override
  Future<List<String>> exposedBy(String workspaceId, String? spaceId) async =>
      const [];
}
