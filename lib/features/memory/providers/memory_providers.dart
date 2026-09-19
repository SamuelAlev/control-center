import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams memory facts for a given workspace.
final memoryFactsProvider = StreamProvider.family<List<MemoryFact>, String>((
  ref,
  workspaceId,
) {
  final repo = ref.watch(memoryFactRepositoryProvider);
  return repo.watchByWorkspace(workspaceId);
});

/// Streams memory policies for a given workspace.
final memoryPoliciesProvider =
    StreamProvider.family<List<MemoryPolicy>, String>((ref, workspaceId) {
      final repo = ref.watch(memoryPolicyRepositoryProvider);
      return repo.watchByWorkspace(workspaceId);
    });

/// Streams memory domains for a given workspace.
final memoryDomainsProvider = StreamProvider.family<List<MemoryDomain>, String>(
  (ref, workspaceId) {
    final repo = ref.watch(memoryDomainRepositoryProvider);
    return repo.watchByWorkspace(workspaceId);
  },
);
