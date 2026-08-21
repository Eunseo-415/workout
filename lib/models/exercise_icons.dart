import 'package:flutter/material.dart';

/// 커스텀 운동 아이콘 선택 목록에 쓰이는 항목 하나.
///
/// [key]는 저장소에 영구 보관되는 값이므로, [Icon.codePoint]처럼 폰트 트리
/// 셰이킹에 따라 값이 흔들릴 수 있는 필드 대신 문자열 키로 아이콘을 식별한다.
class ExerciseIconChoice {
  final String key;
  final IconData icon;
  const ExerciseIconChoice(this.key, this.icon);
}

/// Material Icons 중 운동/스포츠와 관련된 아이콘만 추린 목록.
/// 커스텀 운동을 추가할 때 사용자가 이 중에서 아이콘을 고른다.
const List<ExerciseIconChoice> kExerciseIconChoices = [
  ExerciseIconChoice('fitness_center', Icons.fitness_center),
  ExerciseIconChoice('sports_gymnastics', Icons.sports_gymnastics),
  ExerciseIconChoice('sports_martial_arts', Icons.sports_martial_arts),
  ExerciseIconChoice('sports_mma', Icons.sports_mma),
  ExerciseIconChoice('sports_kabaddi', Icons.sports_kabaddi),
  ExerciseIconChoice('directions_run', Icons.directions_run),
  ExerciseIconChoice('directions_walk', Icons.directions_walk),
  ExerciseIconChoice('directions_bike', Icons.directions_bike),
  ExerciseIconChoice('pool', Icons.pool),
  ExerciseIconChoice('rowing', Icons.rowing),
  ExerciseIconChoice('self_improvement', Icons.self_improvement),
  ExerciseIconChoice('terrain', Icons.terrain),
  ExerciseIconChoice('hiking', Icons.hiking),
  ExerciseIconChoice('nordic_walking', Icons.nordic_walking),
  ExerciseIconChoice('sports_tennis', Icons.sports_tennis),
  ExerciseIconChoice('sports_basketball', Icons.sports_basketball),
  ExerciseIconChoice('sports_soccer', Icons.sports_soccer),
  ExerciseIconChoice('sports_volleyball', Icons.sports_volleyball),
  ExerciseIconChoice('sports_football', Icons.sports_football),
  ExerciseIconChoice('sports_rugby', Icons.sports_rugby),
  ExerciseIconChoice('sports_handball', Icons.sports_handball),
  ExerciseIconChoice('sports_hockey', Icons.sports_hockey),
  ExerciseIconChoice('sports_cricket', Icons.sports_cricket),
  ExerciseIconChoice('sports_golf', Icons.sports_golf),
  ExerciseIconChoice('ice_skating', Icons.ice_skating),
  ExerciseIconChoice('kitesurfing', Icons.kitesurfing),
  ExerciseIconChoice('surfing', Icons.surfing),
  ExerciseIconChoice('kayaking', Icons.kayaking),
  ExerciseIconChoice('skateboarding', Icons.skateboarding),
  ExerciseIconChoice('snowboarding', Icons.snowboarding),
  ExerciseIconChoice('downhill_skiing', Icons.downhill_skiing),
  ExerciseIconChoice('paragliding', Icons.paragliding),
  ExerciseIconChoice('sports_score', Icons.sports_score),
  ExerciseIconChoice('monitor_heart', Icons.monitor_heart),
  ExerciseIconChoice('favorite', Icons.favorite),
  ExerciseIconChoice('bolt', Icons.bolt),
  ExerciseIconChoice('timer', Icons.timer),
  ExerciseIconChoice('accessibility_new', Icons.accessibility_new),
];

final Map<String, IconData> _exerciseIconByKey = {
  for (final choice in kExerciseIconChoices) choice.key: choice.icon,
};

/// 기본 커스텀 운동 아이콘 키 (디자인 원본의 sparkle 아이콘에 대응).
const String kDefaultCustomIconKey = 'auto_awesome';

const IconData kCustomExerciseIcon = Icons.auto_awesome;

/// [key]에 해당하는 아이콘을 찾는다. 목록에 없거나(구버전 데이터 등) 알 수
/// 없는 키라면 기본 커스텀 아이콘으로 대체한다.
IconData iconForKey(String key) => _exerciseIconByKey[key] ?? kCustomExerciseIcon;
