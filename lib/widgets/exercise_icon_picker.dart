import 'package:flutter/material.dart';

import '../models/exercise_icons.dart';
import '../theme/app_theme.dart';

/// Material Icons 중 운동 관련 아이콘 목록을 그리드로 보여주는 선택기.
class ExerciseIconPicker extends StatelessWidget {
  final String selectedKey;
  final ValueChanged<String> onChanged;

  const ExerciseIconPicker({
    super.key,
    required this.selectedKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: GridView.count(
        crossAxisCount: 6,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: [
          for (final choice in kExerciseIconChoices)
            IconChoiceButton(
              choice: choice,
              selected: choice.key == selectedKey,
              onTap: () => onChanged(choice.key),
            ),
        ],
      ),
    );
  }
}

class IconChoiceButton extends StatelessWidget {
  final ExerciseIconChoice choice;
  final bool selected;
  final VoidCallback onTap;

  const IconChoiceButton({
    super.key,
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent100 : AppColors.surface,
          border: Border.all(
              color: selected ? AppColors.accent : Colors.transparent),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          choice.icon,
          size: 20,
          color: selected ? AppColors.accent800 : AppColors.text,
        ),
      ),
    );
  }
}
