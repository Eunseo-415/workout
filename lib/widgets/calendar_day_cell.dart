import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme/app_theme.dart';
import 'exercise_icon.dart';

class CalendarDay {
  final String dateStr;
  final int dayNum;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final List<String> shownExerciseKeys;
  final int overflowCount;

  const CalendarDay({
    required this.dateStr,
    required this.dayNum,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.shownExerciseKeys,
    required this.overflowCount,
  });
}

class DayCell extends StatelessWidget {
  final CalendarDay day;
  final List<CustomExercise> customExercises;
  final VoidCallback onTap;
  const DayCell({
    super.key,
    required this.day,
    required this.customExercises,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final numColor = day.isSelected
        ? AppColors.accent800
        : (day.isToday ? AppColors.accent700 : AppColors.text);
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: day.inMonth ? 1 : 0.32,
        child: Container(
          padding: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: day.isSelected ? AppColors.accent100 : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${day.dayNum}',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.15,
                  fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w400,
                  color: numColor,
                ),
              ),
              const SizedBox(height: 3),
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  children: [
                    for (final key in day.shownExerciseKeys)
                      ExerciseIcon(
                        exerciseKey: key,
                        customExercises: customExercises,
                        size: 11,
                        color: AppColors.accent700,
                      ),
                    if (day.overflowCount > 0)
                      Text(
                        '+${day.overflowCount}',
                        style: const TextStyle(
                            fontSize: 9,
                            height: 1.15,
                            color: AppColors.accent700),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
