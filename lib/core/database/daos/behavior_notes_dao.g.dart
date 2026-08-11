// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'behavior_notes_dao.dart';

// ignore_for_file: type=lint
mixin _$BehaviorNotesDaoMixin on DatabaseAccessor<AppDatabase> {
  $GamesTable get games => attachedDatabase.games;
  $PlayersTable get players => attachedDatabase.players;
  $BehaviorNotesTable get behaviorNotes => attachedDatabase.behaviorNotes;
  BehaviorNotesDaoManager get managers => BehaviorNotesDaoManager(this);
}

class BehaviorNotesDaoManager {
  final _$BehaviorNotesDaoMixin _db;
  BehaviorNotesDaoManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db.attachedDatabase, _db.games);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db.attachedDatabase, _db.players);
  $$BehaviorNotesTableTableManager get behaviorNotes =>
      $$BehaviorNotesTableTableManager(_db.attachedDatabase, _db.behaviorNotes);
}
