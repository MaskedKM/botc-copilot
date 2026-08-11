import 'package:botc_copilot/core/constants/character.dart';
import 'package:botc_copilot/core/constants/script.dart';
import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/player_detail/data/behavior_note_repository.dart';
import 'package:botc_copilot/feature/setup/data/setup_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late BehaviorNoteRepository repo;
  late int gameId;
  late List<Player> players;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BehaviorNoteRepository(db);
    gameId = await SetupRepository(db).createGame(
      script: Script.troubleBrewing,
      names: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      myRole: Character.empath,
    );
    players = await db.playersDao.watchByGame(gameId).first;
  });

  tearDown(() => db.close());

  test('同一玩家同一天可记录多条备注', () async {
    await repo.addNote(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 2,
      note: '投票时犹豫',
    );
    await repo.addNote(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 2,
      note: '主动带票冲 5 号',
    );
    final notes = await db.behaviorNotesDao.watchByPlayer(players[0].id).first;
    expect(notes.length, 2);
    expect(notes[0].note, '投票时犹豫');
    expect(notes[1].note, '主动带票冲 5 号');
  });

  test('备注按天隔离', () async {
    await repo.addNote(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 2,
      note: '第2天备注',
    );
    await repo.addNote(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 3,
      note: '第3天备注',
    );
    final notes = await db.behaviorNotesDao.watchByPlayer(players[0].id).first;
    expect(notes.length, 2);
    expect(notes.map((n) => n.dayNumber), [2, 3]);
  });

  test('删除备注', () async {
    final id = await repo.addNote(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 2,
      note: '待删除',
    );
    await repo.deleteNote(id);
    final notes = await db.behaviorNotesDao.watchByPlayer(players[0].id).first;
    expect(notes, isEmpty);
  });

  test('删除对局级联删除备注', () async {
    await repo.addNote(
      gameId: gameId,
      playerId: players[0].id,
      dayNumber: 2,
      note: '级联测试',
    );
    await db.gamesDao.deleteGame(gameId);
    final notes = await db.behaviorNotesDao.watchByGame(gameId).first;
    expect(notes, isEmpty);
  });
}
