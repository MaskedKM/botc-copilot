// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trust_logs_dao.dart';

// ignore_for_file: type=lint
mixin _$TrustLogsDaoMixin on DatabaseAccessor<AppDatabase> {
  $GamesTable get games => attachedDatabase.games;
  $PlayersTable get players => attachedDatabase.players;
  $TrustLogsTable get trustLogs => attachedDatabase.trustLogs;
  TrustLogsDaoManager get managers => TrustLogsDaoManager(this);
}

class TrustLogsDaoManager {
  final _$TrustLogsDaoMixin _db;
  TrustLogsDaoManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db.attachedDatabase, _db.games);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db.attachedDatabase, _db.players);
  $$TrustLogsTableTableManager get trustLogs =>
      $$TrustLogsTableTableManager(_db.attachedDatabase, _db.trustLogs);
}
