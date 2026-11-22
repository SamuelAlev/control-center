part of 'improvement_adoption_test.dart';

/// The proposals, in memory, with the conditional moves of the real store.
class _Proposals implements ImprovementProposalRepository {
  final Map<String, ImprovementProposal> byId = {};
  final _changes = StreamController<void>.broadcast();

  ImprovementProposal _copy(
    ImprovementProposal p, {
    ImprovementStatus? status,
    String? before,
    String? after,
    String? appliedRef,
    String? decidedBy,
    DateTime? decidedAt,
    String? campaignId,
    ImprovementCampaignState? campaignState,
    String? candidate,
    bool clearCandidate = false,
    bool clearCampaign = false,
  }) => ImprovementProposal(
    id: p.id,
    workspaceId: p.workspaceId,
    agentId: p.agentId,
    spaceId: p.spaceId,
    conversationId: p.conversationId,
    goalId: p.goalId,
    reviewRunId: p.reviewRunId,
    kind: p.kind,
    scope: p.scope,
    scopeRefId: p.scopeRefId,
    operation: p.operation,
    targetRef: p.targetRef,
    change: p.change,
    evidence: p.evidence,
    expected: p.expected,
    status: status ?? p.status,
    beforeText: before ?? p.beforeText,
    afterText: after ?? p.afterText,
    appliedRef: appliedRef ?? p.appliedRef,
    candidateRevisionId: clearCandidate
        ? null
        : candidate ?? p.candidateRevisionId,
    campaignId: clearCampaign ? null : campaignId ?? p.campaignId,
    campaignState: campaignState ?? p.campaignState,
    decidedByUserId: decidedBy ?? p.decidedByUserId,
    decidedAt: decidedAt ?? p.decidedAt,
    createdAt: p.createdAt,
    expiresAt: p.expiresAt,
  );

  @override
  Future<void> insert(ImprovementProposal p) async {
    byId[p.id] = p;
    _changes.add(null);
  }

  @override
  Future<ImprovementProposal?> getById(String ws, String id) async {
    final p = byId[id];
    return p?.workspaceId == ws ? p : null;
  }

  @override
  Future<bool> decide(
    String workspaceId, {
    required String id,
    required ImprovementStatus from,
    required ImprovementStatus to,
    required String? decidedByUserId,
    String? beforeText,
    String? afterText,
    String? appliedRef,
    required DateTime now,
  }) async {
    final p = byId[id];
    if (p == null || p.workspaceId != workspaceId || p.status != from) {
      return false;
    }
    byId[id] = _copy(
      p,
      status: to,
      before: beforeText,
      after: afterText,
      appliedRef: appliedRef,
      decidedBy: decidedByUserId,
      decidedAt: now,
    );
    _changes.add(null);
    return true;
  }

  @override
  Future<bool> setCampaign(
    String workspaceId, {
    required String id,
    required Set<ImprovementCampaignState> from,
    required String? campaignId,
    required ImprovementCampaignState state,
    required String? candidateRevisionId,
  }) async {
    final p = byId[id];
    if (p == null ||
        p.workspaceId != workspaceId ||
        p.status != ImprovementStatus.proposed ||
        !from.contains(p.campaignState)) {
      return false;
    }
    byId[id] = _copy(
      p,
      campaignId: campaignId,
      clearCampaign: campaignId == null,
      campaignState: state,
      candidate: candidateRevisionId,
      clearCandidate: candidateRevisionId == null,
    );
    _changes.add(null);
    return true;
  }

  @override
  Future<bool> releaseStaging(
    String workspaceId, {
    required String id,
    required ImprovementCampaignState to,
  }) async {
    final p = byId[id];
    if (p == null ||
        p.workspaceId != workspaceId ||
        p.campaignState != ImprovementCampaignState.staging) {
      return false;
    }
    byId[id] = _copy(p, campaignState: to, clearCandidate: true);
    return true;
  }

  @override
  Future<bool> markApplied(
    String workspaceId, {
    required String id,
    required String appliedRef,
  }) async {
    final p = byId[id];
    if (p == null ||
        p.workspaceId != workspaceId ||
        p.status != ImprovementStatus.accepted ||
        p.appliedRef != null) {
      return false;
    }
    byId[id] = _copy(p, appliedRef: appliedRef);
    return true;
  }

  @override
  Future<List<ImprovementProposal>> listForWorkspace(
    String workspaceId, {
    Set<ImprovementStatus>? statuses,
  }) async => [
    for (final p in byId.values)
      if (p.workspaceId == workspaceId &&
          (statuses == null || statuses.contains(p.status)))
        p,
  ];

  @override
  Stream<List<ImprovementProposal>> watchForWorkspace(String ws) =>
      _watch(_changes.stream, () => [...byId.values]);

  @override
  Future<int> expireDue(
    String workspaceId, {
    required DateTime now,
    required Set<String> except,
  }) async {
    var n = 0;
    for (final p in byId.values.toList()) {
      if (p.workspaceId == workspaceId &&
          !except.contains(p.id) &&
          p.status == ImprovementStatus.proposed &&
          !p.expiresAt.isAfter(now)) {
        byId[p.id] = _copy(p, status: ImprovementStatus.expired);
        n++;
      }
    }
    return n;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Facts implements MemoryFactRepository {
  final Map<String, MemoryFact> byId = {};

  @override
  Future<MemoryFact?> getById(String ws, String id) async {
    final f = byId[id];
    return f?.workspaceId == ws ? f : null;
  }

  @override
  Future<void> upsert(MemoryFact fact) async => byId[fact.id] = fact;

  @override
  Future<void> delete(String ws, String id) async => byId.remove(id);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Policies implements MemoryPolicyRepository {
  final Map<String, MemoryPolicy> byId = {};

  @override
  Future<MemoryPolicy?> getById(String ws, String id) async {
    final p = byId[id];
    return p?.workspaceId == ws ? p : null;
  }

  @override
  Future<void> upsert(MemoryPolicy policy) async => byId[policy.id] = policy;

  @override
  Future<void> delete(String ws, String id) async => byId.remove(id);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Notes implements AgentWorkingMemoryRepository {
  final Map<String, AgentWorkingMemory> byAgent = {};

  @override
  Future<AgentWorkingMemory?> getByAgent(String ws, String agentId) async {
    final n = byAgent[agentId];
    return n?.workspaceId == ws ? n : null;
  }

  @override
  Future<void> upsert(AgentWorkingMemory memory) async =>
      byAgent[memory.agentId] = memory;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

/// [ImprovementApplyPort] over the fakes: the claim, then the target
/// compared with the row the plan read, then the write; a mismatch undoes
/// the claim (what the real port's transaction does).
class _Apply implements ImprovementApplyPort {
  _Apply(this.proposals, this.facts, this.policies, this.notes);
  final _Proposals proposals;
  final _Facts facts;
  final _Policies policies;
  final _Notes notes;

  /// Runs between the claim and the write, like a crash or a racing writer.
  Future<void> Function()? between;

  @override
  Future<ImprovementApplyOutcome> decideAndWrite(
    String workspaceId, {
    required String id,
    required ImprovementStatus from,
    required ImprovementStatus to,
    required String decidedByUserId,
    required String? beforeText,
    required String? afterText,
    required String? appliedRef,
    required DateTime now,
    required ImprovementTextWrite write,
  }) async {
    final before = proposals.byId[id];
    if (!await proposals.decide(
      workspaceId,
      id: id,
      from: from,
      to: to,
      decidedByUserId: decidedByUserId,
      beforeText: beforeText,
      afterText: afterText,
      appliedRef: appliedRef,
      now: now,
    )) {
      return ImprovementApplyOutcome.alreadyDecided;
    }
    try {
      await between?.call();
      final same = switch (write) {
        ImprovementFactWrite(:final expected, :final fact) =>
          facts.byId[expected?.id ?? fact!.id] == expected,
        ImprovementPolicyWrite(:final expected, :final policy) =>
          policies.byId[expected?.id ?? policy!.id] == expected,
        ImprovementNoteWrite(:final expected, :final note) =>
          notes.byAgent[note.agentId] == expected,
      };
      if (!same) {
        proposals.byId[id] = before!;
        return ImprovementApplyOutcome.changedSince;
      }
      switch (write) {
        case ImprovementFactWrite(:final expected, :final fact):
          fact == null
              ? facts.byId.remove(expected!.id)
              : facts.byId[fact.id] = fact;
        case ImprovementPolicyWrite(:final expected, :final policy):
          policy == null
              ? policies.byId.remove(expected!.id)
              : policies.byId[policy.id] = policy;
        case ImprovementNoteWrite(:final note):
          notes.byAgent[note.agentId] = note;
      }
      return ImprovementApplyOutcome.applied;
    } on Object {
      // The transaction rolls back: neither half stays.
      proposals.byId[id] = before!;
      rethrow;
    }
  }
}

class _Repos implements RepoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Files implements WorkspaceFilesystemPort {
  final Map<String, String> skills = {};

  @override
  Future<String?> readSkillFile(String ws, String slug) async =>
      skills['$ws/$slug'];

  /// Runs once, right after the next skill write (another writer).
  void Function()? afterWrite;

  @override
  Future<void> writeSkillFile(String ws, String slug, String content) async {
    skills['$ws/$slug'] = content;
    final hook = afterWrite;
    afterWrite = null;
    hook?.call();
  }

  @override
  Future<void> deleteSkillDir(String ws, String slug) async =>
      skills.remove('$ws/$slug');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

/// Snapshots of the fake filesystem's skills, kept by hash.
class _Snapshots implements SkillEvaluationSnapshotStore {
  _Snapshots(this.files);
  final _Files files;
  final Map<String, AdmittedSkillEvaluationSnapshot> byHash = {};

  @override
  Future<AdmittedSkillEvaluationSnapshot> capture({
    required String workspaceId,
    required String slug,
    String? repoId,
    String? skillPath,
  }) async {
    final text = files.skills['$workspaceId/$slug']!;
    final bytes = <String, List<int>>{'SKILL.md': utf8.encode(text)};
    final snapshot = AdmittedSkillEvaluationSnapshot(
      skillKey: 'workspace:$slug',
      package: SkillPackageSnapshot(
        slug: slug,
        files: bytes,
        packageHash: SkillPackageSnapshot.computeHash(bytes),
        origin: 'workspace',
      ),
      scan: const SkillScanResult(
        verdict: SkillScanVerdict.pass,
        findings: [],
        manifest: SkillCapabilityManifest(),
        rulesVersion: 1,
      ),
    );
    byHash[snapshot.package.packageHash] = snapshot;
    return snapshot;
  }

  @override
  Future<AdmittedSkillEvaluationSnapshot?> previous({
    required String workspaceId,
    required String skillKey,
    required String hash,
  }) async => byHash[hash];

  @override
  Future<AdmittedSkillEvaluationSnapshot> stage({
    required String workspaceId,
    required String slug,
    required AdmittedSkillEvaluationSnapshot? base,
    required String skillMd,
  }) async {
    final bytes = <String, List<int>>{
      ...?base?.package.files,
      'SKILL.md': utf8.encode(skillMd),
    };
    final snapshot = _snapshot(slug, bytes);
    byHash[snapshot.package.packageHash] = snapshot;
    return snapshot;
  }

  @override
  Future<void> discard({
    required String workspaceId,
    required String skillKey,
    required String hash,
  }) async {
    if (failDiscard) {
      throw StateError('disk full');
    }
    discarded.add(hash);
    byHash.remove(hash);
  }

  final List<String> discarded = [];
  bool failDiscard = false;

  static AdmittedSkillEvaluationSnapshot _snapshot(
    String slug,
    Map<String, List<int>> bytes,
  ) => AdmittedSkillEvaluationSnapshot(
    skillKey: 'workspace:$slug',
    package: SkillPackageSnapshot(
      slug: slug,
      files: bytes,
      packageHash: SkillPackageSnapshot.computeHash(bytes),
      origin: 'workspace',
    ),
    scan: const SkillScanResult(
      verdict: SkillScanVerdict.pass,
      findings: [],
      manifest: SkillCapabilityManifest(),
      rulesVersion: 1,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Evals implements EvalsRepository {
  final Map<String, SkillEvaluationCampaign> campaigns = {};
  final _campaignChanges = StreamController<void>.broadcast();

  /// Tells the watchers a campaign row changed.
  void changed() => _campaignChanges.add(null);

  @override
  Stream<List<SkillEvaluationCampaign>> watchSkillCampaigns(
    String workspaceId, {
    String? skillKey,
  }) => _watch(_campaignChanges.stream, () => [...campaigns.values]);

  @override
  Future<SkillEvaluationCampaign?> skillCampaignById(
    String ws,
    String id,
  ) async => campaigns[id];

  @override
  Future<List<SkillEvaluationCampaign>> skillCampaigns(
    String workspaceId, {
    String? skillKey,
    int limit = 100,
  }) async => [
    for (final c in campaigns.values)
      if (c.workspaceId == workspaceId &&
          (skillKey == null || c.skillKey == skillKey))
        c,
  ].take(limit).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

/// A skill evaluation that records what it was asked and spends nothing.
class _Evaluation implements SkillEvaluationService {
  _Evaluation(this.snapshots);

  @override
  final _Snapshots snapshots;

  @override
  final _Evals repository = _Evals();

  final List<SkillEvaluationSettings> launched = [];
  final List<String> cancelled = [];

  /// Runs once, after the next launch and before it returns.
  Future<Object?> Function()? onLaunch;

  /// The live `SKILL.md` when the campaign was launched.
  String? liveAtLaunch;

  SkillEvaluationCampaign campaign(
    SkillEvaluationSettings s,
    SkillEvaluationCampaignStatus status, {
    String id = 'camp-1',
    String skillHash = 'cand',
    Map<String, dynamic>? report,
  }) => SkillEvaluationCampaign(
    id: id,
    workspaceId: _ws,
    skillKey: 'workspace:${s.skillSlug}',
    skillSlug: s.skillSlug,
    skillHash: skillHash,
    baselineHash: s.baselineHash,
    corpusId: s.corpusId,
    providerId: s.providerId,
    modelId: s.modelId,
    configurationHash: 'config',
    comparison: s.comparison,
    status: status,
    repetitions: s.repetitions,
    budgetMicros: s.budgetMicros,
    plannedAttempts: 2,
    completedAttempts: 0,
    createdAt: _t0,
    actor: const UserPrincipal('user-1'),
    triggeredBy: 'manual',
    configuration: s.toJson(),
    report: report,
  );

  @override
  Future<SkillEvaluationCampaign> launch({
    required String workspaceId,
    required Principal actor,
    required SkillEvaluationSettings settings,
    bool automatic = false,
  }) async {
    launched.add(settings);
    // What the campaign measures: the staged candidate, never the live file.
    liveAtLaunch = snapshots.files.skills['$workspaceId/${settings.skillSlug}'];
    final c = campaign(
      settings,
      SkillEvaluationCampaignStatus.running,
      id: 'camp-${launched.length}',
      skillHash: settings.candidateHash!,
    );
    repository.campaigns[c.id] = c;
    final hook = onLaunch;
    onLaunch = null;
    await hook?.call();
    return c;
  }

  /// When set, a cancel throws it (the evaluation refused or failed).
  Object? failCancel;

  /// People the evaluation no longer authorizes (removed from the
  /// workspace): a cancel in their name is refused.
  final Set<String> removedActors = {};

  /// Campaigns cancelled in a person's name (`evals.cancelCampaign`).
  final List<String> cancelledByPerson = [];

  @override
  Future<SkillEvaluationCampaign> cancel(
    String workspaceId,
    Principal actor,
    String id,
  ) async {
    if (removedActors.contains(actor.id)) {
      throw const AuthException('Unknown workspace or actor');
    }
    final failure = failCancel;
    if (failure != null) {
      throw failure;
    }
    cancelledByPerson.add(id);
    final c = repository.campaigns[id]!;
    repository.campaigns[id] = c.copyWith(
      status: SkillEvaluationCampaignStatus.cancelled,
    );
    repository.changed();
    return repository.campaigns[id]!;
  }

  @override
  Future<SkillEvaluationCampaign?> cancelAsServer(
    String workspaceId,
    String id,
  ) async {
    final failure = failCancel;
    if (failure != null) {
      throw failure;
    }
    cancelled.add(id);
    final c = repository.campaigns[id]!;
    repository.campaigns[id] = c.copyWith(
      status: SkillEvaluationCampaignStatus.cancelled,
    );
    repository.changed();
    return repository.campaigns[id]!;
  }

  /// Ends campaign [id] with [status] and [report].
  void finish(
    SkillEvaluationCampaignStatus status,
    Map<String, dynamic> report, {
    String id = 'camp-1',
  }) {
    final c = repository.campaigns[id]!;
    repository.campaigns[id] = c.copyWith(status: status, report: report);
    repository.changed();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Kit {
  _Kit({
    bool recovered = true,
    Duration recoveryWait = const Duration(seconds: 5),
  }) {
    evaluation = _Evaluation(_Snapshots(files));
    apply = _Apply(proposals, facts, policies, notes);
    service = ImprovementAdoptionService(
      proposals: proposals,
      apply: apply,
      facts: facts,
      policies: policies,
      notes: notes,
      repos: _Repos(),
      filesystem: files,
      scanner: null,
      evaluation: () => evaluation,
      now: () => now,
      recoveryWait: recoveryWait,
    );
    if (recovered) {
      service.markRecovered();
    }
  }

  final proposals = _Proposals();
  final facts = _Facts();
  final policies = _Policies();
  final notes = _Notes();
  final files = _Files();
  late final _Evaluation evaluation;
  late final _Apply apply;
  late final ImprovementAdoptionService service;
  DateTime now = _t0;

  ImprovementProposal add({
    String id = 'p-1',
    String workspaceId = _ws,
    String? spaceId = 'space-1',
    ImprovementKind kind = ImprovementKind.memoryFact,
    ImprovementScope scope = ImprovementScope.workspace,
    String? scopeRefId,
    ImprovementOperation operation = ImprovementOperation.add,
    String? targetRef = 'build',
    String change = 'Run make gen before make test.',
  }) {
    final p = ImprovementProposal(
      id: id,
      workspaceId: workspaceId,
      agentId: 'agent-1',
      spaceId: spaceId,
      conversationId: 'conv-1',
      kind: kind,
      scope: scope,
      scopeRefId: scopeRefId,
      operation: operation,
      targetRef: targetRef,
      change: change,
      evidence: ImprovementEvidence(messageIds: const ['m-1']),
      expected: 'The first build passes.',
      createdAt: now,
      expiresAt: now.add(ImprovementProposal.lifetime),
    );
    proposals.byId[id] = p;
    return p;
  }
}

/// A completed skill campaign's report: one candidate arm against the
/// baseline, with [candidateOnly] and [baselineOnly] pairs only that arm
/// solved and [bothPass] pairs both solved, out of [pairs] over [tasks] used
/// task blocks. The observed task-mean difference is [delta], by default
/// the pair difference (equal repetitions per task make them agree).
Map<String, dynamic> _report({
  String verdict = 'inconclusive',
  int pairs = 8,
  int tasks = 4,
  int candidateOnly = 1,
  int baselineOnly = 1,
  int bothPass = 4,
  double? delta,
  bool omitDelta = false,
  bool coverage = true,
  List<String> planViolations = const [],
  List<String> regressions = const [],
  String recommendation = 'keep_quality_default',
}) => {
  'coverageComplete': coverage,
  'planViolations': planViolations,
  'recommendation': recommendation,
  'regressions': [
    for (final (i, kind) in regressions.indexed)
      {'taskId': 't-$i', 'treatmentArmId': 'candidate', 'kind': kind},
  ],
  'verdicts': [
    {
      'baselineArmId': 'baseline',
      'treatmentArmId': 'candidate',
      'pairs': pairs,
      'treatmentOnlyWins': candidateOnly,
      'baselineOnlyWins': baselineOnly,
      'bothPass': bothPass,
      'effectiveTaskCount': tasks,
      if (!omitDelta)
        'observedDelta': delta ?? (candidateOnly - baselineOnly) / pairs,
      'lowerBound': -0.4,
      'verdict': verdict,
      'recommendation': recommendation,
    },
  ],
};

/// A report that passes: a superior screen.
final _passing = _report(
  verdict: 'superior',
  candidateOnly: 3,
  baselineOnly: 0,
  recommendation: 'adopt_treatment',
);

/// A report that fails: the baseline solved one pair more, so the observed
/// task-mean difference is below 0.
final _failing = _report(candidateOnly: 1, baselineOnly: 2);

Matcher _refused(String kind) => throwsA(
  isA<ImprovementRefusedException>().having((e) => e.code, 'code', kind),
);

/// A watch like the store's: the rows now, then again on every change; a
/// cancel ends it at once (an `async*` loop parked in `await for` would not).
Stream<List<T>> _watch<T>(Stream<void> changes, List<T> Function() rows) =>
    Stream.multi((out) {
      out.add(rows());
      final sub = changes.listen((_) => out.add(rows()));
      out.onCancel = sub.cancel;
    });
