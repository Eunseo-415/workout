import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme/app_theme.dart';
import 'exercise_icon.dart';

class ExerciseChip extends StatelessWidget {
  final String label;
  final String exerciseKey;
  final List<CustomExercise> customExercises;
  final bool selected;
  final VoidCallback onTap;

  const ExerciseChip({
    super.key,
    required this.label,
    required this.exerciseKey,
    required this.customExercises,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent100 : Colors.transparent,
          border: Border.all(color: selected ? AppColors.accent : Colors.transparent),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExerciseIcon(
              exerciseKey: exerciseKey,
              customExercises: customExercises,
              size: 22,
              color: selected ? AppColors.accent800 : AppColors.text,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  color: selected ? AppColors.accent800 : AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
