// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_profile_dao.dart';

// ignore_for_file: type=lint
mixin _$VoiceProfileDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $VoiceProfilesTableTable get voiceProfilesTable =>
      attachedDatabase.voiceProfilesTable;
  VoiceProfileDaoManager get managers => VoiceProfileDaoManager(this);
}

class VoiceProfileDaoManager {
  final _$VoiceProfileDaoMixin _db;
  VoiceProfileDaoManager(this._db);
  $$VoiceProfilesTableTableTableManager get voiceProfilesTable =>
      $$VoiceProfilesTableTableTableManager(
        _db.attachedDatabase,
        _db.voiceProfilesTable,
      );
}
