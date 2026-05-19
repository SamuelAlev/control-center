import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/features/teams/data/repositories/team_repository_impl.dart';
import 'package:control_center/features/teams/domain/repositories/team_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [TeamRepository] implementation.
final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepositoryImpl(ref.watch(databaseProvider).teamDao);
});
