import 'package:flutter/material.dart';

import '../models/exercise.dart';

/// 운동 종목 키에 해당하는 아이콘을 그린다. 미리 정의된 종목이면 해당 아이콘을,
/// 커스텀 종목이면 사용자가 고른 아이콘을 [customExercises]에서 찾아 사용한다.
class ExerciseIcon extends StatelessWidget {
  final String exerciseKey;
  final List<CustomExercise> customExercises;
  final double size;
  final Color? color;

  const ExerciseIcon({
    super.key,
    required this.exerciseKey,
    this.customExercises = const [],
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final icon = iconForExercise(exerciseKey, customExercises);
    return Icon(icon, size: size, color: color);
  }
}
