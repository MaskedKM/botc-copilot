// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GamesTable extends Games with TableInfo<$GamesTable, Game> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Script, int> script =
      GeneratedColumn<int>(
        'script',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Script>($GamesTable.$converterscript);
  static const VerificationMeta _playerCountMeta = const VerificationMeta(
    'playerCount',
  );
  @override
  late final GeneratedColumn<int> playerCount = GeneratedColumn<int>(
    'player_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GameStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<GameStatus>($GamesTable.$converterstatus);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Character?, int> myRole =
      GeneratedColumn<int>(
        'my_role',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Character?>($GamesTable.$convertermyRolen);
  static const VerificationMeta _myPlayerIdMeta = const VerificationMeta(
    'myPlayerId',
  );
  @override
  late final GeneratedColumn<int> myPlayerId = GeneratedColumn<int>(
    'my_player_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _demonBluffsJsonMeta = const VerificationMeta(
    'demonBluffsJson',
  );
  @override
  late final GeneratedColumn<String> demonBluffsJson = GeneratedColumn<String>(
    'demon_bluffs_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    script,
    playerCount,
    status,
    createdAt,
    myRole,
    myPlayerId,
    demonBluffsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'games';
  @override
  VerificationContext validateIntegrity(
    Insertable<Game> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_count')) {
      context.handle(
        _playerCountMeta,
        playerCount.isAcceptableOrUnknown(
          data['player_count']!,
          _playerCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playerCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('my_player_id')) {
      context.handle(
        _myPlayerIdMeta,
        myPlayerId.isAcceptableOrUnknown(
          data['my_player_id']!,
          _myPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('demon_bluffs_json')) {
      context.handle(
        _demonBluffsJsonMeta,
        demonBluffsJson.isAcceptableOrUnknown(
          data['demon_bluffs_json']!,
          _demonBluffsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Game map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Game(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      script: $GamesTable.$converterscript.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}script'],
        )!,
      ),
      playerCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_count'],
      )!,
      status: $GamesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      myRole: $GamesTable.$convertermyRolen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}my_role'],
        ),
      ),
      myPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}my_player_id'],
      ),
      demonBluffsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}demon_bluffs_json'],
      ),
    );
  }

  @override
  $GamesTable createAlias(String alias) {
    return $GamesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Script, int, int> $converterscript =
      const EnumIndexConverter<Script>(Script.values);
  static JsonTypeConverter2<GameStatus, String, String> $converterstatus =
      const EnumNameConverter<GameStatus>(GameStatus.values);
  static JsonTypeConverter2<Character, int, int> $convertermyRole =
      const EnumIndexConverter<Character>(Character.values);
  static JsonTypeConverter2<Character?, int?, int?> $convertermyRolen =
      JsonTypeConverter2.asNullable($convertermyRole);
}

class Game extends DataClass implements Insertable<Game> {
  /// 自增主键。
  final int id;

  /// 剧本。
  final Script script;

  /// 玩家数（5-15）。
  final int playerCount;

  /// 对局状态。
  final GameStatus status;

  /// 创建时间。
  final DateTime createdAt;

  /// 我的角色（开局设置时可能暂未确定，允许为空）。
  final Character? myRole;

  /// 我的玩家 id（哪个座位是我；首次录入我的信息时确定）。
  ///
  /// 注意：故意不用 references()——Games↔Players 互相引用会让 Drift
  /// 为打破循环而丢弃 Players.gameId 的 CASCADE 外键。
  /// 该列由应用层维护一致性。
  final int? myPlayerId;

  /// 恶魔的 3 个 Bluff 角色（JSON 数组，仅当我是恶魔时录入）。
  final String? demonBluffsJson;
  const Game({
    required this.id,
    required this.script,
    required this.playerCount,
    required this.status,
    required this.createdAt,
    this.myRole,
    this.myPlayerId,
    this.demonBluffsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['script'] = Variable<int>($GamesTable.$converterscript.toSql(script));
    }
    map['player_count'] = Variable<int>(playerCount);
    {
      map['status'] = Variable<String>(
        $GamesTable.$converterstatus.toSql(status),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || myRole != null) {
      map['my_role'] = Variable<int>(
        $GamesTable.$convertermyRolen.toSql(myRole),
      );
    }
    if (!nullToAbsent || myPlayerId != null) {
      map['my_player_id'] = Variable<int>(myPlayerId);
    }
    if (!nullToAbsent || demonBluffsJson != null) {
      map['demon_bluffs_json'] = Variable<String>(demonBluffsJson);
    }
    return map;
  }

  GamesCompanion toCompanion(bool nullToAbsent) {
    return GamesCompanion(
      id: Value(id),
      script: Value(script),
      playerCount: Value(playerCount),
      status: Value(status),
      createdAt: Value(createdAt),
      myRole: myRole == null && nullToAbsent
          ? const Value.absent()
          : Value(myRole),
      myPlayerId: myPlayerId == null && nullToAbsent
          ? const Value.absent()
          : Value(myPlayerId),
      demonBluffsJson: demonBluffsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(demonBluffsJson),
    );
  }

  factory Game.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Game(
      id: serializer.fromJson<int>(json['id']),
      script: $GamesTable.$converterscript.fromJson(
        serializer.fromJson<int>(json['script']),
      ),
      playerCount: serializer.fromJson<int>(json['playerCount']),
      status: $GamesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      myRole: $GamesTable.$convertermyRolen.fromJson(
        serializer.fromJson<int?>(json['myRole']),
      ),
      myPlayerId: serializer.fromJson<int?>(json['myPlayerId']),
      demonBluffsJson: serializer.fromJson<String?>(json['demonBluffsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'script': serializer.toJson<int>(
        $GamesTable.$converterscript.toJson(script),
      ),
      'playerCount': serializer.toJson<int>(playerCount),
      'status': serializer.toJson<String>(
        $GamesTable.$converterstatus.toJson(status),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'myRole': serializer.toJson<int?>(
        $GamesTable.$convertermyRolen.toJson(myRole),
      ),
      'myPlayerId': serializer.toJson<int?>(myPlayerId),
      'demonBluffsJson': serializer.toJson<String?>(demonBluffsJson),
    };
  }

  Game copyWith({
    int? id,
    Script? script,
    int? playerCount,
    GameStatus? status,
    DateTime? createdAt,
    Value<Character?> myRole = const Value.absent(),
    Value<int?> myPlayerId = const Value.absent(),
    Value<String?> demonBluffsJson = const Value.absent(),
  }) => Game(
    id: id ?? this.id,
    script: script ?? this.script,
    playerCount: playerCount ?? this.playerCount,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    myRole: myRole.present ? myRole.value : this.myRole,
    myPlayerId: myPlayerId.present ? myPlayerId.value : this.myPlayerId,
    demonBluffsJson: demonBluffsJson.present
        ? demonBluffsJson.value
        : this.demonBluffsJson,
  );
  Game copyWithCompanion(GamesCompanion data) {
    return Game(
      id: data.id.present ? data.id.value : this.id,
      script: data.script.present ? data.script.value : this.script,
      playerCount: data.playerCount.present
          ? data.playerCount.value
          : this.playerCount,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      myRole: data.myRole.present ? data.myRole.value : this.myRole,
      myPlayerId: data.myPlayerId.present
          ? data.myPlayerId.value
          : this.myPlayerId,
      demonBluffsJson: data.demonBluffsJson.present
          ? data.demonBluffsJson.value
          : this.demonBluffsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Game(')
          ..write('id: $id, ')
          ..write('script: $script, ')
          ..write('playerCount: $playerCount, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('myRole: $myRole, ')
          ..write('myPlayerId: $myPlayerId, ')
          ..write('demonBluffsJson: $demonBluffsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    script,
    playerCount,
    status,
    createdAt,
    myRole,
    myPlayerId,
    demonBluffsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Game &&
          other.id == this.id &&
          other.script == this.script &&
          other.playerCount == this.playerCount &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.myRole == this.myRole &&
          other.myPlayerId == this.myPlayerId &&
          other.demonBluffsJson == this.demonBluffsJson);
}

class GamesCompanion extends UpdateCompanion<Game> {
  final Value<int> id;
  final Value<Script> script;
  final Value<int> playerCount;
  final Value<GameStatus> status;
  final Value<DateTime> createdAt;
  final Value<Character?> myRole;
  final Value<int?> myPlayerId;
  final Value<String?> demonBluffsJson;
  const GamesCompanion({
    this.id = const Value.absent(),
    this.script = const Value.absent(),
    this.playerCount = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.myRole = const Value.absent(),
    this.myPlayerId = const Value.absent(),
    this.demonBluffsJson = const Value.absent(),
  });
  GamesCompanion.insert({
    this.id = const Value.absent(),
    required Script script,
    required int playerCount,
    required GameStatus status,
    required DateTime createdAt,
    this.myRole = const Value.absent(),
    this.myPlayerId = const Value.absent(),
    this.demonBluffsJson = const Value.absent(),
  }) : script = Value(script),
       playerCount = Value(playerCount),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<Game> custom({
    Expression<int>? id,
    Expression<int>? script,
    Expression<int>? playerCount,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? myRole,
    Expression<int>? myPlayerId,
    Expression<String>? demonBluffsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (script != null) 'script': script,
      if (playerCount != null) 'player_count': playerCount,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (myRole != null) 'my_role': myRole,
      if (myPlayerId != null) 'my_player_id': myPlayerId,
      if (demonBluffsJson != null) 'demon_bluffs_json': demonBluffsJson,
    });
  }

  GamesCompanion copyWith({
    Value<int>? id,
    Value<Script>? script,
    Value<int>? playerCount,
    Value<GameStatus>? status,
    Value<DateTime>? createdAt,
    Value<Character?>? myRole,
    Value<int?>? myPlayerId,
    Value<String?>? demonBluffsJson,
  }) {
    return GamesCompanion(
      id: id ?? this.id,
      script: script ?? this.script,
      playerCount: playerCount ?? this.playerCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      myRole: myRole ?? this.myRole,
      myPlayerId: myPlayerId ?? this.myPlayerId,
      demonBluffsJson: demonBluffsJson ?? this.demonBluffsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (script.present) {
      map['script'] = Variable<int>(
        $GamesTable.$converterscript.toSql(script.value),
      );
    }
    if (playerCount.present) {
      map['player_count'] = Variable<int>(playerCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $GamesTable.$converterstatus.toSql(status.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (myRole.present) {
      map['my_role'] = Variable<int>(
        $GamesTable.$convertermyRolen.toSql(myRole.value),
      );
    }
    if (myPlayerId.present) {
      map['my_player_id'] = Variable<int>(myPlayerId.value);
    }
    if (demonBluffsJson.present) {
      map['demon_bluffs_json'] = Variable<String>(demonBluffsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamesCompanion(')
          ..write('id: $id, ')
          ..write('script: $script, ')
          ..write('playerCount: $playerCount, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('myRole: $myRole, ')
          ..write('myPlayerId: $myPlayerId, ')
          ..write('demonBluffsJson: $demonBluffsJson')
          ..write(')'))
        .toString();
  }
}

class $PlayersTable extends Players with TableInfo<$PlayersTable, Player> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seatNumberMeta = const VerificationMeta(
    'seatNumber',
  );
  @override
  late final GeneratedColumn<int> seatNumber = GeneratedColumn<int>(
    'seat_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAliveMeta = const VerificationMeta(
    'isAlive',
  );
  @override
  late final GeneratedColumn<bool> isAlive = GeneratedColumn<bool>(
    'is_alive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_alive" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _deathDayMeta = const VerificationMeta(
    'deathDay',
  );
  @override
  late final GeneratedColumn<int> deathDay = GeneratedColumn<int>(
    'death_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DeathCause?, String> deathCause =
      GeneratedColumn<String>(
        'death_cause',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DeathCause?>($PlayersTable.$converterdeathCausen);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    name,
    seatNumber,
    isAlive,
    deathDay,
    deathCause,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(
    Insertable<Player> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('seat_number')) {
      context.handle(
        _seatNumberMeta,
        seatNumber.isAcceptableOrUnknown(data['seat_number']!, _seatNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_seatNumberMeta);
    }
    if (data.containsKey('is_alive')) {
      context.handle(
        _isAliveMeta,
        isAlive.isAcceptableOrUnknown(data['is_alive']!, _isAliveMeta),
      );
    }
    if (data.containsKey('death_day')) {
      context.handle(
        _deathDayMeta,
        deathDay.isAcceptableOrUnknown(data['death_day']!, _deathDayMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {gameId, seatNumber},
  ];
  @override
  Player map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Player(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      seatNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seat_number'],
      )!,
      isAlive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_alive'],
      )!,
      deathDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}death_day'],
      ),
      deathCause: $PlayersTable.$converterdeathCausen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}death_cause'],
        ),
      ),
    );
  }

  @override
  $PlayersTable createAlias(String alias) {
    return $PlayersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DeathCause, String, String> $converterdeathCause =
      const EnumNameConverter<DeathCause>(DeathCause.values);
  static JsonTypeConverter2<DeathCause?, String?, String?>
  $converterdeathCausen = JsonTypeConverter2.asNullable($converterdeathCause);
}

class Player extends DataClass implements Insertable<Player> {
  /// 自增主键。
  final int id;

  /// 所属对局。
  final int gameId;

  /// 玩家名。
  final String name;

  /// 座位号（1-N，顺时针）。
  final int seatNumber;

  /// 是否存活。
  final bool isAlive;

  /// 死亡天数（存活则为空）。
  final int? deathDay;

  /// 死亡原因（存活则为空）。
  final DeathCause? deathCause;
  const Player({
    required this.id,
    required this.gameId,
    required this.name,
    required this.seatNumber,
    required this.isAlive,
    this.deathDay,
    this.deathCause,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<int>(gameId);
    map['name'] = Variable<String>(name);
    map['seat_number'] = Variable<int>(seatNumber);
    map['is_alive'] = Variable<bool>(isAlive);
    if (!nullToAbsent || deathDay != null) {
      map['death_day'] = Variable<int>(deathDay);
    }
    if (!nullToAbsent || deathCause != null) {
      map['death_cause'] = Variable<String>(
        $PlayersTable.$converterdeathCausen.toSql(deathCause),
      );
    }
    return map;
  }

  PlayersCompanion toCompanion(bool nullToAbsent) {
    return PlayersCompanion(
      id: Value(id),
      gameId: Value(gameId),
      name: Value(name),
      seatNumber: Value(seatNumber),
      isAlive: Value(isAlive),
      deathDay: deathDay == null && nullToAbsent
          ? const Value.absent()
          : Value(deathDay),
      deathCause: deathCause == null && nullToAbsent
          ? const Value.absent()
          : Value(deathCause),
    );
  }

  factory Player.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Player(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int>(json['gameId']),
      name: serializer.fromJson<String>(json['name']),
      seatNumber: serializer.fromJson<int>(json['seatNumber']),
      isAlive: serializer.fromJson<bool>(json['isAlive']),
      deathDay: serializer.fromJson<int?>(json['deathDay']),
      deathCause: $PlayersTable.$converterdeathCausen.fromJson(
        serializer.fromJson<String?>(json['deathCause']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int>(gameId),
      'name': serializer.toJson<String>(name),
      'seatNumber': serializer.toJson<int>(seatNumber),
      'isAlive': serializer.toJson<bool>(isAlive),
      'deathDay': serializer.toJson<int?>(deathDay),
      'deathCause': serializer.toJson<String?>(
        $PlayersTable.$converterdeathCausen.toJson(deathCause),
      ),
    };
  }

  Player copyWith({
    int? id,
    int? gameId,
    String? name,
    int? seatNumber,
    bool? isAlive,
    Value<int?> deathDay = const Value.absent(),
    Value<DeathCause?> deathCause = const Value.absent(),
  }) => Player(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    name: name ?? this.name,
    seatNumber: seatNumber ?? this.seatNumber,
    isAlive: isAlive ?? this.isAlive,
    deathDay: deathDay.present ? deathDay.value : this.deathDay,
    deathCause: deathCause.present ? deathCause.value : this.deathCause,
  );
  Player copyWithCompanion(PlayersCompanion data) {
    return Player(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      name: data.name.present ? data.name.value : this.name,
      seatNumber: data.seatNumber.present
          ? data.seatNumber.value
          : this.seatNumber,
      isAlive: data.isAlive.present ? data.isAlive.value : this.isAlive,
      deathDay: data.deathDay.present ? data.deathDay.value : this.deathDay,
      deathCause: data.deathCause.present
          ? data.deathCause.value
          : this.deathCause,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Player(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('name: $name, ')
          ..write('seatNumber: $seatNumber, ')
          ..write('isAlive: $isAlive, ')
          ..write('deathDay: $deathDay, ')
          ..write('deathCause: $deathCause')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, gameId, name, seatNumber, isAlive, deathDay, deathCause);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Player &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.name == this.name &&
          other.seatNumber == this.seatNumber &&
          other.isAlive == this.isAlive &&
          other.deathDay == this.deathDay &&
          other.deathCause == this.deathCause);
}

class PlayersCompanion extends UpdateCompanion<Player> {
  final Value<int> id;
  final Value<int> gameId;
  final Value<String> name;
  final Value<int> seatNumber;
  final Value<bool> isAlive;
  final Value<int?> deathDay;
  final Value<DeathCause?> deathCause;
  const PlayersCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.name = const Value.absent(),
    this.seatNumber = const Value.absent(),
    this.isAlive = const Value.absent(),
    this.deathDay = const Value.absent(),
    this.deathCause = const Value.absent(),
  });
  PlayersCompanion.insert({
    this.id = const Value.absent(),
    required int gameId,
    required String name,
    required int seatNumber,
    this.isAlive = const Value.absent(),
    this.deathDay = const Value.absent(),
    this.deathCause = const Value.absent(),
  }) : gameId = Value(gameId),
       name = Value(name),
       seatNumber = Value(seatNumber);
  static Insertable<Player> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<String>? name,
    Expression<int>? seatNumber,
    Expression<bool>? isAlive,
    Expression<int>? deathDay,
    Expression<String>? deathCause,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (name != null) 'name': name,
      if (seatNumber != null) 'seat_number': seatNumber,
      if (isAlive != null) 'is_alive': isAlive,
      if (deathDay != null) 'death_day': deathDay,
      if (deathCause != null) 'death_cause': deathCause,
    });
  }

  PlayersCompanion copyWith({
    Value<int>? id,
    Value<int>? gameId,
    Value<String>? name,
    Value<int>? seatNumber,
    Value<bool>? isAlive,
    Value<int?>? deathDay,
    Value<DeathCause?>? deathCause,
  }) {
    return PlayersCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      name: name ?? this.name,
      seatNumber: seatNumber ?? this.seatNumber,
      isAlive: isAlive ?? this.isAlive,
      deathDay: deathDay ?? this.deathDay,
      deathCause: deathCause ?? this.deathCause,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (seatNumber.present) {
      map['seat_number'] = Variable<int>(seatNumber.value);
    }
    if (isAlive.present) {
      map['is_alive'] = Variable<bool>(isAlive.value);
    }
    if (deathDay.present) {
      map['death_day'] = Variable<int>(deathDay.value);
    }
    if (deathCause.present) {
      map['death_cause'] = Variable<String>(
        $PlayersTable.$converterdeathCausen.toSql(deathCause.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('name: $name, ')
          ..write('seatNumber: $seatNumber, ')
          ..write('isAlive: $isAlive, ')
          ..write('deathDay: $deathDay, ')
          ..write('deathCause: $deathCause')
          ..write(')'))
        .toString();
  }
}

class $DayRecordsTable extends DayRecords
    with TableInfo<$DayRecordsTable, DayRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dayNumberMeta = const VerificationMeta(
    'dayNumber',
  );
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
    'day_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nightDeathPlayerIdMeta =
      const VerificationMeta('nightDeathPlayerId');
  @override
  late final GeneratedColumn<int> nightDeathPlayerId = GeneratedColumn<int>(
    'night_death_player_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id)',
    ),
  );
  static const VerificationMeta _dayExecutionPlayerIdMeta =
      const VerificationMeta('dayExecutionPlayerId');
  @override
  late final GeneratedColumn<int> dayExecutionPlayerId = GeneratedColumn<int>(
    'day_execution_player_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Character?, int>
  undertakerResultRole = GeneratedColumn<int>(
    'undertaker_result_role',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<Character?>($DayRecordsTable.$converterundertakerResultRolen);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    dayNumber,
    nightDeathPlayerId,
    dayExecutionPlayerId,
    undertakerResultRole,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('day_number')) {
      context.handle(
        _dayNumberMeta,
        dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_dayNumberMeta);
    }
    if (data.containsKey('night_death_player_id')) {
      context.handle(
        _nightDeathPlayerIdMeta,
        nightDeathPlayerId.isAcceptableOrUnknown(
          data['night_death_player_id']!,
          _nightDeathPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('day_execution_player_id')) {
      context.handle(
        _dayExecutionPlayerIdMeta,
        dayExecutionPlayerId.isAcceptableOrUnknown(
          data['day_execution_player_id']!,
          _dayExecutionPlayerIdMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {gameId, dayNumber},
  ];
  @override
  DayRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      dayNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_number'],
      )!,
      nightDeathPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}night_death_player_id'],
      ),
      dayExecutionPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_execution_player_id'],
      ),
      undertakerResultRole: $DayRecordsTable.$converterundertakerResultRolen
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.int,
              data['${effectivePrefix}undertaker_result_role'],
            ),
          ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  $DayRecordsTable createAlias(String alias) {
    return $DayRecordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Character, int, int>
  $converterundertakerResultRole = const EnumIndexConverter<Character>(
    Character.values,
  );
  static JsonTypeConverter2<Character?, int?, int?>
  $converterundertakerResultRolen = JsonTypeConverter2.asNullable(
    $converterundertakerResultRole,
  );
}

class DayRecord extends DataClass implements Insertable<DayRecord> {
  /// 自增主键。
  final int id;

  /// 所属对局。
  final int gameId;

  /// 天数（从 1 开始）。
  final int dayNumber;

  /// 夜晚死亡玩家（无人死亡为空；TB 单杀，多杀剧本后续扩展）。
  final int? nightDeathPlayerId;

  /// 白天被处决玩家（无处决为空）。
  final int? dayExecutionPlayerId;

  /// 掘墓人报出的被处决者角色。
  final Character? undertakerResultRole;

  /// 当日备注。
  final String notes;
  const DayRecord({
    required this.id,
    required this.gameId,
    required this.dayNumber,
    this.nightDeathPlayerId,
    this.dayExecutionPlayerId,
    this.undertakerResultRole,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<int>(gameId);
    map['day_number'] = Variable<int>(dayNumber);
    if (!nullToAbsent || nightDeathPlayerId != null) {
      map['night_death_player_id'] = Variable<int>(nightDeathPlayerId);
    }
    if (!nullToAbsent || dayExecutionPlayerId != null) {
      map['day_execution_player_id'] = Variable<int>(dayExecutionPlayerId);
    }
    if (!nullToAbsent || undertakerResultRole != null) {
      map['undertaker_result_role'] = Variable<int>(
        $DayRecordsTable.$converterundertakerResultRolen.toSql(
          undertakerResultRole,
        ),
      );
    }
    map['notes'] = Variable<String>(notes);
    return map;
  }

  DayRecordsCompanion toCompanion(bool nullToAbsent) {
    return DayRecordsCompanion(
      id: Value(id),
      gameId: Value(gameId),
      dayNumber: Value(dayNumber),
      nightDeathPlayerId: nightDeathPlayerId == null && nullToAbsent
          ? const Value.absent()
          : Value(nightDeathPlayerId),
      dayExecutionPlayerId: dayExecutionPlayerId == null && nullToAbsent
          ? const Value.absent()
          : Value(dayExecutionPlayerId),
      undertakerResultRole: undertakerResultRole == null && nullToAbsent
          ? const Value.absent()
          : Value(undertakerResultRole),
      notes: Value(notes),
    );
  }

  factory DayRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayRecord(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int>(json['gameId']),
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      nightDeathPlayerId: serializer.fromJson<int?>(json['nightDeathPlayerId']),
      dayExecutionPlayerId: serializer.fromJson<int?>(
        json['dayExecutionPlayerId'],
      ),
      undertakerResultRole: $DayRecordsTable.$converterundertakerResultRolen
          .fromJson(serializer.fromJson<int?>(json['undertakerResultRole'])),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int>(gameId),
      'dayNumber': serializer.toJson<int>(dayNumber),
      'nightDeathPlayerId': serializer.toJson<int?>(nightDeathPlayerId),
      'dayExecutionPlayerId': serializer.toJson<int?>(dayExecutionPlayerId),
      'undertakerResultRole': serializer.toJson<int?>(
        $DayRecordsTable.$converterundertakerResultRolen.toJson(
          undertakerResultRole,
        ),
      ),
      'notes': serializer.toJson<String>(notes),
    };
  }

  DayRecord copyWith({
    int? id,
    int? gameId,
    int? dayNumber,
    Value<int?> nightDeathPlayerId = const Value.absent(),
    Value<int?> dayExecutionPlayerId = const Value.absent(),
    Value<Character?> undertakerResultRole = const Value.absent(),
    String? notes,
  }) => DayRecord(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    dayNumber: dayNumber ?? this.dayNumber,
    nightDeathPlayerId: nightDeathPlayerId.present
        ? nightDeathPlayerId.value
        : this.nightDeathPlayerId,
    dayExecutionPlayerId: dayExecutionPlayerId.present
        ? dayExecutionPlayerId.value
        : this.dayExecutionPlayerId,
    undertakerResultRole: undertakerResultRole.present
        ? undertakerResultRole.value
        : this.undertakerResultRole,
    notes: notes ?? this.notes,
  );
  DayRecord copyWithCompanion(DayRecordsCompanion data) {
    return DayRecord(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      nightDeathPlayerId: data.nightDeathPlayerId.present
          ? data.nightDeathPlayerId.value
          : this.nightDeathPlayerId,
      dayExecutionPlayerId: data.dayExecutionPlayerId.present
          ? data.dayExecutionPlayerId.value
          : this.dayExecutionPlayerId,
      undertakerResultRole: data.undertakerResultRole.present
          ? data.undertakerResultRole.value
          : this.undertakerResultRole,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayRecord(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('nightDeathPlayerId: $nightDeathPlayerId, ')
          ..write('dayExecutionPlayerId: $dayExecutionPlayerId, ')
          ..write('undertakerResultRole: $undertakerResultRole, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gameId,
    dayNumber,
    nightDeathPlayerId,
    dayExecutionPlayerId,
    undertakerResultRole,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayRecord &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.dayNumber == this.dayNumber &&
          other.nightDeathPlayerId == this.nightDeathPlayerId &&
          other.dayExecutionPlayerId == this.dayExecutionPlayerId &&
          other.undertakerResultRole == this.undertakerResultRole &&
          other.notes == this.notes);
}

class DayRecordsCompanion extends UpdateCompanion<DayRecord> {
  final Value<int> id;
  final Value<int> gameId;
  final Value<int> dayNumber;
  final Value<int?> nightDeathPlayerId;
  final Value<int?> dayExecutionPlayerId;
  final Value<Character?> undertakerResultRole;
  final Value<String> notes;
  const DayRecordsCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.dayNumber = const Value.absent(),
    this.nightDeathPlayerId = const Value.absent(),
    this.dayExecutionPlayerId = const Value.absent(),
    this.undertakerResultRole = const Value.absent(),
    this.notes = const Value.absent(),
  });
  DayRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int gameId,
    required int dayNumber,
    this.nightDeathPlayerId = const Value.absent(),
    this.dayExecutionPlayerId = const Value.absent(),
    this.undertakerResultRole = const Value.absent(),
    this.notes = const Value.absent(),
  }) : gameId = Value(gameId),
       dayNumber = Value(dayNumber);
  static Insertable<DayRecord> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<int>? dayNumber,
    Expression<int>? nightDeathPlayerId,
    Expression<int>? dayExecutionPlayerId,
    Expression<int>? undertakerResultRole,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (dayNumber != null) 'day_number': dayNumber,
      if (nightDeathPlayerId != null)
        'night_death_player_id': nightDeathPlayerId,
      if (dayExecutionPlayerId != null)
        'day_execution_player_id': dayExecutionPlayerId,
      if (undertakerResultRole != null)
        'undertaker_result_role': undertakerResultRole,
      if (notes != null) 'notes': notes,
    });
  }

  DayRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? gameId,
    Value<int>? dayNumber,
    Value<int?>? nightDeathPlayerId,
    Value<int?>? dayExecutionPlayerId,
    Value<Character?>? undertakerResultRole,
    Value<String>? notes,
  }) {
    return DayRecordsCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      dayNumber: dayNumber ?? this.dayNumber,
      nightDeathPlayerId: nightDeathPlayerId ?? this.nightDeathPlayerId,
      dayExecutionPlayerId: dayExecutionPlayerId ?? this.dayExecutionPlayerId,
      undertakerResultRole: undertakerResultRole ?? this.undertakerResultRole,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (nightDeathPlayerId.present) {
      map['night_death_player_id'] = Variable<int>(nightDeathPlayerId.value);
    }
    if (dayExecutionPlayerId.present) {
      map['day_execution_player_id'] = Variable<int>(
        dayExecutionPlayerId.value,
      );
    }
    if (undertakerResultRole.present) {
      map['undertaker_result_role'] = Variable<int>(
        $DayRecordsTable.$converterundertakerResultRolen.toSql(
          undertakerResultRole.value,
        ),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayRecordsCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('nightDeathPlayerId: $nightDeathPlayerId, ')
          ..write('dayExecutionPlayerId: $dayExecutionPlayerId, ')
          ..write('undertakerResultRole: $undertakerResultRole, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $RoleClaimsTable extends RoleClaims
    with TableInfo<$RoleClaimsTable, RoleClaim> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoleClaimsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dayRecordIdMeta = const VerificationMeta(
    'dayRecordId',
  );
  @override
  late final GeneratedColumn<int> dayRecordId = GeneratedColumn<int>(
    'day_record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES day_records (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Character, int> character =
      GeneratedColumn<int>(
        'character',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Character>($RoleClaimsTable.$convertercharacter);
  @override
  late final GeneratedColumnWithTypeConverter<ClaimType, String> claimType =
      GeneratedColumn<String>(
        'claim_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ClaimType>($RoleClaimsTable.$converterclaimType);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playerId,
    dayRecordId,
    character,
    claimType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'role_claims';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoleClaim> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('day_record_id')) {
      context.handle(
        _dayRecordIdMeta,
        dayRecordId.isAcceptableOrUnknown(
          data['day_record_id']!,
          _dayRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dayRecordIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoleClaim map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoleClaim(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      dayRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_record_id'],
      )!,
      character: $RoleClaimsTable.$convertercharacter.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}character'],
        )!,
      ),
      claimType: $RoleClaimsTable.$converterclaimType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}claim_type'],
        )!,
      ),
    );
  }

  @override
  $RoleClaimsTable createAlias(String alias) {
    return $RoleClaimsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Character, int, int> $convertercharacter =
      const EnumIndexConverter<Character>(Character.values);
  static JsonTypeConverter2<ClaimType, String, String> $converterclaimType =
      const EnumNameConverter<ClaimType>(ClaimType.values);
}

class RoleClaim extends DataClass implements Insertable<RoleClaim> {
  /// 自增主键。
  final int id;

  /// 声明者。
  final int playerId;

  /// 声明发生的当天。
  final int dayRecordId;

  /// 声明的角色。
  final Character character;

  /// 声明类型（首次/改口/死亡揭示）。
  final ClaimType claimType;
  const RoleClaim({
    required this.id,
    required this.playerId,
    required this.dayRecordId,
    required this.character,
    required this.claimType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<int>(playerId);
    map['day_record_id'] = Variable<int>(dayRecordId);
    {
      map['character'] = Variable<int>(
        $RoleClaimsTable.$convertercharacter.toSql(character),
      );
    }
    {
      map['claim_type'] = Variable<String>(
        $RoleClaimsTable.$converterclaimType.toSql(claimType),
      );
    }
    return map;
  }

  RoleClaimsCompanion toCompanion(bool nullToAbsent) {
    return RoleClaimsCompanion(
      id: Value(id),
      playerId: Value(playerId),
      dayRecordId: Value(dayRecordId),
      character: Value(character),
      claimType: Value(claimType),
    );
  }

  factory RoleClaim.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoleClaim(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<int>(json['playerId']),
      dayRecordId: serializer.fromJson<int>(json['dayRecordId']),
      character: $RoleClaimsTable.$convertercharacter.fromJson(
        serializer.fromJson<int>(json['character']),
      ),
      claimType: $RoleClaimsTable.$converterclaimType.fromJson(
        serializer.fromJson<String>(json['claimType']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<int>(playerId),
      'dayRecordId': serializer.toJson<int>(dayRecordId),
      'character': serializer.toJson<int>(
        $RoleClaimsTable.$convertercharacter.toJson(character),
      ),
      'claimType': serializer.toJson<String>(
        $RoleClaimsTable.$converterclaimType.toJson(claimType),
      ),
    };
  }

  RoleClaim copyWith({
    int? id,
    int? playerId,
    int? dayRecordId,
    Character? character,
    ClaimType? claimType,
  }) => RoleClaim(
    id: id ?? this.id,
    playerId: playerId ?? this.playerId,
    dayRecordId: dayRecordId ?? this.dayRecordId,
    character: character ?? this.character,
    claimType: claimType ?? this.claimType,
  );
  RoleClaim copyWithCompanion(RoleClaimsCompanion data) {
    return RoleClaim(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      dayRecordId: data.dayRecordId.present
          ? data.dayRecordId.value
          : this.dayRecordId,
      character: data.character.present ? data.character.value : this.character,
      claimType: data.claimType.present ? data.claimType.value : this.claimType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoleClaim(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('dayRecordId: $dayRecordId, ')
          ..write('character: $character, ')
          ..write('claimType: $claimType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, playerId, dayRecordId, character, claimType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoleClaim &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.dayRecordId == this.dayRecordId &&
          other.character == this.character &&
          other.claimType == this.claimType);
}

class RoleClaimsCompanion extends UpdateCompanion<RoleClaim> {
  final Value<int> id;
  final Value<int> playerId;
  final Value<int> dayRecordId;
  final Value<Character> character;
  final Value<ClaimType> claimType;
  const RoleClaimsCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.dayRecordId = const Value.absent(),
    this.character = const Value.absent(),
    this.claimType = const Value.absent(),
  });
  RoleClaimsCompanion.insert({
    this.id = const Value.absent(),
    required int playerId,
    required int dayRecordId,
    required Character character,
    required ClaimType claimType,
  }) : playerId = Value(playerId),
       dayRecordId = Value(dayRecordId),
       character = Value(character),
       claimType = Value(claimType);
  static Insertable<RoleClaim> custom({
    Expression<int>? id,
    Expression<int>? playerId,
    Expression<int>? dayRecordId,
    Expression<int>? character,
    Expression<String>? claimType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (dayRecordId != null) 'day_record_id': dayRecordId,
      if (character != null) 'character': character,
      if (claimType != null) 'claim_type': claimType,
    });
  }

  RoleClaimsCompanion copyWith({
    Value<int>? id,
    Value<int>? playerId,
    Value<int>? dayRecordId,
    Value<Character>? character,
    Value<ClaimType>? claimType,
  }) {
    return RoleClaimsCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      dayRecordId: dayRecordId ?? this.dayRecordId,
      character: character ?? this.character,
      claimType: claimType ?? this.claimType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (dayRecordId.present) {
      map['day_record_id'] = Variable<int>(dayRecordId.value);
    }
    if (character.present) {
      map['character'] = Variable<int>(
        $RoleClaimsTable.$convertercharacter.toSql(character.value),
      );
    }
    if (claimType.present) {
      map['claim_type'] = Variable<String>(
        $RoleClaimsTable.$converterclaimType.toSql(claimType.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoleClaimsCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('dayRecordId: $dayRecordId, ')
          ..write('character: $character, ')
          ..write('claimType: $claimType')
          ..write(')'))
        .toString();
  }
}

class $InfoDeclarationsTable extends InfoDeclarations
    with TableInfo<$InfoDeclarationsTable, InfoDeclaration> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InfoDeclarationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dayRecordIdMeta = const VerificationMeta(
    'dayRecordId',
  );
  @override
  late final GeneratedColumn<int> dayRecordId = GeneratedColumn<int>(
    'day_record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES day_records (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Character, int> characterType =
      GeneratedColumn<int>(
        'character_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Character>(
        $InfoDeclarationsTable.$convertercharacterType,
      );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Reliability, String> reliability =
      GeneratedColumn<String>(
        'reliability',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Reliability>(
        $InfoDeclarationsTable.$converterreliability,
      );
  static const VerificationMeta _isMineMeta = const VerificationMeta('isMine');
  @override
  late final GeneratedColumn<bool> isMine = GeneratedColumn<bool>(
    'is_mine',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_mine" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playerId,
    dayRecordId,
    characterType,
    payloadJson,
    reliability,
    isMine,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'info_declarations';
  @override
  VerificationContext validateIntegrity(
    Insertable<InfoDeclaration> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('day_record_id')) {
      context.handle(
        _dayRecordIdMeta,
        dayRecordId.isAcceptableOrUnknown(
          data['day_record_id']!,
          _dayRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dayRecordIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('is_mine')) {
      context.handle(
        _isMineMeta,
        isMine.isAcceptableOrUnknown(data['is_mine']!, _isMineMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InfoDeclaration map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InfoDeclaration(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      dayRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_record_id'],
      )!,
      characterType: $InfoDeclarationsTable.$convertercharacterType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}character_type'],
        )!,
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      reliability: $InfoDeclarationsTable.$converterreliability.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reliability'],
        )!,
      ),
      isMine: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_mine'],
      )!,
    );
  }

  @override
  $InfoDeclarationsTable createAlias(String alias) {
    return $InfoDeclarationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Character, int, int> $convertercharacterType =
      const EnumIndexConverter<Character>(Character.values);
  static JsonTypeConverter2<Reliability, String, String> $converterreliability =
      const EnumNameConverter<Reliability>(Reliability.values);
}

class InfoDeclaration extends DataClass implements Insertable<InfoDeclaration> {
  /// 自增主键。
  final int id;

  /// 信息提供者。
  final int playerId;

  /// 信息报出的当天。
  final int dayRecordId;

  /// 信息来源角色（决定 payload 结构）。
  final Character characterType;

  /// 结构化信息内容（JSON，格式由角色的 InfoInputType 决定）。
  final String payloadJson;

  /// 信息可靠性（醉/毒追踪）。
  final Reliability reliability;

  /// 是否为我的信息（false = 他人公开声明）。
  final bool isMine;
  const InfoDeclaration({
    required this.id,
    required this.playerId,
    required this.dayRecordId,
    required this.characterType,
    required this.payloadJson,
    required this.reliability,
    required this.isMine,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<int>(playerId);
    map['day_record_id'] = Variable<int>(dayRecordId);
    {
      map['character_type'] = Variable<int>(
        $InfoDeclarationsTable.$convertercharacterType.toSql(characterType),
      );
    }
    map['payload_json'] = Variable<String>(payloadJson);
    {
      map['reliability'] = Variable<String>(
        $InfoDeclarationsTable.$converterreliability.toSql(reliability),
      );
    }
    map['is_mine'] = Variable<bool>(isMine);
    return map;
  }

  InfoDeclarationsCompanion toCompanion(bool nullToAbsent) {
    return InfoDeclarationsCompanion(
      id: Value(id),
      playerId: Value(playerId),
      dayRecordId: Value(dayRecordId),
      characterType: Value(characterType),
      payloadJson: Value(payloadJson),
      reliability: Value(reliability),
      isMine: Value(isMine),
    );
  }

  factory InfoDeclaration.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InfoDeclaration(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<int>(json['playerId']),
      dayRecordId: serializer.fromJson<int>(json['dayRecordId']),
      characterType: $InfoDeclarationsTable.$convertercharacterType.fromJson(
        serializer.fromJson<int>(json['characterType']),
      ),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      reliability: $InfoDeclarationsTable.$converterreliability.fromJson(
        serializer.fromJson<String>(json['reliability']),
      ),
      isMine: serializer.fromJson<bool>(json['isMine']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<int>(playerId),
      'dayRecordId': serializer.toJson<int>(dayRecordId),
      'characterType': serializer.toJson<int>(
        $InfoDeclarationsTable.$convertercharacterType.toJson(characterType),
      ),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'reliability': serializer.toJson<String>(
        $InfoDeclarationsTable.$converterreliability.toJson(reliability),
      ),
      'isMine': serializer.toJson<bool>(isMine),
    };
  }

  InfoDeclaration copyWith({
    int? id,
    int? playerId,
    int? dayRecordId,
    Character? characterType,
    String? payloadJson,
    Reliability? reliability,
    bool? isMine,
  }) => InfoDeclaration(
    id: id ?? this.id,
    playerId: playerId ?? this.playerId,
    dayRecordId: dayRecordId ?? this.dayRecordId,
    characterType: characterType ?? this.characterType,
    payloadJson: payloadJson ?? this.payloadJson,
    reliability: reliability ?? this.reliability,
    isMine: isMine ?? this.isMine,
  );
  InfoDeclaration copyWithCompanion(InfoDeclarationsCompanion data) {
    return InfoDeclaration(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      dayRecordId: data.dayRecordId.present
          ? data.dayRecordId.value
          : this.dayRecordId,
      characterType: data.characterType.present
          ? data.characterType.value
          : this.characterType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      reliability: data.reliability.present
          ? data.reliability.value
          : this.reliability,
      isMine: data.isMine.present ? data.isMine.value : this.isMine,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InfoDeclaration(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('dayRecordId: $dayRecordId, ')
          ..write('characterType: $characterType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('reliability: $reliability, ')
          ..write('isMine: $isMine')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    playerId,
    dayRecordId,
    characterType,
    payloadJson,
    reliability,
    isMine,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InfoDeclaration &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.dayRecordId == this.dayRecordId &&
          other.characterType == this.characterType &&
          other.payloadJson == this.payloadJson &&
          other.reliability == this.reliability &&
          other.isMine == this.isMine);
}

class InfoDeclarationsCompanion extends UpdateCompanion<InfoDeclaration> {
  final Value<int> id;
  final Value<int> playerId;
  final Value<int> dayRecordId;
  final Value<Character> characterType;
  final Value<String> payloadJson;
  final Value<Reliability> reliability;
  final Value<bool> isMine;
  const InfoDeclarationsCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.dayRecordId = const Value.absent(),
    this.characterType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.reliability = const Value.absent(),
    this.isMine = const Value.absent(),
  });
  InfoDeclarationsCompanion.insert({
    this.id = const Value.absent(),
    required int playerId,
    required int dayRecordId,
    required Character characterType,
    required String payloadJson,
    required Reliability reliability,
    this.isMine = const Value.absent(),
  }) : playerId = Value(playerId),
       dayRecordId = Value(dayRecordId),
       characterType = Value(characterType),
       payloadJson = Value(payloadJson),
       reliability = Value(reliability);
  static Insertable<InfoDeclaration> custom({
    Expression<int>? id,
    Expression<int>? playerId,
    Expression<int>? dayRecordId,
    Expression<int>? characterType,
    Expression<String>? payloadJson,
    Expression<String>? reliability,
    Expression<bool>? isMine,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (dayRecordId != null) 'day_record_id': dayRecordId,
      if (characterType != null) 'character_type': characterType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (reliability != null) 'reliability': reliability,
      if (isMine != null) 'is_mine': isMine,
    });
  }

  InfoDeclarationsCompanion copyWith({
    Value<int>? id,
    Value<int>? playerId,
    Value<int>? dayRecordId,
    Value<Character>? characterType,
    Value<String>? payloadJson,
    Value<Reliability>? reliability,
    Value<bool>? isMine,
  }) {
    return InfoDeclarationsCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      dayRecordId: dayRecordId ?? this.dayRecordId,
      characterType: characterType ?? this.characterType,
      payloadJson: payloadJson ?? this.payloadJson,
      reliability: reliability ?? this.reliability,
      isMine: isMine ?? this.isMine,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (dayRecordId.present) {
      map['day_record_id'] = Variable<int>(dayRecordId.value);
    }
    if (characterType.present) {
      map['character_type'] = Variable<int>(
        $InfoDeclarationsTable.$convertercharacterType.toSql(
          characterType.value,
        ),
      );
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (reliability.present) {
      map['reliability'] = Variable<String>(
        $InfoDeclarationsTable.$converterreliability.toSql(reliability.value),
      );
    }
    if (isMine.present) {
      map['is_mine'] = Variable<bool>(isMine.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InfoDeclarationsCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('dayRecordId: $dayRecordId, ')
          ..write('characterType: $characterType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('reliability: $reliability, ')
          ..write('isMine: $isMine')
          ..write(')'))
        .toString();
  }
}

class $TrustLogsTable extends TrustLogs
    with TableInfo<$TrustLogsTable, TrustLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrustLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dayNumberMeta = const VerificationMeta(
    'dayNumber',
  );
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
    'day_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TrustLevel, String> trustLevel =
      GeneratedColumn<String>(
        'trust_level',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TrustLevel>($TrustLogsTable.$convertertrustLevel);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    playerId,
    dayNumber,
    trustLevel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trust_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrustLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('day_number')) {
      context.handle(
        _dayNumberMeta,
        dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_dayNumberMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrustLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrustLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      dayNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_number'],
      )!,
      trustLevel: $TrustLogsTable.$convertertrustLevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}trust_level'],
        )!,
      ),
    );
  }

  @override
  $TrustLogsTable createAlias(String alias) {
    return $TrustLogsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TrustLevel, String, String> $convertertrustLevel =
      const EnumNameConverter<TrustLevel>(TrustLevel.values);
}

class TrustLog extends DataClass implements Insertable<TrustLog> {
  /// 自增主键。
  final int id;

  /// 所属对局。
  final int gameId;

  /// 目标玩家。
  final int playerId;

  /// 天数。
  final int dayNumber;

  /// 信任度等级。
  final TrustLevel trustLevel;
  const TrustLog({
    required this.id,
    required this.gameId,
    required this.playerId,
    required this.dayNumber,
    required this.trustLevel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<int>(gameId);
    map['player_id'] = Variable<int>(playerId);
    map['day_number'] = Variable<int>(dayNumber);
    {
      map['trust_level'] = Variable<String>(
        $TrustLogsTable.$convertertrustLevel.toSql(trustLevel),
      );
    }
    return map;
  }

  TrustLogsCompanion toCompanion(bool nullToAbsent) {
    return TrustLogsCompanion(
      id: Value(id),
      gameId: Value(gameId),
      playerId: Value(playerId),
      dayNumber: Value(dayNumber),
      trustLevel: Value(trustLevel),
    );
  }

  factory TrustLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrustLog(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int>(json['gameId']),
      playerId: serializer.fromJson<int>(json['playerId']),
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      trustLevel: $TrustLogsTable.$convertertrustLevel.fromJson(
        serializer.fromJson<String>(json['trustLevel']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int>(gameId),
      'playerId': serializer.toJson<int>(playerId),
      'dayNumber': serializer.toJson<int>(dayNumber),
      'trustLevel': serializer.toJson<String>(
        $TrustLogsTable.$convertertrustLevel.toJson(trustLevel),
      ),
    };
  }

  TrustLog copyWith({
    int? id,
    int? gameId,
    int? playerId,
    int? dayNumber,
    TrustLevel? trustLevel,
  }) => TrustLog(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    playerId: playerId ?? this.playerId,
    dayNumber: dayNumber ?? this.dayNumber,
    trustLevel: trustLevel ?? this.trustLevel,
  );
  TrustLog copyWithCompanion(TrustLogsCompanion data) {
    return TrustLog(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      trustLevel: data.trustLevel.present
          ? data.trustLevel.value
          : this.trustLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrustLog(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('playerId: $playerId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('trustLevel: $trustLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, gameId, playerId, dayNumber, trustLevel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrustLog &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.playerId == this.playerId &&
          other.dayNumber == this.dayNumber &&
          other.trustLevel == this.trustLevel);
}

class TrustLogsCompanion extends UpdateCompanion<TrustLog> {
  final Value<int> id;
  final Value<int> gameId;
  final Value<int> playerId;
  final Value<int> dayNumber;
  final Value<TrustLevel> trustLevel;
  const TrustLogsCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.dayNumber = const Value.absent(),
    this.trustLevel = const Value.absent(),
  });
  TrustLogsCompanion.insert({
    this.id = const Value.absent(),
    required int gameId,
    required int playerId,
    required int dayNumber,
    required TrustLevel trustLevel,
  }) : gameId = Value(gameId),
       playerId = Value(playerId),
       dayNumber = Value(dayNumber),
       trustLevel = Value(trustLevel);
  static Insertable<TrustLog> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<int>? playerId,
    Expression<int>? dayNumber,
    Expression<String>? trustLevel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (playerId != null) 'player_id': playerId,
      if (dayNumber != null) 'day_number': dayNumber,
      if (trustLevel != null) 'trust_level': trustLevel,
    });
  }

  TrustLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? gameId,
    Value<int>? playerId,
    Value<int>? dayNumber,
    Value<TrustLevel>? trustLevel,
  }) {
    return TrustLogsCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      playerId: playerId ?? this.playerId,
      dayNumber: dayNumber ?? this.dayNumber,
      trustLevel: trustLevel ?? this.trustLevel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (trustLevel.present) {
      map['trust_level'] = Variable<String>(
        $TrustLogsTable.$convertertrustLevel.toSql(trustLevel.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrustLogsCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('playerId: $playerId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('trustLevel: $trustLevel')
          ..write(')'))
        .toString();
  }
}

class $NominationsTable extends Nominations
    with TableInfo<$NominationsTable, Nomination> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NominationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dayRecordIdMeta = const VerificationMeta(
    'dayRecordId',
  );
  @override
  late final GeneratedColumn<int> dayRecordId = GeneratedColumn<int>(
    'day_record_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES day_records (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nominatorPlayerIdMeta = const VerificationMeta(
    'nominatorPlayerId',
  );
  @override
  late final GeneratedColumn<int> nominatorPlayerId = GeneratedColumn<int>(
    'nominator_player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id)',
    ),
  );
  static const VerificationMeta _nomineePlayerIdMeta = const VerificationMeta(
    'nomineePlayerId',
  );
  @override
  late final GeneratedColumn<int> nomineePlayerId = GeneratedColumn<int>(
    'nominee_player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id)',
    ),
  );
  static const VerificationMeta _passedMeta = const VerificationMeta('passed');
  @override
  late final GeneratedColumn<bool> passed = GeneratedColumn<bool>(
    'passed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("passed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _voteResultJsonMeta = const VerificationMeta(
    'voteResultJson',
  );
  @override
  late final GeneratedColumn<String> voteResultJson = GeneratedColumn<String>(
    'vote_result_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    dayRecordId,
    nominatorPlayerId,
    nomineePlayerId,
    passed,
    voteResultJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nominations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Nomination> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('day_record_id')) {
      context.handle(
        _dayRecordIdMeta,
        dayRecordId.isAcceptableOrUnknown(
          data['day_record_id']!,
          _dayRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dayRecordIdMeta);
    }
    if (data.containsKey('nominator_player_id')) {
      context.handle(
        _nominatorPlayerIdMeta,
        nominatorPlayerId.isAcceptableOrUnknown(
          data['nominator_player_id']!,
          _nominatorPlayerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nominatorPlayerIdMeta);
    }
    if (data.containsKey('nominee_player_id')) {
      context.handle(
        _nomineePlayerIdMeta,
        nomineePlayerId.isAcceptableOrUnknown(
          data['nominee_player_id']!,
          _nomineePlayerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nomineePlayerIdMeta);
    }
    if (data.containsKey('passed')) {
      context.handle(
        _passedMeta,
        passed.isAcceptableOrUnknown(data['passed']!, _passedMeta),
      );
    } else if (isInserting) {
      context.missing(_passedMeta);
    }
    if (data.containsKey('vote_result_json')) {
      context.handle(
        _voteResultJsonMeta,
        voteResultJson.isAcceptableOrUnknown(
          data['vote_result_json']!,
          _voteResultJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_voteResultJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Nomination map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Nomination(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      dayRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_record_id'],
      )!,
      nominatorPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}nominator_player_id'],
      )!,
      nomineePlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}nominee_player_id'],
      )!,
      passed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}passed'],
      )!,
      voteResultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vote_result_json'],
      )!,
    );
  }

  @override
  $NominationsTable createAlias(String alias) {
    return $NominationsTable(attachedDatabase, alias);
  }
}

class Nomination extends DataClass implements Insertable<Nomination> {
  /// 自增主键。
  final int id;

  /// 所属对局。
  final int gameId;

  /// 提名发生的当天。
  final int dayRecordId;

  /// 提名者。
  final int nominatorPlayerId;

  /// 被提名者。
  final int nomineePlayerId;

  /// 是否达到处决阈值（赞成票 >= 存活人数一半）。
  final bool passed;

  /// 投票结果 JSON：[{playerId, vote: for/against/abstain, isDeadVote}]。
  final String voteResultJson;
  const Nomination({
    required this.id,
    required this.gameId,
    required this.dayRecordId,
    required this.nominatorPlayerId,
    required this.nomineePlayerId,
    required this.passed,
    required this.voteResultJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<int>(gameId);
    map['day_record_id'] = Variable<int>(dayRecordId);
    map['nominator_player_id'] = Variable<int>(nominatorPlayerId);
    map['nominee_player_id'] = Variable<int>(nomineePlayerId);
    map['passed'] = Variable<bool>(passed);
    map['vote_result_json'] = Variable<String>(voteResultJson);
    return map;
  }

  NominationsCompanion toCompanion(bool nullToAbsent) {
    return NominationsCompanion(
      id: Value(id),
      gameId: Value(gameId),
      dayRecordId: Value(dayRecordId),
      nominatorPlayerId: Value(nominatorPlayerId),
      nomineePlayerId: Value(nomineePlayerId),
      passed: Value(passed),
      voteResultJson: Value(voteResultJson),
    );
  }

  factory Nomination.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Nomination(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int>(json['gameId']),
      dayRecordId: serializer.fromJson<int>(json['dayRecordId']),
      nominatorPlayerId: serializer.fromJson<int>(json['nominatorPlayerId']),
      nomineePlayerId: serializer.fromJson<int>(json['nomineePlayerId']),
      passed: serializer.fromJson<bool>(json['passed']),
      voteResultJson: serializer.fromJson<String>(json['voteResultJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int>(gameId),
      'dayRecordId': serializer.toJson<int>(dayRecordId),
      'nominatorPlayerId': serializer.toJson<int>(nominatorPlayerId),
      'nomineePlayerId': serializer.toJson<int>(nomineePlayerId),
      'passed': serializer.toJson<bool>(passed),
      'voteResultJson': serializer.toJson<String>(voteResultJson),
    };
  }

  Nomination copyWith({
    int? id,
    int? gameId,
    int? dayRecordId,
    int? nominatorPlayerId,
    int? nomineePlayerId,
    bool? passed,
    String? voteResultJson,
  }) => Nomination(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    dayRecordId: dayRecordId ?? this.dayRecordId,
    nominatorPlayerId: nominatorPlayerId ?? this.nominatorPlayerId,
    nomineePlayerId: nomineePlayerId ?? this.nomineePlayerId,
    passed: passed ?? this.passed,
    voteResultJson: voteResultJson ?? this.voteResultJson,
  );
  Nomination copyWithCompanion(NominationsCompanion data) {
    return Nomination(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      dayRecordId: data.dayRecordId.present
          ? data.dayRecordId.value
          : this.dayRecordId,
      nominatorPlayerId: data.nominatorPlayerId.present
          ? data.nominatorPlayerId.value
          : this.nominatorPlayerId,
      nomineePlayerId: data.nomineePlayerId.present
          ? data.nomineePlayerId.value
          : this.nomineePlayerId,
      passed: data.passed.present ? data.passed.value : this.passed,
      voteResultJson: data.voteResultJson.present
          ? data.voteResultJson.value
          : this.voteResultJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Nomination(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('dayRecordId: $dayRecordId, ')
          ..write('nominatorPlayerId: $nominatorPlayerId, ')
          ..write('nomineePlayerId: $nomineePlayerId, ')
          ..write('passed: $passed, ')
          ..write('voteResultJson: $voteResultJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    gameId,
    dayRecordId,
    nominatorPlayerId,
    nomineePlayerId,
    passed,
    voteResultJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Nomination &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.dayRecordId == this.dayRecordId &&
          other.nominatorPlayerId == this.nominatorPlayerId &&
          other.nomineePlayerId == this.nomineePlayerId &&
          other.passed == this.passed &&
          other.voteResultJson == this.voteResultJson);
}

class NominationsCompanion extends UpdateCompanion<Nomination> {
  final Value<int> id;
  final Value<int> gameId;
  final Value<int> dayRecordId;
  final Value<int> nominatorPlayerId;
  final Value<int> nomineePlayerId;
  final Value<bool> passed;
  final Value<String> voteResultJson;
  const NominationsCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.dayRecordId = const Value.absent(),
    this.nominatorPlayerId = const Value.absent(),
    this.nomineePlayerId = const Value.absent(),
    this.passed = const Value.absent(),
    this.voteResultJson = const Value.absent(),
  });
  NominationsCompanion.insert({
    this.id = const Value.absent(),
    required int gameId,
    required int dayRecordId,
    required int nominatorPlayerId,
    required int nomineePlayerId,
    required bool passed,
    required String voteResultJson,
  }) : gameId = Value(gameId),
       dayRecordId = Value(dayRecordId),
       nominatorPlayerId = Value(nominatorPlayerId),
       nomineePlayerId = Value(nomineePlayerId),
       passed = Value(passed),
       voteResultJson = Value(voteResultJson);
  static Insertable<Nomination> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<int>? dayRecordId,
    Expression<int>? nominatorPlayerId,
    Expression<int>? nomineePlayerId,
    Expression<bool>? passed,
    Expression<String>? voteResultJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (dayRecordId != null) 'day_record_id': dayRecordId,
      if (nominatorPlayerId != null) 'nominator_player_id': nominatorPlayerId,
      if (nomineePlayerId != null) 'nominee_player_id': nomineePlayerId,
      if (passed != null) 'passed': passed,
      if (voteResultJson != null) 'vote_result_json': voteResultJson,
    });
  }

  NominationsCompanion copyWith({
    Value<int>? id,
    Value<int>? gameId,
    Value<int>? dayRecordId,
    Value<int>? nominatorPlayerId,
    Value<int>? nomineePlayerId,
    Value<bool>? passed,
    Value<String>? voteResultJson,
  }) {
    return NominationsCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      dayRecordId: dayRecordId ?? this.dayRecordId,
      nominatorPlayerId: nominatorPlayerId ?? this.nominatorPlayerId,
      nomineePlayerId: nomineePlayerId ?? this.nomineePlayerId,
      passed: passed ?? this.passed,
      voteResultJson: voteResultJson ?? this.voteResultJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (dayRecordId.present) {
      map['day_record_id'] = Variable<int>(dayRecordId.value);
    }
    if (nominatorPlayerId.present) {
      map['nominator_player_id'] = Variable<int>(nominatorPlayerId.value);
    }
    if (nomineePlayerId.present) {
      map['nominee_player_id'] = Variable<int>(nomineePlayerId.value);
    }
    if (passed.present) {
      map['passed'] = Variable<bool>(passed.value);
    }
    if (voteResultJson.present) {
      map['vote_result_json'] = Variable<String>(voteResultJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NominationsCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('dayRecordId: $dayRecordId, ')
          ..write('nominatorPlayerId: $nominatorPlayerId, ')
          ..write('nomineePlayerId: $nomineePlayerId, ')
          ..write('passed: $passed, ')
          ..write('voteResultJson: $voteResultJson')
          ..write(')'))
        .toString();
  }
}

class $PoisonStatusesTable extends PoisonStatuses
    with TableInfo<$PoisonStatusesTable, PoisonStatus> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PoisonStatusesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dayNumberMeta = const VerificationMeta(
    'dayNumber',
  );
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
    'day_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PoisonSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PoisonSource>($PoisonStatusesTable.$convertersource);
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    playerId,
    dayNumber,
    source,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'poison_statuses';
  @override
  VerificationContext validateIntegrity(
    Insertable<PoisonStatus> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('day_number')) {
      context.handle(
        _dayNumberMeta,
        dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_dayNumberMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PoisonStatus map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PoisonStatus(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      dayNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_number'],
      )!,
      source: $PoisonStatusesTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $PoisonStatusesTable createAlias(String alias) {
    return $PoisonStatusesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PoisonSource, String, String> $convertersource =
      const EnumNameConverter<PoisonSource>(PoisonSource.values);
}

class PoisonStatus extends DataClass implements Insertable<PoisonStatus> {
  /// 自增主键。
  final int id;

  /// 所属对局。
  final int gameId;

  /// 玩家。
  final int playerId;

  /// 生效天数。
  final int dayNumber;

  /// 污染来源。
  final PoisonSource source;

  /// 当前是否生效（毒只在当夜+次日生效，可解除）。
  final bool isActive;
  const PoisonStatus({
    required this.id,
    required this.gameId,
    required this.playerId,
    required this.dayNumber,
    required this.source,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<int>(gameId);
    map['player_id'] = Variable<int>(playerId);
    map['day_number'] = Variable<int>(dayNumber);
    {
      map['source'] = Variable<String>(
        $PoisonStatusesTable.$convertersource.toSql(source),
      );
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  PoisonStatusesCompanion toCompanion(bool nullToAbsent) {
    return PoisonStatusesCompanion(
      id: Value(id),
      gameId: Value(gameId),
      playerId: Value(playerId),
      dayNumber: Value(dayNumber),
      source: Value(source),
      isActive: Value(isActive),
    );
  }

  factory PoisonStatus.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PoisonStatus(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int>(json['gameId']),
      playerId: serializer.fromJson<int>(json['playerId']),
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      source: $PoisonStatusesTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int>(gameId),
      'playerId': serializer.toJson<int>(playerId),
      'dayNumber': serializer.toJson<int>(dayNumber),
      'source': serializer.toJson<String>(
        $PoisonStatusesTable.$convertersource.toJson(source),
      ),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  PoisonStatus copyWith({
    int? id,
    int? gameId,
    int? playerId,
    int? dayNumber,
    PoisonSource? source,
    bool? isActive,
  }) => PoisonStatus(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    playerId: playerId ?? this.playerId,
    dayNumber: dayNumber ?? this.dayNumber,
    source: source ?? this.source,
    isActive: isActive ?? this.isActive,
  );
  PoisonStatus copyWithCompanion(PoisonStatusesCompanion data) {
    return PoisonStatus(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      source: data.source.present ? data.source.value : this.source,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PoisonStatus(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('playerId: $playerId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('source: $source, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, gameId, playerId, dayNumber, source, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PoisonStatus &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.playerId == this.playerId &&
          other.dayNumber == this.dayNumber &&
          other.source == this.source &&
          other.isActive == this.isActive);
}

class PoisonStatusesCompanion extends UpdateCompanion<PoisonStatus> {
  final Value<int> id;
  final Value<int> gameId;
  final Value<int> playerId;
  final Value<int> dayNumber;
  final Value<PoisonSource> source;
  final Value<bool> isActive;
  const PoisonStatusesCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.dayNumber = const Value.absent(),
    this.source = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  PoisonStatusesCompanion.insert({
    this.id = const Value.absent(),
    required int gameId,
    required int playerId,
    required int dayNumber,
    required PoisonSource source,
    this.isActive = const Value.absent(),
  }) : gameId = Value(gameId),
       playerId = Value(playerId),
       dayNumber = Value(dayNumber),
       source = Value(source);
  static Insertable<PoisonStatus> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<int>? playerId,
    Expression<int>? dayNumber,
    Expression<String>? source,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (playerId != null) 'player_id': playerId,
      if (dayNumber != null) 'day_number': dayNumber,
      if (source != null) 'source': source,
      if (isActive != null) 'is_active': isActive,
    });
  }

  PoisonStatusesCompanion copyWith({
    Value<int>? id,
    Value<int>? gameId,
    Value<int>? playerId,
    Value<int>? dayNumber,
    Value<PoisonSource>? source,
    Value<bool>? isActive,
  }) {
    return PoisonStatusesCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      playerId: playerId ?? this.playerId,
      dayNumber: dayNumber ?? this.dayNumber,
      source: source ?? this.source,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $PoisonStatusesTable.$convertersource.toSql(source.value),
      );
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PoisonStatusesCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('playerId: $playerId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('source: $source, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $BehaviorNotesTable extends BehaviorNotes
    with TableInfo<$BehaviorNotesTable, BehaviorNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BehaviorNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES players (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dayNumberMeta = const VerificationMeta(
    'dayNumber',
  );
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
    'day_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    playerId,
    dayNumber,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'behavior_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<BehaviorNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('day_number')) {
      context.handle(
        _dayNumberMeta,
        dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_dayNumberMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BehaviorNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BehaviorNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      dayNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_number'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BehaviorNotesTable createAlias(String alias) {
    return $BehaviorNotesTable(attachedDatabase, alias);
  }
}

class BehaviorNote extends DataClass implements Insertable<BehaviorNote> {
  /// 自增主键。
  final int id;

  /// 所属对局。
  final int gameId;

  /// 玩家。
  final int playerId;

  /// 天数。
  final int dayNumber;

  /// 备注内容。
  final String note;

  /// 记录时间。
  final DateTime createdAt;
  const BehaviorNote({
    required this.id,
    required this.gameId,
    required this.playerId,
    required this.dayNumber,
    required this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<int>(gameId);
    map['player_id'] = Variable<int>(playerId);
    map['day_number'] = Variable<int>(dayNumber);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BehaviorNotesCompanion toCompanion(bool nullToAbsent) {
    return BehaviorNotesCompanion(
      id: Value(id),
      gameId: Value(gameId),
      playerId: Value(playerId),
      dayNumber: Value(dayNumber),
      note: Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory BehaviorNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BehaviorNote(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int>(json['gameId']),
      playerId: serializer.fromJson<int>(json['playerId']),
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int>(gameId),
      'playerId': serializer.toJson<int>(playerId),
      'dayNumber': serializer.toJson<int>(dayNumber),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BehaviorNote copyWith({
    int? id,
    int? gameId,
    int? playerId,
    int? dayNumber,
    String? note,
    DateTime? createdAt,
  }) => BehaviorNote(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    playerId: playerId ?? this.playerId,
    dayNumber: dayNumber ?? this.dayNumber,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  BehaviorNote copyWithCompanion(BehaviorNotesCompanion data) {
    return BehaviorNote(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BehaviorNote(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('playerId: $playerId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, gameId, playerId, dayNumber, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BehaviorNote &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.playerId == this.playerId &&
          other.dayNumber == this.dayNumber &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class BehaviorNotesCompanion extends UpdateCompanion<BehaviorNote> {
  final Value<int> id;
  final Value<int> gameId;
  final Value<int> playerId;
  final Value<int> dayNumber;
  final Value<String> note;
  final Value<DateTime> createdAt;
  const BehaviorNotesCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.dayNumber = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BehaviorNotesCompanion.insert({
    this.id = const Value.absent(),
    required int gameId,
    required int playerId,
    required int dayNumber,
    required String note,
    required DateTime createdAt,
  }) : gameId = Value(gameId),
       playerId = Value(playerId),
       dayNumber = Value(dayNumber),
       note = Value(note),
       createdAt = Value(createdAt);
  static Insertable<BehaviorNote> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<int>? playerId,
    Expression<int>? dayNumber,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (playerId != null) 'player_id': playerId,
      if (dayNumber != null) 'day_number': dayNumber,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BehaviorNotesCompanion copyWith({
    Value<int>? id,
    Value<int>? gameId,
    Value<int>? playerId,
    Value<int>? dayNumber,
    Value<String>? note,
    Value<DateTime>? createdAt,
  }) {
    return BehaviorNotesCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      playerId: playerId ?? this.playerId,
      dayNumber: dayNumber ?? this.dayNumber,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BehaviorNotesCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('playerId: $playerId, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GamesTable games = $GamesTable(this);
  late final $PlayersTable players = $PlayersTable(this);
  late final $DayRecordsTable dayRecords = $DayRecordsTable(this);
  late final $RoleClaimsTable roleClaims = $RoleClaimsTable(this);
  late final $InfoDeclarationsTable infoDeclarations = $InfoDeclarationsTable(
    this,
  );
  late final $TrustLogsTable trustLogs = $TrustLogsTable(this);
  late final $NominationsTable nominations = $NominationsTable(this);
  late final $PoisonStatusesTable poisonStatuses = $PoisonStatusesTable(this);
  late final $BehaviorNotesTable behaviorNotes = $BehaviorNotesTable(this);
  late final GamesDao gamesDao = GamesDao(this as AppDatabase);
  late final PlayersDao playersDao = PlayersDao(this as AppDatabase);
  late final DayRecordsDao dayRecordsDao = DayRecordsDao(this as AppDatabase);
  late final RoleClaimsDao roleClaimsDao = RoleClaimsDao(this as AppDatabase);
  late final InfoDeclarationsDao infoDeclarationsDao = InfoDeclarationsDao(
    this as AppDatabase,
  );
  late final TrustLogsDao trustLogsDao = TrustLogsDao(this as AppDatabase);
  late final NominationsDao nominationsDao = NominationsDao(
    this as AppDatabase,
  );
  late final PoisonStatusesDao poisonStatusesDao = PoisonStatusesDao(
    this as AppDatabase,
  );
  late final BehaviorNotesDao behaviorNotesDao = BehaviorNotesDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    games,
    players,
    dayRecords,
    roleClaims,
    infoDeclarations,
    trustLogs,
    nominations,
    poisonStatuses,
    behaviorNotes,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('players', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('day_records', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'players',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('role_claims', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'day_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('role_claims', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'players',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('info_declarations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'day_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('info_declarations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('trust_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'players',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('trust_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('nominations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'day_records',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('nominations', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('poison_statuses', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'players',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('poison_statuses', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('behavior_notes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'players',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('behavior_notes', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$GamesTableCreateCompanionBuilder =
    GamesCompanion Function({
      Value<int> id,
      required Script script,
      required int playerCount,
      required GameStatus status,
      required DateTime createdAt,
      Value<Character?> myRole,
      Value<int?> myPlayerId,
      Value<String?> demonBluffsJson,
    });
typedef $$GamesTableUpdateCompanionBuilder =
    GamesCompanion Function({
      Value<int> id,
      Value<Script> script,
      Value<int> playerCount,
      Value<GameStatus> status,
      Value<DateTime> createdAt,
      Value<Character?> myRole,
      Value<int?> myPlayerId,
      Value<String?> demonBluffsJson,
    });

final class $$GamesTableReferences
    extends BaseReferences<_$AppDatabase, $GamesTable, Game> {
  $$GamesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlayersTable, List<Player>> _playersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.players,
    aliasName: 'games__id__players__game_id',
  );

  $$PlayersTableProcessedTableManager get playersRefs {
    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DayRecordsTable, List<DayRecord>>
  _dayRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dayRecords,
    aliasName: 'games__id__day_records__game_id',
  );

  $$DayRecordsTableProcessedTableManager get dayRecordsRefs {
    final manager = $$DayRecordsTableTableManager(
      $_db,
      $_db.dayRecords,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_dayRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TrustLogsTable, List<TrustLog>>
  _trustLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trustLogs,
    aliasName: 'games__id__trust_logs__game_id',
  );

  $$TrustLogsTableProcessedTableManager get trustLogsRefs {
    final manager = $$TrustLogsTableTableManager(
      $_db,
      $_db.trustLogs,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trustLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NominationsTable, List<Nomination>>
  _nominationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.nominations,
    aliasName: 'games__id__nominations__game_id',
  );

  $$NominationsTableProcessedTableManager get nominationsRefs {
    final manager = $$NominationsTableTableManager(
      $_db,
      $_db.nominations,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_nominationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PoisonStatusesTable, List<PoisonStatus>>
  _poisonStatusesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.poisonStatuses,
    aliasName: 'games__id__poison_statuses__game_id',
  );

  $$PoisonStatusesTableProcessedTableManager get poisonStatusesRefs {
    final manager = $$PoisonStatusesTableTableManager(
      $_db,
      $_db.poisonStatuses,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_poisonStatusesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BehaviorNotesTable, List<BehaviorNote>>
  _behaviorNotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.behaviorNotes,
    aliasName: 'games__id__behavior_notes__game_id',
  );

  $$BehaviorNotesTableProcessedTableManager get behaviorNotesRefs {
    final manager = $$BehaviorNotesTableTableManager(
      $_db,
      $_db.behaviorNotes,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_behaviorNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GamesTableFilterComposer extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Script, Script, int> get script =>
      $composableBuilder(
        column: $table.script,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get playerCount => $composableBuilder(
    column: $table.playerCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GameStatus, GameStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Character?, Character, int> get myRole =>
      $composableBuilder(
        column: $table.myRole,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get myPlayerId => $composableBuilder(
    column: $table.myPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get demonBluffsJson => $composableBuilder(
    column: $table.demonBluffsJson,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playersRefs(
    Expression<bool> Function($$PlayersTableFilterComposer f) f,
  ) {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dayRecordsRefs(
    Expression<bool> Function($$DayRecordsTableFilterComposer f) f,
  ) {
    final $$DayRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dayRecords,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayRecordsTableFilterComposer(
            $db: $db,
            $table: $db.dayRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> trustLogsRefs(
    Expression<bool> Function($$TrustLogsTableFilterComposer f) f,
  ) {
    final $$TrustLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trustLogs,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrustLogsTableFilterComposer(
            $db: $db,
            $table: $db.trustLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> nominationsRefs(
    Expression<bool> Function($$NominationsTableFilterComposer f) f,
  ) {
    final $$NominationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nominations,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NominationsTableFilterComposer(
            $db: $db,
            $table: $db.nominations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> poisonStatusesRefs(
    Expression<bool> Function($$PoisonStatusesTableFilterComposer f) f,
  ) {
    final $$PoisonStatusesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poisonStatuses,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoisonStatusesTableFilterComposer(
            $db: $db,
            $table: $db.poisonStatuses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> behaviorNotesRefs(
    Expression<bool> Function($$BehaviorNotesTableFilterComposer f) f,
  ) {
    final $$BehaviorNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.behaviorNotes,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BehaviorNotesTableFilterComposer(
            $db: $db,
            $table: $db.behaviorNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GamesTableOrderingComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get script => $composableBuilder(
    column: $table.script,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playerCount => $composableBuilder(
    column: $table.playerCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get myRole => $composableBuilder(
    column: $table.myRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get myPlayerId => $composableBuilder(
    column: $table.myPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get demonBluffsJson => $composableBuilder(
    column: $table.demonBluffsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Script, int> get script =>
      $composableBuilder(column: $table.script, builder: (column) => column);

  GeneratedColumn<int> get playerCount => $composableBuilder(
    column: $table.playerCount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<GameStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Character?, int> get myRole =>
      $composableBuilder(column: $table.myRole, builder: (column) => column);

  GeneratedColumn<int> get myPlayerId => $composableBuilder(
    column: $table.myPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get demonBluffsJson => $composableBuilder(
    column: $table.demonBluffsJson,
    builder: (column) => column,
  );

  Expression<T> playersRefs<T extends Object>(
    Expression<T> Function($$PlayersTableAnnotationComposer a) f,
  ) {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> dayRecordsRefs<T extends Object>(
    Expression<T> Function($$DayRecordsTableAnnotationComposer a) f,
  ) {
    final $$DayRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dayRecords,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.dayRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> trustLogsRefs<T extends Object>(
    Expression<T> Function($$TrustLogsTableAnnotationComposer a) f,
  ) {
    final $$TrustLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trustLogs,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrustLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.trustLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> nominationsRefs<T extends Object>(
    Expression<T> Function($$NominationsTableAnnotationComposer a) f,
  ) {
    final $$NominationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nominations,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NominationsTableAnnotationComposer(
            $db: $db,
            $table: $db.nominations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> poisonStatusesRefs<T extends Object>(
    Expression<T> Function($$PoisonStatusesTableAnnotationComposer a) f,
  ) {
    final $$PoisonStatusesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poisonStatuses,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoisonStatusesTableAnnotationComposer(
            $db: $db,
            $table: $db.poisonStatuses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> behaviorNotesRefs<T extends Object>(
    Expression<T> Function($$BehaviorNotesTableAnnotationComposer a) f,
  ) {
    final $$BehaviorNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.behaviorNotes,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BehaviorNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.behaviorNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GamesTable,
          Game,
          $$GamesTableFilterComposer,
          $$GamesTableOrderingComposer,
          $$GamesTableAnnotationComposer,
          $$GamesTableCreateCompanionBuilder,
          $$GamesTableUpdateCompanionBuilder,
          (Game, $$GamesTableReferences),
          Game,
          PrefetchHooks Function({
            bool playersRefs,
            bool dayRecordsRefs,
            bool trustLogsRefs,
            bool nominationsRefs,
            bool poisonStatusesRefs,
            bool behaviorNotesRefs,
          })
        > {
  $$GamesTableTableManager(_$AppDatabase db, $GamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<Script> script = const Value.absent(),
                Value<int> playerCount = const Value.absent(),
                Value<GameStatus> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<Character?> myRole = const Value.absent(),
                Value<int?> myPlayerId = const Value.absent(),
                Value<String?> demonBluffsJson = const Value.absent(),
              }) => GamesCompanion(
                id: id,
                script: script,
                playerCount: playerCount,
                status: status,
                createdAt: createdAt,
                myRole: myRole,
                myPlayerId: myPlayerId,
                demonBluffsJson: demonBluffsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required Script script,
                required int playerCount,
                required GameStatus status,
                required DateTime createdAt,
                Value<Character?> myRole = const Value.absent(),
                Value<int?> myPlayerId = const Value.absent(),
                Value<String?> demonBluffsJson = const Value.absent(),
              }) => GamesCompanion.insert(
                id: id,
                script: script,
                playerCount: playerCount,
                status: status,
                createdAt: createdAt,
                myRole: myRole,
                myPlayerId: myPlayerId,
                demonBluffsJson: demonBluffsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GamesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                playersRefs = false,
                dayRecordsRefs = false,
                trustLogsRefs = false,
                nominationsRefs = false,
                poisonStatusesRefs = false,
                behaviorNotesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playersRefs) db.players,
                    if (dayRecordsRefs) db.dayRecords,
                    if (trustLogsRefs) db.trustLogs,
                    if (nominationsRefs) db.nominations,
                    if (poisonStatusesRefs) db.poisonStatuses,
                    if (behaviorNotesRefs) db.behaviorNotes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playersRefs)
                        await $_getPrefetchedData<Game, $GamesTable, Player>(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._playersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(db, table, p0).playersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (dayRecordsRefs)
                        await $_getPrefetchedData<Game, $GamesTable, DayRecord>(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._dayRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).dayRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (trustLogsRefs)
                        await $_getPrefetchedData<Game, $GamesTable, TrustLog>(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._trustLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).trustLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (nominationsRefs)
                        await $_getPrefetchedData<
                          Game,
                          $GamesTable,
                          Nomination
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._nominationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).nominationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (poisonStatusesRefs)
                        await $_getPrefetchedData<
                          Game,
                          $GamesTable,
                          PoisonStatus
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._poisonStatusesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).poisonStatusesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (behaviorNotesRefs)
                        await $_getPrefetchedData<
                          Game,
                          $GamesTable,
                          BehaviorNote
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._behaviorNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).behaviorNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GamesTable,
      Game,
      $$GamesTableFilterComposer,
      $$GamesTableOrderingComposer,
      $$GamesTableAnnotationComposer,
      $$GamesTableCreateCompanionBuilder,
      $$GamesTableUpdateCompanionBuilder,
      (Game, $$GamesTableReferences),
      Game,
      PrefetchHooks Function({
        bool playersRefs,
        bool dayRecordsRefs,
        bool trustLogsRefs,
        bool nominationsRefs,
        bool poisonStatusesRefs,
        bool behaviorNotesRefs,
      })
    >;
typedef $$PlayersTableCreateCompanionBuilder =
    PlayersCompanion Function({
      Value<int> id,
      required int gameId,
      required String name,
      required int seatNumber,
      Value<bool> isAlive,
      Value<int?> deathDay,
      Value<DeathCause?> deathCause,
    });
typedef $$PlayersTableUpdateCompanionBuilder =
    PlayersCompanion Function({
      Value<int> id,
      Value<int> gameId,
      Value<String> name,
      Value<int> seatNumber,
      Value<bool> isAlive,
      Value<int?> deathDay,
      Value<DeathCause?> deathCause,
    });

final class $$PlayersTableReferences
    extends BaseReferences<_$AppDatabase, $PlayersTable, Player> {
  $$PlayersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('players__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DayRecordsTable, List<DayRecord>>
  _nightDeathDaysTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dayRecords,
    aliasName: 'players__id__day_records__night_death_player_id',
  );

  $$DayRecordsTableProcessedTableManager get nightDeathDays {
    final manager = $$DayRecordsTableTableManager($_db, $_db.dayRecords).filter(
      (f) => f.nightDeathPlayerId.id.sqlEquals($_itemColumn<int>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_nightDeathDaysTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DayRecordsTable, List<DayRecord>>
  _executionDaysTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dayRecords,
    aliasName: 'players__id__day_records__day_execution_player_id',
  );

  $$DayRecordsTableProcessedTableManager get executionDays {
    final manager = $$DayRecordsTableTableManager($_db, $_db.dayRecords).filter(
      (f) => f.dayExecutionPlayerId.id.sqlEquals($_itemColumn<int>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_executionDaysTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RoleClaimsTable, List<RoleClaim>>
  _roleClaimsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.roleClaims,
    aliasName: 'players__id__role_claims__player_id',
  );

  $$RoleClaimsTableProcessedTableManager get roleClaimsRefs {
    final manager = $$RoleClaimsTableTableManager(
      $_db,
      $_db.roleClaims,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_roleClaimsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InfoDeclarationsTable, List<InfoDeclaration>>
  _infoDeclarationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.infoDeclarations,
    aliasName: 'players__id__info_declarations__player_id',
  );

  $$InfoDeclarationsTableProcessedTableManager get infoDeclarationsRefs {
    final manager = $$InfoDeclarationsTableTableManager(
      $_db,
      $_db.infoDeclarations,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _infoDeclarationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TrustLogsTable, List<TrustLog>>
  _trustLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trustLogs,
    aliasName: 'players__id__trust_logs__player_id',
  );

  $$TrustLogsTableProcessedTableManager get trustLogsRefs {
    final manager = $$TrustLogsTableTableManager(
      $_db,
      $_db.trustLogs,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trustLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PoisonStatusesTable, List<PoisonStatus>>
  _poisonStatusesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.poisonStatuses,
    aliasName: 'players__id__poison_statuses__player_id',
  );

  $$PoisonStatusesTableProcessedTableManager get poisonStatusesRefs {
    final manager = $$PoisonStatusesTableTableManager(
      $_db,
      $_db.poisonStatuses,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_poisonStatusesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BehaviorNotesTable, List<BehaviorNote>>
  _behaviorNotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.behaviorNotes,
    aliasName: 'players__id__behavior_notes__player_id',
  );

  $$BehaviorNotesTableProcessedTableManager get behaviorNotesRefs {
    final manager = $$BehaviorNotesTableTableManager(
      $_db,
      $_db.behaviorNotes,
    ).filter((f) => f.playerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_behaviorNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlayersTableFilterComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seatNumber => $composableBuilder(
    column: $table.seatNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAlive => $composableBuilder(
    column: $table.isAlive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deathDay => $composableBuilder(
    column: $table.deathDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DeathCause?, DeathCause, String>
  get deathCause => $composableBuilder(
    column: $table.deathCause,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> nightDeathDays(
    Expression<bool> Function($$DayRecordsTableFilterComposer f) f,
  ) {
    final $$DayRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dayRecords,
      getReferencedColumn: (t) => t.nightDeathPlayerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayRecordsTableFilterComposer(
            $db: $db,
            $table: $db.dayRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> executionDays(
    Expression<bool> Function($$DayRecordsTableFilterComposer f) f,
  ) {
    final $$DayRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dayRecords,
      getReferencedColumn: (t) => t.dayExecutionPlayerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayRecordsTableFilterComposer(
            $db: $db,
            $table: $db.dayRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> roleClaimsRefs(
    Expression<bool> Function($$RoleClaimsTableFilterComposer f) f,
  ) {
    final $$RoleClaimsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.roleClaims,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoleClaimsTableFilterComposer(
            $db: $db,
            $table: $db.roleClaims,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> infoDeclarationsRefs(
    Expression<bool> Function($$InfoDeclarationsTableFilterComposer f) f,
  ) {
    final $$InfoDeclarationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.infoDeclarations,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InfoDeclarationsTableFilterComposer(
            $db: $db,
            $table: $db.infoDeclarations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> trustLogsRefs(
    Expression<bool> Function($$TrustLogsTableFilterComposer f) f,
  ) {
    final $$TrustLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trustLogs,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrustLogsTableFilterComposer(
            $db: $db,
            $table: $db.trustLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> poisonStatusesRefs(
    Expression<bool> Function($$PoisonStatusesTableFilterComposer f) f,
  ) {
    final $$PoisonStatusesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poisonStatuses,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoisonStatusesTableFilterComposer(
            $db: $db,
            $table: $db.poisonStatuses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> behaviorNotesRefs(
    Expression<bool> Function($$BehaviorNotesTableFilterComposer f) f,
  ) {
    final $$BehaviorNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.behaviorNotes,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BehaviorNotesTableFilterComposer(
            $db: $db,
            $table: $db.behaviorNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seatNumber => $composableBuilder(
    column: $table.seatNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAlive => $composableBuilder(
    column: $table.isAlive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deathDay => $composableBuilder(
    column: $table.deathDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deathCause => $composableBuilder(
    column: $table.deathCause,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get seatNumber => $composableBuilder(
    column: $table.seatNumber,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAlive =>
      $composableBuilder(column: $table.isAlive, builder: (column) => column);

  GeneratedColumn<int> get deathDay =>
      $composableBuilder(column: $table.deathDay, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DeathCause?, String> get deathCause =>
      $composableBuilder(
        column: $table.deathCause,
        builder: (column) => column,
      );

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> nightDeathDays<T extends Object>(
    Expression<T> Function($$DayRecordsTableAnnotationComposer a) f,
  ) {
    final $$DayRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dayRecords,
      getReferencedColumn: (t) => t.nightDeathPlayerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.dayRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> executionDays<T extends Object>(
    Expression<T> Function($$DayRecordsTableAnnotationComposer a) f,
  ) {
    final $$DayRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dayRecords,
      getReferencedColumn: (t) => t.dayExecutionPlayerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.dayRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> roleClaimsRefs<T extends Object>(
    Expression<T> Function($$RoleClaimsTableAnnotationComposer a) f,
  ) {
    final $$RoleClaimsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.roleClaims,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoleClaimsTableAnnotationComposer(
            $db: $db,
            $table: $db.roleClaims,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> infoDeclarationsRefs<T extends Object>(
    Expression<T> Function($$InfoDeclarationsTableAnnotationComposer a) f,
  ) {
    final $$InfoDeclarationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.infoDeclarations,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InfoDeclarationsTableAnnotationComposer(
            $db: $db,
            $table: $db.infoDeclarations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> trustLogsRefs<T extends Object>(
    Expression<T> Function($$TrustLogsTableAnnotationComposer a) f,
  ) {
    final $$TrustLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trustLogs,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrustLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.trustLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> poisonStatusesRefs<T extends Object>(
    Expression<T> Function($$PoisonStatusesTableAnnotationComposer a) f,
  ) {
    final $$PoisonStatusesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poisonStatuses,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoisonStatusesTableAnnotationComposer(
            $db: $db,
            $table: $db.poisonStatuses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> behaviorNotesRefs<T extends Object>(
    Expression<T> Function($$BehaviorNotesTableAnnotationComposer a) f,
  ) {
    final $$BehaviorNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.behaviorNotes,
      getReferencedColumn: (t) => t.playerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BehaviorNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.behaviorNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayersTable,
          Player,
          $$PlayersTableFilterComposer,
          $$PlayersTableOrderingComposer,
          $$PlayersTableAnnotationComposer,
          $$PlayersTableCreateCompanionBuilder,
          $$PlayersTableUpdateCompanionBuilder,
          (Player, $$PlayersTableReferences),
          Player,
          PrefetchHooks Function({
            bool gameId,
            bool nightDeathDays,
            bool executionDays,
            bool roleClaimsRefs,
            bool infoDeclarationsRefs,
            bool trustLogsRefs,
            bool poisonStatusesRefs,
            bool behaviorNotesRefs,
          })
        > {
  $$PlayersTableTableManager(_$AppDatabase db, $PlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gameId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> seatNumber = const Value.absent(),
                Value<bool> isAlive = const Value.absent(),
                Value<int?> deathDay = const Value.absent(),
                Value<DeathCause?> deathCause = const Value.absent(),
              }) => PlayersCompanion(
                id: id,
                gameId: gameId,
                name: name,
                seatNumber: seatNumber,
                isAlive: isAlive,
                deathDay: deathDay,
                deathCause: deathCause,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gameId,
                required String name,
                required int seatNumber,
                Value<bool> isAlive = const Value.absent(),
                Value<int?> deathDay = const Value.absent(),
                Value<DeathCause?> deathCause = const Value.absent(),
              }) => PlayersCompanion.insert(
                id: id,
                gameId: gameId,
                name: name,
                seatNumber: seatNumber,
                isAlive: isAlive,
                deathDay: deathDay,
                deathCause: deathCause,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlayersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                gameId = false,
                nightDeathDays = false,
                executionDays = false,
                roleClaimsRefs = false,
                infoDeclarationsRefs = false,
                trustLogsRefs = false,
                poisonStatusesRefs = false,
                behaviorNotesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (nightDeathDays) db.dayRecords,
                    if (executionDays) db.dayRecords,
                    if (roleClaimsRefs) db.roleClaims,
                    if (infoDeclarationsRefs) db.infoDeclarations,
                    if (trustLogsRefs) db.trustLogs,
                    if (poisonStatusesRefs) db.poisonStatuses,
                    if (behaviorNotesRefs) db.behaviorNotes,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (gameId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.gameId,
                                    referencedTable: $$PlayersTableReferences
                                        ._gameIdTable(db),
                                    referencedColumn: $$PlayersTableReferences
                                        ._gameIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (nightDeathDays)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          DayRecord
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._nightDeathDaysTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).nightDeathDays,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.nightDeathPlayerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (executionDays)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          DayRecord
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._executionDaysTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).executionDays,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dayExecutionPlayerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (roleClaimsRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          RoleClaim
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._roleClaimsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).roleClaimsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (infoDeclarationsRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          InfoDeclaration
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._infoDeclarationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).infoDeclarationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (trustLogsRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          TrustLog
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._trustLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).trustLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (poisonStatusesRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          PoisonStatus
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._poisonStatusesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).poisonStatusesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (behaviorNotesRefs)
                        await $_getPrefetchedData<
                          Player,
                          $PlayersTable,
                          BehaviorNote
                        >(
                          currentTable: table,
                          referencedTable: $$PlayersTableReferences
                              ._behaviorNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlayersTableReferences(
                                db,
                                table,
                                p0,
                              ).behaviorNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayersTable,
      Player,
      $$PlayersTableFilterComposer,
      $$PlayersTableOrderingComposer,
      $$PlayersTableAnnotationComposer,
      $$PlayersTableCreateCompanionBuilder,
      $$PlayersTableUpdateCompanionBuilder,
      (Player, $$PlayersTableReferences),
      Player,
      PrefetchHooks Function({
        bool gameId,
        bool nightDeathDays,
        bool executionDays,
        bool roleClaimsRefs,
        bool infoDeclarationsRefs,
        bool trustLogsRefs,
        bool poisonStatusesRefs,
        bool behaviorNotesRefs,
      })
    >;
typedef $$DayRecordsTableCreateCompanionBuilder =
    DayRecordsCompanion Function({
      Value<int> id,
      required int gameId,
      required int dayNumber,
      Value<int?> nightDeathPlayerId,
      Value<int?> dayExecutionPlayerId,
      Value<Character?> undertakerResultRole,
      Value<String> notes,
    });
typedef $$DayRecordsTableUpdateCompanionBuilder =
    DayRecordsCompanion Function({
      Value<int> id,
      Value<int> gameId,
      Value<int> dayNumber,
      Value<int?> nightDeathPlayerId,
      Value<int?> dayExecutionPlayerId,
      Value<Character?> undertakerResultRole,
      Value<String> notes,
    });

final class $$DayRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $DayRecordsTable, DayRecord> {
  $$DayRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('day_records__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlayersTable _nightDeathPlayerIdTable(_$AppDatabase db) =>
      db.players.createAlias('day_records__night_death_player_id__players__id');

  $$PlayersTableProcessedTableManager? get nightDeathPlayerId {
    final $_column = $_itemColumn<int>('night_death_player_id');
    if ($_column == null) return null;
    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nightDeathPlayerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlayersTable _dayExecutionPlayerIdTable(_$AppDatabase db) => db
      .players
      .createAlias('day_records__day_execution_player_id__players__id');

  $$PlayersTableProcessedTableManager? get dayExecutionPlayerId {
    final $_column = $_itemColumn<int>('day_execution_player_id');
    if ($_column == null) return null;
    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _dayExecutionPlayerIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RoleClaimsTable, List<RoleClaim>>
  _roleClaimsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.roleClaims,
    aliasName: 'day_records__id__role_claims__day_record_id',
  );

  $$RoleClaimsTableProcessedTableManager get roleClaimsRefs {
    final manager = $$RoleClaimsTableTableManager(
      $_db,
      $_db.roleClaims,
    ).filter((f) => f.dayRecordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_roleClaimsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InfoDeclarationsTable, List<InfoDeclaration>>
  _infoDeclarationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.infoDeclarations,
    aliasName: 'day_records__id__info_declarations__day_record_id',
  );

  $$InfoDeclarationsTableProcessedTableManager get infoDeclarationsRefs {
    final manager = $$InfoDeclarationsTableTableManager(
      $_db,
      $_db.infoDeclarations,
    ).filter((f) => f.dayRecordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _infoDeclarationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NominationsTable, List<Nomination>>
  _nominationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.nominations,
    aliasName: 'day_records__id__nominations__day_record_id',
  );

  $$NominationsTableProcessedTableManager get nominationsRefs {
    final manager = $$NominationsTableTableManager(
      $_db,
      $_db.nominations,
    ).filter((f) => f.dayRecordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_nominationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DayRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $DayRecordsTable> {
  $$DayRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Character?, Character, int>
  get undertakerResultRole => $composableBuilder(
    column: $table.undertakerResultRole,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableFilterComposer get nightDeathPlayerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nightDeathPlayerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableFilterComposer get dayExecutionPlayerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayExecutionPlayerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> roleClaimsRefs(
    Expression<bool> Function($$RoleClaimsTableFilterComposer f) f,
  ) {
    final $$RoleClaimsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.roleClaims,
      getReferencedColumn: (t) => t.dayRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoleClaimsTableFilterComposer(
            $db: $db,
            $table: $db.roleClaims,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> infoDeclarationsRefs(
    Expression<bool> Function($$InfoDeclarationsTableFilterComposer f) f,
  ) {
    final $$InfoDeclarationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.infoDeclarations,
      getReferencedColumn: (t) => t.dayRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InfoDeclarationsTableFilterComposer(
            $db: $db,
            $table: $db.infoDeclarations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> nominationsRefs(
    Expression<bool> Function($$NominationsTableFilterComposer f) f,
  ) {
    final $$NominationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nominations,
      getReferencedColumn: (t) => t.dayRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NominationsTableFilterComposer(
            $db: $db,
            $table: $db.nominations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DayRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $DayRecordsTable> {
  $$DayRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get undertakerResultRole => $composableBuilder(
    column: $table.undertakerResultRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableOrderingComposer get nightDeathPlayerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nightDeathPlayerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableOrderingComposer get dayExecutionPlayerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayExecutionPlayerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DayRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayRecordsTable> {
  $$DayRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayNumber =>
      $composableBuilder(column: $table.dayNumber, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Character?, int> get undertakerResultRole =>
      $composableBuilder(
        column: $table.undertakerResultRole,
        builder: (column) => column,
      );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableAnnotationComposer get nightDeathPlayerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nightDeathPlayerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableAnnotationComposer get dayExecutionPlayerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayExecutionPlayerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> roleClaimsRefs<T extends Object>(
    Expression<T> Function($$RoleClaimsTableAnnotationComposer a) f,
  ) {
    final $$RoleClaimsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.roleClaims,
      getReferencedColumn: (t) => t.dayRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoleClaimsTableAnnotationComposer(
            $db: $db,
            $table: $db.roleClaims,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> infoDeclarationsRefs<T extends Object>(
    Expression<T> Function($$InfoDeclarationsTableAnnotationComposer a) f,
  ) {
    final $$InfoDeclarationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.infoDeclarations,
      getReferencedColumn: (t) => t.dayRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InfoDeclarationsTableAnnotationComposer(
            $db: $db,
            $table: $db.infoDeclarations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> nominationsRefs<T extends Object>(
    Expression<T> Function($$NominationsTableAnnotationComposer a) f,
  ) {
    final $$NominationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nominations,
      getReferencedColumn: (t) => t.dayRecordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NominationsTableAnnotationComposer(
            $db: $db,
            $table: $db.nominations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DayRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayRecordsTable,
          DayRecord,
          $$DayRecordsTableFilterComposer,
          $$DayRecordsTableOrderingComposer,
          $$DayRecordsTableAnnotationComposer,
          $$DayRecordsTableCreateCompanionBuilder,
          $$DayRecordsTableUpdateCompanionBuilder,
          (DayRecord, $$DayRecordsTableReferences),
          DayRecord,
          PrefetchHooks Function({
            bool gameId,
            bool nightDeathPlayerId,
            bool dayExecutionPlayerId,
            bool roleClaimsRefs,
            bool infoDeclarationsRefs,
            bool nominationsRefs,
          })
        > {
  $$DayRecordsTableTableManager(_$AppDatabase db, $DayRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gameId = const Value.absent(),
                Value<int> dayNumber = const Value.absent(),
                Value<int?> nightDeathPlayerId = const Value.absent(),
                Value<int?> dayExecutionPlayerId = const Value.absent(),
                Value<Character?> undertakerResultRole = const Value.absent(),
                Value<String> notes = const Value.absent(),
              }) => DayRecordsCompanion(
                id: id,
                gameId: gameId,
                dayNumber: dayNumber,
                nightDeathPlayerId: nightDeathPlayerId,
                dayExecutionPlayerId: dayExecutionPlayerId,
                undertakerResultRole: undertakerResultRole,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gameId,
                required int dayNumber,
                Value<int?> nightDeathPlayerId = const Value.absent(),
                Value<int?> dayExecutionPlayerId = const Value.absent(),
                Value<Character?> undertakerResultRole = const Value.absent(),
                Value<String> notes = const Value.absent(),
              }) => DayRecordsCompanion.insert(
                id: id,
                gameId: gameId,
                dayNumber: dayNumber,
                nightDeathPlayerId: nightDeathPlayerId,
                dayExecutionPlayerId: dayExecutionPlayerId,
                undertakerResultRole: undertakerResultRole,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DayRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                gameId = false,
                nightDeathPlayerId = false,
                dayExecutionPlayerId = false,
                roleClaimsRefs = false,
                infoDeclarationsRefs = false,
                nominationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (roleClaimsRefs) db.roleClaims,
                    if (infoDeclarationsRefs) db.infoDeclarations,
                    if (nominationsRefs) db.nominations,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (gameId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.gameId,
                                    referencedTable: $$DayRecordsTableReferences
                                        ._gameIdTable(db),
                                    referencedColumn:
                                        $$DayRecordsTableReferences
                                            ._gameIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (nightDeathPlayerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.nightDeathPlayerId,
                                    referencedTable: $$DayRecordsTableReferences
                                        ._nightDeathPlayerIdTable(db),
                                    referencedColumn:
                                        $$DayRecordsTableReferences
                                            ._nightDeathPlayerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (dayExecutionPlayerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.dayExecutionPlayerId,
                                    referencedTable: $$DayRecordsTableReferences
                                        ._dayExecutionPlayerIdTable(db),
                                    referencedColumn:
                                        $$DayRecordsTableReferences
                                            ._dayExecutionPlayerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (roleClaimsRefs)
                        await $_getPrefetchedData<
                          DayRecord,
                          $DayRecordsTable,
                          RoleClaim
                        >(
                          currentTable: table,
                          referencedTable: $$DayRecordsTableReferences
                              ._roleClaimsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DayRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).roleClaimsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dayRecordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (infoDeclarationsRefs)
                        await $_getPrefetchedData<
                          DayRecord,
                          $DayRecordsTable,
                          InfoDeclaration
                        >(
                          currentTable: table,
                          referencedTable: $$DayRecordsTableReferences
                              ._infoDeclarationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DayRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).infoDeclarationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dayRecordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (nominationsRefs)
                        await $_getPrefetchedData<
                          DayRecord,
                          $DayRecordsTable,
                          Nomination
                        >(
                          currentTable: table,
                          referencedTable: $$DayRecordsTableReferences
                              ._nominationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DayRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).nominationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dayRecordId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DayRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayRecordsTable,
      DayRecord,
      $$DayRecordsTableFilterComposer,
      $$DayRecordsTableOrderingComposer,
      $$DayRecordsTableAnnotationComposer,
      $$DayRecordsTableCreateCompanionBuilder,
      $$DayRecordsTableUpdateCompanionBuilder,
      (DayRecord, $$DayRecordsTableReferences),
      DayRecord,
      PrefetchHooks Function({
        bool gameId,
        bool nightDeathPlayerId,
        bool dayExecutionPlayerId,
        bool roleClaimsRefs,
        bool infoDeclarationsRefs,
        bool nominationsRefs,
      })
    >;
typedef $$RoleClaimsTableCreateCompanionBuilder =
    RoleClaimsCompanion Function({
      Value<int> id,
      required int playerId,
      required int dayRecordId,
      required Character character,
      required ClaimType claimType,
    });
typedef $$RoleClaimsTableUpdateCompanionBuilder =
    RoleClaimsCompanion Function({
      Value<int> id,
      Value<int> playerId,
      Value<int> dayRecordId,
      Value<Character> character,
      Value<ClaimType> claimType,
    });

final class $$RoleClaimsTableReferences
    extends BaseReferences<_$AppDatabase, $RoleClaimsTable, RoleClaim> {
  $$RoleClaimsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlayersTable _playerIdTable(_$AppDatabase db) =>
      db.players.createAlias('role_claims__player_id__players__id');

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<int>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DayRecordsTable _dayRecordIdTable(_$AppDatabase db) =>
      db.dayRecords.createAlias('role_claims__day_record_id__day_records__id');

  $$DayRecordsTableProcessedTableManager get dayRecordId {
    final $_column = $_itemColumn<int>('day_record_id')!;

    final manager = $$DayRecordsTableTableManager(
      $_db,
      $_db.dayRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RoleClaimsTableFilterComposer
    extends Composer<_$AppDatabase, $RoleClaimsTable> {
  $$RoleClaimsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Character, Character, int> get character =>
      $composableBuilder(
        column: $table.character,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ClaimType, ClaimType, String> get claimType =>
      $composableBuilder(
        column: $table.claimType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DayRecordsTableFilterComposer get dayRecordId {
    final $$DayRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayRecordId,
      referencedTable: $db.dayRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayRecordsTableFilterComposer(
            $db: $db,
            $table: $db.dayRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoleClaimsTableOrderingComposer
    extends Composer<_$AppDatabase, $RoleClaimsTable> {
  $$RoleClaimsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get character => $composableBuilder(
    column: $table.character,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get claimType => $composableBuilder(
    column: $table.claimType,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DayRecordsTableOrderingComposer get dayRecordId {
    final $$DayRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayRecordId,
      referencedTable: $db.dayRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.dayRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoleClaimsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoleClaimsTable> {
  $$RoleClaimsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Character, int> get character =>
      $composableBuilder(column: $table.character, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ClaimType, String> get claimType =>
      $composableBuilder(column: $table.claimType, builder: (column) => column);

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DayRecordsTableAnnotationComposer get dayRecordId {
    final $$DayRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayRecordId,
      referencedTable: $db.dayRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.dayRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoleClaimsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoleClaimsTable,
          RoleClaim,
          $$RoleClaimsTableFilterComposer,
          $$RoleClaimsTableOrderingComposer,
          $$RoleClaimsTableAnnotationComposer,
          $$RoleClaimsTableCreateCompanionBuilder,
          $$RoleClaimsTableUpdateCompanionBuilder,
          (RoleClaim, $$RoleClaimsTableReferences),
          RoleClaim,
          PrefetchHooks Function({bool playerId, bool dayRecordId})
        > {
  $$RoleClaimsTableTableManager(_$AppDatabase db, $RoleClaimsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoleClaimsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoleClaimsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoleClaimsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> playerId = const Value.absent(),
                Value<int> dayRecordId = const Value.absent(),
                Value<Character> character = const Value.absent(),
                Value<ClaimType> claimType = const Value.absent(),
              }) => RoleClaimsCompanion(
                id: id,
                playerId: playerId,
                dayRecordId: dayRecordId,
                character: character,
                claimType: claimType,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int playerId,
                required int dayRecordId,
                required Character character,
                required ClaimType claimType,
              }) => RoleClaimsCompanion.insert(
                id: id,
                playerId: playerId,
                dayRecordId: dayRecordId,
                character: character,
                claimType: claimType,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RoleClaimsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playerId = false, dayRecordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable: $$RoleClaimsTableReferences
                                    ._playerIdTable(db),
                                referencedColumn: $$RoleClaimsTableReferences
                                    ._playerIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (dayRecordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dayRecordId,
                                referencedTable: $$RoleClaimsTableReferences
                                    ._dayRecordIdTable(db),
                                referencedColumn: $$RoleClaimsTableReferences
                                    ._dayRecordIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RoleClaimsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoleClaimsTable,
      RoleClaim,
      $$RoleClaimsTableFilterComposer,
      $$RoleClaimsTableOrderingComposer,
      $$RoleClaimsTableAnnotationComposer,
      $$RoleClaimsTableCreateCompanionBuilder,
      $$RoleClaimsTableUpdateCompanionBuilder,
      (RoleClaim, $$RoleClaimsTableReferences),
      RoleClaim,
      PrefetchHooks Function({bool playerId, bool dayRecordId})
    >;
typedef $$InfoDeclarationsTableCreateCompanionBuilder =
    InfoDeclarationsCompanion Function({
      Value<int> id,
      required int playerId,
      required int dayRecordId,
      required Character characterType,
      required String payloadJson,
      required Reliability reliability,
      Value<bool> isMine,
    });
typedef $$InfoDeclarationsTableUpdateCompanionBuilder =
    InfoDeclarationsCompanion Function({
      Value<int> id,
      Value<int> playerId,
      Value<int> dayRecordId,
      Value<Character> characterType,
      Value<String> payloadJson,
      Value<Reliability> reliability,
      Value<bool> isMine,
    });

final class $$InfoDeclarationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $InfoDeclarationsTable, InfoDeclaration> {
  $$InfoDeclarationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlayersTable _playerIdTable(_$AppDatabase db) =>
      db.players.createAlias('info_declarations__player_id__players__id');

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<int>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DayRecordsTable _dayRecordIdTable(_$AppDatabase db) => db.dayRecords
      .createAlias('info_declarations__day_record_id__day_records__id');

  $$DayRecordsTableProcessedTableManager get dayRecordId {
    final $_column = $_itemColumn<int>('day_record_id')!;

    final manager = $$DayRecordsTableTableManager(
      $_db,
      $_db.dayRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InfoDeclarationsTableFilterComposer
    extends Composer<_$AppDatabase, $InfoDeclarationsTable> {
  $$InfoDeclarationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Character, Character, int> get characterType =>
      $composableBuilder(
        column: $table.characterType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Reliability, Reliability, String>
  get reliability => $composableBuilder(
    column: $table.reliability,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isMine => $composableBuilder(
    column: $table.isMine,
    builder: (column) => ColumnFilters(column),
  );

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DayRecordsTableFilterComposer get dayRecordId {
    final $$DayRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayRecordId,
      referencedTable: $db.dayRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayRecordsTableFilterComposer(
            $db: $db,
            $table: $db.dayRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InfoDeclarationsTableOrderingComposer
    extends Composer<_$AppDatabase, $InfoDeclarationsTable> {
  $$InfoDeclarationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get characterType => $composableBuilder(
    column: $table.characterType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reliability => $composableBuilder(
    column: $table.reliability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMine => $composableBuilder(
    column: $table.isMine,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DayRecordsTableOrderingComposer get dayRecordId {
    final $$DayRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayRecordId,
      referencedTable: $db.dayRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.dayRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InfoDeclarationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InfoDeclarationsTable> {
  $$InfoDeclarationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Character, int> get characterType =>
      $composableBuilder(
        column: $table.characterType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Reliability, String> get reliability =>
      $composableBuilder(
        column: $table.reliability,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get isMine =>
      $composableBuilder(column: $table.isMine, builder: (column) => column);

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DayRecordsTableAnnotationComposer get dayRecordId {
    final $$DayRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayRecordId,
      referencedTable: $db.dayRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.dayRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InfoDeclarationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InfoDeclarationsTable,
          InfoDeclaration,
          $$InfoDeclarationsTableFilterComposer,
          $$InfoDeclarationsTableOrderingComposer,
          $$InfoDeclarationsTableAnnotationComposer,
          $$InfoDeclarationsTableCreateCompanionBuilder,
          $$InfoDeclarationsTableUpdateCompanionBuilder,
          (InfoDeclaration, $$InfoDeclarationsTableReferences),
          InfoDeclaration,
          PrefetchHooks Function({bool playerId, bool dayRecordId})
        > {
  $$InfoDeclarationsTableTableManager(
    _$AppDatabase db,
    $InfoDeclarationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InfoDeclarationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InfoDeclarationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InfoDeclarationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> playerId = const Value.absent(),
                Value<int> dayRecordId = const Value.absent(),
                Value<Character> characterType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<Reliability> reliability = const Value.absent(),
                Value<bool> isMine = const Value.absent(),
              }) => InfoDeclarationsCompanion(
                id: id,
                playerId: playerId,
                dayRecordId: dayRecordId,
                characterType: characterType,
                payloadJson: payloadJson,
                reliability: reliability,
                isMine: isMine,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int playerId,
                required int dayRecordId,
                required Character characterType,
                required String payloadJson,
                required Reliability reliability,
                Value<bool> isMine = const Value.absent(),
              }) => InfoDeclarationsCompanion.insert(
                id: id,
                playerId: playerId,
                dayRecordId: dayRecordId,
                characterType: characterType,
                payloadJson: payloadJson,
                reliability: reliability,
                isMine: isMine,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InfoDeclarationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playerId = false, dayRecordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable:
                                    $$InfoDeclarationsTableReferences
                                        ._playerIdTable(db),
                                referencedColumn:
                                    $$InfoDeclarationsTableReferences
                                        ._playerIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (dayRecordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dayRecordId,
                                referencedTable:
                                    $$InfoDeclarationsTableReferences
                                        ._dayRecordIdTable(db),
                                referencedColumn:
                                    $$InfoDeclarationsTableReferences
                                        ._dayRecordIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InfoDeclarationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InfoDeclarationsTable,
      InfoDeclaration,
      $$InfoDeclarationsTableFilterComposer,
      $$InfoDeclarationsTableOrderingComposer,
      $$InfoDeclarationsTableAnnotationComposer,
      $$InfoDeclarationsTableCreateCompanionBuilder,
      $$InfoDeclarationsTableUpdateCompanionBuilder,
      (InfoDeclaration, $$InfoDeclarationsTableReferences),
      InfoDeclaration,
      PrefetchHooks Function({bool playerId, bool dayRecordId})
    >;
typedef $$TrustLogsTableCreateCompanionBuilder =
    TrustLogsCompanion Function({
      Value<int> id,
      required int gameId,
      required int playerId,
      required int dayNumber,
      required TrustLevel trustLevel,
    });
typedef $$TrustLogsTableUpdateCompanionBuilder =
    TrustLogsCompanion Function({
      Value<int> id,
      Value<int> gameId,
      Value<int> playerId,
      Value<int> dayNumber,
      Value<TrustLevel> trustLevel,
    });

final class $$TrustLogsTableReferences
    extends BaseReferences<_$AppDatabase, $TrustLogsTable, TrustLog> {
  $$TrustLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('trust_logs__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlayersTable _playerIdTable(_$AppDatabase db) =>
      db.players.createAlias('trust_logs__player_id__players__id');

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<int>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrustLogsTableFilterComposer
    extends Composer<_$AppDatabase, $TrustLogsTable> {
  $$TrustLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TrustLevel, TrustLevel, String>
  get trustLevel => $composableBuilder(
    column: $table.trustLevel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrustLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrustLogsTable> {
  $$TrustLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trustLevel => $composableBuilder(
    column: $table.trustLevel,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrustLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrustLogsTable> {
  $$TrustLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayNumber =>
      $composableBuilder(column: $table.dayNumber, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TrustLevel, String> get trustLevel =>
      $composableBuilder(
        column: $table.trustLevel,
        builder: (column) => column,
      );

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrustLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrustLogsTable,
          TrustLog,
          $$TrustLogsTableFilterComposer,
          $$TrustLogsTableOrderingComposer,
          $$TrustLogsTableAnnotationComposer,
          $$TrustLogsTableCreateCompanionBuilder,
          $$TrustLogsTableUpdateCompanionBuilder,
          (TrustLog, $$TrustLogsTableReferences),
          TrustLog,
          PrefetchHooks Function({bool gameId, bool playerId})
        > {
  $$TrustLogsTableTableManager(_$AppDatabase db, $TrustLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrustLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrustLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrustLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gameId = const Value.absent(),
                Value<int> playerId = const Value.absent(),
                Value<int> dayNumber = const Value.absent(),
                Value<TrustLevel> trustLevel = const Value.absent(),
              }) => TrustLogsCompanion(
                id: id,
                gameId: gameId,
                playerId: playerId,
                dayNumber: dayNumber,
                trustLevel: trustLevel,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gameId,
                required int playerId,
                required int dayNumber,
                required TrustLevel trustLevel,
              }) => TrustLogsCompanion.insert(
                id: id,
                gameId: gameId,
                playerId: playerId,
                dayNumber: dayNumber,
                trustLevel: trustLevel,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TrustLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false, playerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.gameId,
                                referencedTable: $$TrustLogsTableReferences
                                    ._gameIdTable(db),
                                referencedColumn: $$TrustLogsTableReferences
                                    ._gameIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable: $$TrustLogsTableReferences
                                    ._playerIdTable(db),
                                referencedColumn: $$TrustLogsTableReferences
                                    ._playerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrustLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrustLogsTable,
      TrustLog,
      $$TrustLogsTableFilterComposer,
      $$TrustLogsTableOrderingComposer,
      $$TrustLogsTableAnnotationComposer,
      $$TrustLogsTableCreateCompanionBuilder,
      $$TrustLogsTableUpdateCompanionBuilder,
      (TrustLog, $$TrustLogsTableReferences),
      TrustLog,
      PrefetchHooks Function({bool gameId, bool playerId})
    >;
typedef $$NominationsTableCreateCompanionBuilder =
    NominationsCompanion Function({
      Value<int> id,
      required int gameId,
      required int dayRecordId,
      required int nominatorPlayerId,
      required int nomineePlayerId,
      required bool passed,
      required String voteResultJson,
    });
typedef $$NominationsTableUpdateCompanionBuilder =
    NominationsCompanion Function({
      Value<int> id,
      Value<int> gameId,
      Value<int> dayRecordId,
      Value<int> nominatorPlayerId,
      Value<int> nomineePlayerId,
      Value<bool> passed,
      Value<String> voteResultJson,
    });

final class $$NominationsTableReferences
    extends BaseReferences<_$AppDatabase, $NominationsTable, Nomination> {
  $$NominationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('nominations__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DayRecordsTable _dayRecordIdTable(_$AppDatabase db) =>
      db.dayRecords.createAlias('nominations__day_record_id__day_records__id');

  $$DayRecordsTableProcessedTableManager get dayRecordId {
    final $_column = $_itemColumn<int>('day_record_id')!;

    final manager = $$DayRecordsTableTableManager(
      $_db,
      $_db.dayRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlayersTable _nominatorPlayerIdTable(_$AppDatabase db) =>
      db.players.createAlias('nominations__nominator_player_id__players__id');

  $$PlayersTableProcessedTableManager get nominatorPlayerId {
    final $_column = $_itemColumn<int>('nominator_player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nominatorPlayerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlayersTable _nomineePlayerIdTable(_$AppDatabase db) =>
      db.players.createAlias('nominations__nominee_player_id__players__id');

  $$PlayersTableProcessedTableManager get nomineePlayerId {
    final $_column = $_itemColumn<int>('nominee_player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nomineePlayerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NominationsTableFilterComposer
    extends Composer<_$AppDatabase, $NominationsTable> {
  $$NominationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get passed => $composableBuilder(
    column: $table.passed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voteResultJson => $composableBuilder(
    column: $table.voteResultJson,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DayRecordsTableFilterComposer get dayRecordId {
    final $$DayRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayRecordId,
      referencedTable: $db.dayRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayRecordsTableFilterComposer(
            $db: $db,
            $table: $db.dayRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableFilterComposer get nominatorPlayerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nominatorPlayerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableFilterComposer get nomineePlayerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nomineePlayerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NominationsTableOrderingComposer
    extends Composer<_$AppDatabase, $NominationsTable> {
  $$NominationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get passed => $composableBuilder(
    column: $table.passed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voteResultJson => $composableBuilder(
    column: $table.voteResultJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DayRecordsTableOrderingComposer get dayRecordId {
    final $$DayRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayRecordId,
      referencedTable: $db.dayRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.dayRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableOrderingComposer get nominatorPlayerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nominatorPlayerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableOrderingComposer get nomineePlayerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nomineePlayerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NominationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NominationsTable> {
  $$NominationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get passed =>
      $composableBuilder(column: $table.passed, builder: (column) => column);

  GeneratedColumn<String> get voteResultJson => $composableBuilder(
    column: $table.voteResultJson,
    builder: (column) => column,
  );

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DayRecordsTableAnnotationComposer get dayRecordId {
    final $$DayRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayRecordId,
      referencedTable: $db.dayRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.dayRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableAnnotationComposer get nominatorPlayerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nominatorPlayerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableAnnotationComposer get nomineePlayerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nomineePlayerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NominationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NominationsTable,
          Nomination,
          $$NominationsTableFilterComposer,
          $$NominationsTableOrderingComposer,
          $$NominationsTableAnnotationComposer,
          $$NominationsTableCreateCompanionBuilder,
          $$NominationsTableUpdateCompanionBuilder,
          (Nomination, $$NominationsTableReferences),
          Nomination,
          PrefetchHooks Function({
            bool gameId,
            bool dayRecordId,
            bool nominatorPlayerId,
            bool nomineePlayerId,
          })
        > {
  $$NominationsTableTableManager(_$AppDatabase db, $NominationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NominationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NominationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NominationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gameId = const Value.absent(),
                Value<int> dayRecordId = const Value.absent(),
                Value<int> nominatorPlayerId = const Value.absent(),
                Value<int> nomineePlayerId = const Value.absent(),
                Value<bool> passed = const Value.absent(),
                Value<String> voteResultJson = const Value.absent(),
              }) => NominationsCompanion(
                id: id,
                gameId: gameId,
                dayRecordId: dayRecordId,
                nominatorPlayerId: nominatorPlayerId,
                nomineePlayerId: nomineePlayerId,
                passed: passed,
                voteResultJson: voteResultJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gameId,
                required int dayRecordId,
                required int nominatorPlayerId,
                required int nomineePlayerId,
                required bool passed,
                required String voteResultJson,
              }) => NominationsCompanion.insert(
                id: id,
                gameId: gameId,
                dayRecordId: dayRecordId,
                nominatorPlayerId: nominatorPlayerId,
                nomineePlayerId: nomineePlayerId,
                passed: passed,
                voteResultJson: voteResultJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NominationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                gameId = false,
                dayRecordId = false,
                nominatorPlayerId = false,
                nomineePlayerId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (gameId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.gameId,
                                    referencedTable:
                                        $$NominationsTableReferences
                                            ._gameIdTable(db),
                                    referencedColumn:
                                        $$NominationsTableReferences
                                            ._gameIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (dayRecordId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.dayRecordId,
                                    referencedTable:
                                        $$NominationsTableReferences
                                            ._dayRecordIdTable(db),
                                    referencedColumn:
                                        $$NominationsTableReferences
                                            ._dayRecordIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (nominatorPlayerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.nominatorPlayerId,
                                    referencedTable:
                                        $$NominationsTableReferences
                                            ._nominatorPlayerIdTable(db),
                                    referencedColumn:
                                        $$NominationsTableReferences
                                            ._nominatorPlayerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (nomineePlayerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.nomineePlayerId,
                                    referencedTable:
                                        $$NominationsTableReferences
                                            ._nomineePlayerIdTable(db),
                                    referencedColumn:
                                        $$NominationsTableReferences
                                            ._nomineePlayerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$NominationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NominationsTable,
      Nomination,
      $$NominationsTableFilterComposer,
      $$NominationsTableOrderingComposer,
      $$NominationsTableAnnotationComposer,
      $$NominationsTableCreateCompanionBuilder,
      $$NominationsTableUpdateCompanionBuilder,
      (Nomination, $$NominationsTableReferences),
      Nomination,
      PrefetchHooks Function({
        bool gameId,
        bool dayRecordId,
        bool nominatorPlayerId,
        bool nomineePlayerId,
      })
    >;
typedef $$PoisonStatusesTableCreateCompanionBuilder =
    PoisonStatusesCompanion Function({
      Value<int> id,
      required int gameId,
      required int playerId,
      required int dayNumber,
      required PoisonSource source,
      Value<bool> isActive,
    });
typedef $$PoisonStatusesTableUpdateCompanionBuilder =
    PoisonStatusesCompanion Function({
      Value<int> id,
      Value<int> gameId,
      Value<int> playerId,
      Value<int> dayNumber,
      Value<PoisonSource> source,
      Value<bool> isActive,
    });

final class $$PoisonStatusesTableReferences
    extends BaseReferences<_$AppDatabase, $PoisonStatusesTable, PoisonStatus> {
  $$PoisonStatusesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('poison_statuses__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlayersTable _playerIdTable(_$AppDatabase db) =>
      db.players.createAlias('poison_statuses__player_id__players__id');

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<int>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PoisonStatusesTableFilterComposer
    extends Composer<_$AppDatabase, $PoisonStatusesTable> {
  $$PoisonStatusesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PoisonSource, PoisonSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PoisonStatusesTableOrderingComposer
    extends Composer<_$AppDatabase, $PoisonStatusesTable> {
  $$PoisonStatusesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PoisonStatusesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PoisonStatusesTable> {
  $$PoisonStatusesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayNumber =>
      $composableBuilder(column: $table.dayNumber, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PoisonSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PoisonStatusesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PoisonStatusesTable,
          PoisonStatus,
          $$PoisonStatusesTableFilterComposer,
          $$PoisonStatusesTableOrderingComposer,
          $$PoisonStatusesTableAnnotationComposer,
          $$PoisonStatusesTableCreateCompanionBuilder,
          $$PoisonStatusesTableUpdateCompanionBuilder,
          (PoisonStatus, $$PoisonStatusesTableReferences),
          PoisonStatus,
          PrefetchHooks Function({bool gameId, bool playerId})
        > {
  $$PoisonStatusesTableTableManager(
    _$AppDatabase db,
    $PoisonStatusesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PoisonStatusesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PoisonStatusesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PoisonStatusesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gameId = const Value.absent(),
                Value<int> playerId = const Value.absent(),
                Value<int> dayNumber = const Value.absent(),
                Value<PoisonSource> source = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => PoisonStatusesCompanion(
                id: id,
                gameId: gameId,
                playerId: playerId,
                dayNumber: dayNumber,
                source: source,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gameId,
                required int playerId,
                required int dayNumber,
                required PoisonSource source,
                Value<bool> isActive = const Value.absent(),
              }) => PoisonStatusesCompanion.insert(
                id: id,
                gameId: gameId,
                playerId: playerId,
                dayNumber: dayNumber,
                source: source,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PoisonStatusesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false, playerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.gameId,
                                referencedTable: $$PoisonStatusesTableReferences
                                    ._gameIdTable(db),
                                referencedColumn:
                                    $$PoisonStatusesTableReferences
                                        ._gameIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable: $$PoisonStatusesTableReferences
                                    ._playerIdTable(db),
                                referencedColumn:
                                    $$PoisonStatusesTableReferences
                                        ._playerIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PoisonStatusesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PoisonStatusesTable,
      PoisonStatus,
      $$PoisonStatusesTableFilterComposer,
      $$PoisonStatusesTableOrderingComposer,
      $$PoisonStatusesTableAnnotationComposer,
      $$PoisonStatusesTableCreateCompanionBuilder,
      $$PoisonStatusesTableUpdateCompanionBuilder,
      (PoisonStatus, $$PoisonStatusesTableReferences),
      PoisonStatus,
      PrefetchHooks Function({bool gameId, bool playerId})
    >;
typedef $$BehaviorNotesTableCreateCompanionBuilder =
    BehaviorNotesCompanion Function({
      Value<int> id,
      required int gameId,
      required int playerId,
      required int dayNumber,
      required String note,
      required DateTime createdAt,
    });
typedef $$BehaviorNotesTableUpdateCompanionBuilder =
    BehaviorNotesCompanion Function({
      Value<int> id,
      Value<int> gameId,
      Value<int> playerId,
      Value<int> dayNumber,
      Value<String> note,
      Value<DateTime> createdAt,
    });

final class $$BehaviorNotesTableReferences
    extends BaseReferences<_$AppDatabase, $BehaviorNotesTable, BehaviorNote> {
  $$BehaviorNotesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('behavior_notes__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlayersTable _playerIdTable(_$AppDatabase db) =>
      db.players.createAlias('behavior_notes__player_id__players__id');

  $$PlayersTableProcessedTableManager get playerId {
    final $_column = $_itemColumn<int>('player_id')!;

    final manager = $$PlayersTableTableManager(
      $_db,
      $_db.players,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BehaviorNotesTableFilterComposer
    extends Composer<_$AppDatabase, $BehaviorNotesTable> {
  $$BehaviorNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableFilterComposer get playerId {
    final $$PlayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableFilterComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BehaviorNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $BehaviorNotesTable> {
  $$BehaviorNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableOrderingComposer get playerId {
    final $$PlayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableOrderingComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BehaviorNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BehaviorNotesTable> {
  $$BehaviorNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayNumber =>
      $composableBuilder(column: $table.dayNumber, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlayersTableAnnotationComposer get playerId {
    final $$PlayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playerId,
      referencedTable: $db.players,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayersTableAnnotationComposer(
            $db: $db,
            $table: $db.players,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BehaviorNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BehaviorNotesTable,
          BehaviorNote,
          $$BehaviorNotesTableFilterComposer,
          $$BehaviorNotesTableOrderingComposer,
          $$BehaviorNotesTableAnnotationComposer,
          $$BehaviorNotesTableCreateCompanionBuilder,
          $$BehaviorNotesTableUpdateCompanionBuilder,
          (BehaviorNote, $$BehaviorNotesTableReferences),
          BehaviorNote,
          PrefetchHooks Function({bool gameId, bool playerId})
        > {
  $$BehaviorNotesTableTableManager(_$AppDatabase db, $BehaviorNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BehaviorNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BehaviorNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BehaviorNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gameId = const Value.absent(),
                Value<int> playerId = const Value.absent(),
                Value<int> dayNumber = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BehaviorNotesCompanion(
                id: id,
                gameId: gameId,
                playerId: playerId,
                dayNumber: dayNumber,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gameId,
                required int playerId,
                required int dayNumber,
                required String note,
                required DateTime createdAt,
              }) => BehaviorNotesCompanion.insert(
                id: id,
                gameId: gameId,
                playerId: playerId,
                dayNumber: dayNumber,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BehaviorNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false, playerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.gameId,
                                referencedTable: $$BehaviorNotesTableReferences
                                    ._gameIdTable(db),
                                referencedColumn: $$BehaviorNotesTableReferences
                                    ._gameIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (playerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playerId,
                                referencedTable: $$BehaviorNotesTableReferences
                                    ._playerIdTable(db),
                                referencedColumn: $$BehaviorNotesTableReferences
                                    ._playerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BehaviorNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BehaviorNotesTable,
      BehaviorNote,
      $$BehaviorNotesTableFilterComposer,
      $$BehaviorNotesTableOrderingComposer,
      $$BehaviorNotesTableAnnotationComposer,
      $$BehaviorNotesTableCreateCompanionBuilder,
      $$BehaviorNotesTableUpdateCompanionBuilder,
      (BehaviorNote, $$BehaviorNotesTableReferences),
      BehaviorNote,
      PrefetchHooks Function({bool gameId, bool playerId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db, _db.games);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db, _db.players);
  $$DayRecordsTableTableManager get dayRecords =>
      $$DayRecordsTableTableManager(_db, _db.dayRecords);
  $$RoleClaimsTableTableManager get roleClaims =>
      $$RoleClaimsTableTableManager(_db, _db.roleClaims);
  $$InfoDeclarationsTableTableManager get infoDeclarations =>
      $$InfoDeclarationsTableTableManager(_db, _db.infoDeclarations);
  $$TrustLogsTableTableManager get trustLogs =>
      $$TrustLogsTableTableManager(_db, _db.trustLogs);
  $$NominationsTableTableManager get nominations =>
      $$NominationsTableTableManager(_db, _db.nominations);
  $$PoisonStatusesTableTableManager get poisonStatuses =>
      $$PoisonStatusesTableTableManager(_db, _db.poisonStatuses);
  $$BehaviorNotesTableTableManager get behaviorNotes =>
      $$BehaviorNotesTableTableManager(_db, _db.behaviorNotes);
}
