// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_records_dao.dart';

// ignore_for_file: type=lint
mixin _$DayRecordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $GamesTable get games => attachedDatabase.games;
  $PlayersTable get players => attachedDatabase.players;
  $DayRecordsTable get dayRecords => attachedDatabase.dayRecords;
  DayRecordsDaoManager get managers => DayRecordsDaoManager(this);
}

class DayRecordsDaoManager {
  final _$DayRecordsDaoMixin _db;
  DayRecordsDaoManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db.attachedDatabase, _db.games);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db.attachedDatabase, _db.players);
  $$DayRecordsTableTableManager get dayRecords =>
      $$DayRecordsTableTableManager(_db.attachedDatabase, _db.dayRecords);
}
