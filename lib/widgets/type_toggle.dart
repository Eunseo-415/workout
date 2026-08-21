import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';

/// Strength/Cardio 종류를 고르는 두 칸짜리 세그먼트 토글.
class TypeToggle extends StatelessWidget {
  final ExerciseType type;
  final AppLocalizations loc;
  final ValueChanged<ExerciseType> onChanged;

  const TypeToggle({
    super.key,
    required this.type,
    required this.loc,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          for (final t in ExerciseType.values) ...[
            if (t != ExerciseType.values.first)
              Container(width: 1, height: 32, color: AppColors.divider),
            Expanded(child: _option(t)),
          ],
        ],
      ),
    );
  }

  Widget _option(ExerciseType t) {
    final selected = t == type;
    return InkWell(
      onTap: () => onChanged(t),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 7),
        color: selected ? AppColors.accent : Colors.transparent,
        child: Text(
          t.label(loc),
          style: TextStyle(
            fontSize: 13,
            color: selected ? AppColors.bg : AppColors.text,
          ),
        ),
      ),
    );
  }
}
