// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demon_inheritances_dao.dart';

// ignore_for_file: type=lint
mixin _$DemonInheritancesDaoMixin on DatabaseAccessor<AppDatabase> {
  $GamesTable get games => attachedDatabase.games;
  $PlayersTable get players => attachedDatabase.players;
  $DemonInheritancesTable get demonInheritances =>
      attachedDatabase.demonInheritances;
  DemonInheritancesDaoManager get managers => DemonInheritancesDaoManager(this);
}

class DemonInheritancesDaoManager {
  final _$DemonInheritancesDaoMixin _db;
  DemonInheritancesDaoManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db.attachedDatabase, _db.games);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db.attachedDatabase, _db.players);
  $$DemonInheritancesTableTableManager get demonInheritances =>
      $$DemonInheritancesTableTableManager(
        _db.attachedDatabase,
        _db.demonInheritances,
      );
}
