import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'exercise_icons.dart';

/// 운동 종목의 대분류. 칩 목록과 커스텀 운동 추가 다이얼로그에서 두 그룹으로
/// 나눠 보여주는 데 쓰인다.
enum ExerciseType {
  strength,
  cardio;

  String label(AppLocalizations loc) => switch (this) {
        ExerciseType.strength => loc.exerciseTypeStrength,
        ExerciseType.cardio => loc.exerciseTypeCardio,
      };

  String toJson() => name;

  static ExerciseType fromJson(String? value) => value == 'cardio'
      ? ExerciseType.cardio
      : ExerciseType.strength;
}

/// 미리 정의된 운동 종목 하나(칩 목록에 항상 표시됨).
class ExercisePreset {
  final String key;
  final IconData icon;
  final ExerciseType type;
  final String Function(AppLocalizations loc) _label;

  const ExercisePreset({
    required this.key,
    required this.icon,
    required this.type,
    required String Function(AppLocalizations loc) label,
  }) : _label = label;

  String label(AppLocalizations loc) => _label(loc);
}

const List<ExercisePreset> kExercisePresets = [
  ExercisePreset(
    key: 'strength',
    icon: Icons.fitness_center,
    type: ExerciseType.strength,
    label: _labelStrength,
  ),
  ExercisePreset(
    key: 'run',
    icon: Icons.directions_run,
    type: ExerciseType.cardio,
    label: _labelRun,
  ),
  ExercisePreset(
    key: 'cycle',
    icon: Icons.directions_bike,
    type: ExerciseType.cardio,
    label: _labelCycle,
  ),
  ExercisePreset(
    key: 'swim',
    icon: Icons.pool,
    type: ExerciseType.cardio,
    label: _labelSwim,
  ),
  ExercisePreset(
    key: 'yoga',
    icon: Icons.self_improvement,
    type: ExerciseType.cardio,
    label: _labelYoga,
  ),
  ExercisePreset(
    key: 'climb',
    icon: Icons.terrain,
    type: ExerciseType.cardio,
    label: _labelClimb,
  ),
];

String _labelStrength(AppLocalizations loc) => loc.exerciseStrength;
String _labelRun(AppLocalizations loc) => loc.exerciseRun;
String _labelCycle(AppLocalizations loc) => loc.exerciseCycle;
String _labelSwim(AppLocalizations loc) => loc.exerciseSwim;
String _labelYoga(AppLocalizations loc) => loc.exerciseYoga;
String _labelClimb(AppLocalizations loc) => loc.exerciseClimb;

ExercisePreset? presetForKey(String key) {
  for (final preset in kExercisePresets) {
    if (preset.key == key) return preset;
  }
  return null;
}

/// 사용자가 이름·종류·아이콘을 직접 골라 추가하는 커스텀 운동 종목.
class CustomExercise {
  final String key;
  String name;
  ExerciseType type;
  String iconKey;

  CustomExercise({
    required this.key,
    required this.name,
    this.type = ExerciseType.strength,
    this.iconKey = kDefaultCustomIconKey,
  });

  factory CustomExercise.fromJson(Map<String, dynamic> json) => CustomExercise(
        key: json['key'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: ExerciseType.fromJson(json['type'] as String?),
        iconKey: json['iconKey'] as String? ?? kDefaultCustomIconKey,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'type': type.toJson(),
        'iconKey': iconKey,
      };
}

CustomExercise? customForKey(String key, List<CustomExercise> customExercises) {
  for (final custom in customExercises) {
    if (custom.key == key) return custom;
  }
  return null;
}

/// 운동 종목 키에 해당하는 아이콘을 찾는다. 미리 정의된 종목이면 해당
/// 아이콘을, 커스텀 종목이면 사용자가 고른 아이콘을, 그 외(알 수 없는 키)에는
/// 기본 커스텀 아이콘을 사용한다.
IconData iconForExercise(String key, List<CustomExercise> customExercises) {
  final preset = presetForKey(key);
  if (preset != null) return preset.icon;
  final custom = customForKey(key, customExercises);
  if (custom != null) return iconForKey(custom.iconKey);
  return kCustomExerciseIcon;
}

/// 운동 종목 키에 해당하는 대분류(strength/cardio)를 찾는다.
ExerciseType? typeForExercise(String key, List<CustomExercise> customExercises) {
  final preset = presetForKey(key);
  if (preset != null) return preset.type;
  return customForKey(key, customExercises)?.type;
}
