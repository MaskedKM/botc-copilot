// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'games_dao.dart';

// ignore_for_file: type=lint
mixin _$GamesDaoMixin on DatabaseAccessor<AppDatabase> {
  $GamesTable get games => attachedDatabase.games;
  GamesDaoManager get managers => GamesDaoManager(this);
}

class GamesDaoManager {
  final _$GamesDaoMixin _db;
  GamesDaoManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db.attachedDatabase, _db.games);
}
