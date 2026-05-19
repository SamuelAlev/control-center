import 'dart:math' as math;

import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/repositories/dao_voice_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DaoVoiceProfileRepository repo;

  setUp(() async {
    db = createTestDatabase();
    await db.customStatement('PRAGMA foreign_keys = OFF');
    repo = DaoVoiceProfileRepository(db.voiceProfileDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('DaoVoiceProfileRepository.enroll', () {
    test('creates a new profile on first enrollment (round-trips embedding)',
        () async {
      await repo.enroll(
        workspaceId: 'w1',
        displayName: 'Alex',
        sampleEmbedding: const [1, 0, 0],
      );

      final profiles = await repo.getByWorkspace('w1');
      expect(profiles, hasLength(1));
      expect(profiles.single.displayName, 'Alex');
      expect(profiles.single.sampleCount, 1);
      expect(profiles.single.embedding, [1.0, 0.0, 0.0]);
    });

    test('blends a second sample into the centroid and increments the count',
        () async {
      await repo.enroll(
        workspaceId: 'w1',
        displayName: 'Alex',
        sampleEmbedding: const [1, 0, 0],
      );
      await repo.enroll(
        workspaceId: 'w1',
        displayName: 'Alex',
        sampleEmbedding: const [0, 1, 0],
      );

      final profile = await repo.getByName('w1', 'Alex');
      expect(profile, isNotNull);
      expect(profile!.sampleCount, 2);
      // mean([1,0,0],[0,1,0]) = [0.5,0.5,0] → normalized = [0.707,0.707,0]
      expect(profile.embedding[0], closeTo(math.sqrt1_2, 1e-9));
      expect(profile.embedding[1], closeTo(math.sqrt1_2, 1e-9));
      expect(profile.embedding[2], closeTo(0, 1e-9));
      // Still exactly one row for that name (enrollment upserts, never dupes).
      expect(await repo.getByWorkspace('w1'), hasLength(1));
    });

    test('is workspace-scoped: an enrollment never leaks to another workspace',
        () async {
      await repo.enroll(
        workspaceId: 'w1',
        displayName: 'Alex',
        sampleEmbedding: const [1, 0, 0],
      );
      expect(await repo.getByWorkspace('w2'), isEmpty);
    });

    test('ignores an empty name or empty sample', () async {
      await repo.enroll(
        workspaceId: 'w1',
        displayName: '   ',
        sampleEmbedding: const [1, 0],
      );
      await repo.enroll(
        workspaceId: 'w1',
        displayName: 'Alex',
        sampleEmbedding: const [],
      );
      expect(await repo.getByWorkspace('w1'), isEmpty);
    });
  });

  group('DaoVoiceProfileRepository.unenroll', () {
    test('deletes the profile when its only sample is removed', () async {
      await repo.enroll(
        workspaceId: 'w1',
        displayName: 'Alex',
        sampleEmbedding: const [1, 0, 0],
      );

      await repo.unenroll(
        workspaceId: 'w1',
        displayName: 'Alex',
        sampleEmbedding: const [1, 0, 0],
      );

      expect(await repo.getByName('w1', 'Alex'), isNull);
    });

    test('backs a sample out of a two-sample centroid and decrements the count',
        () async {
      await repo.enroll(
        workspaceId: 'w1',
        displayName: 'Alex',
        sampleEmbedding: const [1, 0, 0],
      );
      await repo.enroll(
        workspaceId: 'w1',
        displayName: 'Alex',
        sampleEmbedding: const [0, 1, 0],
      );

      // Remove the [0,1,0] sample → count 2→1 and the centroid leans back
      // toward [1,0,0] (approximate inverse; re-normalization makes it inexact).
      await repo.unenroll(
        workspaceId: 'w1',
        displayName: 'Alex',
        sampleEmbedding: const [0, 1, 0],
      );

      final profile = await repo.getByName('w1', 'Alex');
      expect(profile, isNotNull);
      expect(profile!.sampleCount, 1);
      expect(profile.embedding[0], greaterThan(profile.embedding[1]));
    });

    test('is a no-op when no profile with that name exists', () async {
      await repo.unenroll(
        workspaceId: 'w1',
        displayName: 'Ghost',
        sampleEmbedding: const [1, 0, 0],
      );
      expect(await repo.getByWorkspace('w1'), isEmpty);
    });

    test('is workspace-scoped: cannot un-enroll a foreign workspace profile',
        () async {
      await repo.enroll(
        workspaceId: 'w1',
        displayName: 'Alex',
        sampleEmbedding: const [1, 0, 0],
      );

      // A "w2" un-enroll must not touch w1's profile.
      await repo.unenroll(
        workspaceId: 'w2',
        displayName: 'Alex',
        sampleEmbedding: const [1, 0, 0],
      );

      expect(await repo.getByName('w1', 'Alex'), isNotNull);
    });

    test('ignores an empty name or empty sample', () async {
      await repo.enroll(
        workspaceId: 'w1',
        displayName: 'Alex',
        sampleEmbedding: const [1, 0, 0],
      );

      await repo.unenroll(
        workspaceId: 'w1',
        displayName: '   ',
        sampleEmbedding: const [1, 0, 0],
      );
      await repo.unenroll(
        workspaceId: 'w1',
        displayName: 'Alex',
        sampleEmbedding: const [],
      );

      expect(await repo.getByName('w1', 'Alex'), isNotNull);
    });
  });
}
