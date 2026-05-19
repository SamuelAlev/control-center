import 'package:control_center/core/domain/entities/repo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Github linked repos of.
List<Repo> githubLinkedReposOf(AsyncValue<List<Repo>> async) {
  final repos = async.value ?? const <Repo>[];
  return repos.where((r) => r.hasGitHubRemote).toList(growable: false);
}

