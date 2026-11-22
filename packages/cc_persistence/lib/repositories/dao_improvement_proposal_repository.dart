import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_persistence/database/daos/improvement_proposal_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/improvement_proposal_mapper.dart';
import 'package:cc_persistence/repositories/refused_rows.dart';
import 'package:drift/drift.dart';

/// Drift-backed [ImprovementProposalRepository].
///
/// Resolves `_dbs.of(workspaceId).improvementProposalDao` per call;
/// [insert] picks the file from the proposal's own workspace. A decision and
/// the campaign fields are each one conditional statement. A row the entity
/// refuses is left out and reported through the warning sink; a `proposed`
/// one is marked `expired` by the read, so nobody can accept it.
class DaoImprovementProposalRepository
    implements ImprovementProposalRepository {
  /// Creates a [DaoImprovementProposalRepository] over the per-workspace
  /// databases.
  DaoImprovementProposalRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final ImprovementProposalMapper _mapper = const ImprovementProposalMapper();

  static final String _proposed = ImprovementStatus.proposed.wire;

  ImprovementProposalDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).improvementProposalDao;

  Future<List<ImprovementProposal>> _list(
    String workspaceId,
    Iterable<ImprovementProposalsTableData> rows,
  ) => mapSettlingRefused(
    dbs: _dbs,
    workspaceId: workspaceId,
    repository: 'ImprovementProposalRepository',
    table: 'improvement_proposals',
    rows: rows,
    map: _mapper.tryToDomain,
    isOpen: (row) => row.status == _proposed,
    idOf: (row) => row.id,
    settle: (ids) async {
      var expired = 0;
      for (final id in ids) {
        if (await _dao(workspaceId).writeIf(
          id,
          (t) => t.status.equals(_proposed),
          ImprovementProposalsTableCompanion(
            status: Value(ImprovementStatus.expired.wire),
          ),
        )) {
          expired++;
        }
      }
      return expired;
    },
    settledAs: ImprovementStatus.expired.wire,
  );

  Future<ImprovementProposal?> _one(
    String workspaceId,
    ImprovementProposalsTableData? row,
  ) async => row == null ? null : (await _list(workspaceId, [row])).firstOrNull;

  @override
  Future<void> insert(ImprovementProposal proposal) =>
      _dao(proposal.workspaceId).insert(_mapper.toCompanion(proposal));

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
  }) {
    if (to == ImprovementStatus.proposed || to == from) {
      throw ArgumentError.value(
        to,
        'to',
        'must be a decided status other than ${from.wire}',
      );
    }
    if (decidedByUserId != null && decidedByUserId.isEmpty) {
      throw ArgumentError.value(
        decidedByUserId,
        'decidedByUserId',
        'must not be empty',
      );
    }
    return _dao(workspaceId).writeIf(
      id,
      (t) => t.status.equals(from.wire),
      ImprovementProposalsTableCompanion(
        status: Value(to.wire),
        decidedByUserId: Value(decidedByUserId),
        decidedAt: Value(now),
        beforeText: Value.absentIfNull(beforeText),
        afterText: Value.absentIfNull(afterText),
        appliedRef: Value.absentIfNull(appliedRef),
      ),
    );
  }

  @override
  Future<bool> setCampaign(
    String workspaceId, {
    required String id,
    required Set<ImprovementCampaignState> from,
    required String? campaignId,
    required ImprovementCampaignState state,
    required String? candidateRevisionId,
  }) => _dao(workspaceId).writeIf(
    id,
    (t) =>
        t.status.equals(_proposed) &
        t.campaignState.isIn([for (final f in from) f.wire]),
    ImprovementProposalsTableCompanion(
      campaignState: Value(state.wire),
      campaignId: Value(campaignId),
      candidateRevisionId: Value(candidateRevisionId),
    ),
  );

  @override
  Future<bool> releaseStaging(
    String workspaceId, {
    required String id,
    required ImprovementCampaignState to,
  }) => _dao(workspaceId).writeIf(
    id,
    (t) => t.campaignState.equals(ImprovementCampaignState.staging.wire),
    ImprovementProposalsTableCompanion(
      campaignState: Value(to.wire),
      candidateRevisionId: const Value(null),
    ),
  );

  @override
  Future<bool> markApplied(
    String workspaceId, {
    required String id,
    required String appliedRef,
  }) => _dao(workspaceId).writeIf(
    id,
    (t) =>
        t.status.equals(ImprovementStatus.accepted.wire) &
        t.appliedRef.isNull(),
    ImprovementProposalsTableCompanion(appliedRef: Value(appliedRef)),
  );

  @override
  Future<ImprovementProposal?> getById(String workspaceId, String id) async =>
      _one(workspaceId, await _dao(workspaceId).getById(id));

  @override
  Future<List<ImprovementProposal>> listForWorkspace(
    String workspaceId, {
    Set<ImprovementStatus>? statuses,
  }) async => _list(
    workspaceId,
    await _dao(workspaceId).list(
      statuses: statuses == null ? null : {for (final s in statuses) s.wire},
    ),
  );

  @override
  Stream<List<ImprovementProposal>> watchForWorkspace(String workspaceId) =>
      _dao(workspaceId).watchAll().asyncMap((rows) => _list(workspaceId, rows));

  @override
  Future<List<ImprovementProposal>> listByGoal(
    String workspaceId,
    String goalId,
  ) async => _list(workspaceId, await _dao(workspaceId).listByGoal(goalId));

  @override
  Future<ImprovementProposal?> latestForConversation(
    String workspaceId,
    String conversationId,
  ) async => _one(
    workspaceId,
    await _dao(workspaceId).latestForConversation(conversationId),
  );

  @override
  Future<int> expireDue(
    String workspaceId, {
    required DateTime now,
    required Set<String> except,
  }) => _dao(workspaceId).expireDue(now, except: except);
}
