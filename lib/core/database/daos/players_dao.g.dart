// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'players_dao.dart';

// ignore_for_file: type=lint
mixin _$PlayersDaoMixin on DatabaseAccessor<AppDatabase> {
  $GamesTable get games => attachedDatabase.games;
  $PlayersTable get players => attachedDatabase.players;
  PlayersDaoManager get managers => PlayersDaoManager(this);
}

class PlayersDaoManager {
  final _$PlayersDaoMixin _db;
  PlayersDaoManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db.attachedDatabase, _db.games);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db.attachedDatabase, _db.players);
}
