import 'package:flutter/material.dart';

import '../models/exercise.dart';

/// 운동 종목 키에 해당하는 아이콘을 그린다. 미리 정의된 종목이면 해당 아이콘을,
/// 그 외(커스텀 종목)에는 [kCustomExerciseIcon]을 사용한다 — 디자인 원본과 동일한 규칙.
class ExerciseIcon extends StatelessWidget {
  final String exerciseKey;
  final double size;
  final Color? color;

  const ExerciseIcon({
    super.key,
    required this.exerciseKey,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final icon = presetForKey(exerciseKey)?.icon ?? kCustomExerciseIcon;
    return Icon(icon, size: size, color: color);
  }
}
