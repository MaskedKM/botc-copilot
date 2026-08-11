import 'package:botc_copilot/core/database/app_database.dart';
import 'package:botc_copilot/feature/player_detail/domain/info_payload_formatter.dart';
import 'package:botc_copilot/shared/models/enums.dart';

/// 时间线事件类型。
enum TimelineEventType {
  /// 夜晚死亡。
  nightDeath,

  /// 白天处决。
  execution,

  /// 掘墓人信息。
  undertakerResult,

  /// 角色声明。
  roleClaim,

  /// 信息声明。
  infoDeclaration,

  /// 醉/毒标记（issue #35）。
  poisonMarked,
}

/// 一条时间线事件。
class TimelineEvent {
  /// 创建事件。
  const TimelineEvent({
    required this.type,
    required this.summary,
    this.playerId,
  });

  /// 事件类型（决定图标与颜色）。
  final TimelineEventType type;

  /// 可读摘要。
  final String summary;

  /// 相关玩家 id（可空，如无人死亡）。
  final int? playerId;
}

/// 按天分组的时间线。
class TimelineDay {
  /// 创建天分组。
  const TimelineDay({required this.dayNumber, required this.events});

  /// 天数。
  final int dayNumber;

  /// 当日事件（按记录顺序）。
  final List<TimelineEvent> events;
}

/// 时间线构建器：day_records + role_claims + info_declarations 联合。
abstract final class TimelineBuilder {
  /// 从数据库记录构建按天分组的时间线。
  static List<TimelineDay> build({
    required List<DayRecord> days,
    required List<RoleClaim> claims,
    required List<InfoDeclaration> declarations,
    required Map<int, Player> playersById,
    required Map<int, int> dayRecordToDayNumber,
    List<PoisonStatuse> poisonStatuses = const [],
  }) {
    String nameOf(int? playerId) {
      if (playerId == null) return '';
      final p = playersById[playerId];
      return p != null ? '${p.seatNumber}号 ${p.name}' : '?';
    }

    final sortedDays = [...days]..sort(
        (a, b) => a.dayNumber.compareTo(b.dayNumber),
      );
    return [
      for (final day in sortedDays)
        TimelineDay(
          dayNumber: day.dayNumber,
          events: [
            // 夜晚死亡
            if (day.nightDeathPlayerId != null)
              TimelineEvent(
                type: TimelineEventType.nightDeath,
                summary: '${nameOf(day.nightDeathPlayerId)} 夜晚死亡',
                playerId: day.nightDeathPlayerId,
              )
            else
              const TimelineEvent(
                type: TimelineEventType.nightDeath,
                summary: '夜晚无人死亡',
              ),
            // 角色声明（该天的）
            for (final claim in claims.where(
              (c) => dayRecordToDayNumber[c.dayRecordId] == day.dayNumber,
            ))
              TimelineEvent(
                type: TimelineEventType.roleClaim,
                summary: '${nameOf(claim.playerId)} 声明 ${claim.character.nameCn}'
                    '${claim.claimType == ClaimType.changed ? '（改口）' : ''}'
                    '${claim.claimType == ClaimType.revealedOnDeath ? '（死亡揭示）' : ''}',
                playerId: claim.playerId,
              ),
            // 信息声明（该天的）
            for (final decl in declarations.where(
              (d) => dayRecordToDayNumber[d.dayRecordId] == day.dayNumber,
            ))
              TimelineEvent(
                type: TimelineEventType.infoDeclaration,
                summary: decl.isMine
                    ? '我（${nameOf(decl.playerId)}）获得 ${InfoPayloadFormatter.summarize(decl)}'
                    : '${nameOf(decl.playerId)} 报 ${InfoPayloadFormatter.summarize(decl)}',
                playerId: decl.playerId,
              ),
            // 处决
            if (day.dayExecutionPlayerId != null)
              TimelineEvent(
                type: TimelineEventType.execution,
                summary: '${nameOf(day.dayExecutionPlayerId)} 被处决',
                playerId: day.dayExecutionPlayerId,
              ),
            // 醉/毒标记（该天的）
            for (final ps in poisonStatuses.where(
              (p) => p.dayNumber == day.dayNumber && p.isActive,
            ))
              TimelineEvent(
                type: TimelineEventType.poisonMarked,
                summary:
                    '${nameOf(ps.playerId)} 可能被${ps.source.nameCn}（信息可能不可靠）',
                playerId: ps.playerId,
              ),
            // 掘墓人信息
            if (day.undertakerResultRole != null)
              TimelineEvent(
                type: TimelineEventType.undertakerResult,
                summary: '掘墓人：被处决者是 ${day.undertakerResultRole!.nameCn}',
              ),
          ],
        ),
    ];
  }
}
