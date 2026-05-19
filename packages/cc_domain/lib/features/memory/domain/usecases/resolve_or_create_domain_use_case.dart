import 'package:cc_domain/core/domain/entities/memory_access_grant.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/memory_permission.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';
import 'package:uuid/uuid.dart';

/// Resolves a domain input string to an existing [MemoryDomain] or creates a
/// new one, seeding access grants for all roles.
class ResolveOrCreateDomainUseCase {
  /// Creates a [ResolveOrCreateDomainUseCase].
  ResolveOrCreateDomainUseCase({
    required MemoryDomainRepository domainRepository,
    required MemoryAccessGrantRepository grantRepository,
  }) : _domainRepository = domainRepository,
       _grantRepository = grantRepository;

  final MemoryDomainRepository _domainRepository;
  final MemoryAccessGrantRepository _grantRepository;
  final _uuid = const Uuid();

  /// Resolves [domainInput] to an existing domain or creates a new one.
  ///
  /// When [repoSlug] is given the domain is scoped to that repo and stored
  /// under a `repo:<repoSlug>/<name>` slug; otherwise it is workspace-wide.
  /// The two are independent domains — recording into `architecture` for a repo
  /// never touches the workspace-wide `architecture`.
  ///
  /// [domainInput] may itself already be qualified (an agent echoing a slug
  /// back from `list_memory_domains`); its own scope is then replaced by
  /// [repoSlug], so the caller's repo always wins and a slug cannot accumulate
  /// two prefixes.
  ///
  /// Returns the resolved or created [MemoryDomain].
  Future<MemoryDomain> execute({
    required String workspaceId,
    required String domainInput,
    String? domainLabel,
    String? domainDescription,
    String? repoSlug,
    required AgentRole authorRole,
  }) async {
    final effectiveRepo =
        repoSlug ?? MemoryDomainScope.parse(domainInput.trim()).repoSlug;
    final slug = MemoryDomainScope.qualify(
      domainInput: domainInput,
      repoSlug: effectiveRepo,
    );
    final existing = await _domainRepository.findByName(workspaceId, slug);
    if (existing != null) {
      return existing;
    }

    final now = DateTime.now();
    final domain = MemoryDomain(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      name: slug,
      // The label stays the BARE human name; the repo is shown as its own chip
      // rather than baked into the text, so the same domain reads identically
      // whichever repo it belongs to.
      label: domainLabel ?? MemoryDomainScope.parse(domainInput.trim()).name,
      description: domainDescription,
      createdAt: now,
      createdByRole: authorRole.name,
    );

    await _domainRepository.upsert(domain);
    await _seedAccessGrants(workspaceId, slug, authorRole);

    return domain;
  }

  /// Seeds grants on the BARE domain name, never the repo-qualified slug.
  ///
  /// Grants are keyed `(workspaceId, agentRole, memoryDomain)`, so keying them
  /// on the full slug would mint a fresh row per role per repo — the access
  /// matrix would grow with the repo count and tightening `architecture` to
  /// read-only would silently leave every repo's copy writable.
  Future<void> _seedAccessGrants(
    String workspaceId,
    String domainSlug,
    AgentRole creatorRole,
  ) async {
    final bare = MemoryDomainScope.bareName(domainSlug);
    // Workspace memory is collaborative: seed WRITE for every role so any
    // agent can contribute facts and policies. (Previously only the creating
    // role got write, which silently blocked `propose_policy` for everyone
    // else — the reason agents almost never wrote policies.) The access-matrix
    // editor remains the place to tighten a sensitive domain to read/none.
    final grants = <MemoryAccessGrant>[
      for (final role in AgentRole.values)
        MemoryAccessGrant(
          workspaceId: workspaceId,
          agentRole: role,
          memoryDomain: bare,
          permission: MemoryPermission.write,
        ),
    ];
    await _grantRepository.upsertAll(grants);
  }
}
