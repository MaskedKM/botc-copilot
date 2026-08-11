// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poison_statuses_dao.dart';

// ignore_for_file: type=lint
mixin _$PoisonStatusesDaoMixin on DatabaseAccessor<AppDatabase> {
  $GamesTable get games => attachedDatabase.games;
  $PlayersTable get players => attachedDatabase.players;
  $PoisonStatusesTable get poisonStatuses => attachedDatabase.poisonStatuses;
  PoisonStatusesDaoManager get managers => PoisonStatusesDaoManager(this);
}

class PoisonStatusesDaoManager {
  final _$PoisonStatusesDaoMixin _db;
  PoisonStatusesDaoManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db.attachedDatabase, _db.games);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db.attachedDatabase, _db.players);
  $$PoisonStatusesTableTableManager get poisonStatuses =>
      $$PoisonStatusesTableTableManager(
        _db.attachedDatabase,
        _db.poisonStatuses,
      );
}
