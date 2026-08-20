import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// 미리 정의된 운동 종목 하나(칩 목록에 항상 표시됨).
class ExercisePreset {
  final String key;
  final IconData icon;
  final String Function(AppLocalizations loc) _label;

  const ExercisePreset({
    required this.key,
    required this.icon,
    required String Function(AppLocalizations loc) label,
  }) : _label = label;

  String label(AppLocalizations loc) => _label(loc);
}

const List<ExercisePreset> kExercisePresets = [
  ExercisePreset(
    key: 'strength',
    icon: Icons.fitness_center,
    label: _labelStrength,
  ),
  ExercisePreset(
    key: 'run',
    icon: Icons.directions_run,
    label: _labelRun,
  ),
  ExercisePreset(
    key: 'cycle',
    icon: Icons.directions_bike,
    label: _labelCycle,
  ),
  ExercisePreset(
    key: 'swim',
    icon: Icons.pool,
    label: _labelSwim,
  ),
  ExercisePreset(
    key: 'yoga',
    icon: Icons.self_improvement,
    label: _labelYoga,
  ),
  ExercisePreset(
    key: 'climb',
    icon: Icons.terrain,
    label: _labelClimb,
  ),
];

/// 커스텀 운동 종목에 항상 쓰이는 아이콘(디자인 원본의 sparkle 아이콘에 대응).
const IconData kCustomExerciseIcon = Icons.auto_awesome;

String _labelStrength(AppLocalizations loc) => loc.exerciseStrength;
String _labelRun(AppLocalizations loc) => loc.exerciseRun;
String _labelCycle(AppLocalizations loc) => loc.exerciseCycle;
String _labelSwim(AppLocalizations loc) => loc.exerciseSwim;
String _labelYoga(AppLocalizations loc) => loc.exerciseYoga;
String _labelClimb(AppLocalizations loc) => loc.exerciseClimb;

/// 사용자가 이름만 입력해 추가하는 커스텀 운동 종목. 아이콘은 항상
/// [kCustomExerciseIcon]으로 고정된다(디자인 원본과 동일한 규칙).
ExercisePreset? presetForKey(String key) {
  for (final preset in kExercisePresets) {
    if (preset.key == key) return preset;
  }
  return null;
}

class CustomExercise {
  final String key;
  String name;

  CustomExercise({required this.key, required this.name});

  factory CustomExercise.fromJson(Map<String, dynamic> json) => CustomExercise(
        key: json['key'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'key': key, 'name': name};
}
