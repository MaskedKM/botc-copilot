// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'info_declarations_dao.dart';

// ignore_for_file: type=lint
mixin _$InfoDeclarationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $GamesTable get games => attachedDatabase.games;
  $PlayersTable get players => attachedDatabase.players;
  $DayRecordsTable get dayRecords => attachedDatabase.dayRecords;
  $InfoDeclarationsTable get infoDeclarations =>
      attachedDatabase.infoDeclarations;
  InfoDeclarationsDaoManager get managers => InfoDeclarationsDaoManager(this);
}

class InfoDeclarationsDaoManager {
  final _$InfoDeclarationsDaoMixin _db;
  InfoDeclarationsDaoManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db.attachedDatabase, _db.games);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db.attachedDatabase, _db.players);
  $$DayRecordsTableTableManager get dayRecords =>
      $$DayRecordsTableTableManager(_db.attachedDatabase, _db.dayRecords);
  $$InfoDeclarationsTableTableManager get infoDeclarations =>
      $$InfoDeclarationsTableTableManager(
        _db.attachedDatabase,
        _db.infoDeclarations,
      );
}
