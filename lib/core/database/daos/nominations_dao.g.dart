// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nominations_dao.dart';

// ignore_for_file: type=lint
mixin _$NominationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $GamesTable get games => attachedDatabase.games;
  $PlayersTable get players => attachedDatabase.players;
  $DayRecordsTable get dayRecords => attachedDatabase.dayRecords;
  $NominationsTable get nominations => attachedDatabase.nominations;
  NominationsDaoManager get managers => NominationsDaoManager(this);
}

class NominationsDaoManager {
  final _$NominationsDaoMixin _db;
  NominationsDaoManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db.attachedDatabase, _db.games);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db.attachedDatabase, _db.players);
  $$DayRecordsTableTableManager get dayRecords =>
      $$DayRecordsTableTableManager(_db.attachedDatabase, _db.dayRecords);
  $$NominationsTableTableManager get nominations =>
      $$NominationsTableTableManager(_db.attachedDatabase, _db.nominations);
}
