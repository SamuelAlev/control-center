import 'package:cc_domain/features/messaging/domain/repositories/channel_read_repository.dart';
import 'package:cc_persistence/database/daos/messaging_dao.dart';

/// [ChannelReadRepository] backed by [MessagingDao].
///
/// Thin pass-through over the DAO's read-cursor column on
/// `channel_participants`. The DAO owns the SQL; this class exists so consumers
/// depend on the domain port, not the Drift DAO.
class DaoChannelReadRepository implements ChannelReadRepository {
  /// Creates a [DaoChannelReadRepository].
  DaoChannelReadRepository(this._dao);

  final MessagingDao _dao;

  @override
  Future<void> markChannelRead(String channelId) =>
      _dao.markChannelRead(channelId);

  @override
  Stream<DateTime?> watchUserLastReadAt(String channelId) =>
      _dao.watchUserLastReadAt(channelId);
}
