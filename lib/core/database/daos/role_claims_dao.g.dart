// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_claims_dao.dart';

// ignore_for_file: type=lint
mixin _$RoleClaimsDaoMixin on DatabaseAccessor<AppDatabase> {
  $GamesTable get games => attachedDatabase.games;
  $PlayersTable get players => attachedDatabase.players;
  $DayRecordsTable get dayRecords => attachedDatabase.dayRecords;
  $RoleClaimsTable get roleClaims => attachedDatabase.roleClaims;
  RoleClaimsDaoManager get managers => RoleClaimsDaoManager(this);
}

class RoleClaimsDaoManager {
  final _$RoleClaimsDaoMixin _db;
  RoleClaimsDaoManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db.attachedDatabase, _db.games);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db.attachedDatabase, _db.players);
  $$DayRecordsTableTableManager get dayRecords =>
      $$DayRecordsTableTableManager(_db.attachedDatabase, _db.dayRecords);
  $$RoleClaimsTableTableManager get roleClaims =>
      $$RoleClaimsTableTableManager(_db.attachedDatabase, _db.roleClaims);
}
